# Situation Report

Last updated: 2026-01-28

## Summary

Hive integration with core-geth is **working**. Legacy consensus test suite restarting after power outage (previously reached 57%).

## Current Activity

**Restarting:** `./hive --sim ethereum/consensus --sim.limit legacy --client core-geth`
- Suite: `legacy` (LegacyTests/Constantinople/BlockchainTests)
- Previous progress: 18,732 / 32,615 tests (57%) before power outage
- Status: Restarting from scratch
- Rate: ~70 tests/minute
- Estimated total suite time: ~7.8 hours

## Repository Status

| Repo | Branch | Remote |
|------|--------|--------|
| etc-nexus | `main` | IstoraMandiri/etc-nexus |
| hive | `istora-core-geth-client` | IstoraMandiri/hive |
| core-geth | `master` | IstoraMandiri/core-geth |

## What's Working

### Passing Tests (Phase 1)
| Test | Result | Notes |
|------|--------|-------|
| **smoke/genesis** | 6/9 | Core tests pass; 3 Cancun failures expected |
| **smoke/network** | 2/2 | Full pass |
| **devp2p/discv4** | 16/16 | Full pass |
| **ethereum/consensus (legacy)** | 0 / 32,615 | Restarting after power outage |

### Build Pipeline
- core-geth builds from `IstoraMandiri/core-geth` (~2 min)
- Hive builds and runs successfully
- Client version confirmed: `CoreGeth/v1.12.21-unstable-4185df45`

## Fixes Applied

### 1. TTD Handling (mapper.jq)
**Problem:** TTD was always set (defaulted to max int), causing post-merge mode.
**Fix:** Only set TTD when `HIVE_TERMINAL_TOTAL_DIFFICULTY` is explicitly provided.

### 2. `--nocompaction` Flag (geth.sh)
**Problem:** Flag not supported by core-geth.
**Fix:** Removed from block import command.

### 3. Fake PoW Support (geth.sh)
**Problem:** Tests with `SealEngine: "NoProof"` failed PoW verification.
**Fix:** Added `HIVE_SKIP_POW` handling to enable `--fakepow` flag.

## RPC Compatibility Analysis

**33 passing** tests cover:
- `eth_getBlockReceipts`, `eth_estimateGas`, `eth_createAccessList`
- `eth_getCode`, `eth_getBlockByHash`, `debug_getRaw*` (genesis)
- `eth_chainId`, `net_version`

**167 failing** tests breakdown:
- **eth_simulateV1** (91): Not implemented - **Expected for ETC**
- **eth_getBlock/Transaction*** (40+): Many require post-London features
- **eth_blobBaseFee** (1): Cancun method - **Expected for ETC**
- **debug_getRaw*** crash (3): **Bug - method handler crashes**

## Key Files Modified

1. `hive/clients/core-geth/geth.sh` - Fixed `--nocompaction`, added `HIVE_SKIP_POW`
2. `hive/clients/core-geth/mapper.jq` - Fixed TTD handling

## Commands Reference

```bash
# Navigate to hive
cd /workspaces/etc-nexus/hive

# Passing tests (run these to verify setup)
./hive --sim smoke/genesis --client core-geth      # 6/9
./hive --sim smoke/network --client core-geth      # 2/2
./hive --sim devp2p --sim.limit discv4 --client core-geth  # 16/16
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth  # Working!

# RPC tests
./hive --sim ethereum/rpc-compat --client core-geth
```

## Next Steps

1. **Run legacy test suite** - Restarting after power outage (~7.8 hours)
2. **Run Istanbul/Berlin tests** from `legacy-cancun` suite (~27,000 ETC-relevant tests)
3. **Test additional simulators** (graphql, sync, devp2p/eth)
4. **File bug** for `debug_getRaw*` method handler crash

## Test Suite Reference (ethereum/tests)

| Suite | Total Tests | ETC Relevant | Notes |
|-------|-------------|--------------|-------|
| `legacy` | 32,615 | 32,615 (100%) | Constantinople and earlier - **Running now** |
| `legacy-cancun` | 111,983 | ~27,000 | Istanbul + Berlin relevant |
| `consensus` | 1,148 | 571 | Cancun only (Prague not supported) |
| **Total** | **145,746** | **~60,000** | |
