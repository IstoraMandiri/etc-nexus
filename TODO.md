# TODO

## Current Challenge

Upstream Hive tests are designed for Ethereum mainnet (post-merge, Cancun era). ETC is pre-merge with a different fork schedule. We need a testing methodology that:

1. Validates core-geth works correctly for ETC use cases
2. Doesn't skip tests that SHOULD pass
3. Clearly documents why certain tests are excluded

## Test Categorization Methodology

### Step 1: Categorize All Hive Simulators

| Simulator | Relevance | Notes |
|-----------|-----------|-------|
| `devp2p/discv4` | **ETC-relevant** | P2P discovery - should pass |
| `devp2p/eth` | **Needs investigation** | Uses Engine API (post-merge) |
| `smoke/genesis` | **ETC-relevant** | Basic genesis handling - should pass |
| `smoke/network` | **ETC-relevant** | Basic networking |
| `ethereum/consensus` | **Partially relevant** | EVM tests, but defaults to Cancun |
| `ethereum/sync` | **ETH-only** | Post-merge beacon sync |
| `ethereum/engine` | **ETH-only** | Engine API (post-merge) |
| `ethereum/rpc-compat` | **Partially relevant** | Many methods ETC doesn't implement |
| `eth2/*` | **ETH-only** | Beacon chain tests |

### Step 2: Establish ETC Baseline

For each ETC-relevant simulator, run tests and document:
- Total tests
- Passed
- Failed (with reason: ETC-expected vs bug)

### Step 3: Create ETC Test Suite

Options:
1. **Filter existing tests** - Run consensus tests with pre-merge fork configs
2. **Create ETC simulator** - New `simulators/etc/` with ETC-specific tests
3. **Fork test data** - Create ETC-specific test vectors

## Immediate Actions

### 1. Audit Passing Tests
```bash
# These MUST pass - they're ETC-relevant
./hive --sim devp2p --sim.limit discv4 --client core-geth  # 16/16 ✓
./hive --sim smoke/genesis --client core-geth              # 6/6 ✓
```

### 2. Investigate devp2p/eth Failures
The eth protocol tests fail because:
- They use `--engineapi` (Engine API for post-merge)
- Test chain data is from go-ethereum (may have post-merge assumptions)

**Action**: Check if we can run eth protocol tests WITHOUT Engine API requirements.

### 3. Run Pre-Merge Consensus Tests
The consensus tests support different fork configs. Try:
```bash
# Run only pre-London tests
./hive --sim ethereum/consensus --client core-geth --sim.limit "Berlin|Istanbul|Constantinople"
```

### 4. Document RPC Compatibility
Run rpc-compat and categorize failures:
- `eth_simulateV1` - Not implemented (OK for ETC)
- `eth_syncing` - Should work (investigate)
- Basic methods like `eth_blockNumber`, `eth_getBalance` - Must work

## Test Results Tracking

### Baseline (Current core-geth)

| Test Suite | Pass | Fail | Notes |
|------------|------|------|-------|
| devp2p/discv4 | 16 | 0 | ✓ All pass |
| smoke/genesis | 6 | 0 | ✓ All pass |
| devp2p/eth | 1 | 19 | Engine API required |
| ethereum/sync | 0 | 2 | Post-merge only |
| ethereum/rpc-compat | 33 | 167 | Many ETH-only methods |

### Target for ETC

We need to define which tests core-geth MUST pass for ETC. Create this list by:
1. Identifying pre-merge, EVM-focused tests
2. Running them against current core-geth
3. Filing bugs for unexpected failures

## Future: ECIP Testing

Once baseline is established:
- [ ] ECIP-1120 implementation + tests
- [ ] ECIP-1121 implementation + tests
- [ ] ETC fork transition tests (Classic-specific ECIPs)

## Quick Reference

```bash
# Build and run Hive
cd hive && go build . && ./hive --sim <simulator> --client core-geth

# See available simulators
ls simulators/

# Filter tests
./hive --sim ethereum/consensus --sim.limit "pattern"

# Logs location
workspace/logs/
```
