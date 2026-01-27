# TODO

## Immediate Actions (Next Session)

### 1. Fix `--nocompaction` Flag
**File:** `hive/clients/core-geth/geth.sh:112`

```bash
# Current (broken):
(cd /blocks && $geth $FLAGS --gcmode=archive --verbosity=$HIVE_LOGLEVEL import --nocompaction `ls | sort -n`)

# Fixed (remove --nocompaction):
(cd /blocks && $geth $FLAGS --gcmode=archive --verbosity=$HIVE_LOGLEVEL import `ls | sort -n`)
```

### 2. Fix TTD Handling for Pre-Merge Tests
**File:** `hive/clients/core-geth/mapper.jq`

The mapper sets TTD even for pre-merge fork tests, causing core-geth to enter beacon sync mode. Investigation needed:

Options:
1. Check if mapper can detect pre-merge configs and skip TTD
2. Look for hive flag to disable post-merge mode
3. Modify genesis.json generation to omit merge config

**Evidence from client logs:**
```
Consensus: Beacon (proof-of-stake), merged from Ethash (proof-of-work)
Chain post-merge, sync via beacon client
```

### 3. Re-run Consensus Tests After Fixes
Once TTD issue is resolved:
```bash
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
```

### 4. File Bug for debug_getRaw* Crash
**Issue:** `debug_getRawBlock`, `debug_getRawHeader`, `debug_getRawReceipts` return "method handler crashed" for non-genesis blocks.

**Evidence:**
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"method handler crashed"}}
```

---

## Test Status Summary

### Passing Tests (ETC Baseline)
| Test | Pass | Fail | Status |
|------|------|------|--------|
| smoke/genesis | 6 | 3 | ✅ (3 Cancun expected) |
| smoke/network | 2 | 0 | ✅ |
| devp2p/discv4 | 16 | 0 | ✅ |

### Partially Working
| Test | Pass | Fail | Notes |
|------|------|------|-------|
| ethereum/rpc-compat | 33 | 167 | 91 eth_simulateV1 expected |

### Blocked (Need TTD Fix)
| Test | Issue |
|------|-------|
| ethereum/consensus (legacy) | Beacon sync mode |
| devp2p/eth | Engine API required |
| ethereum/sync | Post-merge tests |

### Not Applicable to ETC
- ethereum/engine - Post-merge only
- eth2/* - Beacon chain
- portal/ - Experimental

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
