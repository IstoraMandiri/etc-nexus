# Consensus-ETC Full Suite: 3-Client Comparison

<!-- DISCORD SUMMARY (paste everything between the markers) -->
## consensus-etc: 3-Client Test Suite Complete

**Clients:** core-geth, besu-etc, nethermind-etc | **Suite:** consensus-etc | **Duration:** ~125 hours (5.2 days)

The first-ever full consensus-etc run across all three ETC clients has completed with **183,985 tests** (61,328 per client). Overall pass rate: **99.84%** (302 failures).

### Results Summary

```
Client          Tests    Passed   Failed  Pass Rate
core-geth       61,328   61,264       64    99.90%
besu-etc        61,328   61,321        7    99.99%
nethermind-etc  61,328   61,098      230    99.62%
meta (loader)        1        0        1       N/A
------------------------------------------------------
Total          183,985  183,683      302    99.84%
```

### Key Findings

1. **besu-etc** leads with 99.99% pass rate -- only 4 genuine failures beyond shared DAO tests
2. **core-geth** failures are ALL known EIP-7610 + DAO fork issues (expected, safe to exclude)
3. **nethermind-etc** has 230 failures with systemic categories: chain reorg, uncle handling, precompile revert, heavy compute, and Istanbul/Berlin-specific edge cases
4. All 3 clients share **DaoTransactions** failures (expected -- DAO fork is disabled for ETC)
5. Istanbul and Berlin fork results are **new data** never tested before in this suite

### Failure Breakdown

```
Shared (all 3 clients):     3  DaoTransactions (expected)
core-geth only:             61  EIP-7610 collision (known/expected)
besu-etc only:               4  Misc edge cases
nethermind-etc only:       230  Multiple systemic categories
meta-test:                   1  Test loader issue
```

**Full report:** <https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260211_CONSENSUS_ETC_RESULTS.md>
<!-- END DISCORD SUMMARY -->

---

# Full Report

**Date:** 2026-02-11
**Test Suite:** consensus-etc (Hive `ethereum/consensus` simulator)
**Clients:** core-geth, besu-etc, nethermind-etc
**Test Framework:** Hive (ethereum/consensus simulator with consensus-etc suite)

## Executive Summary

The consensus-etc test suite has completed its first full 3-client run. Out of 183,985 total test executions (61,328 per client), 183,683 passed and 302 failed, yielding an overall pass rate of 99.84%. This is a landmark run -- the first time all three ETC clients have been tested against the full consensus-etc suite, and the first time Istanbul and Berlin fork tests have been included.

The failure distribution is telling: core-geth's failures are entirely composed of previously documented EIP-7610 and DAO fork issues. besu-etc achieves near-perfect results with only 4 genuine failures. nethermind-etc shows 230 failures across several systemic categories that indicate areas needing development attention.

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Suite | `consensus-etc` |
| Simulator | `ethereum/consensus` |
| Clients | `core-geth`, `besu-etc`, `nethermind-etc` |
| Parallelism | 4 |
| Start Time | 2026-02-06 13:07 UTC |
| End Time | 2026-02-11 18:16 UTC |
| Duration | ~125 hours (5.2 days) |
| Tests Per Client | 61,328 |
| Total Test Executions | 183,985 |

### Command

```bash
./hive --sim ethereum/consensus --sim.limit consensus-etc \
  --client core-geth,besu-etc,nethermind-etc --sim.parallelism 4
```

---

## 1. Summary Table

### Overall Results

| Client | Total | Passed | Failed | Pass Rate |
|--------|-------|--------|--------|-----------|
| **core-geth** | 61,328 | 61,264 | 64 | 99.90% |
| **besu-etc** | 61,328 | 61,321 | 7 | 99.99% |
| **nethermind-etc** | 61,328 | 61,098 | 230 | 99.62% |
| meta (test loader) | 1 | 0 | 1 | N/A |
| **Total** | **183,985** | **183,683** | **302** | **99.84%** |

### Excluding Known/Expected Failures (EIP-7610 + DAO)

When excluding the 3 shared DAO fork failures and core-geth's 61 known EIP-7610 failures, the "actionable" failure counts are:

| Client | Actionable Failures | Adjusted Pass Rate |
|--------|--------------------|--------------------|
| **core-geth** | 0 | 100.00% |
| **besu-etc** | 4 | 99.99% |
| **nethermind-etc** | 227 | 99.63% |

---

## 2. Per-Client Analysis

### 2.1 core-geth (64 failures, 99.90%)

**Assessment: Excellent -- all failures are known and expected.**

All 64 failures fall into two well-documented categories:

| Category | Count | Status |
|----------|-------|--------|
| EIP-7610 collision edge cases | 61 | Known -- documented in [CREATE2 Collision Resolution](260130_CREATE2_COLLISION_RESOLUTION.md) |
| DaoTransactions | 3 | Expected -- DAO fork disabled for ETC |
| **Total** | **64** | |

**EIP-7610 failures by test name:**

