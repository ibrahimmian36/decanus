/-
Copyright (c) 2026 Millennium Research. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Millennium Research (Ibby Mian)
-/
import Mathlib.NumberTheory.Divisors
import Mathlib.NumberTheory.ArithmeticFunction.Defs

/-!
# Witness format and Bool checkers (Erdős #647, step 1)

An exclusion certificate for #647 is a chain of *kill witnesses*. A witness
for the cover position `C` is a number `m = C - d` (stored as the offset `d`)
together with a list of prime-power pairs `(p, e)` whose product divides `m`.
The pairs certify the divisor-count lower bound

  `τ(m) ≥ ∏ (e + 1)`,

which needs no primality certificates for large primes: every `p` in a pair
is below `1024` and is checked prime by eleven trial divisions. A witness
with certified bound `t` kills every `n ∈ [m+1, m+t-3]`, because for such
`n` we have `m < n` and `m + τ(m) ≥ n + 3 > n + 2`.

Everything in this file is a `Bool` computation designed to be evaluated by
the kernel: structural recursion only, no `Nat.sqrt`, no well-founded
recursion, no `Finset`. The soundness lemmas live in `TauLower.lean` and
`Chain.lean`; the generated certificate chunks in `certs/` are checked by a
single `decide` per chunk against `chainOk`.
-/

namespace Erdos647

/-- A witness's prime-power pairs. Stored most-significant prime first,
strictly decreasing, all below `1024`. -/
abbrev Pairs := List (ℕ × ℕ)

/-- `∏ p ^ e` over the pairs. -/
def smoothVal : Pairs → ℕ
  | [] => 1
  | (p, e) :: t => p ^ e * smoothVal t

/-- `∏ (e + 1)` over the pairs: the certified divisor-count lower bound. -/
def smoothTau : Pairs → ℕ
  | [] => 1
  | (_, e) :: t => (e + 1) * smoothTau t

/-- The primes up to `31`: trial divisors sufficient for primality below
`1024 = 32²`. -/
def smallSieve : List ℕ := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]

/-- No element of `l` divides `p`. -/
def noDiv (p : ℕ) : List ℕ → Bool
  | [] => true
  | q :: t => decide (p % q ≠ 0) && noDiv p t

/-- Primality for `p < 1024`, kernel-cheap: either `p` is one of the eleven
trial divisors, or it is in `(31, 1024)` and none of them divides it. -/
def isPrimeSmall (p : ℕ) : Bool :=
  smallSieve.contains p ||
    (decide (31 < p) && decide (p < 1024) && noDiv p smallSieve)

/-- Pairs wellformed below `bound`: heads strictly decreasing (hence
distinct), every head a certified small prime. Call with `bound = 1024`. -/
def pairsOk : ℕ → Pairs → Bool
  | _, [] => true
  | bound, (p, _) :: t => decide (p < bound) && isPrimeSmall p && pairsOk p t

/-- The pairs are the *maximal* powers in `m`: for each `(p, e)`, `p^(e+1)`
does not divide `m`. This makes the cofactor `m / smoothVal ps` coprime to
the smooth part, which is what licenses the factor `2` in `certTau`. -/
def maximalIn (m : ℕ) : Pairs → Bool
  | [] => true
  | (p, e) :: t => decide (m % p ^ (e + 1) ≠ 0) && maximalIn m t

/-- The certified divisor-count lower bound for `m` with maximal smooth
part `ps`: `∏ (e + 1)`, doubled when a nontrivial cofactor remains, since
that cofactor is coprime to the smooth part and contributes at least the
two divisors `1` and itself. -/
def certTau (m : ℕ) (ps : Pairs) : ℕ :=
  if smoothVal ps < m then 2 * smoothTau ps else smoothTau ps

/-- One witness at cover position `C`: offset `d` and pairs `ps` with
`m = C - d`, requiring `0 < m`, wellformed pairs, `smoothVal ps ∣ m`, and
maximality of every listed power. -/
def witnessOk (C : ℕ) (d : ℕ) (ps : Pairs) : Bool :=
  decide (d < C) && pairsOk 1024 ps && decide ((C - d) % smoothVal ps = 0)
    && maximalIn (C - d) ps

/-- Cover position after applying a witness: the killed interval is
`[m+1, m + certTau m ps - 3]`, so the new cover is its right end. -/
def nextCover (C : ℕ) (d : ℕ) (ps : Pairs) : ℕ :=
  (C - d) + certTau (C - d) ps - 3

/-- The chain checker. `chainOk C ws X = true` certifies (via
`Chain.chain_sound`) that every `n` with `C < n ≤ X` is killed by some
witness in `ws`. The recursion is `&&`-chained head-first, so kernel
evaluation is effectively tail recursive. -/
def chainOk : ℕ → List (ℕ × Pairs) → ℕ → Bool
  | C, [], X => decide (X ≤ C)
  | C, (d, ps) :: ws, X => witnessOk C d ps && chainOk (nextCover C d ps) ws X

end Erdos647
