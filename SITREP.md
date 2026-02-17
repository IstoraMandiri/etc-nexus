# Situation Report

Last updated: 2026-02-17 UTC

## Summary

Hive integration testing for ETC clients. Three clients under test: core-geth, besu-etc, nethermind-etc. Implemented `consensus-etc` suite in Hive for streamlined ETC testing. **Full 3-client consensus-etc run complete: 183,985 tests, 302 failures. Per-client attribution finalized from results JSON.**

**Status: All work committed and pushed. Server decommissioned. Ready to restore on a new instance.**

## Active Tests

None — all test runs complete. Server being decommissioned.

## Test Results — consensus-etc Full Suite (3 clients)

```
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth,besu-etc,nethermind-etc --sim.parallelism 4
```

| Client | Tests | Passed | Failed | Pass Rate | Status |
|--------|-------|--------|--------|-----------|--------|
| core-geth | 61,328 | 61,264 | 64 | 99.90% | Complete |
| besu-etc | 61,328 | 61,321 | 7 | 99.99% | Complete |
| nethermind-etc | 61,328 | 61,098 | 230 | 99.62% | Complete |
| meta-test | 1 | 0 | 1 | — | Complete |
| **Total** | **183,985** | **183,683** | **302** | **99.84%** | **Complete** |

- **Duration:** ~125h / 5.2 days (2026-02-06 13:07 — 2026-02-11 ~18:30 UTC)
- **Rate:** ~24.5 tests/min (all clients combined), ~8.2 tests/min per client
- **Fork coverage:** Frontier (3,927), Homestead (7,197), EIP150 (4,425), EIP158 (4,428), Byzantium (15,759), Constantinople (33,225), ConstantinopleFix (33,210), Istanbul (38,793), Berlin (41,964)
- **core-geth (64 failures):** ALL EIP-7610/CREATE2 collision edge cases (61) + DAO fork tests (3). No genuine EVM failures. Categories: `InitCollision` (16+8 Paris), `create2collisionStorage` (12+6 Paris), `RevertInCreateInInit` (5+2 Paris), `RevertInCreateInInitCreate2` (4+2 Paris), `dynamicAccountOverwriteEmpty` (4+2 Paris), `DaoTransactions` (3)
- **besu-etc (7 failures):** DAO fork tests (3) + 4 genuine: `codesizeOOGInvalidSize_EIP158` (known), `RevertOpcode_d0g1v0_Istanbul`, `eip2929OOG_d3g0v0_Istanbul`, `gasCostMemSeg_d41g0v0_Berlin`
- **nethermind-etc (230 failures):** Multiple systematic categories:
  - Chain reorg/multi-chain (~60): ChainAtoChainB variants, newChainFrom4/5/6Block, sidechain/uncle tests
  - RPC/infrastructure (16): RPC_API_Test (9), ForkStressTest (7)
  - Precompile (24): RevertPrecompiledTouch (12), static_Call50000_sha256 (10), CALLBlake2f_MaxRounds (2)
  - Trie/branch tests (16): lotsOfBranches variants, lotsOfLeafs
  - Istanbul/Berlin specific (~50): randomStatetest variants, InvalidBlocks, wallet tests, storage/state tests
  - Heavy compute (7): loopMul (6), loopExp (1)
  - DAO fork (4): DaoTransactions (3), HomesteadOverrideFrontier (1)
  - Block-level (5): BLOCK_* RLP tests, ExtraData32, notxs
  - Final crashes (5): wallet* tests at very end — "terminated unexpectedly"
- **Full report:** [`reports/260211_CONSENSUS_ETC_RESULTS.md`](reports/260211_CONSENSUS_ETC_RESULTS.md)

## Test Results — Baseline (ETH test suites)

Full runs using upstream Hive `legacy` and `legacy-cancun` suites.

| Client | Suite | Tests | Passed | Failed | Pass Rate | Status |
|--------|-------|-------|--------|--------|-----------|--------|
| core-geth | legacy | 32,616 | 32,595 | 21 | 99.94% | Complete |
| core-geth | legacy-cancun | 111,983 | 111,893 | 90 | 99.92% | Complete |
| besu-etc | legacy | 32,616 | 32,613 | 3 | 99.99% | Complete |