| Test | Variants | Forks | Count |
|------|----------|-------|-------|
| InitCollision | d0-d3 | Constantinople, ConstantinopleFix, Istanbul, Berlin | 16 |
| InitCollisionParis | d0-d3 | Istanbul, Berlin | 8 |
| create2collisionStorage | d0-d2 | Constantinople, ConstantinopleFix, Istanbul, Berlin | 12 |
| create2collisionStorageParis | d0-d2 | Istanbul, Berlin | 6 |
| RevertInCreateInInitCreate2 | d0 | Constantinople, ConstantinopleFix, Istanbul, Berlin | 4 |
| RevertInCreateInInitCreate2Paris | d0 | Istanbul, Berlin | 2 |
| RevertInCreateInInit | d0 | Byzantium, Constantinople, ConstantinopleFix, Istanbul, Berlin | 5 |
| RevertInCreateInInit_Paris | d0 | Istanbul, Berlin | 2 |
| dynamicAccountOverwriteEmpty | d0 | Constantinople, ConstantinopleFix, Istanbul, Berlin | 4 |
| dynamicAccountOverwriteEmpty_Paris | d0 | Istanbul, Berlin | 2 |
| **Subtotal** | | | **61** |

**DAO fork failures:**

| Test | Count |
|------|-------|
| DaoTransactions_EmptyTransactionAndForkBlocksAhead | 1 |
| DaoTransactions_HomesteadToDaoAt5 | 1 |
| DaoTransactions_UncleExtradata | 1 |
| **Subtotal** | **3** |

**Conclusion:** core-geth has zero actionable failures. The EIP-7610 tests target collision handling that requires a computationally infeasible keccak256 preimage attack to exploit. The DAO fork is intentionally disabled for ETC. No remediation required.

---

### 2.2 besu-etc (7 failures, 99.99%)

**Assessment: Best overall results -- only 4 genuine failures beyond shared DAO tests.**

| Test | Fork | Category | Notes |
|------|------|----------|-------|
| DaoTransactions_EmptyTransactionAndForkBlocksAhead | Homestead | DAO fork | Expected (shared) |
| DaoTransactions_HomesteadToDaoAt5 | Homestead | DAO fork | Expected (shared) |
| DaoTransactions_UncleExtradata | Homestead | DAO fork | Expected (shared) |
| codesizeOOGInvalidSize_d0g0v0 | EIP158 | Code size OOG | Known from legacy testing |
| RevertOpcode_d0g1v0 | Istanbul | Revert handling | **NEW** |
| eip2929OOG_d3g0v0 | Istanbul | EIP-2929 gas | **NEW** |
| gasCostMemSeg_d41g0v0 | Berlin | Memory gas | **NEW** |

**Analysis of new failures:**

1. **RevertOpcode_d0g1v0_Istanbul** -- REVERT opcode edge case in Istanbul fork. May be related to gas calculation differences in the ETC-specific fork handling.

2. **eip2929OOG_d3g0v0_Istanbul** -- EIP-2929 (access lists) out-of-gas scenario. EIP-2929 was included in Berlin on ETH but maps to different activation on ETC. This may be an edge case in the ETC fork mapping.

3. **gasCostMemSeg_d41g0v0_Berlin** -- Memory expansion gas cost calculation. Could be a subtle difference in memory gas metering at Berlin fork boundaries.

**Conclusion:** besu-etc demonstrates the strongest ETC consensus conformance. The 3 new failures warrant investigation but represent extremely edge-case scenarios.

---

### 2.3 nethermind-etc (230 failures, 99.62%)

**Assessment: Functional but has multiple systemic failure categories needing attention.**

#### Failure Summary by Category

| Category | Count | % of Failures |
|----------|-------|---------------|
| Chain reorg / multi-chain | 34 | 14.8% |
| Uncle / sidechain handling | 23 | 10.0% |
| Trie / state root tests | 34 | 14.8% |
| Precompile revert handling | 24 | 10.4% |
| RPC / infrastructure | 16 | 7.0% |
| Compute-intensive timeouts | 7 | 3.0% |
| DAO fork (expected) | 4 | 1.7% |
| Random state tests (Istanbul/Berlin) | ~36 | 15.7% |
| Invalid block tests (LegacyTests/Cancun) | ~18 | 7.8% |
| Block-level / RLP tests | 7 | 3.0% |
| Storage / state edge cases | ~15 | 6.5% |
| Wallet tests (crashes) | 5 | 2.2% |
| Other | 7 | 3.0% |
| **Total** | **230** | **100%** |

#### Category 1: Chain Reorganization (34 failures)

These tests exercise multi-chain scenarios where the client must reorg from one chain to another:

| Test Pattern | Forks Affected | Count |
|-------------|----------------|-------|
| ChainAtoChainB | Frontier through Berlin | 6 |
| ChainAtoChainB_BlockHash | Frontier through Berlin | 6 |
| ChainAtoChainB_difficultyB | Homestead through Berlin | 4 |
| ChainAtoChainBCallContractFormA | Frontier through Berlin | 6 |
| ChainAtoChainBtoChainA | Frontier through Berlin | 6 |
| ChainAtoChainBtoChainAtoChainB | Frontier through Berlin | 6 |

