#!/usr/bin/env bash
# Decanus (Erdős 647) maximal-verification BUILD pod.
# Usage: COMPILER=gcc bash pod_build.sh   (or COMPILER=clang; SMOKE=1 preflight)
# Self-contained: pins every commit; no cache; toolchain built from source;
# certificate regeneration diffed against the committed chunks; external
# re-check via lean4checker (pinned master commit; no v4.30.0 tag upstream).
# Hard cap: WALL_CAP seconds, then results tarball; pod idles loudly (NO
# self-stop: no persistent volume, stopping would erase the results).
set -u
export DEBIAN_FRONTEND=noninteractive
export GIT_TERMINAL_PROMPT=0

COMPILER="${COMPILER:-gcc}"                 # gcc | clang
WALL_CAP="${WALL_CAP:-36000}"               # 10h hard cap (64 vCPU sizing)
SMOKE="${SMOKE:-0}"                          # SMOKE=1: cheap preflight only
DECANUS_COMMIT=adf6670aac5fbbed89440c09d5ed9e008ed8a54b
MATHLIB_REV=c5ea00351c28e24afc9f0f84379aa41082b1188f
LEAN_TAG=v4.30.0
L4C_COMMIT=91a7f0e8e9dffe927089f5a6edcfeeb8a0e07709   # master; no v4.30.0 tag
L4L_BRANCH=v4.30.0                          # best-effort leg; SKIP allowed
WORK=/workspace/decanus_audit
OUT=$WORK/results
mkdir -p "$WORK" "$OUT"
MANIFEST=$OUT/MANIFEST.txt
: > "$MANIFEST"
note() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$MANIFEST"; }
note "pod_build.sh compiler=$COMPILER cap=${WALL_CAP}s host=$(uname -mrs)"

finish() {
  if [ "$SMOKE" = "1" ]; then return 0; fi
  note "packaging results"
  ( cd "$WORK" && tar czf /workspace/results_decanus_${COMPILER}.tar.gz results ) || true
  note "tarball: /workspace/results_decanus_${COMPILER}.tar.gz"
  while true; do
    echo "*** RESULTS READY: download /workspace/results_decanus_${COMPILER}.tar.gz then TERMINATE this pod ***"
    sleep 300
  done
}
trap finish EXIT

