# Situation Report

Last updated: 2026-01-27

## Summary

Hive integration with core-geth is **partially working**. Basic tests pass (P2P, genesis, network), but consensus tests are **blocked** by a post-merge configuration issue. The framework sets Terminal Total Difficulty (TTD) for all chains, causing core-geth to enter beacon sync mode instead of processing PoW blocks.

## Repository Status

| Repo | Branch | Remote |
|------|--------|--------|
| etc-nexus | `main` | IstoraMandiri/etc-nexus |
| hive | `istora-core-geth-client` | IstoraMandiri/hive |
| core-geth | `master` | IstoraMandiri/core-geth |

## What's Working

### Passing Tests (Phase 1 Complete)
| Test | Result | Notes |
|------|--------|-------|
| **smoke/genesis** | 6/9 | Core tests pass; 3 Cancun failures expected |
| **smoke/network** | 2/2 | Full pass |
| **devp2p/discv4** | 16/16 | Full pass |
| **ethereum/rpc-compat** | 33/200 | Partial (see analysis below) |

### Build Pipeline
- core-geth builds from `IstoraMandiri/core-geth` (~2 min)
- Hive builds and runs successfully
- Client version confirmed: `CoreGeth/v1.12.21-unstable-4185df45`

## Critical Blockers

### 1. Consensus Tests Fail Due to Post-Merge Config
**Symptom:** Running `./hive --sim ethereum/consensus --sim.limit legacy` causes ALL pre-merge tests (Homestead, Byzantium, etc.) to fail.

**Root Cause:** Hive sets `HIVE_TERMINAL_TOTAL_DIFFICULTY` in chain config via `mapper.jq`. Core-geth sees TTD and enters post-merge mode:
```
Consensus: Beacon (proof-of-stake), merged from Ethash (proof-of-work)
Chain post-merge, sync via beacon client
```

**Impact:** Client waits for Engine API calls instead of processing PoW blocks from tests.

**Fix Required:** Modify `hive/clients/core-geth/mapper.jq` to not set TTD for pre-merge fork tests, or investigate if hive has a pre-merge test mode.

### 2. Unknown Flag: `--nocompaction`
**Symptom:** Client logs show `flag provided but not defined: -nocompaction`

**Root Cause:** `hive/clients/core-geth/geth.sh:112` passes this flag during block import, but core-geth doesn't support it.

**Fix Required:** Remove `--nocompaction` from geth.sh.

## RPC Compatibility Analysis

**33 passing** tests cover:
- `eth_getBlockReceipts`, `eth_estimateGas`, `eth_createAccessList`
- `eth_getCode`, `eth_getBlockByHash`, `debug_getRaw*` (genesis)
- `eth_chainId`, `net_version`

**167 failing** tests breakdown:
- **eth_simulateV1** (91): Not implemented - **Expected for ETC**
- **eth_getBlock/Transaction*** (40+): Client stuck at block 0 (not syncing)
- **eth_call** (6): Returns `0x` (no state)
- **eth_blobBaseFee** (1): Cancun method - **Expected for ETC**
- **debug_getRaw*** crash (3): **Bug - method handler crashes**

**Note:** Most failures are because client doesn't import the test chain (beacon sync mode issue).

## Key Files Modified This Session

1. `HIVE-TEST-ANALYSIS.md` - Comprehensive test results and analysis
2. `CLAUDE.md` - Added lessons learned (TTD issue, nocompaction flag)

## Commands Reference

```bash
# Navigate to hive
cd /workspaces/etc-nexus/hive

# Passing tests (run these to verify setup)
./hive --sim smoke/genesis --client core-geth      # 6/9
./hive --sim smoke/network --client core-geth      # 2/2
./hive --sim devp2p --sim.limit discv4 --client core-geth  # 16/16

# Blocked tests (fail due to TTD/beacon mode)
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
```

## Next Session Should

1. **Fix `--nocompaction` flag** in `hive/clients/core-geth/geth.sh`
2. **Investigate TTD handling** in `mapper.jq` - find way to disable for pre-merge tests
3. **Re-run consensus tests** after fixes
4. **File bug** for `debug_getRaw*` method handler crash
5. **Test graphql and sync simulators** to see if same issues apply