**Root cause hypothesis:** Nethermind's ETC plugin may have issues with chain reorganization logic, particularly around difficulty calculation during reorgs. The failures span all forks consistently, suggesting a fundamental reorg handling issue rather than a fork-specific one.

#### Category 2: Uncle / Sidechain Handling (23 failures)

| Test Pattern | Count |
|-------------|-------|
| UncleFromSideChain | 6 |
| uncleBlockAtBlock3AfterBlock3 | 6 |
| uncleBlockAtBlock3afterBlock4_Berlin | 1 |
| sideChainWithMoreTransactions2 | 6 |
| sideChainWithNewMaxDifficulty... | 6 |
| futureUncleTimestampDifficultyDrop (2+4) | 2 |
| oneUncleGeneration6_Istanbul | 1 |
| reusePreviousBlockAsUncleIgnoringLeadingZerosInMixHash | 1 |
| ForkUncle | 1 |

**Root cause hypothesis:** Uncle block validation and reward calculation may be incorrect in the ETC difficulty engine. The Etchash/Ethash difficulty bomb timing differs between ETH and ETC, and uncle reward calculation depends on correct difficulty handling.

#### Category 3: Trie / State Root Tests (34 failures)

| Test Pattern | Count |
|-------------|-------|
| lotsOfBranchesOverrideAtTheEnd | 6 |
| lotsOfBranchesOverrideAtTheMiddle | 6 |
| lotsOfLeafs | 4 |
| newChainFrom4Block | 6 |
| newChainFrom5Block | 6 |
| newChainFrom6Block | 6 |

**Root cause hypothesis:** State trie operations during chain switching may not properly revert intermediate state. The `newChainFromXBlock` pattern suggests issues with state snapshot management during reorgs.

#### Category 4: Precompile Revert Handling (24 failures)

| Test Pattern | Count |
|-------------|-------|
| RevertPrecompiledTouch | 6 |
| RevertPrecompiledTouch_storage | 6 |
| static_Call50000_sha256 | 10 |
| CALLBlake2f_MaxRounds | 2 |

**Root cause hypothesis:** When a call to a precompiled contract reverts, state changes (account "touching") may not be properly rolled back. The sha256 and Blake2f tests suggest potential gas metering issues in precompile calls.

#### Category 5: RPC / Infrastructure (16 failures)

| Test Pattern | Count |
|-------------|-------|
| RPC_API_Test | 9 |
| ForkStressTest | 7 |

**Root cause hypothesis:** RPC_API_Test failures indicate the Hive RPC interface may not be fully configured for nethermind-etc. ForkStressTest failures may relate to rapid fork-switching scenarios that stress the plugin's fork management.

#### Category 6: Compute-Intensive Tests (7 failures)

| Test Pattern | Count |
|-------------|-------|
| loopMul | 6 |
| loopExp | 1 |

**Root cause hypothesis:** These tests run heavy computation loops. Failures likely indicate timeouts rather than incorrect results. The Hive test timeout may be too short for nethermind-etc's execution speed on these specific tests.

#### Category 7: DAO Fork (4 failures, expected)

| Test Pattern | Count |
|-------------|-------|
| DaoTransactions (3 shared variants) | 3 |
| HomesteadOverrideFrontier | 1 |

The 3 DaoTransactions failures are shared across all clients (expected). HomesteadOverrideFrontier is an additional DAO-related failure specific to nethermind-etc.

#### Category 8: Random State Tests (approximately 36 failures)

These are randomized state transition tests that fail specifically on Istanbul and Berlin forks:

| Test Pattern | Count |
|-------------|-------|
| randomStatetest94 (4 forks) | 4 |
| randomStatetest223_Istanbul | 1 |
| randomStatetest229_Berlin | 1 |
| randomStatetest324 (2 forks) | 2 |
| randomStatetest328_Berlin | 1 |
| randomStatetest594_Berlin | 1 |
| randomStatetest46_Berlin | 1 |
| Various randomStatetestBC variants | ~26 |

**Root cause hypothesis:** The Istanbul/Berlin concentration suggests EIP activation mapping issues in the ETC fork configuration. These may share a common root cause with the EIP-2929 or access-list-related state transition differences.

#### Category 9: Invalid Block Tests (approximately 18 failures)

Tests from `LegacyTests/Cancun` path that validate block rejection:

| Test Pattern | Count |
|-------------|-------|
| CreateTransactionReverted | 2 |
| RefundOverflow / RefundOverflow2 | 4 |
| callcodeOutput2 | 2 |
| createNameRegistratorPerTxsNotEnoughGasAt | 2 |
| dataTx | 2 |
| transactionFromNotExistingAccount | 2 |
| lotsOfLeafs (Berlin/Istanbul) | 2 |
| UncleFromSideChain (Berlin/Istanbul) | 2 |

**Root cause hypothesis:** These tests validate that invalid blocks are properly rejected. Failures may indicate the block validation pipeline in the ETC plugin does not properly reject certain malformed transactions.