**Notes:**
- core-geth failures: All 21+90 are EIP-7610 edge cases (CREATE2 collision) — safe to exclude for ETC
- besu-etc legacy failures: 3 genuine failures (sstore_combinations, codesizeOOGInvalidSize, ecmul) — needs investigation
- Full reports: [`reports/`](reports/)

## Test Results — consensus-etc Suite (Partial / Early Runs)

Early partial runs before the full 3-client suite was started.

| Client | Scope | Tests | Passed | Failed | Pass Rate | Status |
|--------|-------|-------|--------|--------|-----------|--------|
| nethermind-etc | bcValidBlockTest | 167 | 166 | 1 | 99.4% | Complete |

**Notes:**
- nethermind-etc: 166/167 real tests pass; only the "test file loader" meta-test failed
- Fork breakdown (passing): Frontier 20, Homestead 20, EIP150 19, EIP158 19, Byzantium 19, Constantinople 20, ConstantinopleFix 20, Istanbul 14, Berlin 15
- Full 3-client run results in section above

## Smoke Tests

| Client | genesis | network | Status |
|--------|---------|---------|--------|
| core-geth | 6/6 | 2/2 | Pass |
| besu-etc | 6/6 | 2/2 | Pass |
| nethermind-etc | 6/6 | 2/2 | Pass |

## Infrastructure

| Component | Status |
|-----------|--------|
| Hive binary | Built |
| core-geth image | Ready |
| besu-etc image | Ready |
| nethermind-etc image | Ready |
| Docker | Running |
| consensus-etc suite | Implemented & pushed |

## Repository Status

| Repo | Branch | Latest Commit | Status |
|------|--------|---------------|--------|
| etc-nexus | `main` | `bd64ef7` | Up to date |
| hive | `istora-core-geth-client` | `701402d` | Pushed |
| nethermind-etc-plugin | `main` | `bc99146` | In sync |

## Commands Reference

```bash
cd /workspaces/nexus/hive
export PATH=$PATH:/usr/local/go/bin

# Smoke tests
./hive --sim smoke/genesis --client core-geth
./hive --sim smoke/genesis --client nethermind-etc

# ETC consensus tests (new suite) — always use --sim.parallelism
# All three clients in one command (preferred):
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth,besu-etc,nethermind-etc --sim.parallelism 4

# Single client:
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth --sim.parallelism 4

# Filter by fork or test category
./hive --sim ethereum/consensus --sim.limit "consensus-etc/Berlin" --client core-geth
./hive --sim ethereum/consensus --sim.limit "consensus-etc/.*bcValidBlockTest" --client nethermind-etc

# Legacy suites (ETH-native, broader)
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth
```

---

## Operation Log

### 2026-02-17: Server Decommission Handoff
- Verified all work committed and pushed across all repos (etc-nexus, hive, nethermind-etc-plugin)
- No running processes, no uncommitted changes, no unpushed commits
- Server being shut down to save costs; restore from `git clone --recursive` on new instance
- To resume: `/pickup` in a new session

### 2026-02-11: consensus-etc Full Suite Complete
- **Result:** 183,985 tests, 302 failures across 3 clients
- **Duration:** ~125 hours / 5.2 days (Feb 6 13:07 — Feb 11 18:16 UTC)
- **Per-client results (from results JSON):**
  - core-geth: 61,264/61,328 passed (99.90%) — 64 failures, all EIP-7610 + DAO fork
  - besu-etc: 61,321/61,328 passed (99.99%) — 7 failures (3 DAO + 4 genuine)
  - nethermind-etc: 61,098/61,328 passed (99.62%) — 230 failures (chain reorg, precompile, Istanbul/Berlin issues)