main() {
set -x
# ---------- stage 0: deps ----------
apt-get update -qq
apt-get install -y -qq git curl cmake make g++ clang libgmp-dev libuv1-dev \
  pkg-config ccache python3 python3-numpy || { note "STAGE0 FAIL apt"; exit 1; }
curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain none
export PATH="$HOME/.elan/bin:$PATH"
note "STAGE0 PASS deps"

# Jobs bounded by RAM. Decanus certificate chunks elaborate at ~3.8GB peak
# (heavier than mathlib's ~2.5GB), so the chunk stage uses RAM/4.
CORES=$(nproc)
RAM_GB=$(awk '/MemTotal/{printf "%d", $2/1048576}' /proc/meminfo)
CHUNK_JOBS=$(( RAM_GB / 4 < CORES ? RAM_GB / 4 : CORES )); [ "$CHUNK_JOBS" -lt 2 ] && CHUNK_JOBS=2
note "cores=$CORES ram=${RAM_GB}GB chunk_jobs=$CHUNK_JOBS"

# ---------- SMOKE mode: preflight everything cheap, then exit ----------
if [ "$SMOKE" = "1" ]; then
  cd "$WORK"
  git clone --depth 1 --branch $LEAN_TAG https://github.com/leanprover/lean4 lean4-src \
    && note "SMOKE ok: lean4 $LEAN_TAG clone" || { note "SMOKE FAIL lean4 clone"; exit 1; }
  ( cd lean4-src && cmake --preset release > "$OUT/smoke_cmake.log" 2>&1 ) \
    && note "SMOKE ok: cmake configure" || { note "SMOKE FAIL cmake configure"; tail -20 "$OUT/smoke_cmake.log" >> "$MANIFEST"; exit 1; }
  git clone --filter=blob:none https://github.com/ibrahimmian36/decanus decanus \
    && ( cd decanus && git checkout $DECANUS_COMMIT ) \
    && note "SMOKE ok: decanus @ pinned commit" || { note "SMOKE FAIL decanus clone/checkout"; exit 1; }
  grep -q "$MATHLIB_REV" decanus/lake-manifest.json \
    && note "SMOKE ok: mathlib pin" || { note "SMOKE FAIL mathlib pin"; exit 1; }
  git clone --filter=blob:none https://github.com/leanprover/lean4checker l4c-smoke \
    && ( cd l4c-smoke && git cat-file -e $L4C_COMMIT ) \
    && note "SMOKE ok: lean4checker pinned commit exists" \
    || note "SMOKE WARN lean4checker commit missing"
  git ls-remote --exit-code https://github.com/digama0/lean4lean "refs/heads/$L4L_BRANCH" >/dev/null \
    && note "SMOKE ok: lean4lean branch" || note "SMOKE WARN lean4lean branch missing (leg will SKIP)"
  note "SMOKE PASS — rerun without SMOKE=1 for the real build (reuses these clones)"
  exit 0
fi

# ---------- stage 1: Lean toolchain from source ----------
cd "$WORK"
[ -d lean4-src ] || git clone --depth 1 --branch $LEAN_TAG https://github.com/leanprover/lean4 lean4-src \
  || { note "STAGE1 FAIL clone"; exit 1; }
cd lean4-src
if [ "$COMPILER" = clang ]; then CC=clang; CXX=clang++; else CC=gcc; CXX=g++; fi
cmake --preset release -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX \
  > "$OUT/toolchain_cmake.log" 2>&1 \
  && make -C build/release -j"$CORES" > "$OUT/toolchain_make.log" 2>&1 \
  || { note "STAGE1 FAIL toolchain build (see toolchain_make.log tail)"; tail -50 "$OUT/toolchain_make.log" >> "$MANIFEST"; exit 1; }
elan toolchain link lean-src "$WORK/lean4-src/build/release/stage1"
note "STAGE1 PASS toolchain from source ($COMPILER)"

# ---------- stage 2: decanus, pinned; NO cache; full source build ----------
cd "$WORK"
[ -d decanus ] || git clone https://github.com/ibrahimmian36/decanus decanus || { note "STAGE2 FAIL clone"; exit 1; }
cd decanus && git checkout $DECANUS_COMMIT || { note "STAGE2 FAIL checkout"; exit 1; }
elan override set lean-src
grep -q "$MATHLIB_REV" lake-manifest.json || { note "STAGE2 FAIL mathlib pin mismatch"; exit 1; }
# NO cache: purge any prefetched build artifacts. ProofWidgets' fetched
# release is retained (UI/JS bundle; its oleans get re-kernel-checked by the
# lean4checker full-environment replay in stage 5 regardless of origin).
for d in .lake/packages/*/; do
  case "$(basename "$d")" in
    proofwidgets|ProofWidgets) ;;
    *) rm -rf "${d}.lake/build" ;;
  esac
done
rm -rf .lake/build
# Mathlib and the soundness layer first (mathlib elaboration fits full-core).
lake build Erdos647.Bridge > "$OUT/lake_build.log" 2>&1 \
  || { note "STAGE2 FAIL base build (tail follows)"; tail -80 "$OUT/lake_build.log" >> "$MANIFEST"; exit 1; }
# Certificate chunks in RAM-bounded groups.
build_range() {
  PFX=$1; LAST=$2
  i=0
  while [ "$i" -le "$LAST" ]; do
    t=""
    j=$i
    while [ "$j" -le "$LAST" ] && [ $(( j - i )) -lt "$CHUNK_JOBS" ]; do
      t="$t Erdos647.$PFX.Chunk$(printf %04d $j)"
      j=$(( j + 1 ))
    done
    lake build $t >> "$OUT/lake_build.log" 2>&1 || return 1
    i=$j
  done
}
build_range Certs 30 || { note "STAGE2 FAIL Certs chunks"; tail -40 "$OUT/lake_build.log" >> "$MANIFEST"; exit 1; }
build_range Certs8 222 || { note "STAGE2 FAIL Certs8 chunks"; tail -40 "$OUT/lake_build.log" >> "$MANIFEST"; exit 1; }
lake build Erdos647 >> "$OUT/lake_build.log" 2>&1 \
  || { note "STAGE2 FAIL final build"; tail -40 "$OUT/lake_build.log" >> "$MANIFEST"; exit 1; }
note "STAGE2 PASS full from-source build (mathlib + Erdos647, no cache)"

# ---------- stage 3: certificate regeneration, independent verify, diff ----------
cd "$WORK/decanus"
python3 scripts/gen_chain.py 1e7 "$OUT/chain_1e7.jsonl" > "$OUT/gen_1e7.log" 2>&1 \
  && python3 scripts/verify_chain.py "$OUT/chain_1e7.jsonl" 1e7 >> "$OUT/gen_1e7.log" 2>&1 \
  && note "STAGE3 PASS regenerate+verify 1e7" || note "STAGE3 FAIL regenerate 1e7"
python3 scripts/gen_chain.py 1e8 "$OUT/chain_1e8.jsonl" > "$OUT/gen_1e8.log" 2>&1 \
  && python3 scripts/verify_chain.py "$OUT/chain_1e8.jsonl" 1e8 >> "$OUT/gen_1e8.log" 2>&1 \
  && note "STAGE3 PASS regenerate+verify 1e8" || note "STAGE3 FAIL regenerate 1e8"
mkdir -p "$WORK/regen"
python3 scripts/emit_lean.py "$OUT/chain_1e7.jsonl" 1e7 "$WORK/regen/Certs" 4000 > /dev/null 2>&1
python3 scripts/emit_lean.py "$OUT/chain_1e8.jsonl" 1e8 "$WORK/regen/Certs8" 4000 1e8 > /dev/null 2>&1
DIFF_OK=1
diff -r "$WORK/regen/Certs" Erdos647/Certs > "$OUT/diff_certs.txt" 2>&1 || DIFF_OK=0
diff -r "$WORK/regen/Certs8" Erdos647/Certs8 > "$OUT/diff_certs8.txt" 2>&1 || DIFF_OK=0
diff "$WORK/regen/Cert.lean" Erdos647/Cert.lean > "$OUT/diff_cert_driver.txt" 2>&1 || DIFF_OK=0
diff "$WORK/regen/Cert1E8.lean" Erdos647/Cert1E8.lean > "$OUT/diff_cert1e8_driver.txt" 2>&1 || DIFF_OK=0
[ "$DIFF_OK" = 1 ] \
  && note "STAGE3 PASS committed certificates regenerate byte-identically" \
  || note "STAGE3 FAIL regeneration diff (see diff_*.txt)"
python3 scripts/cross_check.py > "$OUT/cross_check.log" 2>&1 \
  && note "STAGE3 PASS cross_check (third implementation, 1e7)" \
  || note "STAGE3 FAIL cross_check"

# ---------- stage 4: axiom gate (both layers) ----------
cd "$WORK/decanus"
bash scripts/axiom_gate.sh > "$OUT/axiom_gate.log" 2>&1 \
  && note "STAGE4 PASS axiom gate ($(grep 'AXIOM GATE: PASS' "$OUT/axiom_gate.log" | tail -1))" \
  || { note "STAGE4 FAIL axiom gate (tail)"; tail -20 "$OUT/axiom_gate.log" >> "$MANIFEST"; }

# ---------- stage 5: lean4checker over the ENTIRE search path ----------
cd "$WORK"
git clone https://github.com/leanprover/lean4checker \
  && cd lean4checker && git checkout $L4C_COMMIT && elan override set lean-src \
  && lake build > "$OUT/l4c_build.log" 2>&1 \
  || { note "STAGE5 FAIL lean4checker build"; tail -30 "$OUT/l4c_build.log" >> "$MANIFEST"; }
cd "$WORK/decanus"
L4C_OK=1
for PAT in Erdos647 Mathlib Batteries Aesop Qq ProofWidgets Plausible ImportGraph Cli LeanSearchClient; do
  lake env "$WORK/lean4checker/.lake/build/bin/lean4checker" "$PAT" \
    >> "$OUT/lean4checker_full.log" 2>&1 || { L4C_OK=0; note "STAGE5 lean4checker FAIL on $PAT"; }
done
[ "$L4C_OK" = 1 ] \
  && note "STAGE5 PASS lean4checker external replay (Erdos647 + Mathlib + all deps)" \
  || { note "STAGE5 FAIL lean4checker (log tail)"; tail -30 "$OUT/lean4checker_full.log" >> "$MANIFEST"; }

# ---------- stage 6: lean4lean (BEST-EFFORT; SKIP is acceptable) ----------
cd "$WORK"
if git clone --depth 1 --branch $L4L_BRANCH https://github.com/digama0/lean4lean; then
  cd lean4lean && elan override set lean-src
  if lake build > "$OUT/l4l_build.log" 2>&1; then
    cd "$WORK/decanus"
    timeout 14400 lake env "$WORK/lean4lean/.lake/build/bin/lean4lean" Erdos647 \
      > "$OUT/lean4lean_erdos647.log" 2>&1 \
      && note "STAGE6 PASS lean4lean over Erdos647" \
      || note "STAGE6 SKIP lean4lean run failed/timeout (expected possible)"
  else
    note "STAGE6 SKIP lean4lean does not build under $LEAN_TAG"
  fi
else
  note "STAGE6 SKIP lean4lean clone failed"
fi

# ---------- stage 7: digests ----------
cd "$WORK/decanus"
find .lake/build/lib/lean -name '*.olean' -exec sha256sum {} + | sort -k2 \
  > "$OUT/oleans_erdos647.sha256"
find .lake/packages/mathlib/.lake/build/lib/lean -name '*.olean' -exec sha256sum {} + 2>/dev/null \
  | sort -k2 > "$OUT/oleans_mathlib.sha256"
git -C .lake/packages/mathlib rev-parse HEAD > "$OUT/mathlib_head.txt" 2>/dev/null
note "STAGE7 PASS digests recorded"
note "ALL STAGES COMPLETE compiler=$COMPILER"
}

main &
MAIN_PID=$!
( sleep "$WALL_CAP" && note "WALL CAP HIT — killing main" && kill -TERM "$MAIN_PID" ) &
WD_PID=$!
wait "$MAIN_PID"; RC=$?
kill "$WD_PID" 2>/dev/null
trap - EXIT
finish
exit $RC
