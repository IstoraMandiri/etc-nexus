# Situation Report

Last updated: 2026-01-30

## Summary

Hive integration with core-geth is **working**. Legacy consensus test suite completed with 99.94% pass rate (32,595/32,616). Added **besu-etc** client for multi-client testing.

## Currently Running (2026-01-30 13:52 UTC)

### core-geth: `legacy-cancun` suite

| Metric | Value |
|--------|-------|
| Progress | 16,321 / 111,983 (14.6%) |
| Passed | 16,321 |
| Failed | 0 |
| Rate | ~43 tests/minute |
| ETA | ~37 hours remaining |
| Started | 2026-01-30 07:31 UTC |

**Note:** Only ~27,000 tests are ETC-relevant (Istanbul + Berlin). Future runs should use `--sim.limit "Istanbul|Berlin"`.

### besu-etc: `legacy` suite

| Metric | Value |
|--------|-------|
| Progress | 4,177 / 32,616 (12.8%) |
| Rate | ~11 tests/minute |
| ETA | ~42 hours |
| Started | 2026-01-30 07:43 UTC |

---

## Session Summary (2026-01-30)

Added Besu ETC client to Hive:
- Created `hive/clients/besu-etc/` using standard `hyperledger/besu` image (native ETC support)
- Modified `mapper.jq` to handle ETC-specific forks (Atlantis, Agharta, Phoenix, Thanos, Magneto, Mystique, Spiral)
- Smoke tests pass: genesis (6/6), network (2/2)
- Committed: `271ae4c`

## Previous Session (2026-01-28)

Legacy consensus test suite completed:
- **Result:** 99.94% pass rate (32,595/32,616)
- **Key finding:** 21 failures all related to CREATE2 collision edge cases

## Latest Results

**Completed:** Legacy consensus test suite
- Suite: `legacy` (LegacyTests/Constantinople/BlockchainTests)
- Total tests: 32,616
- Passed: 32,595 (99.94%)
- Failed: 21 tests

**Failed tests** (all CREATE2 collision edge cases):
- `InitCollision_*` (8 tests) - Constantinople/ConstantinopleFix
- `create2collisionStorage_*` (6 tests)
- `RevertInCreateInInit*` (5 tests)
- `dynamicAccountOverwriteEmpty_*` (2 tests)

## Repository Status

| Repo | Branch | Remote |
|------|--------|--------|
| etc-nexus | `main` | IstoraMandiri/etc-nexus |
| hive | `istora-core-geth-client` | IstoraMandiri/hive |
| core-geth | `master` | IstoraMandiri/core-geth |

## What's Working

### Client Status

| Client | Status | Notes |
|--------|--------|-------|
| **core-geth** | ✅ Working | Primary ETC client (Go) |
| **besu-etc** | ✅ Working | Smoke tests pass |
| **nethermind** | 📋 Planned | .NET client with ETC support |
| **fukuii** | 📋 Planned | Rust client |

### Baseline Tests

| Test | core-geth | besu-etc | nethermind | fukuii |
|------|-----------|----------|------------|--------|
| smoke/genesis | 6/9 | 6/6 | - | - |
| smoke/network | 2/2 | 2/2 | - | - |
| devp2p/discv4 | 16/16 | - | - | - |
| rpc-compat | 33/200 | - | - | - |

### Consensus Tests

| Suite | core-geth | besu-etc | nethermind | fukuii |
|-------|-----------|----------|------------|--------|
| legacy (32,616) | 99.94% | 🔄 12.8% (~42h) | - | - |
| legacy-cancun (~27k) | 🔄 14.6% (~37h) | - | - | - |

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

1. **Investigate CREATE2 failures** - 21 tests failing in legacy suite
2. **Run Istanbul/Berlin tests** from `legacy-cancun` suite (~27,000 ETC-relevant tests)
3. **Test additional simulators** (graphql, sync, devp2p/eth)
4. **File bug** for `debug_getRaw*` method handler crash

## Test Suite Reference (ethereum/tests)

| Suite | Total Tests | ETC Relevant | Notes |
|-------|-------------|--------------|-------|
| `legacy` | 32,616 | 32,616 (100%) | Constantinople and earlier - **99.94% pass** |
| `legacy-cancun` | 111,983 | ~27,000 | Istanbul + Berlin relevant |
| `consensus` | 1,148 | 571 | Cancun only (Prague not supported) |
| **Total** | **145,746** | **~60,000** | |
