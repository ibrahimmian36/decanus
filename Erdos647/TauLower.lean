/-
Copyright (c) 2026 Millennium Research. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Millennium Research (Ibby Mian)
-/
import Erdos647.Defs
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.NormNum.Prime

/-!
# Soundness of the witness checkers (Erdős #647, step 2)

The Bool checkers of `Defs.lean` certify divisor-count lower bounds:

* `isPrimeSmall p = true → p.Prime` — eleven trial divisions suffice below
  `1024 = 32²`, by the `minFac` square bound.
* `pairsOk b ps = true → (smoothVal ps).divisors.card = smoothTau ps` — the
  pairs are strictly decreasing certified primes, so the prime powers are
  pairwise coprime and the divisor count multiplies out.
* `witnessOk C d ps = true → smoothTau ps ≤ (C - d).divisors.card` — the
  smooth part divides `m = C - d`, and divisor sets are monotone under
  divisibility.

No axioms beyond the standard three enter here; every computation the
kernel will do at certificate-checking time is justified by these lemmas
once, abstractly.
-/

namespace Erdos647

/-! ## Primality below 1024 -/

theorem noDiv_sound {p : ℕ} {l : List ℕ} (h : noDiv p l = true) :
    ∀ q ∈ l, p % q ≠ 0 := by
  induction l with
  | nil => intro q hq; cases hq
  | cons a t ih =>
    rw [noDiv, Bool.and_eq_true, decide_eq_true_eq] at h
    intro q hq
    rcases List.mem_cons.mp hq with rfl | hmem
    · exact h.1
    · exact ih h.2 q hmem

theorem mem_smallSieve_prime {p : ℕ} (h : p ∈ smallSieve) : p.Prime := by
  simp only [smallSieve, List.mem_cons, List.not_mem_nil, or_false] at h
  rcases h with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl
    <;> norm_num

theorem prime_le_31_mem_smallSieve {q : ℕ} (hq : q.Prime) (hle : q ≤ 31) :
    q ∈ smallSieve := by
  interval_cases q <;> revert hq <;> decide

theorem isPrimeSmall_sound {p : ℕ} (h : isPrimeSmall p = true) : p.Prime := by
  rw [isPrimeSmall, Bool.or_eq_true] at h
  rcases h with h | h
  · exact mem_smallSieve_prime (by simpa using h)
  · rw [Bool.and_eq_true, Bool.and_eq_true, decide_eq_true_eq,
      decide_eq_true_eq] at h
    obtain ⟨⟨h31, h1024⟩, hnodiv⟩ := h
    by_contra hnp
    have hminp : p.minFac.Prime := Nat.minFac_prime (by omega)
    have hsq : p.minFac ^ 2 ≤ p := Nat.minFac_sq_le_self (by omega) hnp
    have hlt : p.minFac ≤ 31 := by
      by_contra hgt
      have : 32 ^ 2 ≤ p.minFac ^ 2 := Nat.pow_le_pow_left (by omega) 2
      omega
    have hmem : p.minFac ∈ smallSieve := prime_le_31_mem_smallSieve hminp hlt
    exact noDiv_sound hnodiv p.minFac hmem
      (Nat.dvd_iff_mod_eq_zero.mp (Nat.minFac_dvd p))

/-! ## The smooth part: positivity, prime support, divisor count -/

theorem smoothVal_pos {b : ℕ} {ps : Pairs} (h : pairsOk b ps = true) :
    0 < smoothVal ps := by
  induction ps generalizing b with
  | nil => simp [smoothVal]
  | cons hd t ih =>
    obtain ⟨p, e⟩ := hd
    rw [pairsOk, Bool.and_eq_true, Bool.and_eq_true] at h
    have hp : p.Prime := isPrimeSmall_sound h.1.2
    exact Nat.mul_pos (pow_pos hp.pos e) (ih h.2)

