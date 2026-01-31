# TODO

> **Note:** For current test progress and status, see [SITREP.md](SITREP.md).
> This file focuses on planned future work.

## Agent Pickup Points

### test-geth
Resume core-geth `legacy-cancun` suite (interrupted at 37,944/111,983, ~33.9%).
```bash
cd /workspaces/nexus/hive && ./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth
```
Use `/hourly-monitor` for automated progress updates.

### test-besu
Resume besu-etc `legacy` suite (interrupted at 9,788/32,616, ~30.0%).
```bash
cd /workspaces/nexus/hive && ./hive --sim ethereum/consensus --sim.limit legacy --client besu-etc
```
Use `/hourly-monitor` for automated progress updates.

### reporter
Monitor both test runs. When complete, create analysis reports using `/report`:
- besu-etc legacy results (compare with core-geth 99.94% baseline)
- core-geth Istanbul/Berlin subset from legacy-cancun
- Multi-client validation summary

## Immediate Actions

### 1. Resume Interrupted Test Runs
Resume the test runs that were interrupted by power outage (now on reliable cloud infrastructure).

### 3. Run Additional Test Suites
```bash
# GraphQL tests
./hive --sim ethereum/graphql --client core-geth

# Sync tests (may still have issues)
./hive --sim ethereum/sync --client core-geth

# devp2p eth protocol
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
cd /workspaces/nexus/hive
export PATH=$PATH:/usr/local/go/bin  # Add Go to PATH
go build .
./hive --sim <simulator> --client <core-geth|besu-etc>

# See available simulators
ls simulators/

# Filter tests
./hive --sim ethereum/consensus --sim.limit "pattern"

# Logs location
workspace/logs/

# Check client logs
ls workspace/logs/core-geth/
ls workspace/logs/besu-etc/
```