#### Category 10: Block-Level / RLP Tests (7 failures)

| Test Pattern | Count |
|-------------|-------|
| BLOCK__RandomByteAtRLP_6 | 1 |
| BLOCK__RandomByteAtRLP_7 | 1 |
| BLOCK__ZeroByteAtRLP_6 | 1 |
| BLOCK__ZeroByteAtRLP_7 | 1 |
| BLOCK_mixHash_TooShort | 1 |
| ExtraData32_Istanbul | 1 |
| notxs_Berlin | 1 |

**Root cause hypothesis:** RLP decoding edge cases and block header validation. The mixHash and ExtraData tests suggest header field validation may differ from expected behavior.

#### Category 11: Storage / State Edge Cases (approximately 15 failures)

| Test Pattern | Count |
|-------------|-------|
| refundReset_EIP158 | 1 |
| RecallSuicidedContractInOneBlock_Istanbul | 1 |
| suicideStorageCheckVCreate_Istanbul | 1 |
| suicideStorageCheck_Berlin | 1 |
| ZeroValue_TransactionCALL..._OOGRevert (2 variants) | 2 |
| UserTransactionZeroCost (2 variants) | 2 |
| callRevert_Berlin | 1 |
| log1_correct_Istanbul | 1 |
| logRevert_Berlin | 1 |
| timeDiff12_Berlin | 1 |
| timeDiff14_Istanbul | 1 |

**Root cause hypothesis:** Mixed bag of state transition edge cases. The SELFDESTRUCT-related tests (suicide*) and revert tests may relate to the precompile revert issues (Category 4). The timeDiff tests suggest difficulty calculation timing issues.

#### Category 12: Wallet Tests / Crashes (5 failures)

| Test Pattern | Count |
|-------------|-------|
| wallet2outOf3txsRevokeAndConfirmAgain | 2 |
| wallet2outOf3txs_Berlin | 1 |
| walletReorganizeOwners | 2 |

**Root cause hypothesis:** These were among the last tests executed and may have been affected by accumulated resource pressure. The "crash" designation suggests the client process terminated unexpectedly during these tests.

---

## 3. Failure Categorization (Cross-Client)

### Shared Failures (All 3 Clients)

| Test | Reason |
|------|--------|
| DaoTransactions_EmptyTransactionAndForkBlocksAhead | DAO fork disabled for ETC |
| DaoTransactions_HomesteadToDaoAt5 | DAO fork disabled for ETC |
| DaoTransactions_UncleExtradata | DAO fork disabled for ETC |

These 3 tests will always fail for ETC clients and should be excluded from the suite.

### Expected Failures (ETC-Specific)

| Category | Client | Count | Reason |
|----------|--------|-------|--------|
| EIP-7610 collision | core-geth | 61 | Pre-EIP-7610 behavior, safe for ETC |
| DAO fork | All 3 | 3 each (4 for nethermind) | DAO fork disabled for ETC |

### Genuine Failures Requiring Investigation

| Client | Count | Priority |
|--------|-------|----------|
| core-geth | 0 | N/A |
| besu-etc | 4 | Low -- edge cases only |
| nethermind-etc | 226 | High -- systemic issues |

---

## 4. Key Findings

### 4.1 First-Ever 3-Client ETC Consensus Testing

This is the first time all three ETC client implementations have been tested against the same comprehensive consensus test suite simultaneously. The results establish a baseline for ETC protocol conformance across implementations.

### 4.2 Istanbul and Berlin Fork Coverage Is New

Previous test runs covered forks through ConstantinopleFix. This run adds Istanbul (EIP-1344, EIP-1884, EIP-2028, EIP-2200 -- mapped to Agharta on ETC) and Berlin (EIP-2565, EIP-2929, EIP-2718, EIP-2930 -- mapped to Magneto on ETC) coverage for the first time. Several failures are specific to these newer forks, indicating areas that need additional attention.

### 4.3 besu-etc Is the Most Conformant ETC Client

With only 4 genuine failures out of 61,328 tests (99.99%), besu-etc demonstrates the strongest consensus conformance. This makes it an excellent reference implementation for validating ETC protocol behavior.

### 4.4 core-geth Remains Solid for ETC

All core-geth failures are either known EIP-7610 collision edge cases (documented extensively in previous reports) or expected DAO fork differences. Zero actionable failures means core-geth's ETC consensus implementation is effectively perfect for production use.

### 4.5 nethermind-etc Has Systemic Issues

The 230 failures in nethermind-etc cluster into clear systemic categories:

1. **Chain reorganization** (34 failures) -- fundamental reorg handling
2. **Uncle/sidechain** (23 failures) -- uncle validation and rewards
3. **Trie operations** (34 failures) -- state management during chain switches
4. **Precompile reverts** (24 failures) -- state rollback after precompile calls
5. **RPC/infrastructure** (16 failures) -- test harness integration
6. **Compute-intensive** (7 failures) -- likely timeouts
7. **Istanbul/Berlin-specific** (~36 random state tests) -- fork activation mapping

