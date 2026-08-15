# Decanus

[![axiom gate](https://github.com/ibrahimmian36/decanus/actions/workflows/ci.yml/badge.svg)](https://github.com/ibrahimmian36/decanus/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![axioms](https://img.shields.io/badge/axioms-propext%20%7C%20Classical.choice%20%7C%20Quot.sound-success)](#the-certified-results)

Kernel-certified verification for Erdős problem 647: with τ(m) the number
of divisors of m, is there some n > 24 with max_{m<n}(m + τ(m)) ≤ n + 2?
The condition holds at n = 24, and Erdős offered £25 for any larger
example. The problem is open. This repository does not solve it. What it
contains is the first verification at any finite bound that is checked
end to end by a proof kernel.

## The certified results

    theorem Erdos647.erdos647_no_solution_upto :
        ∀ n : ℕ, 24 < n → n ≤ 10000000 →
          ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2)

    theorem Erdos647.erdos647_no_solution_upto_1e8 :
        ∀ n : ℕ, 24 < n → n ≤ 100000000 →
          ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2)

Both compile in Lean 4.30.0 / mathlib v4.30.0 with axioms exactly
`{propext, Classical.choice, Quot.sound}`: no `sorry`, no `native_decide`,
no extra axioms, enforced by a two-layer gate (`scripts/axiom_gate.sh`, run
in CI on every push). The inner predicate is carried from
google-deepmind/formal-conjectures (`FormalConjectures/ErdosProblems/647.lean`,
commit `c252a41`, pinned; a copy of the upstream file is kept in
`docs/upstream_647_c252a41.lean`), identical up to one coercion the
elaborator inserts either way, so the theorems speak the upstream
statement's vocabulary.

## Two tiers, stated plainly

This is a certification result, not a computational record. Larger
uncertified computations exist and are cited deliberately:

- Exhaustive to 10^12: Idén's segmented multiplicative sieve (2026,
  [doi:10.5281/zenodo.21084248](https://doi.org/10.5281/zenodo.21084248)).
  C implementation, single run, minimum observed gap 224 near 10^11.
- To about 6.157 x 10^17: Hughes's frontier certificate
  ([erdos647-proof-chain](https://github.com/scottdhughes/erdos647-proof-chain)),
  a modular reduction verified in Lean via `native_decide` plus one
  problem-specific axiom, with the 41 open residue classes searched by a
  GPU scan re-derivable by a pure-Python verifier.
- To about 9.174 x 10^18: bentrd's C extension of Hughes's frontier scan
  ([erdos647-frontier-extension](https://github.com/bentrd/erdos647-frontier-extension)).

What this repository adds is that every step below 10^8 — the divisor
bound of every witness, the primality of every listed factor, and the
gapless concatenation of the kill intervals — is checked by the Lean
kernel rather than trusted contributor code, native-compiled evaluation,
or unverified scans.

## Proof architecture

A *kill witness* for n is an m < n with m + τ(m) ≥ n + 3: one witness
rules out every n in [m+1, m+τ(m)−3]. The certificate is a greedy chain
of such witnesses (greedy is optimal for interval covering) whose kill
intervals concatenate without gap: 123,323 witnesses covering (24, 10^7]
(`Erdos647/Certs/`, 31 chunks) and 891,554 covering (24, 10^8]
(`Erdos647/Certs8/`, 223 chunks). Each chunk is a single Bool equality
over the chain checker `chainOk`, evaluated by `decide`.

A witness stores the maximal power of each prime below 1024 dividing m.
The kernel re-multiplies the powers, checks divisibility and maximality,
and reads off τ(m) ≥ ∏(eᵢ+1), doubled when a cofactor remains: maximality
makes the cofactor coprime to the smooth part, so it contributes at least
the divisors 1 and itself. Primality of a listed factor takes eleven trial
divisions (32² = 1024), so no large-prime certificates appear anywhere.
Soundness lemmas are in `Erdos647/TauLower.lean` and `Erdos647/Chain.lean`;
the bridge to the upstream statement is `Erdos647/Bridge.lean`.

A third rung at 10^9 would need roughly 260 MB of certificate source,
which is past what a repository should carry; the ceiling is file size
and kernel time, not mathematics.

## Verifying it yourself

    lake exe cache get
    lake build
    bash scripts/axiom_gate.sh

The gate fails on any theorem whose axiom closure exceeds
{propext, Classical.choice, Quot.sound}, on any `sorry`, and on any
native-code axiom, in two independent layers: a curated `#print axioms`
manifest and a mechanical audit that walks every theorem of every
`Erdos647` module in the compiled environment.

Regenerate the certificates from scratch (two independent implementations;
`verify_chain.py` shares no code with the generator and re-derives every
witness by trial division):

    python3 scripts/gen_chain.py 1e7 data/chain_1e7.jsonl
    python3 scripts/verify_chain.py data/chain_1e7.jsonl 1e7
    python3 scripts/emit_lean.py data/chain_1e7.jsonl 1e7 Erdos647/Certs 4000
    python3 scripts/gen_chain.py 1e8 data/chain_1e8.jsonl
    python3 scripts/verify_chain.py data/chain_1e8.jsonl 1e8
    python3 scripts/emit_lean.py data/chain_1e8.jsonl 1e8 Erdos647/Certs8 4000 1e8

    python3 scripts/cross_check.py

The last command rebuilds τ from scratch by an independent sieve and
confirms the solution set below 10^7 is exactly {2, 3, 4, 5, 6, 8, 10,
12, 24} (OEIS [A087280](https://oeis.org/A087280) plus the trivial small
cases), and spot-checks n + τ(n) against OEIS
[A062249](https://oeis.org/A062249).

## Layout

    Erdos647/Defs.lean       witness format and Bool checkers
    Erdos647/TauLower.lean   soundness: certified divisor-count lower bounds
    Erdos647/Chain.lean      soundness: chain coverage
    Erdos647/Bridge.lean     bridge to the pinned upstream statement
    Erdos647/Certs/          generated chunks, rung (24, 1e7]
    Erdos647/Certs8/         generated chunks, rung (24, 1e8]
    Erdos647/Cert*.lean      generated drivers composing the chunks
    Erdos647/Headline.lean   the two theorems above
    Erdos647/AxiomCheck.lean curated #print axioms manifest
    Erdos647/AxiomAudit.lean mechanical whole-library axiom audit
    scripts/                 generator, verifier, cross-check, gate
    docs/                    pinned upstream copy, drafts

## Context and credit

The structural mathematics of #647 belongs to others: the modular ladder
of Sayan Dutta and Boris Alexeev, Kenta Kitamura's shift condition, and
Scott Hughes's residue reduction, prime-chain families, and density
bounds (see the
[#647 discussion thread](https://www.erdosproblems.com/forum/discuss/647)).
Idén's 10^12 sieve is the reference full-range computation. This
repository is complementary to all of it: a small certified initial
segment, kernel-checked end to end. The certificate shape is the finite,
fully proved version of a domination-interval argument sketched in a
withdrawn January 2026 claim on this problem, whose unproven step was
exactly the assertion that the intervals overlap forever; here the
overlap of every adjacent pair of intervals in the covered range is what
the kernel checks.

Companion repositories: [centurion](https://github.com/ibrahimmian36/centurion)
(Erdős #7), [Optio](https://github.com/ibrahimmian36/Optio) (Erdős #364),
[Pilus](https://github.com/ibrahimmian36/Pilus) (Erdős #486).

Millennium Research: Ibby Mian, Shayaan Siddique.

## License

Apache 2.0.