- **Forks tested:** Frontier, Homestead, EIP150, EIP158, Byzantium, Constantinople, ConstantinopleFix, Istanbul, Berlin (all 9 ETC-compatible forks)
- **Key findings:**
  - core-geth: No genuine EVM failures — all 64 are EIP-7610 (not applicable to ETC) + DAO fork (disabled for ETC)
  - besu-etc: Best pass rate at 99.99% — only 4 genuine failures beyond DAO tests
  - nethermind-etc: Systematic issues with chain reorg/uncle handling (~60 failures), heavy precompile tests, and Istanbul/Berlin-specific tests
- **Report:** [`reports/260211_CONSENSUS_ETC_RESULTS.md`](reports/260211_CONSENSUS_ETC_RESULTS.md)

### 2026-02-06: consensus-etc suite & nethermind-etc progress
- Implemented `consensus-etc` suite in Hive consensus simulator
  - Added `etc` role to core-geth, besu-etc, nethermind-etc client YAMLs
  - Created `etc_forks.go` with ETC fork env mappings (Frontier through Berlin + transitions)
  - Modified `main.go`: `makeETCSuite()` loads all test dirs, filters to ETC forks, uses `etc` role
  - No DAO fork vote for ETC runs; chain ID 1 for test vector compatibility
- Added nethermind-etc client definition (Dockerfile, mapper.jq, scripts)
- nethermind-etc genesis smoke tests fixed: 6/6 pass
- nethermind-etc consensus-etc/bcValidBlockTest: 166/167 pass (99.4%)
- Committed and pushed to hive `istora-core-geth-client` branch (`701402d`)

### 2026-02-06: Power Outage Recovery
- All Hive processes killed; Docker images survived
- Corrected SITREP: besu-etc legacy was actually complete (32,613/32,616, 99.99%)
- Corrected SITREP: nethermind-etc legacy never ran (was still on genesis smoke tests)
- Corrected SITREP: besu-etc "full consensus" was misconfigured (only ran 572 Cancun tests)

### 2026-02-06: nethermind-etc genesis debugging
- Smoke tests intermittently passing/failing
- Vanilla nethermind passes (6/6), nethermind-etc regressed
- Fixed by resolving plugin architecture conflict

### 2026-02-01: besu-etc legacy Complete
- **Result:** 99.99% pass (32,613/32,616)
- **Duration:** ~30.5 hours (Jan 31 00:24 -- Feb 1 06:53 UTC)
- **Failed:** 3 tests (genuine failures, not EIP-7610)
- Forks tested: Frontier, Homestead, EIP150, EIP158, Byzantium, Constantinople, ConstantinopleFix

### 2026-02-02: core-geth legacy-cancun Complete
- **Result:** 99.92% pass (111,893/111,983)
- **Duration:** ~59 hours
- **Failed:** 90 tests (all EIP-7610 edge cases)
- **Report:** [260202_LEGACY_CANCUN_RESULTS.md](reports/260202_LEGACY_CANCUN_RESULTS.md)

### 2026-02-02: besu-etc full consensus (misconfigured)
- Ran `--sim.limit .*` which only matched `consensus` suite (Cancun tests)
- All 572 tests failed (expected — besu-etc doesn't support Cancun)
- Did NOT actually run legacy or legacy-cancun suites

### 2026-01-31: Started core-geth legacy-cancun
- Running Istanbul through Cancun forks
- Completed Feb 2, 11:29 UTC

### 2026-01-30: Cloud Deployment
- Migrated to cloud after power outage
- Both clients verified: smoke/genesis 6/6, smoke/network 2/2
- Added besu-etc client definition (commit `271ae4c`)

### 2026-01-28: core-geth legacy Complete
- **Result:** 99.94% pass (32,595/32,616)
- **Failed:** 21 tests (CREATE2 collision edge cases)
- **Report:** [260130_CREATE2_COLLISION_RESOLUTION.md](reports/260130_CREATE2_COLLISION_RESOLUTION.md)

### 2026-01-27: Hive Integration Setup
- Created core-geth client definition in Hive
- Fixed TTD handling, removed `--nocompaction`, added `--fakepow` support
- Baseline tests passing: devp2p 16/16, smoke/genesis 6/6
