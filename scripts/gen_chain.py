"""Greedy kill-chain generator for the Erdős #647 exclusion certificate.

Computes, for every m up to a bound X, the certified divisor-count lower
bound tau_cert(m) = prod (e_i + 1) over the prime factorization of the
1024-smooth part of m (primes below 1024 only, matching the Lean checker's
isPrimeSmall). Walks the greedy chain

    C_0 = 24,   C_{k+1} = max_{m <= C_k} (m + tau_cert(m)) - 3

until C >= X, emitting one witness (d, pairs) per step, where d = C - m and
pairs is the smooth factorization, most significant prime first. The chain
is exactly what Erdos647/Defs.lean's chainOk re-checks in the kernel.

Output: JSONL ledger, one witness per line, plus a header and footer record
with exact coverage. Every run starts with a self-test at X = 10^4.

Usage: python3 gen_chain.py X out.jsonl [--block 10000000]
"""

import json
import sys
import time

import numpy as np

PRIME_BOUND = 1024
COVER_START = 24


def primes_below(bound: int) -> list[int]:
    sieve = np.ones(bound, dtype=bool)
    sieve[:2] = False
    for p in range(2, int(bound**0.5) + 1):
        if sieve[p]:
            sieve[p * p :: p] = False
    return [int(p) for p in np.nonzero(sieve)[0]]


SMALL_PRIMES = primes_below(PRIME_BOUND)


def tau_cert_block(lo: int, hi: int) -> np.ndarray:
    """Certified divisor-count lower bound for m in [lo, hi), as int64.

    tau accumulates prod (e+1) over primes below 1024: for each prime power
    q = p^k the entries divisible by q carry the p-contribution k after the
    previous pass, so multiplying by (k+1) and dividing by k is exact.
    val accumulates the full smooth part; entries with val < m keep a
    nontrivial cofactor, which is coprime to the smooth part and doubles
    the certified bound (matching Erdos647/Defs.lean certTau).
    """
    n = hi - lo
    tau = np.ones(n, dtype=np.int64)
    val = np.ones(n, dtype=np.int64)
    for p in SMALL_PRIMES:
        q, k = p, 1
        while q < hi:
            start = ((lo + q - 1) // q) * q - lo
            if start < n:
                if k == 1:
                    tau[start::q] *= 2
                else:
                    np.floor_divide(tau[start::q] * (k + 1), k,
                                    out=tau[start::q], casting="unsafe")
                val[start::q] *= p
            q *= p
            k += 1
    ms = np.arange(lo, hi, dtype=np.int64)
    return np.where(val < ms, 2 * tau, tau)


def factor_smooth(m: int) -> list[tuple[int, int]]:
    """1024-smooth factorization of m, most significant prime first."""
    pairs = []
    for p in SMALL_PRIMES:
        if p * p > m and m > 1:
            break
        e = 0
        while m % p == 0:
            m //= p
            e += 1
        if e:
            pairs.append((p, e))
    if 1 < m < PRIME_BOUND:
        pairs.append((m, 1))
    return pairs[::-1]


def generate(x: int, out_path: str, block: int = 10_000_000) -> dict:
    t0 = time.time()
    witnesses = 0
    cover = COVER_START
    # Running maximum of m + tau_cert(m) over all m <= current block end,
    # with the attaining m. Carried across blocks.
    best_val = 0
    best_m = 0
    with open(out_path, "w", encoding="utf-8") as out:
        out.write(json.dumps({
            "record": "header", "problem": "erdos647",
            "claim": f"kill chain covering ({COVER_START}, {x}]",
            "prime_bound": PRIME_BOUND, "cover_start": COVER_START,
            "generator": "gen_chain.py tau_cert segmented sieve",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        }) + "\n")
        lo = 1
        while cover < x:
            hi = min(lo + block, x + 1)
            if lo < hi:
                tau = tau_cert_block(lo, hi)
                vals = np.arange(lo, hi, dtype=np.int64) + tau
                prefix = np.maximum.accumulate(vals)
                argmax = np.empty(hi - lo, dtype=np.int64)
                improving = vals >= prefix
                idx = np.arange(lo, hi, dtype=np.int64)
                argmax[improving] = idx[improving]
                for i in range(1, hi - lo):
                    if not improving[i]:
                        argmax[i] = argmax[i - 1]
            # Walk the chain as far as this block allows: the maximum over
            # m <= cover is available while cover < hi.
            while cover < min(hi, x):
                if cover >= lo:
                    i = cover - lo
                    if prefix[i] > best_val:
                        best_val = int(prefix[i])
                        best_m = int(argmax[i])
                m = best_m
                pairs = factor_smooth(m)
                t = 1
                sv = 1
                for pp, e in pairs:
                    t *= e + 1
                    sv *= pp**e
                if sv < m:
                    t *= 2
                nxt = m + t - 3
                if nxt <= cover:
                    raise RuntimeError(
                        f"chain stalled at cover={cover}: best m={m}, "
                        f"tau_cert={t}")
                out.write(json.dumps({
                    "record": "witness", "d": cover - m, "pairs": pairs,
                }) + "\n")
                witnesses += 1
                cover = nxt
            if cover >= x:
                break
            # Advance the carried maximum over the full block before moving on.
            if lo < hi:
                if prefix[-1] > best_val:
                    best_val = int(prefix[-1])
                    best_m = int(argmax[-1])
            lo = hi
        footer = {
            "record": "footer", "witnesses": witnesses,
            "final_cover": cover, "exhausted": [COVER_START + 1, x],
            "seconds": round(time.time() - t0, 1),
        }
        out.write(json.dumps(footer) + "\n")
    return footer


def self_test() -> None:
    """Smoke: chain to 10^4, checked against known facts."""
    import tempfile
    with tempfile.NamedTemporaryFile("r", suffix=".jsonl") as f:
        footer = generate(10_000, f.name, block=3_000)
        assert footer["final_cover"] >= 10_000, footer
        assert 400 < footer["witnesses"] < 700, footer
    # tau_cert equals full tau for m < 1024 (all factors are small).
    tau = tau_cert_block(1, 1024)
    for m, want in [(1, 1), (2, 2), (6, 4), (24, 8), (360, 24), (960, 28)]:
        assert tau[m - 1] == want, (m, tau[m - 1], want)
    # cofactor doubling: 3482 = 2 * 1741 has smooth part 2, certified 4
    tau2 = tau_cert_block(3480, 3484)
    assert tau2[2] == 4, tau2
    # factor_smooth round-trips and orders correctly.
    assert factor_smooth(360360) == [(13, 1), (11, 1), (7, 1), (5, 1),
                                     (3, 2), (2, 3)]
    print("self-test ok")


if __name__ == "__main__":
    self_test()
    if len(sys.argv) > 1:
        x = int(float(sys.argv[1]))
        out = sys.argv[2] if len(sys.argv) > 2 else f"chain_{x}.jsonl"
        blk = int(float(sys.argv[4])) if len(sys.argv) > 4 else 10_000_000
        footer = generate(x, out, block=blk)
        print(json.dumps(footer))
