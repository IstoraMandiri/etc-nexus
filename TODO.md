# TODO

## Currently Running (2026-01-30 09:48 UTC)

### core-geth: `legacy-cancun` suite

| Metric | Value |
|--------|-------|
| Progress | 5,894 / 111,983 (5.3%) |
| Rate | ~42 tests/minute |
| ETA | ~42 hours |

**Note:** Only ~27k tests are ETC-relevant. Future runs: `--sim.limit "Istanbul|Berlin"`

### besu-etc: `legacy` suite

| Metric | Value |
|--------|-------|
| Progress | 1,434 / 32,616 (4.4%) |
| Rate | ~12 tests/minute |
| ETA | ~44 hours |

---

## Latest Update (2026-01-30)

**Added besu-etc client** - Besu for Ethereum Classic using `hyperledger/besu` image.
- Smoke tests pass: genesis (6/6), network (2/2)
- Location: `hive/clients/besu-etc/`
- Commit: `271ae4c`

## Latest Test Results (core-geth)

**Legacy consensus test suite completed:**
- Total: 32,616 tests
- Passed: 32,595 (99.94%)
- Failed: 21 tests (CREATE2 collision edge cases)

**Failed tests:**
- `InitCollision_*` (8) - Constantinople/ConstantinopleFix
- `create2collisionStorage_*` (6)
- `RevertInCreateInInit*` (5)
- `dynamicAccountOverwriteEmpty_*` (2)

---

## Immediate Actions (After Current Run)

### 1. Investigate CREATE2 Failures
21 tests failing in legacy suite - all related to CREATE2 collision handling.

### 3. Run Additional Test Suites
```bash
# GraphQL tests
./hive --sim ethereum/graphql --client core-geth

# Sync tests (may still have issues)
./hive --sim ethereum/sync --client core-geth

# devp2p eth protocol (was blocked by TTD issue)
./hive --sim devp2p/eth --client core-geth
```

### 4. File Bug for debug_getRaw* Crash
**Issue:** `debug_getRawBlock`, `debug_getRawHeader`, `debug_getRawReceipts` return "method handler crashed" for non-genesis blocks.

**Evidence:**
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"method handler crashed"}}
```

---

## Test Suite Reference (ethereum/tests)

| Suite | Total Tests | ETC Relevant | Notes |
|-------|-------------|--------------|-------|
| `legacy` | 32,616 | 32,616 (100%) | Constantinople and earlier - **99.94% pass** |
| `legacy-cancun` | 111,983 | ~27,000 | Istanbul + Berlin relevant |
| `consensus` | 1,148 | 571 | Cancun only (Prague not supported) |
| **Total** | **145,746** | **~60,000** | |

---

## Multi-Client Test Status

### Client Overview

| Client | Status | Notes |
|--------|--------|-------|
| **core-geth** | ✅ Working | Primary ETC client (Go) |
| **besu-etc** | ✅ Working | Smoke tests pass |
| **nethermind** | 📋 Planned | .NET client |
| **fukuii** | 📋 Planned | Rust client |

### Baseline Tests (smoke, devp2p)

| Test | core-geth | besu-etc | nethermind | fukuii |
|------|-----------|----------|------------|--------|
| smoke/genesis | 6/9 | 6/6 | - | - |
| smoke/network | 2/2 | 2/2 | - | - |
| devp2p/discv4 | 16/16 | - | - | - |
| ethereum/rpc-compat | 33/200 | - | - | - |

### Consensus Tests

| Suite | core-geth | besu-etc | nethermind | fukuii |
|-------|-----------|----------|------------|--------|
| legacy (32,616) | 99.94% | 🔄 4.4% (~44h) | - | - |
| legacy-cancun (~27k) | 🔄 5.3% (~42h) | - | - | - |

### Not Applicable to ETC
- ethereum/engine - Post-merge only
- eth2/* - Beacon chain
- portal/ - Experimental

---

## Fixes Applied This Session

### 1. Removed `--nocompaction` Flag
**File:** `hive/clients/core-geth/geth.sh:112`
- Removed unsupported `--nocompaction` flag from block import command

### 2. Fixed TTD Handling for Pre-Merge Tests
**File:** `hive/clients/core-geth/mapper.jq`
- Changed TTD to only be set when `HIVE_TERMINAL_TOTAL_DIFFICULTY` is explicitly provided
- Changed `terminalTotalDifficultyPassed` to only be `true` when TTD is set

### 3. Added Fake PoW Support
**File:** `hive/clients/core-geth/geth.sh`
- Added handling for `HIVE_SKIP_POW` environment variable
- Enables `--fakepow` flag for tests with `SealEngine: "NoProof"`

---

## Documentation Status

- [x] `HIVE-TEST-ANALYSIS.md` - Comprehensive analysis complete
- [x] `CLAUDE.md` - Lessons learned documented
- [x] `SITREP.md` - Updated with current state
- [x] `TODO.md` - This file

---

## Future: ECIP Testing

Once baseline is established:
- [ ] ECIP-1120 implementation + tests
- [ ] ECIP-1121 implementation + tests
- [ ] ETC fork transition tests (Classic-specific ECIPs)
- [ ] Consider creating `simulators/etc/` for ETC-specific tests

---

## Quick Reference

```bash
# Build and run Hive
cd /workspaces/etc-nexus/hive
go build .
./hive --sim <simulator> --client core-geth

# See available simulators
ls simulators/

# Filter tests
./hive --sim ethereum/consensus --sim.limit "pattern"

# Logs location
workspace/logs/

# Check client logs
ls workspace/logs/core-geth/
```
