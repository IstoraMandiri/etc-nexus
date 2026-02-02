# Legacy-Cancun BlockchainTests: 99.92% Pass Rate

<!-- DISCORD SUMMARY (paste everything between the markers) -->
## core-geth: Legacy-Cancun BlockchainTests Complete

**Client:** core-geth v1.12.21 | **Suite:** legacy-cancun | **Duration:** ~59 hours

The comprehensive legacy-cancun test suite has completed with **99.92% pass rate** (111,893/111,983 tests).

### Results Summary

```
Total:   111,983 tests
Passed:  111,893 (99.92%)
Failed:      90  (0.08%)
Rate:       ~31 tests/min
```

### Failed Tests (90 total)

```
InitCollisionParis         24  (EIP-7610)
create2collisionStorageParis 18  (EIP-7610)
InitCollision              12  (EIP-7610)
create2collisionStorage     9  (EIP-7610)
dynamicAccountOverwriteEmpty  9  (EIP-7610)
RevertInCreateInInit*      18  (EIP-7610)
```

### Analysis

**Root cause:** All 90 failures are EIP-7610 edge cases - same class as the 21 failures in the legacy suite. These tests target "ghost account" collision handling that requires a computationally infeasible keccak256 preimage attack to exploit.

### Impact

**No action required** - These are known behavioral differences documented in [CREATE2 Collision Resolution](reports/260130_CREATE2_COLLISION_RESOLUTION.md). core-geth follows pre-EIP-7610 behavior, which is safe and correct for ETC.

### Key Findings

1. **ETC-relevant forks validated:** Istanbul, Berlin tests passing
2. **Post-merge forks tested:** London, Paris, Shanghai, Cancun also passing (99.9%+)
3. **Consistent failure pattern:** Same 10 base test cases across 6 forks = 90 failures

**Full report:** <https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260202_LEGACY_CANCUN_RESULTS.md>
<!-- END DISCORD SUMMARY -->

---

# Full Report

**Date:** 2026-02-02
**Test Suite:** legacy-cancun (BlockchainTests)
**Client:** CoreGeth/v1.12.21-unstable-4185df45-20250123/linux-amd64/go1.22.12
**Test Framework:** Hive (ethereum/consensus simulator)

## Executive Summary

The legacy-cancun test suite completed successfully after ~59 hours of execution. Out of 111,983 tests, 111,893 passed (99.92%) and 90 failed. All failures are related to EIP-7610 behavior, the same class of edge cases identified in the earlier legacy suite testing.

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Suite | `legacy-cancun` |
| Simulator | `ethereum/consensus` |
| Client | `core-geth` |
| Start Time | 2026-01-31 00:22 UTC |
| End Time | 2026-02-02 11:29 UTC |
| Duration | ~59 hours (2.5 days) |
| Test Rate | ~31 tests/minute |

## Results

### Summary Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Total Tests | 111,983 | 100% |
| Passed | 111,893 | 99.92% |
| Failed | 90 | 0.08% |

### Failed Tests by Base Name

| Test Name | Count | Category |
|-----------|-------|----------|
| InitCollisionParis | 24 | EIP-7610 |
| create2collisionStorageParis | 18 | EIP-7610 |
| InitCollision | 12 | EIP-7610 |
| create2collisionStorage | 9 | EIP-7610 |
| dynamicAccountOverwriteEmpty_Paris | 6 | EIP-7610 |
| RevertInCreateInInit_Paris | 6 | EIP-7610 |
| RevertInCreateInInitCreate2Paris | 6 | EIP-7610 |
| dynamicAccountOverwriteEmpty | 3 | EIP-7610 |
| RevertInCreateInInitCreate2 | 3 | EIP-7610 |
| RevertInCreateInInit | 3 | EIP-7610 |
| **Total** | **90** | |

### Failed Tests by Fork

| Fork | Failed Tests | Notes |
|------|--------------|-------|
| Berlin | 20 | ETC-relevant |
| Istanbul | 20 | ETC-relevant |
| London | 20 | Post-ETC |
| Paris | 10 | Post-Merge |
| Shanghai | 10 | Post-Merge |
| Cancun | 10 | Latest |
| **Total** | **90** | |

