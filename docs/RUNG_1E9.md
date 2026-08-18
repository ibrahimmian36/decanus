# The 10^9 rung (release artifact)

A third certified rung extends the exclusion to (24, 10^9]:

    theorem Erdos647.erdos647_no_solution_upto_1e9 :
        ∀ n : ℕ, 24 < n → n ≤ 1000000000 →
          ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2)

    'Erdos647.erdos647_no_solution_upto_1e9' depends on axioms:
    [propext, Classical.choice, Quot.sound]

Its certificate is 6,685,922 witnesses in 1,672 chunk files, about 260 MB
of Lean source: past what a repository should carry, so the source ships
as a release asset rather than in git.

## Provenance

Generated and verified on 2026-08-18 from the scripts at commit adf6670
(tag v1.0.0):

- `gen_chain.py 1e9` produced the chain in 300.7 s (footer: 6,685,922
  witnesses, final cover 1,000,000,021, exhausted [25, 10^9]);
  `verify_chain.py` (the independent pure-Python implementation) replayed
  every witness.
- The chunks were emitted at 4,000 witnesses per file and built on an x86
  host (96 vCPU) under the clang from-source Lean toolchain of the
  verification leg recorded in `docs/verification/`. Every chunk theorem
  is a single `decide`, checked by the kernel during the build. The
  composed driver needed `set_option maxRecDepth 1000000` and
  `set_option maxHeartbeats 0` (1,672 cases exceed the elaborator's
  defaults; `scripts/emit_lean.py` now emits these for every driver).
- `#print axioms` on the theorem returns exactly the three standard
  axioms, which is transitive over all 1,672 chunks: any `sorry` or
  native-code axiom anywhere below would appear in this closure.
- lean4checker replayed the driver and headline modules.

## Trust status, plainly

The 10^7 and 10^8 rungs in this repository are verified on the ARM build
machine, in CI on every push, and by two x86 from-source legs (gcc and
clang) with byte-identical artifacts. The 10^9 rung has been built and
kernel-checked on one machine, once, under the clang from-source
toolchain. Its generation pipeline is the same one shown to reproduce
the lower rungs byte for byte across machines and compilers.

## Reproduce

    python3 scripts/gen_chain.py 1e9 data/chain_1e9.jsonl
    python3 scripts/verify_chain.py data/chain_1e9.jsonl 1e9
    python3 scripts/emit_lean.py data/chain_1e9.jsonl 1e9 Erdos647/Certs9 4000 1e9

then add a headline file instantiating `bounded_exclusion killed_upto_1e9`
and build `Erdos647.Certs9.*`, the driver, and the headline (about 20
CPU-hours; a many-core machine is recommended).

## Artifact

Release asset `results_1e9_experiment.tar.gz`
(sha256 c2d6ddc08ea7c242c35ce35ffecc712caf6f4d21afd0fdb9015b86533c884bcb):
`Erdos647/Certs9/` (1,672 chunk files), `Erdos647/Cert1E9.lean`,
`Erdos647/Headline9.lean`, and the generation and build logs.