/-- Every prime dividing the smooth part is below the running bound. -/
theorem prime_dvd_smoothVal_lt {b : ℕ} {ps : Pairs} (h : pairsOk b ps = true)
    {q : ℕ} (hq : q.Prime) (hdvd : q ∣ smoothVal ps) : q < b := by
  induction ps generalizing b with
  | nil =>
    exfalso
    exact hq.one_lt.ne' (Nat.eq_one_of_dvd_one (by simpa [smoothVal] using hdvd))
  | cons hd t ih =>
    obtain ⟨p, e⟩ := hd
    rw [pairsOk, Bool.and_eq_true, Bool.and_eq_true, decide_eq_true_eq] at h
    obtain ⟨⟨hpb, hprime⟩, ht⟩ := h
    have hp : p.Prime := isPrimeSmall_sound hprime
    rw [smoothVal] at hdvd
    rcases (Nat.Prime.dvd_mul hq).mp hdvd with hleft | hright
    · have : q = p := (Nat.prime_dvd_prime_iff_eq hq hp).mp
        (hq.dvd_of_dvd_pow hleft)
      omega
    · exact lt_trans (ih ht hright) hpb

theorem coprime_pow_smoothVal {p e : ℕ} {t : Pairs} (hp : p.Prime)
    (ht : pairsOk p t = true) : Nat.Coprime (p ^ e) (smoothVal t) := by
  apply Nat.Coprime.pow_left
  rw [hp.coprime_iff_not_dvd]
  intro hdvd
  exact lt_irrefl p (prime_dvd_smoothVal_lt ht hp hdvd)

/-- The certified divisor count of the smooth part is exact. -/
theorem card_divisors_smoothVal {b : ℕ} {ps : Pairs} (h : pairsOk b ps = true) :
    (smoothVal ps).divisors.card = smoothTau ps := by
  induction ps generalizing b with
  | nil => simp [smoothVal, smoothTau, Nat.divisors_one]
  | cons hd t ih =>
    obtain ⟨p, e⟩ := hd
    rw [pairsOk, Bool.and_eq_true, Bool.and_eq_true] at h
    obtain ⟨⟨_, hprime⟩, ht⟩ := h
    have hp : p.Prime := isPrimeSmall_sound hprime
    rw [smoothVal, smoothTau,
      Nat.Coprime.card_divisors_mul (coprime_pow_smoothVal hp ht),
      Nat.divisors_prime_pow hp, Finset.card_map, Finset.card_range, ih ht]

/-! ## The coprime cofactor -/

/-- Each listed power divides the smooth part. -/
theorem pow_dvd_smoothVal {ps : Pairs} {p e : ℕ} (h : (p, e) ∈ ps) :
    p ^ e ∣ smoothVal ps := by
  induction ps with
  | nil => cases h
  | cons hd t ih =>
    obtain ⟨q, f⟩ := hd
    rw [smoothVal]
    rcases List.mem_cons.mp h with heq | hmem
    · rw [Prod.mk.injEq] at heq
      obtain ⟨rfl, rfl⟩ := heq
      exact dvd_mul_right _ _
    · exact (ih hmem).mul_left _

/-- Every prime of the smooth part is a listed base. -/
theorem prime_dvd_smoothVal_mem {b : ℕ} {ps : Pairs} (h : pairsOk b ps = true)
    {q : ℕ} (hq : q.Prime) (hdvd : q ∣ smoothVal ps) :
    ∃ e, (q, e) ∈ ps := by
  induction ps generalizing b with
  | nil =>
    exact absurd (Nat.eq_one_of_dvd_one (by simpa [smoothVal] using hdvd))
      hq.one_lt.ne'
  | cons hd t ih =>
    obtain ⟨p, e⟩ := hd
    rw [pairsOk, Bool.and_eq_true, Bool.and_eq_true] at h
    have hp : p.Prime := isPrimeSmall_sound h.1.2
    rw [smoothVal] at hdvd
    rcases (Nat.Prime.dvd_mul hq).mp hdvd with hleft | hright
    · exact ⟨e, by
        have : q = p := (Nat.prime_dvd_prime_iff_eq hq hp).mp
          (hq.dvd_of_dvd_pow hleft)
        subst this
        exact List.mem_cons_self ..⟩
    · obtain ⟨f, hf⟩ := ih h.2 hright
      exact ⟨f, List.mem_cons_of_mem _ hf⟩

theorem maximalIn_sound {m : ℕ} {ps : Pairs} (h : maximalIn m ps = true)
    {p e : ℕ} (hmem : (p, e) ∈ ps) : ¬ p ^ (e + 1) ∣ m := by
  induction ps with
  | nil => cases hmem
  | cons hd t ih =>
    obtain ⟨q, f⟩ := hd
    rw [maximalIn, Bool.and_eq_true, decide_eq_true_eq] at h
    rcases List.mem_cons.mp hmem with heq | hmem'
    · rw [Prod.mk.injEq] at heq
      obtain ⟨rfl, rfl⟩ := heq
      intro hdvd
      exact h.1 (Nat.dvd_iff_mod_eq_zero.mp hdvd)
    · exact ih h.2 hmem'