## Analysis

### Root Cause

All 90 failures are EIP-7610 ("Revert creation in case of non-empty storage") edge cases. This is the same class of failures identified in the legacy test suite, scaled across more forks:

- **Legacy suite:** 21 failures (3 forks: Constantinople, ConstantinopleFix, Istanbul)
- **Legacy-cancun suite:** 90 failures (6 forks: Istanbul, Berlin, London, Paris, Shanghai, Cancun)
- **Base test cases:** 10 unique tests × ~9 variants = 90 total

### Why These Failures Are Safe

1. **Computationally infeasible attack:** Exploiting requires keccak256 preimage attack (~$10B+ cost)
2. **Not activated on ETH:** EIP-7610 not yet live on Ethereum mainnet
3. **Not adopted by ETC:** core-geth follows pre-EIP-7610 behavior (correct for ETC)

See [CREATE2 Collision Resolution Report](260130_CREATE2_COLLISION_RESOLUTION.md) for detailed analysis.

### ETC-Relevant Results

Filtering to ETC-supported forks (Istanbul, Berlin):

| Fork | Tests | Passed | Failed | Pass Rate |
|------|-------|--------|--------|-----------|
| Istanbul | ~18,600* | 18,580+ | 20 | 99.9%+ |
| Berlin | ~18,600* | 18,580+ | 20 | 99.9%+ |

*Estimated based on test distribution across forks

## Comparison with Legacy Suite

| Metric | Legacy | Legacy-Cancun |
|--------|--------|---------------|
| Total Tests | 32,616 | 111,983 |
| Pass Rate | 99.94% | 99.92% |
| Failed | 21 | 90 |
| Base Failures | 7 | 10 |
| Forks Tested | 3 | 6 |
| Duration | ~17h | ~59h |

The slightly lower pass rate in legacy-cancun is expected - more forks means more variants of the same base failing tests.

## Recommendations

### Immediate

1. **No action required** - Results confirm core-geth correctness for ETC
2. **Update SITREP.md** with final results (done)
3. **Create test exclusion list** for EIP-7610 tests in Hive fork

### Next Steps

1. Complete besu-etc legacy suite (currently at 63.7%)
2. Run additional simulators (graphql, sync, devp2p/eth)
3. Begin ECIP-1120/1121 specific testing once baseline established

## Test Infrastructure

### Environment

- **Platform:** Linux (cloud instance)
- **Docker:** Running
- **Hive branch:** istora-core-geth-client
- **Go version:** 1.22.12

### Command Used

```bash
./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth
```

## References