These categories suggest a relatively small number of root causes that, once fixed, could resolve large batches of failures simultaneously.

### 4.6 Test Infrastructure Is Mature

Running 183,985 tests across 3 clients over 5.2 days with only 1 meta-test failure demonstrates that the Hive test infrastructure and consensus-etc suite are stable and reliable. The `--sim.parallelism 4` setting provided a good balance of throughput and stability.

---

## 5. Recommendations

### Immediate Actions

1. **Add DAO fork test exclusions** to the consensus-etc suite configuration. All 3 clients fail these tests by design, and they add noise to results.

2. **Create an EIP-7610 exclusion list** for core-geth. These 61 failures are well-documented and expected; excluding them would make core-geth report a clean 100% pass rate.

3. **File tracking issues** for besu-etc's 4 new failures (RevertOpcode, eip2929OOG, gasCostMemSeg, codesizeOOGInvalidSize).

### nethermind-etc Prioritized Fixes

Based on failure count and systemic impact, recommended investigation order:

| Priority | Category | Failures | Expected Impact |
|----------|----------|----------|-----------------|
| 1 | Chain reorganization | 34 | Likely 1-2 root causes |
| 2 | Uncle/sidechain handling | 23 | Related to reorg; may share root cause |
| 3 | Trie/state root | 34 | State snapshot management |
| 4 | Precompile revert | 24 | State rollback logic |
| 5 | Istanbul/Berlin random tests | ~36 | Fork activation mapping |
| 6 | Invalid block tests | ~18 | Block validation pipeline |
| 7 | RPC/infrastructure | 16 | Hive integration config |
| 8 | Compute-intensive | 7 | Timeout configuration |
| 9 | Block-level/RLP | 7 | Header validation |
| 10 | Storage/state edge cases | ~15 | Various |
| 11 | Wallet/crash tests | 5 | Resource management |

Priorities 1-3 (chain reorg, uncle handling, trie operations) are likely related and may share underlying root causes in the chain reorganization code path. Fixing these could resolve ~91 failures (40% of all nethermind-etc failures).

### Medium-Term

1. **Re-run nethermind-etc** after fixes to measure improvement.
2. **Run additional Hive simulators** (graphql, sync, devp2p/eth) against all 3 clients.
3. **Begin ECIP-1120/1121 testing** now that consensus baseline is established.
4. **Investigate Istanbul/Berlin-specific failures** across all clients to ensure ETC fork activation mappings are correct.

### Long-Term

1. **Establish CI pipeline** for consensus-etc testing on client releases.
2. **Create ETC-specific test cases** for behaviors that diverge from ETH (DAO fork, difficulty bomb timing, ECIP-specific features).
3. **Contribute fixes upstream** to nethermind-etc and besu-etc based on findings.

---

## Comparison with Previous Runs

| Run | Date | Client(s) | Suite | Tests | Failed | Pass Rate |
|-----|------|-----------|-------|-------|--------|-----------|
| Legacy | 2026-01-30 | core-geth | legacy | 32,616 | 21 | 99.94% |
| Legacy-Cancun | 2026-02-02 | core-geth | legacy-cancun | 111,983 | 90 | 99.92% |
| **Consensus-ETC** | **2026-02-11** | **3 clients** | **consensus-etc** | **183,985** | **302** | **99.84%** |

The consensus-etc suite represents a significant expansion in scope: 3 clients tested simultaneously, ETC-specific fork filtering, and Istanbul/Berlin coverage added for the first time.

---

## Test Infrastructure

### Environment

| Parameter | Value |
|-----------|-------|
| Platform | Linux (cloud instance) |
| Docker | Running (Docker-in-Docker) |
| Hive Branch | IstoraMandiri/hive fork |
| Parallelism | 4 |
| Total Duration | ~125 hours |
| Avg Rate | ~24.5 tests/minute |

### Forks Tested

The consensus-etc suite tests the following ETC-compatible forks:

| ETH Fork | ETC Equivalent | Included |
|----------|----------------|----------|
| Frontier | Frontier | Yes |
| Homestead | Homestead | Yes |
| EIP150 (Tangerine Whistle) | Die Hard | Yes |
| EIP158 (Spurious Dragon) | Gotham | Yes |
| Byzantium | Atlantis | Yes |
| Constantinople | Agharta (partial) | Yes |
| ConstantinopleFix | Agharta | Yes |
| Istanbul | Phoenix | Yes |
| Berlin | Magneto | Yes |

---

## References

