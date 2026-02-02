# TODO

> **Note:** For current test progress and status, see [SITREP.md](SITREP.md).
> This file focuses on planned future work.

## Pending Analysis

When current test runs complete:
- [ ] Create besu-etc legacy results report (compare with core-geth baseline)
- [ ] Analyze core-geth Istanbul/Berlin subset from legacy-cancun
- [ ] Create multi-client validation summary

## Run Additional Test Suites
```bash
# GraphQL tests
./hive --sim ethereum/graphql --client core-geth

# Sync tests (may still have issues)
./hive --sim ethereum/sync --client core-geth

# devp2p eth protocol
./hive --sim devp2p/eth --client core-geth
```

## Follow-up Items

- [ ] Create ETC-specific test exclusion list in Hive fork for EIP-7610 tests
- [ ] File bug for `debug_getRaw*` crash (`debug_getRawBlock`, `debug_getRawHeader`, `debug_getRawReceipts` return "method handler crashed" for non-genesis blocks)

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
