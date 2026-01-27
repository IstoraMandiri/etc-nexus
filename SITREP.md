# Situation Report

Last updated: 2025-01-27

## Summary

Hive integration with core-geth is **working**. We can build our fork and run tests. However, most upstream Hive tests target post-merge Ethereum (Cancun era), while ETC is pre-merge. We need ETC-specific test coverage.

## Repository Status

| Repo | Branch | Remote |
|------|--------|--------|
| etc-nexus | `main` | IstoraMandiri/etc-nexus |
| hive | `istora-core-geth-client` | IstoraMandiri/hive |
| core-geth | `master` | IstoraMandiri/core-geth |

## What's Working

### Passing Tests
- **devp2p/discv4**: 16/16 - P2P discovery layer works
- **smoke/genesis**: 6/6 - Basic genesis handling works

### Build Pipeline
- core-geth builds from `IstoraMandiri/core-geth` (~2 min)
- Hive builds and runs successfully
- Client version confirmed: `CoreGeth/v1.12.21-unstable-4185df45`

## What's Not Working (And Why)

### devp2p/eth: 1/20 passed
**Root cause**: Tests use `--engineapi` flag which requires Engine API (post-merge beacon client communication). ETC doesn't use this.

### ethereum/sync: 0/2 passed
**Root cause**: Post-merge sync tests expecting beacon client. Not applicable to ETC.

### ethereum/consensus: Many failures
**Root cause**: All tests run with `_Cancun` suffix (post-merge era). Need to run with pre-merge fork configs.

### ethereum/rpc-compat: 33/200 passed
**Root cause**: Most failures are `eth_simulateV1` - a newer ETH method not in core-geth. Expected for ETC client.

## Key Technical Details

### Hive Client Definition
Location: `hive/clients/core-geth/`
- `Dockerfile` - Builds from IstoraMandiri/core-geth
- `geth.sh` - Startup script with HIVE_* env var handling
- `mapper.jq` - Transforms HIVE_* vars to genesis config

### Test Configuration
- Tests receive fork config via `HIVE_FORK_*` environment variables
- `mapper.jq` converts these to genesis.json format
- Current mapper supports ETH forks; may need ETC-specific forks (ECIPs)

### Why ETH Tests Fail on ETC
1. **Post-merge assumption**: Tests default to Cancun (with withdrawals, beacon sync)
2. **Engine API**: Many tests require `--engineapi` for beacon client communication
3. **Missing methods**: `eth_simulateV1` and other newer ETH RPC methods

## Commands Reference

```bash
# Navigate to hive
cd /workspaces/etc-nexus/hive

# Build hive
go build .

# Run ETC-compatible tests (these pass)
./hive --sim devp2p --sim.limit discv4 --client core-geth
./hive --sim smoke/genesis --client core-geth

# Run other tests (mostly fail due to post-merge)
./hive --sim ethereum/consensus --client core-geth
./hive --sim devp2p --sim.limit eth --client core-geth
```

## Next Session Should

1. Investigate running consensus tests with pre-merge fork filters
2. Check if devp2p/eth can run without Engine API
3. Define which RPC methods ETC MUST support
4. Consider creating `simulators/etc/` for ETC-specific tests
