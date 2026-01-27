# TODO

## Currently Running

**Legacy consensus test suite in progress:**
```bash
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
```
- Progress: ~15,373 / 32,615 tests (~47%)
- Status: All tests passing so far
- Rate: ~68 tests/minute (~8 hours for full suite)
- Estimated time remaining: ~4.2 hours

---

## Immediate Actions (After Current Run)

### 1. Analyze Legacy Test Results
Once the current run completes, document final pass/fail counts.

### 2. Run Istanbul/Berlin Tests
The `legacy-cancun` suite has ~27,000 ETC-relevant tests (Istanbul + Berlin):
```bash
cd /workspaces/etc-nexus/hive
./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth
```

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
| `legacy` | 32,615 | 32,615 (100%) | Constantinople and earlier - **Running** |
| `legacy-cancun` | 111,983 | ~27,000 | Istanbul + Berlin relevant |
| `consensus` | 1,148 | 571 | Cancun only (Prague not supported) |
| **Total** | **145,746** | **~60,000** | |

---

## Test Status Summary

### Passing Tests (ETC Baseline)
| Test | Pass | Fail | Status |
|------|------|------|--------|
| smoke/genesis | 6 | 3 | Good (3 Cancun expected) |
| smoke/network | 2 | 0 | Full pass |
| devp2p/discv4 | 16 | 0 | Full pass |
| ethereum/consensus (legacy) | ~15,373+ | 0 | Running (~47%, ~4.2h remaining) |

### Partially Working
| Test | Pass | Fail | Notes |
|------|------|------|-------|
| ethereum/rpc-compat | 33 | 167 | 91 eth_simulateV1 expected |

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
