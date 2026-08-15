"""Independent cross-check of the #647 landscape below 10^7.

Third implementation, sharing no code with gen_chain.py or
verify_chain.py: a plain divisor-count sieve (increment at every multiple
of every d), the running maximum R(n) = max_{m<n}(m + tau(m)), and the
solution set {n : R(n) <= n + 2}. Asserts:

  - the solution set below 10^7 is exactly {2, 3, 4, 5, 6, 8, 10, 12, 24}
    (OEIS A087280 records 5, 8, 10, 12, 24; the smaller n are the trivial
    cases below A087280's convention),
  - n + tau(n) matches pinned OEIS A062249 values,
  - tau matches a from-scratch factorization on random samples.

Runs in a few minutes in pure Python; pass --fast for 10^6.

Usage: python3 scripts/cross_check.py [--fast]
"""

import random
import sys

# A062249(n) = n + tau(n), first 20 values, transcribed from OEIS.
A062249 = [2, 4, 5, 7, 7, 10, 9, 12, 12, 14,
           13, 18, 15, 18, 19, 21, 19, 24, 21, 26]

EXPECTED_SOLUTIONS = {2, 3, 4, 5, 6, 8, 10, 12, 24}


def tau_by_factorization(m: int) -> int:
    t, d = 1, 2
    while d * d <= m:
        e = 0
        while m % d == 0:
            m //= d
            e += 1
        t *= e + 1
        d += 1
    return t * (2 if m > 1 else 1)


def main(limit: int) -> None:
    tau = [0] * (limit + 1)
    for d in range(1, limit + 1):
        for k in range(d, limit + 1, d):
            tau[k] += 1
    for n, want in enumerate(A062249, start=1):
        assert n + tau[n] == want, (n, n + tau[n], want)
    rng = random.Random(647)
    for _ in range(200):
        m = rng.randrange(2, limit + 1)
        assert tau[m] == tau_by_factorization(m), m
    solutions = set()
    running = 0
    for n in range(2, limit + 1):
        running = max(running, (n - 1) + tau[n - 1])
        if running <= n + 2:
            solutions.add(n)
    assert solutions == {s for s in EXPECTED_SOLUTIONS if s <= limit}, \
        solutions ^ EXPECTED_SOLUTIONS
    print(f"cross-check ok: solutions <= {limit} are exactly "
          f"{sorted(solutions)}; A062249 and sampled tau agree")


if __name__ == "__main__":
    main(10**6 if "--fast" in sys.argv else 10**7)