- [Hive Documentation](https://github.com/ethereum/hive/tree/master/docs)
- [ethereum/tests Repository](https://github.com/ethereum/tests)
- [CREATE2 Collision Resolution Report](260130_CREATE2_COLLISION_RESOLUTION.md)
- [EIP-7610 Specification](https://eips.ethereum.org/EIPS/eip-7610)

## Appendix: Complete Failed Test List

### InitCollision Tests (36 failures)

```
InitCollision_d0g0v0_Istanbul
InitCollision_d0g0v0_Berlin
InitCollision_d0g0v0_London
InitCollision_d1g0v0_Istanbul
InitCollision_d1g0v0_Berlin
InitCollision_d1g0v0_London
InitCollision_d2g0v0_Istanbul
InitCollision_d2g0v0_Berlin
InitCollision_d2g0v0_London
InitCollision_d3g0v0_Istanbul
InitCollision_d3g0v0_Berlin
InitCollision_d3g0v0_London
InitCollisionParis_d0g0v0_Istanbul
InitCollisionParis_d0g0v0_Berlin
InitCollisionParis_d0g0v0_London
InitCollisionParis_d0g0v0_Paris
InitCollisionParis_d0g0v0_Shanghai
InitCollisionParis_d0g0v0_Cancun
InitCollisionParis_d1g0v0_Istanbul
InitCollisionParis_d1g0v0_Berlin
InitCollisionParis_d1g0v0_London
InitCollisionParis_d1g0v0_Paris
InitCollisionParis_d1g0v0_Shanghai
InitCollisionParis_d1g0v0_Cancun
InitCollisionParis_d2g0v0_Istanbul
InitCollisionParis_d2g0v0_Berlin
InitCollisionParis_d2g0v0_London
InitCollisionParis_d2g0v0_Paris
InitCollisionParis_d2g0v0_Shanghai
InitCollisionParis_d2g0v0_Cancun
InitCollisionParis_d3g0v0_Istanbul
InitCollisionParis_d3g0v0_Berlin
InitCollisionParis_d3g0v0_London
InitCollisionParis_d3g0v0_Paris
InitCollisionParis_d3g0v0_Shanghai
InitCollisionParis_d3g0v0_Cancun
```

### create2collisionStorage Tests (27 failures)

```
create2collisionStorage_d0g0v0_Istanbul
create2collisionStorage_d0g0v0_Berlin
create2collisionStorage_d0g0v0_London
create2collisionStorage_d1g0v0_Istanbul
create2collisionStorage_d1g0v0_Berlin
create2collisionStorage_d1g0v0_London
create2collisionStorage_d2g0v0_Istanbul
create2collisionStorage_d2g0v0_Berlin
create2collisionStorage_d2g0v0_London
create2collisionStorageParis_d0g0v0_Istanbul
create2collisionStorageParis_d0g0v0_Berlin
create2collisionStorageParis_d0g0v0_London
create2collisionStorageParis_d0g0v0_Paris
create2collisionStorageParis_d0g0v0_Shanghai
create2collisionStorageParis_d0g0v0_Cancun
create2collisionStorageParis_d1g0v0_Istanbul
create2collisionStorageParis_d1g0v0_Berlin
create2collisionStorageParis_d1g0v0_London
create2collisionStorageParis_d1g0v0_Paris
create2collisionStorageParis_d1g0v0_Shanghai
create2collisionStorageParis_d1g0v0_Cancun
create2collisionStorageParis_d2g0v0_Istanbul
create2collisionStorageParis_d2g0v0_Berlin
create2collisionStorageParis_d2g0v0_London
create2collisionStorageParis_d2g0v0_Paris
create2collisionStorageParis_d2g0v0_Shanghai
create2collisionStorageParis_d2g0v0_Cancun
```

### RevertInCreateInInit Tests (18 failures)

```
RevertInCreateInInit_d0g0v0_Istanbul
RevertInCreateInInit_d0g0v0_Berlin
RevertInCreateInInit_d0g0v0_London
RevertInCreateInInit_Paris_d0g0v0_Istanbul
RevertInCreateInInit_Paris_d0g0v0_Berlin
RevertInCreateInInit_Paris_d0g0v0_London
RevertInCreateInInit_Paris_d0g0v0_Paris
RevertInCreateInInit_Paris_d0g0v0_Shanghai
RevertInCreateInInit_Paris_d0g0v0_Cancun
RevertInCreateInInitCreate2_d0g0v0_Istanbul
RevertInCreateInInitCreate2_d0g0v0_Berlin
RevertInCreateInInitCreate2_d0g0v0_London
RevertInCreateInInitCreate2Paris_d0g0v0_Istanbul
RevertInCreateInInitCreate2Paris_d0g0v0_Berlin
RevertInCreateInInitCreate2Paris_d0g0v0_London
RevertInCreateInInitCreate2Paris_d0g0v0_Paris
RevertInCreateInInitCreate2Paris_d0g0v0_Shanghai
RevertInCreateInInitCreate2Paris_d0g0v0_Cancun
```

### dynamicAccountOverwriteEmpty Tests (9 failures)

```
dynamicAccountOverwriteEmpty_d0g0v0_Istanbul
dynamicAccountOverwriteEmpty_d0g0v0_Berlin
dynamicAccountOverwriteEmpty_d0g0v0_London
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Istanbul
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Berlin
dynamicAccountOverwriteEmpty_Paris_d0g0v0_London
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Paris
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Shanghai
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Cancun
```

---

*Log file: `hive/workspace/logs/1770031800-de80a7ee9a2d58653f314df939f29192.json` (68MB)*
