import Erdos647.Certs.Chunk0000
import Erdos647.Certs.Chunk0001
import Erdos647.Certs.Chunk0002
import Erdos647.Certs.Chunk0003
import Erdos647.Certs.Chunk0004
import Erdos647.Certs.Chunk0005
import Erdos647.Certs.Chunk0006
import Erdos647.Certs.Chunk0007
import Erdos647.Certs.Chunk0008
import Erdos647.Certs.Chunk0009
import Erdos647.Certs.Chunk0010
import Erdos647.Certs.Chunk0011
import Erdos647.Certs.Chunk0012
import Erdos647.Certs.Chunk0013
import Erdos647.Certs.Chunk0014
import Erdos647.Certs.Chunk0015
import Erdos647.Certs.Chunk0016
import Erdos647.Certs.Chunk0017
import Erdos647.Certs.Chunk0018
import Erdos647.Certs.Chunk0019
import Erdos647.Certs.Chunk0020
import Erdos647.Certs.Chunk0021
import Erdos647.Certs.Chunk0022
import Erdos647.Certs.Chunk0023
import Erdos647.Certs.Chunk0024
import Erdos647.Certs.Chunk0025
import Erdos647.Certs.Chunk0026
import Erdos647.Certs.Chunk0027
import Erdos647.Certs.Chunk0028
import Erdos647.Certs.Chunk0029
import Erdos647.Certs.Chunk0030
import Erdos647.Chain

/-! Generated driver: composes the chunk certificates into the
rung theorem covering (24, 10000000]. Do not edit by hand. -/

namespace Erdos647

/-- Every `n` with `24 < n ≤ 10000000` has a kill witness:
the running maximum `max_{m<n}(m + τ(m))` reaches `n + 3`. -/
theorem killed_upto (n : ℕ) (h24 : 24 < n) (hX : n ≤ 10000000) :
    Killed n := by
  by_cases h0 : n ≤ 155797
  · exact chain_sound Certs.chunk0000_ok n (by omega) h0
  by_cases h1 : n ≤ 370389
  · exact chain_sound Certs.chunk0001_ok n (by omega) h1
  by_cases h2 : n ≤ 611789
  · exact chain_sound Certs.chunk0002_ok n (by omega) h2
  by_cases h3 : n ≤ 869207
  · exact chain_sound Certs.chunk0003_ok n (by omega) h3
  by_cases h4 : n ≤ 1140945
  · exact chain_sound Certs.chunk0004_ok n (by omega) h4
  by_cases h5 : n ≤ 1423365
  · exact chain_sound Certs.chunk0005_ok n (by omega) h5
  by_cases h6 : n ≤ 1714213
  · exact chain_sound Certs.chunk0006_ok n (by omega) h6
  by_cases h7 : n ≤ 2012577
  · exact chain_sound Certs.chunk0007_ok n (by omega) h7
  by_cases h8 : n ≤ 2318313
  · exact chain_sound Certs.chunk0008_ok n (by omega) h8
  by_cases h9 : n ≤ 2628797
  · exact chain_sound Certs.chunk0009_ok n (by omega) h9
  by_cases h10 : n ≤ 2946949
  · exact chain_sound Certs.chunk0010_ok n (by omega) h10
  by_cases h11 : n ≤ 3269841
  · exact chain_sound Certs.chunk0011_ok n (by omega) h11
  by_cases h12 : n ≤ 3597669
  · exact chain_sound Certs.chunk0012_ok n (by omega) h12
  by_cases h13 : n ≤ 3929029
  · exact chain_sound Certs.chunk0013_ok n (by omega) h13
  by_cases h14 : n ≤ 4264881
  · exact chain_sound Certs.chunk0014_ok n (by omega) h14
  by_cases h15 : n ≤ 4604789
  · exact chain_sound Certs.chunk0015_ok n (by omega) h15
  by_cases h16 : n ≤ 4949277
  · exact chain_sound Certs.chunk0016_ok n (by omega) h16
  by_cases h17 : n ≤ 5295897
  · exact chain_sound Certs.chunk0017_ok n (by omega) h17
  by_cases h18 : n ≤ 5645893
  · exact chain_sound Certs.chunk0018_ok n (by omega) h18
  by_cases h19 : n ≤ 5997053
  · exact chain_sound Certs.chunk0019_ok n (by omega) h19
  by_cases h20 : n ≤ 6350437
  · exact chain_sound Certs.chunk0020_ok n (by omega) h20
  by_cases h21 : n ≤ 6711893
  · exact chain_sound Certs.chunk0021_ok n (by omega) h21
  by_cases h22 : n ≤ 7074557
  · exact chain_sound Certs.chunk0022_ok n (by omega) h22
  by_cases h23 : n ≤ 7438861
  · exact chain_sound Certs.chunk0023_ok n (by omega) h23
  by_cases h24 : n ≤ 7807017
  · exact chain_sound Certs.chunk0024_ok n (by omega) h24
  by_cases h25 : n ≤ 8178725
  · exact chain_sound Certs.chunk0025_ok n (by omega) h25
  by_cases h26 : n ≤ 8552091
  · exact chain_sound Certs.chunk0026_ok n (by omega) h26
  by_cases h27 : n ≤ 8925691
  · exact chain_sound Certs.chunk0027_ok n (by omega) h27
  by_cases h28 : n ≤ 9302405
  · exact chain_sound Certs.chunk0028_ok n (by omega) h28
  by_cases h29 : n ≤ 9683741
  · exact chain_sound Certs.chunk0029_ok n (by omega) h29
  exact chain_sound Certs.chunk0030_ok n (by omega) (by omega)

end Erdos647
