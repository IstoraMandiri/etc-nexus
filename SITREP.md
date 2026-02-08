# Situation Report

Last updated: 2026-02-08 03:13 UTC

## Summary

Hive integration testing for ETC clients. Three clients under test: core-geth, besu-etc, nethermind-etc. Implemented `consensus-etc` suite in Hive for streamlined ETC testing. nethermind-etc passing initial consensus tests.

## Active Tests

**consensus-etc full suite — 3 clients (started 13:07 UTC)**

```
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth,besu-etc,nethermind-etc --sim.parallelism 4
```

| Client | Tests Done | Failures | Status |
|--------|-----------|----------|--------|
| core-geth | 19,638 | TBD | Running |
| besu-etc | 19,638 | TBD | Running |
| nethermind-etc | 19,638 | TBD | Running |

- **Total:** 58,914 tests completed (34 failures)
- **Rate:** ~26 tests/min (all clients combined), ~8.6 tests/min per client
- **Elapsed:** 38h (started 2026-02-06 13:07 UTC)
- **Current test:** `sstore_combinations_initial1` (d1679) — sstore combo tests continue
- **Fork coverage:** Frontier (2,145), Homestead (4,323), EIP150 (2,394), EIP158 (2,799), Byzantium (9,606), Constantinople (19+k), ConstantinopleFix (19+k)
- **Failures by test (34 total):**
  - `InitCollision` (8) — d0-d3 × Constantinople/ConstantinopleFix — EIP-7610
  - `create2collisionStorage` (6) — d0-d2 × Constantinople/ConstantinopleFix — EIP-7610
  - `RevertPrecompiledTouch` (6) — d0g0v0 + d3g0v0 × Byz/Const/ConstFix
  - `RevertPrecompiledTouch_storage` (6) — d0g0v0 + d3g0v0 × Byz/Const/ConstFix
  - `RevertInCreateInInit` (3) — Byzantium/Constantinople/ConstantinopleFix
  - `RevertInCreateInInitCreate2` (2) — Constantinople/ConstantinopleFix — EIP-7610
  - `dynamicAccountOverwriteEmpty` (2) — Constantinople/ConstantinopleFix — EIP-7610
  - `codesizeOOGInvalidSize` (1) — EIP158 — known besu-etc failure
- **Per-client attribution pending** — detail log doesn't include client IDs; will finalize from results JSON after completion. EIP-7610 tests (18) are likely core-geth (known from legacy run).
- **Note:** Approaching 60k tests. No new failures since 10k mark. Istanbul/Berlin still not reached. 38h elapsed.

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

## Test Results — consensus-etc Suite

The new `consensus-etc` suite filters all test directories to ETC-compatible forks (Frontier through Berlin) and runs only against clients with the `etc` role.

| Client | Scope | Tests | Passed | Failed | Pass Rate | Status |
|--------|-------|-------|--------|--------|-----------|--------|
| nethermind-etc | bcValidBlockTest | 167 | 166 | 1 | 99.4% | Partial run |

**Notes:**
- nethermind-etc: 166/167 real tests pass; only the "test file loader" meta-test failed
- Fork breakdown (passing): Frontier 20, Homestead 20, EIP150 19, EIP158 19, Byzantium 19, Constantinople 20, ConstantinopleFix 20, Istanbul 14, Berlin 15
- Full consensus-etc run (all test categories) not yet attempted

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
| etc-nexus | `main` | `c728939` | Needs update |
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
