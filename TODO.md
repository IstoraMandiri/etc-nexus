# TODO

> **Note:** For current test progress and status, see [SITREP.md](SITREP.md).
> This file focuses on planned future work.

## Immediate — Analyze Results

1. **Investigate nethermind-etc 230 failures** — systematic issues in several categories:
   - [ ] Chain reorg/uncle handling (~60 failures) — all bcMultiChainTest and bcTotalDifficulty tests fail
   - [ ] Heavy precompile tests (10) — `static_Call50000_sha256` block import failures
   - [ ] Istanbul/Berlin-specific failures (~50) — randomStatetest variants, InvalidBlocks, storage tests
   - [ ] RPC_API_Test (9) / ForkStressTest (7) — infrastructure/timeout issues
   - [ ] Precompile revert (12) — `RevertPrecompiledTouch` d0/d3 variants
   - [ ] Final crashes (5) — wallet* tests "terminated unexpectedly"
2. **Investigate besu-etc 4 genuine failures** (beyond DAO fork):
   - [ ] `RevertOpcode_d0g1v0_Istanbul` — NEW
   - [ ] `eip2929OOG_d3g0v0_Istanbul` — EIP-2929 gas cost issue
   - [ ] `gasCostMemSeg_d41g0v0_Berlin` — gas cost calculation
   - [ ] `codesizeOOGInvalidSize_d0g0v0_EIP158` — known from legacy
3. **Create EIP-7610 exclusion list** for core-geth — 61 failures are all CREATE2 collision tests not applicable to ETC

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