/-- With maximal listed powers, the cofactor `m / smoothVal ps` is coprime
to the smooth part. -/
theorem coprime_smooth_cofactor {b m : ℕ} {ps : Pairs}
    (hpairs : pairsOk b ps = true) (hdvd : smoothVal ps ∣ m)
    (hmax : maximalIn m ps = true) :
    Nat.Coprime (smoothVal ps) (m / smoothVal ps) := by
  by_contra hnc
  obtain ⟨q, hq, hqs, hqc⟩ := Nat.Prime.not_coprime_iff_dvd.mp hnc
  obtain ⟨e, hmem⟩ := prime_dvd_smoothVal_mem hpairs hq hqs
  refine maximalIn_sound hmax hmem ?_
  have h1 : q ^ e ∣ smoothVal ps := pow_dvd_smoothVal hmem
  obtain ⟨c, hc⟩ := hdvd
  rw [hc, Nat.mul_div_cancel_left c (smoothVal_pos hpairs)] at hqc
  calc q ^ (e + 1) = q ^ e * q := by ring
    _ ∣ smoothVal ps * c := mul_dvd_mul h1 hqc
    _ = m := hc.symm

/-! ## Monotonicity and witness soundness -/

theorem card_divisors_le_of_dvd {m n : ℕ} (hn : n ≠ 0) (h : m ∣ n) :
    m.divisors.card ≤ n.divisors.card :=
  Finset.card_le_card (Nat.divisors_subset_of_dvd hn h)

theorem two_le_card_divisors {c : ℕ} (hc : 2 ≤ c) : 2 ≤ c.divisors.card := by
  have h1 : (1 : ℕ) ∈ c.divisors := Nat.one_mem_divisors.mpr (by omega)
  have hcc : c ∈ c.divisors := Nat.mem_divisors_self c (by omega)
  exact Finset.one_lt_card.mpr ⟨1, h1, c, hcc, by omega⟩

/-- A passing witness certifies `certTau (C - d) ps ≤ τ(C - d)`. -/
theorem witness_tau {C d : ℕ} {ps : Pairs} (h : witnessOk C d ps = true) :
    certTau (C - d) ps ≤ (C - d).divisors.card := by
  rw [witnessOk, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true,
    decide_eq_true_eq, decide_eq_true_eq] at h
  obtain ⟨⟨⟨hdC, hpairs⟩, hmod⟩, hmax⟩ := h
  set m := C - d with hm
  have hspos : 0 < smoothVal ps := smoothVal_pos hpairs
  have hdvd : smoothVal ps ∣ m := Nat.dvd_iff_mod_eq_zero.mpr hmod
  have hcard : (smoothVal ps).divisors.card = smoothTau ps :=
    card_divisors_smoothVal hpairs
  rw [certTau]
  split_ifs with hlt
  · -- nontrivial cofactor: τ(m) = τ(s) * τ(c) ≥ smoothTau * 2
    have hcop := coprime_smooth_cofactor hpairs hdvd hmax
    obtain ⟨c, hc⟩ := hdvd
    have hceq : m / smoothVal ps = c := by
      rw [hc, Nat.mul_div_cancel_left c hspos]
    have hc2 : 2 ≤ c := by
      rcases Nat.lt_or_ge c 2 with h2 | h2
      · interval_cases c
        · simp at hc; omega
        · simp at hc; omega
      · exact h2
    rw [hceq] at hcop
    have hsplit : m.divisors.card =
        (smoothVal ps).divisors.card * c.divisors.card := by
      rw [hc]
      exact Nat.Coprime.card_divisors_mul hcop
    rw [hsplit, hcard]
    calc 2 * smoothTau ps = smoothTau ps * 2 := by ring
      _ ≤ smoothTau ps * c.divisors.card :=
          Nat.mul_le_mul_left _ (two_le_card_divisors hc2)
  · -- trivial cofactor: the smooth part is m itself
    calc smoothTau ps = (smoothVal ps).divisors.card := hcard.symm
      _ ≤ m.divisors.card := card_divisors_le_of_dvd (by omega) hdvd

end Erdos647
