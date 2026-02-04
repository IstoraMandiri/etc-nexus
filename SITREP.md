# Situation Report

Last updated: 2026-02-04 06:42 UTC

## Summary

Hive integration testing for ETC clients. core-geth baseline complete (99.9%+ pass), besu-etc testing in progress.

## Test Results

| Client | Suite | Tests | Passed | Failed | Pass Rate | ETA | Status |
|--------|-------|-------|--------|--------|-----------|-----|--------|
| core-geth | legacy | 32,616 | 32,595 | 21 | 99.94% | - | ✅ Complete |
| core-geth | legacy-cancun | 111,983 | 111,893 | 90 | 99.92% | - | ✅ Complete |
| besu-etc | legacy | 32,616 | ~30437 | - | ~93.3% | ~7h | 🔄 Running |
| besu-etc | full consensus | 111,983 | ~9708 | - | ~8.7% | ~426h | 🔄 Running |

**Notes:**
- All failures are EIP-7610 edge cases (CREATE2 collision) - safe to exclude for ETC
- besu-etc runs ~5 tests/min (slow due to JVM startup overhead)
- Full reports: [`reports/`](reports/)

## Active Tests

**besu-etc: legacy** (started Jan 31)
- Progress: 30437 / 32,616 (93.3%)
- Rate: ~5.4 tests/min | ETA: ~7h

**besu-etc: full consensus** (started Feb 2, 14:06 UTC)
- Progress: 9708 / 111,983 (8.7%)
- Rate: ~4.0 tests/min | ETA: ~7h
- Note: Will fail post-merge tests (expected - ETC doesn't support merge)

## Infrastructure

| Component | Status |
|-----------|--------|
| Hive binary | ✓ Built |
| core-geth image | ✓ Ready |
| besu-etc image | ✓ Ready |
| Docker | ✓ Running |

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

### 2026-02-02: core-geth legacy-cancun Complete
- **Result:** 99.92% pass (111,893/111,983)
- **Duration:** ~59 hours
- **Failed:** 90 tests (all EIP-7610 edge cases)
- **Report:** [260202_LEGACY_CANCUN_RESULTS.md](reports/260202_LEGACY_CANCUN_RESULTS.md)

### 2026-02-02: Started besu-etc full consensus
- Running `--sim.limit .*` against besu-etc
- Expected to fail post-merge tests

### 2026-01-31: Started besu-etc legacy
- Running `--sim.limit legacy` against besu-etc
- Testing Constantinople and earlier forks

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
