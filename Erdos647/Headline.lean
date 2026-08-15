/-
Copyright (c) 2026 Millennium Research. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Millennium Research (Ibby Mian)
-/
import Erdos647.Cert
import Erdos647.Cert1E8
import Erdos647.Bridge

/-!
# The headline theorem (Erdős #647)

The certified rung: no `n` in `(24, X]` satisfies the #647 condition, with
the inner predicate matching the formal-conjectures statement
(pinned at commit `c252a41054125b5fd9c8356e2137cd9b55337657`). `X` here is
the bound reached by the generated chain in `Cert.lean`.
-/

namespace Erdos647

open ArithmeticFunction ArithmeticFunction.sigma

/-- No solution to Erdős #647 exists in `(24, 10^7]`: every such `n` fails
`max_{m<n}(m + τ(m)) ≤ n + 2`, kernel-checked. -/
theorem erdos647_no_solution_upto :
    ∀ n : ℕ, 24 < n → n ≤ 10000000 →
      ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2) :=
  bounded_exclusion killed_upto

/-- No solution to Erdős #647 exists in `(24, 10^8]`, kernel-checked. -/
theorem erdos647_no_solution_upto_1e8 :
    ∀ n : ℕ, 24 < n → n ≤ 100000000 →
      ¬ (⨆ m : Fin n, ↑m + σ 0 m ≤ n + 2) :=
  bounded_exclusion killed_upto_1e8

end Erdos647
