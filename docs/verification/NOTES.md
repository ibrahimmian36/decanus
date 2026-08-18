# Verification artifacts

Raw outputs of the two from-source legs (`pods/pod_build.sh`) run on
2026-08-18 on a 96-vCPU x86 host: toolchain built from source (gcc leg,
clang leg), mathlib and the development rebuilt with no cache,
certificates regenerated and diffed against the committed files, axiom
gate re-run, environment replayed with lean4checker, olean digests
recorded.

Two manifest lines need context:

- gcc leg, `STAGE5 lean4checker FAIL on Cli`: the minimal build compiles
  no modules of the `Cli` package, so there were no oleans to replay.
  After `lake build Cli`, its 3 modules replay cleanly (recorded at the
  end of `gcc/lean4checker_full.log`'s session; see also the clang leg,
  where the same explicit build precedes the replay).
- clang leg, `STAGE5 FAIL lean4checker build`: the script's clone step
  collided with the directory left by the gcc leg. The replay was run
  manually with the already-built checker; `clang/lean4checker_replay.log`
  records all ten packages passing, `Cli` included.

The digest files show byte-identical compiled artifacts across the gcc
leg, the clang leg, and the ARM build machine (262 modules).