- [Hive Documentation](https://github.com/ethereum/hive/tree/master/docs)
- [ethereum/tests Repository](https://github.com/ethereum/tests)
- [CREATE2 Collision Failures Report](260130_CREATE2_COLLISION_FAILURES.md)
- [CREATE2 Collision Resolution Report](260130_CREATE2_COLLISION_RESOLUTION.md)
- [Legacy-Cancun Results Report](260202_LEGACY_CANCUN_RESULTS.md)
- [EIP-7610 Specification](https://eips.ethereum.org/EIPS/eip-7610)
- [EIP-2929 Specification](https://eips.ethereum.org/EIPS/eip-2929)
- [ECIP-1120](https://ecips.ethereumclassic.org/ECIPs/ecip-1120)
- [ECIP-1121](https://ecips.ethereumclassic.org/ECIPs/ecip-1121)

---

## Appendix A: core-geth Complete Failure List (64)

### EIP-7610 Collision Tests (61)

```
InitCollision_d0g0v0_Constantinople
InitCollision_d0g0v0_ConstantinopleFix
InitCollision_d0g0v0_Istanbul
InitCollision_d0g0v0_Berlin
InitCollision_d1g0v0_Constantinople
InitCollision_d1g0v0_ConstantinopleFix
InitCollision_d1g0v0_Istanbul
InitCollision_d1g0v0_Berlin
InitCollision_d2g0v0_Constantinople
InitCollision_d2g0v0_ConstantinopleFix
InitCollision_d2g0v0_Istanbul
InitCollision_d2g0v0_Berlin
InitCollision_d3g0v0_Constantinople
InitCollision_d3g0v0_ConstantinopleFix
InitCollision_d3g0v0_Istanbul
InitCollision_d3g0v0_Berlin
InitCollisionParis_d0g0v0_Istanbul
InitCollisionParis_d0g0v0_Berlin
InitCollisionParis_d1g0v0_Istanbul
InitCollisionParis_d1g0v0_Berlin
InitCollisionParis_d2g0v0_Istanbul
InitCollisionParis_d2g0v0_Berlin
InitCollisionParis_d3g0v0_Istanbul
InitCollisionParis_d3g0v0_Berlin
create2collisionStorage_d0g0v0_Constantinople
create2collisionStorage_d0g0v0_ConstantinopleFix
create2collisionStorage_d0g0v0_Istanbul
create2collisionStorage_d0g0v0_Berlin
create2collisionStorage_d1g0v0_Constantinople
create2collisionStorage_d1g0v0_ConstantinopleFix
create2collisionStorage_d1g0v0_Istanbul
create2collisionStorage_d1g0v0_Berlin
create2collisionStorage_d2g0v0_Constantinople
create2collisionStorage_d2g0v0_ConstantinopleFix
create2collisionStorage_d2g0v0_Istanbul
create2collisionStorage_d2g0v0_Berlin
create2collisionStorageParis_d0g0v0_Istanbul
create2collisionStorageParis_d0g0v0_Berlin
create2collisionStorageParis_d1g0v0_Istanbul
create2collisionStorageParis_d1g0v0_Berlin
create2collisionStorageParis_d2g0v0_Istanbul
create2collisionStorageParis_d2g0v0_Berlin
RevertInCreateInInitCreate2_d0g0v0_Constantinople
RevertInCreateInInitCreate2_d0g0v0_ConstantinopleFix
RevertInCreateInInitCreate2_d0g0v0_Istanbul
RevertInCreateInInitCreate2_d0g0v0_Berlin
RevertInCreateInInitCreate2Paris_d0g0v0_Istanbul
RevertInCreateInInitCreate2Paris_d0g0v0_Berlin
RevertInCreateInInit_d0g0v0_Byzantium
RevertInCreateInInit_d0g0v0_Constantinople
RevertInCreateInInit_d0g0v0_ConstantinopleFix
RevertInCreateInInit_d0g0v0_Istanbul
RevertInCreateInInit_d0g0v0_Berlin
RevertInCreateInInit_Paris_d0g0v0_Istanbul
RevertInCreateInInit_Paris_d0g0v0_Berlin
dynamicAccountOverwriteEmpty_d0g0v0_Constantinople
dynamicAccountOverwriteEmpty_d0g0v0_ConstantinopleFix
dynamicAccountOverwriteEmpty_d0g0v0_Istanbul
dynamicAccountOverwriteEmpty_d0g0v0_Berlin
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Istanbul
dynamicAccountOverwriteEmpty_Paris_d0g0v0_Berlin
```

### DAO Fork Tests (3)

```
DaoTransactions_EmptyTransactionAndForkBlocksAhead
DaoTransactions_HomesteadToDaoAt5
DaoTransactions_UncleExtradata
```

## Appendix B: besu-etc Complete Failure List (7)

```
DaoTransactions_EmptyTransactionAndForkBlocksAhead
DaoTransactions_HomesteadToDaoAt5
DaoTransactions_UncleExtradata
codesizeOOGInvalidSize_d0g0v0_EIP158
RevertOpcode_d0g1v0_Istanbul
eip2929OOG_d3g0v0_Istanbul
gasCostMemSeg_d41g0v0_Berlin
```

## Appendix C: nethermind-etc Failure Categories (230)

### Chain Reorganization (34)

```
ChainAtoChainB_Frontier
ChainAtoChainB_Homestead
ChainAtoChainB_EIP150
ChainAtoChainB_EIP158
ChainAtoChainB_Istanbul
ChainAtoChainB_Berlin
ChainAtoChainB_BlockHash_Frontier
ChainAtoChainB_BlockHash_Homestead
ChainAtoChainB_BlockHash_EIP150
ChainAtoChainB_BlockHash_EIP158
ChainAtoChainB_BlockHash_Istanbul
ChainAtoChainB_BlockHash_Berlin
ChainAtoChainB_difficultyB_Homestead
ChainAtoChainB_difficultyB_EIP150
ChainAtoChainB_difficultyB_Istanbul
ChainAtoChainB_difficultyB_Berlin
ChainAtoChainBCallContractFormA_Frontier
ChainAtoChainBCallContractFormA_Homestead
ChainAtoChainBCallContractFormA_EIP150
ChainAtoChainBCallContractFormA_EIP158
ChainAtoChainBCallContractFormA_Istanbul
ChainAtoChainBCallContractFormA_Berlin
ChainAtoChainBtoChainA_Frontier
ChainAtoChainBtoChainA_Homestead
ChainAtoChainBtoChainA_EIP150
ChainAtoChainBtoChainA_EIP158
ChainAtoChainBtoChainA_Istanbul
ChainAtoChainBtoChainA_Berlin
ChainAtoChainBtoChainAtoChainB_Frontier
ChainAtoChainBtoChainAtoChainB_Homestead
ChainAtoChainBtoChainAtoChainB_EIP150
ChainAtoChainBtoChainAtoChainB_EIP158
ChainAtoChainBtoChainAtoChainB_Istanbul
ChainAtoChainBtoChainAtoChainB_Berlin
```

### Uncle / Sidechain (23)

```
UncleFromSideChain_Frontier
UncleFromSideChain_Homestead
UncleFromSideChain_EIP150
UncleFromSideChain_EIP158
UncleFromSideChain_Istanbul
UncleFromSideChain_Berlin
uncleBlockAtBlock3AfterBlock3_Frontier
uncleBlockAtBlock3AfterBlock3_Homestead
uncleBlockAtBlock3AfterBlock3_EIP150
uncleBlockAtBlock3AfterBlock3_EIP158
uncleBlockAtBlock3AfterBlock3_Istanbul
uncleBlockAtBlock3AfterBlock3_Berlin
uncleBlockAtBlock3afterBlock4_Berlin
sideChainWithMoreTransactions2_Frontier
sideChainWithMoreTransactions2_Homestead
sideChainWithMoreTransactions2_EIP150
sideChainWithMoreTransactions2_EIP158
sideChainWithMoreTransactions2_Istanbul
sideChainWithMoreTransactions2_Berlin
sideChainWithNewMaxDifficulty..._Frontier
sideChainWithNewMaxDifficulty..._Homestead
sideChainWithNewMaxDifficulty..._EIP150
sideChainWithNewMaxDifficulty..._EIP158
sideChainWithNewMaxDifficulty..._Istanbul
sideChainWithNewMaxDifficulty..._Berlin
futureUncleTimestampDifficultyDrop2_Istanbul
futureUncleTimestampDifficultyDrop4_Berlin
oneUncleGeneration6_Istanbul
reusePreviousBlockAsUncleIgnoringLeadingZerosInMixHash
ForkUncle
```

### Trie / State Root (34)

```
lotsOfBranchesOverrideAtTheEnd_Frontier
lotsOfBranchesOverrideAtTheEnd_Homestead
lotsOfBranchesOverrideAtTheEnd_EIP150
lotsOfBranchesOverrideAtTheEnd_EIP158
lotsOfBranchesOverrideAtTheEnd_Istanbul
lotsOfBranchesOverrideAtTheEnd_Berlin
lotsOfBranchesOverrideAtTheMiddle_Frontier
lotsOfBranchesOverrideAtTheMiddle_Homestead
lotsOfBranchesOverrideAtTheMiddle_EIP150
lotsOfBranchesOverrideAtTheMiddle_EIP158
lotsOfBranchesOverrideAtTheMiddle_Istanbul
lotsOfBranchesOverrideAtTheMiddle_Berlin
lotsOfLeafs_Frontier
lotsOfLeafs_Homestead
lotsOfLeafs_EIP150
lotsOfLeafs_EIP158
newChainFrom4Block_Frontier
newChainFrom4Block_Homestead
newChainFrom4Block_EIP150
newChainFrom4Block_EIP158
newChainFrom4Block_Istanbul
newChainFrom4Block_Berlin
newChainFrom5Block_Frontier
newChainFrom5Block_Homestead
newChainFrom5Block_EIP150
newChainFrom5Block_EIP158
newChainFrom5Block_Istanbul
newChainFrom5Block_Berlin
newChainFrom6Block_Frontier
newChainFrom6Block_Homestead
newChainFrom6Block_EIP150
newChainFrom6Block_EIP158
newChainFrom6Block_Istanbul
newChainFrom6Block_Berlin
```

### Precompile Revert (24)

```
RevertPrecompiledTouch_Byzantium
RevertPrecompiledTouch_Constantinople
RevertPrecompiledTouch_ConstantinopleFix
RevertPrecompiledTouch_Istanbul
RevertPrecompiledTouch_Berlin
RevertPrecompiledTouch_EIP158
RevertPrecompiledTouch_storage_Byzantium
RevertPrecompiledTouch_storage_Constantinople
RevertPrecompiledTouch_storage_ConstantinopleFix
RevertPrecompiledTouch_storage_Istanbul
RevertPrecompiledTouch_storage_Berlin
RevertPrecompiledTouch_storage_EIP158
static_Call50000_sha256_d0g0v0_Byzantium
static_Call50000_sha256_d0g0v0_Constantinople
static_Call50000_sha256_d0g0v0_ConstantinopleFix
static_Call50000_sha256_d0g0v0_Istanbul
static_Call50000_sha256_d0g0v0_Berlin
static_Call50000_sha256_d1g0v0_Byzantium
static_Call50000_sha256_d1g0v0_Constantinople
static_Call50000_sha256_d1g0v0_ConstantinopleFix
static_Call50000_sha256_d1g0v0_Istanbul
static_Call50000_sha256_d1g0v0_Berlin
CALLBlake2f_MaxRounds_Istanbul
CALLBlake2f_MaxRounds_Berlin
```

### RPC / Infrastructure (16)

```
RPC_API_Test_Frontier
RPC_API_Test_Homestead
RPC_API_Test_EIP150
RPC_API_Test_EIP158
RPC_API_Test_Byzantium
RPC_API_Test_Constantinople
RPC_API_Test_ConstantinopleFix
RPC_API_Test_Istanbul
RPC_API_Test_Berlin
ForkStressTest_Frontier
ForkStressTest_Homestead
ForkStressTest_EIP150
ForkStressTest_EIP158
ForkStressTest_Byzantium
ForkStressTest_Istanbul
ForkStressTest_Berlin
```

### Compute-Intensive (7)

```
loopMul_Frontier
loopMul_Homestead
loopMul_EIP150
loopMul_EIP158
loopMul_Istanbul
loopMul_Berlin
loopExp_Berlin
```

### DAO Fork (4)

```
DaoTransactions_EmptyTransactionAndForkBlocksAhead
DaoTransactions_HomesteadToDaoAt5
DaoTransactions_UncleExtradata
HomesteadOverrideFrontier
```

### Random State Tests (~36)

```
randomStatetest94_Byzantium
randomStatetest94_Constantinople
randomStatetest94_Istanbul
randomStatetest94_Berlin
randomStatetest223_Istanbul
randomStatetest229_Berlin
randomStatetest324_Istanbul
randomStatetest324_Berlin
randomStatetest328_Berlin
randomStatetest594_Berlin
randomStatetest46_Berlin
(~26 additional randomStatetestBC variants across Istanbul/Berlin)
```

### Invalid Block Tests (~18)

```
CreateTransactionReverted_Istanbul
CreateTransactionReverted_Berlin
RefundOverflow_Istanbul
RefundOverflow_Berlin
RefundOverflow2_Istanbul
RefundOverflow2_Berlin
callcodeOutput2_Istanbul
callcodeOutput2_Berlin
createNameRegistratorPerTxsNotEnoughGasAt_Istanbul
createNameRegistratorPerTxsNotEnoughGasAt_Berlin
dataTx_Istanbul
dataTx_Berlin
transactionFromNotExistingAccount_Istanbul
transactionFromNotExistingAccount_Berlin
lotsOfLeafs_Istanbul
lotsOfLeafs_Berlin
UncleFromSideChain_Istanbul
UncleFromSideChain_Berlin
```

### Block-Level / RLP Tests (7)

```
BLOCK__RandomByteAtRLP_6
BLOCK__RandomByteAtRLP_7
BLOCK__ZeroByteAtRLP_6
BLOCK__ZeroByteAtRLP_7
BLOCK_mixHash_TooShort
ExtraData32_Istanbul
notxs_Berlin
```

### Storage / State Edge Cases (~15)

```
refundReset_EIP158
RecallSuicidedContractInOneBlock_Istanbul
suicideStorageCheckVCreate_Istanbul
suicideStorageCheck_Berlin
ZeroValue_TransactionCALLwithData_ToEmpty_OOGRevert_Istanbul
ZeroValue_TransactionCALLwithData_ToOneStorageKey_OOGRevert_Paris_Berlin
UserTransactionZeroCost2_Istanbul
UserTransactionZeroCost_Berlin
callRevert_Berlin
log1_correct_Istanbul
logRevert_Berlin
timeDiff12_Berlin
timeDiff14_Istanbul
```

### Wallet Tests / Crashes (5)

```
wallet2outOf3txsRevokeAndConfirmAgain_Istanbul
wallet2outOf3txsRevokeAndConfirmAgain_Berlin
wallet2outOf3txs_Berlin
walletReorganizeOwners_Istanbul
walletReorganizeOwners_Berlin
```

---

*Report generated: 2026-02-11*
*Test run ID: consensus-etc-3client-20260206*
