"""Independent verifier for a #647 kill-chain ledger.

Second implementation, deliberately sharing no code with gen_chain.py: pure
Python, no numpy, trial division throughout. Mirrors the semantics of the
Lean checker (Erdos647/Defs.lean chainOk) step for step:

  - every pair prime is < 1024 and prime (own trial division),
  - pairs strictly decreasing,
  - prod p^e divides m = C - d, with 0 < m,
  - new cover = m + prod (e+1) - 3, and must strictly increase,
  - final cover reaches the claimed X.

Also spot-checks tau_cert against a from-scratch full factorization on a
sample of witnesses, and cross-checks the full tau function against OEIS
A062249 values for m <= 1000 when the b-file is present.

Usage: python3 verify_chain.py chain.jsonl X [b062249.txt]
"""

import json
import sys


def is_prime(p: int) -> bool:
    if p < 2:
        return False
    d = 2
    while d * d <= p:
        if p % d == 0:
            return False
        d += 1
    return True


def full_tau(m: int) -> int:
    t, d = 1, 2
    while d * d <= m:
        e = 0
        while m % d == 0:
            m //= d
            e += 1
        t *= e + 1
        d += 1
    if m > 1:
        t *= 2
    return t


def smooth_tau_lower(m: int, bound: int = 1024) -> int:
    """prod (e+1) over prime factors of m below bound, from scratch."""
    t = 1
    for p in range(2, bound):
        if not is_prime(p):
            continue
        e = 0
        while m % p == 0:
            m //= p
            e += 1
        t *= e + 1
    return t


def verify(path: str, x: int, bfile: str | None = None) -> None:
    cover = None
    witnesses = 0
    sample_stride = 997  # spot-check every 997th witness in depth
    with open(path, encoding="utf-8") as f:
        for line in f:
            rec = json.loads(line)
            if rec["record"] == "header":
                assert rec["cover_start"] == 24, rec
                cover = 24
                continue
            if rec["record"] == "footer":
                assert rec["final_cover"] == cover, (rec, cover)
                assert rec["witnesses"] == witnesses, (rec, witnesses)
                assert rec["exhausted"] == [25, x], rec
                break
            assert cover is not None, "witness before header"
            d, pairs = rec["d"], rec["pairs"]
            m = cover - d
            assert 0 < m <= cover, (cover, d)
            t, val, prev_p = 1, 1, 1024
            for p, e in pairs:
                assert p < prev_p, f"pairs not decreasing at witness {witnesses}"
                assert is_prime(p), f"non-prime {p} at witness {witnesses}"
                assert e >= 1
                prev_p = p
                t *= e + 1
                val *= p**e
            assert m % val == 0, f"smooth part does not divide m={m}"
            for p, e in pairs:
                assert m % p**(e + 1) != 0, \
                    f"pair ({p},{e}) not maximal in m={m}"
            if val < m:
                t *= 2
            if witnesses % sample_stride == 0:
                base = smooth_tau_lower(m)
                assert t in (base, 2 * base), \
                    f"pairs are not the full smooth part of m={m}"
                assert t <= full_tau(m)
            nxt = m + t - 3
            assert nxt > cover, f"no progress at witness {witnesses} (m={m})"
            cover = nxt
            witnesses += 1
        else:
            raise AssertionError("no footer record")
    assert cover >= x, f"chain ends at {cover} < {x}"
    print(f"verified: {witnesses} witnesses cover (24, {x}], final {cover}")
    if bfile:
        vals = {}
        with open(bfile, encoding="utf-8") as f:
            for line in f:
                parts = line.split()
                if len(parts) == 2 and parts[0].isdigit():
                    vals[int(parts[0])] = int(parts[1])
        for n, a in sorted(vals.items()):
            if n > 1000:
                break
            assert n + full_tau(n) == a, (n, a)
        print(f"A062249 cross-check ok ({min(len(vals), 1000)} values)")


if __name__ == "__main__":
    verify(sys.argv[1], int(float(sys.argv[2])),
           sys.argv[3] if len(sys.argv) > 3 else None)
