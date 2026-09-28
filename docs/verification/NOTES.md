# Verification artifacts

Raw outputs of the two from-source legs of `pods/pod_build.sh`, one with
the Lean toolchain compiled by gcc (`gcc/`) and one by clang (`clang/`).
Each leg's `MANIFEST.txt` records the run: 2026-08-18, x86_64 Linux,
96 cores; toolchain built from source; mathlib and the development
rebuilt with no cache; certificates regenerated and found byte-identical
to the committed files; the axiom gate re-run; the environment replayed
with lean4checker; olean digests recorded.

The legs checked out commit adf6670, which is not in this repository's
history; the script now names tag `v1.0.0`.

lean4checker and the `Cli` package:

- Both manifests record `STAGE5 lean4checker FAIL on Cli`. The stage-5
  log of the gcc leg, `gcc/lean4checker_full.log`, shows the cause:
  `Could not find any oleans for: Cli`, i.e. no compiled `Cli` modules
  were present to replay. Every other package in that log reports its
  module count with no error.
- `clang/lean4checker_replay.log` is a replay over the same ten
  packages in which `Cli` reports 3 modules and no package reports an
  error.
- The clang manifest also records `STAGE5 FAIL lean4checker build`,
  followed by the tail of the checker's build log, which ends in
  `Build completed successfully`. The manifest does not record which
  command in that step returned the failure.

The olean digest files (`oleans_erdos647.sha256`, 262 modules, and
`oleans_mathlib.sha256`) are byte-identical between `gcc/` and `clang/`.
The paper reports that the digests also match those of the ARM build
machine; no ARM digest file is in this repository.

The chunk files of the 10^9 rung are covered separately in
`docs/RUNG_1E9.md`.
