/-
Copyright (c) 2026 Millennium Research. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Millennium Research (Ibby Mian)
-/
import Erdos647.TauLower

/-!
# Chain soundness (Erdős #647, step 3)

`chainOk C ws X = true` means: walking the witness list from cover position
`C`, every witness passes `witnessOk` and the final cover reaches `X`. The
soundness theorem turns this single Bool into the mathematical statement
that every `n ∈ (C, X]` has a divisor-count kill witness:

  `∃ m < n, 0 < m ∧ n + 3 ≤ m + τ(m)`.

This is the exact negation core of #647 on the interval: such an `m` forces
`max_{m' < n}(m' + τ(m')) ≥ n + 3 > n + 2`. The bridge to the
formal-conjectures `⨆` statement is in `Bridge.lean`.
-/

namespace Erdos647

/-- The kill predicate: some `m` below `n` pushes the running maximum of
`m + τ(m)` to at least `n + 3`. -/
def Killed (n : ℕ) : Prop :=
  ∃ m : ℕ, m < n ∧ 0 < m ∧ n + 3 ≤ m + m.divisors.card

theorem chain_sound {ws : List (ℕ × Pairs)} :
    ∀ {C X : ℕ}, chainOk C ws X = true →
      ∀ n : ℕ, C < n → n ≤ X → Killed n := by
  induction ws with
  | nil =>
    intro C X h n hCn hnX
    rw [chainOk, decide_eq_true_eq] at h
    omega
  | cons w ws ih =>
    intro C X h n hCn hnX
    obtain ⟨d, ps⟩ := w
    rw [chainOk, Bool.and_eq_true] at h
    obtain ⟨hw, hchain⟩ := h
    by_cases hcov : n ≤ nextCover C d ps
    · -- killed by this witness: m = C - d
      have hdC : d < C := by
        have := hw
        rw [witnessOk, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true,
          decide_eq_true_eq] at this
        exact this.1.1.1
      have htau : certTau (C - d) ps ≤ (C - d).divisors.card := witness_tau hw
      refine ⟨C - d, by omega, by omega, ?_⟩
      have hnc : n ≤ (C - d) + certTau (C - d) ps - 3 := hcov
      omega
    · -- killed further down the chain
      exact ih hchain n (by omega) hnX

end Erdos647
