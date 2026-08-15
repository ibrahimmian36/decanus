import Erdos647.Defs
import Erdos647.TauLower
import Erdos647.Chain
import Erdos647.Bridge
import Erdos647.Cert
import Erdos647.Cert1E8
import Erdos647.Headline

/-! Publication gate: every theorem below must depend on exactly
`[propext, Classical.choice, Quot.sound]` — no `sorryAx`, no `_native.*`.
`AxiomAudit.lean` re-checks every theorem in every Erdos647 module
mechanically; `scripts/axiom_gate.sh` requires both. -/

-- Step 2: the lemma layer (Erdos647.TauLower)
#print axioms Erdos647.isPrimeSmall_sound
#print axioms Erdos647.card_divisors_smoothVal
#print axioms Erdos647.card_divisors_le_of_dvd
#print axioms Erdos647.witness_tau

-- Step 3: chain soundness (Erdos647.Chain)
#print axioms Erdos647.chain_sound

-- Step 4: the certified rung (Erdos647.Cert, generated)
#print axioms Erdos647.killed_upto
#print axioms Erdos647.killed_upto_1e8

-- Step 5: the bridge and the headline (Erdos647.Bridge, Erdos647.Headline)
#print axioms Erdos647.not_sup_le_of_killed
#print axioms Erdos647.bounded_exclusion
#print axioms Erdos647.erdos647_no_solution_upto
#print axioms Erdos647.erdos647_no_solution_upto_1e8
