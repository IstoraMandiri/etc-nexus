# Situation Report

Last updated: 2026-02-06 10:00 UTC

## Summary

Hive integration testing for ETC clients. core-geth and besu-etc baselines complete. nethermind-etc still in setup. Power outage on Feb 6 killed all running processes; Docker images survived.

## Test Results

| Client | Suite | Tests | Passed | Failed | Pass Rate | Status |
|--------|-------|-------|--------|--------|-----------|--------|
| core-geth | legacy | 32,616 | 32,595 | 21 | 99.94% | ✅ Complete |
| core-geth | legacy-cancun | 111,983 | 111,893 | 90 | 99.92% | ✅ Complete |
| besu-etc | legacy | 32,616 | 32,613 | 3 | 99.99% | ✅ Complete |
| besu-etc | full consensus | 572 | 0 | 572 | 0% | ⚠️ Wrong scope |
| nethermind-etc | legacy | - | - | - | - | ❌ Never started |

**Notes:**
- core-geth failures: All 21+90 are EIP-7610 edge cases (CREATE2 collision) - safe to exclude for ETC
- besu-etc legacy failures: 3 genuine failures (sstore_combinations, codesizeOOGInvalidSize, ecmul) - needs investigation
- besu-etc "full consensus" was misconfigured (`--sim.limit .*`) — only matched 572 Cancun tests which besu-etc can't run
- nethermind-etc was still debugging genesis smoke tests; never progressed to consensus runs
- Full reports: [`reports/`](reports/)

## Active Tests

None — all processes killed by power outage (Feb 6 ~09:39 UTC).

## Infrastructure

| Component | Status |
|-----------|--------|
| Hive binary | ✓ Built |
| core-geth image | ✓ Survived outage |
| besu-etc image | ✓ Survived outage |
| nethermind-etc image | ✓ Survived outage |
| Docker | ✓ Running |
| Hive processes | ❌ All killed |

## Repository Status

| Repo | Branch | Purpose |
|------|--------|---------|
| etc-nexus | `main` | Orchestration repo |
| hive | `istora-core-geth-client` | Hive fork with ETC clients |
| core-geth | `master` | ETC client fork |

## Commands Reference

```bash
cd /workspaces/nexus/hive
export PATH=$PATH:/usr/local/go/bin

# Smoke tests
./hive --sim smoke/genesis --client core-geth
./hive --sim smoke/genesis --client besu-etc

# Consensus tests
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth
```

---

## Operation Log

### 2026-02-06: Power Outage Recovery
- All Hive processes killed; Docker images survived
- Corrected SITREP: besu-etc legacy was actually complete (32,613/32,616, 99.99%)
- Corrected SITREP: nethermind-etc legacy never ran (was still on genesis smoke tests)
- Corrected SITREP: besu-etc "full consensus" was misconfigured (only ran 572 Cancun tests)

### 2026-02-06: nethermind-etc genesis debugging
- Smoke tests intermittently passing/failing
- Vanilla nethermind passes (6/6), nethermind-etc regressed
- Never progressed to consensus/legacy test runs

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
