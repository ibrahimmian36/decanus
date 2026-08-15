/-
Copyright (c) 2026 Millennium Research. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Millennium Research (Ibby Mian)
-/
import Erdos647.Chain
import Mathlib.NumberTheory.ArithmeticFunction.Defs

/-!
# Bridge to the formal-conjectures statement (Erdős #647)

The formal-conjectures repository states #647 as

  `theorem erdos_647 : answer(sorry) ↔ ∃ n > 24, ⨆ m : Fin n, m + σ 0 m ≤ n + 2`

(google-deepmind/formal-conjectures, `FormalConjectures/ErdosProblems/647.lean`,
pinned at commit `c252a41054125b5fd9c8356e2137cd9b55337657`; a verbatim copy of
that file is kept in `docs/upstream_647_c252a41.lean`). The supremum runs over
`m ∈ {0, …, n−1}`, i.e. `m < n`, and `σ 0` is the divisor-count function.

This file converts a `Killed` witness (`Chain.lean`) into the negation of the
inner predicate: `bounded_exclusion` states that no `n` with `24 < n ≤ X`
satisfies `⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2`, for any `X` covered by a
certified chain. The rung theorems instantiate it at their certified `X`.
-/

namespace Erdos647

open ArithmeticFunction ArithmeticFunction.sigma

theorem sigma_zero_eq_card_divisors (m : ℕ) : σ 0 m = m.divisors.card := by
  simp [ArithmeticFunction.sigma_zero_apply]

/-- A killed `n` refutes the inner predicate of `erdos_647`, verbatim. -/
theorem not_sup_le_of_killed {n : ℕ} (hk : Killed n) :
    ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2) := by
  obtain ⟨m, hmn, hm0, hkill⟩ := hk
  intro hsup
  have hle : (m + σ 0 m : ℕ) ≤ ⨆ m : Fin n, (↑m + σ 0 m : ℕ) := by
    have h := le_ciSup (f := fun k : Fin n => (↑k + σ 0 k : ℕ))
      (Set.Finite.bddAbove (Set.finite_range _)) ⟨m, hmn⟩
    simpa using h
  rw [sigma_zero_eq_card_divisors] at hle
  omega

/-- The bounded exclusion, generic in the chain-certified bound. -/
theorem bounded_exclusion {X : ℕ}
    (hcov : ∀ n : ℕ, 24 < n → n ≤ X → Killed n) :
    ∀ n : ℕ, 24 < n → n ≤ X → ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2) :=
  fun n h24 hX => not_sup_le_of_killed (hcov n h24 hX)

end Erdos647
