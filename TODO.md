# TODO

> **Note:** For current test progress and status, see [SITREP.md](SITREP.md).
> This file focuses on planned future work.

## Immediate — Full consensus-etc Runs

1. **Run full consensus-etc for nethermind-etc** — only bcValidBlockTest subset done so far (166/167). Run without `--sim.limit` filter to cover all test categories.
2. **Run full consensus-etc for core-geth** — validate against the new suite (should match legacy results)
3. **Run full consensus-etc for besu-etc** — validate against the new suite

## Investigate Known Failures

- [ ] **besu-etc 3 legacy failures** — NOT EIP-7610. Failures: `sstore_combinations_initial1_d1243g0v0_Constantinople`, `codesizeOOGInvalidSize_d0g0v0_EIP158`, `ecmul_1-2_340282366920938463463374607431768211456_21000_128_d0g1v0_ConstantinopleFix`
- [ ] **nethermind-etc "test file loader" meta-test failure** — the 1 failure in the 166/167 run; may be a harness issue rather than a real consensus failure
- [ ] **besu-etc legacy-cancun** — was misconfigured last time (`--sim.limit .*`). Run properly with `--sim.limit legacy-cancun`

## Pending Analysis

When test runs complete:
- [ ] Create multi-client validation summary (core-geth vs besu-etc vs nethermind-etc)
- [ ] Create besu-etc legacy results report (compare with core-geth baseline)
- [ ] Analyze core-geth Istanbul/Berlin subset from legacy-cancun

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

## Future: ETC-Divergent Forks (ECIP-1120, ECIP-1121, etc.)

Eventually ETC will have forks with no Ethereum equivalent. These require:

1. **ETC-specific test directory** (`ETCTests/ECIP1120/`, etc.)
2. **ETC-only fork definitions** in `etc_forks.go` (new `HIVE_FORK_ECIP*` env vars)
3. **Test generation** from reference implementations
4. **Client support** for new env vars in mapper.jq/startup scripts

See [ECIP-1120](https://ecips.ethereumclassic.org/ECIPs/ecip-1120) and [ECIP-1121](https://ecips.ethereumclassic.org/ECIPs/ecip-1121).

---

## Quick Reference

```bash
# Build and run Hive
cd /workspaces/nexus/hive
export PATH=$PATH:/usr/local/go/bin
go build .

# ETC consensus tests (preferred) — multiple clients in one command
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth,besu-etc,nethermind-etc --sim.parallelism 4

# Legacy suites
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth
./hive --sim ethereum/consensus --sim.limit legacy-cancun --client core-geth

# Logs location
workspace/logs/
```
