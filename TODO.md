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

## ECIP-1121 Implementation (Complete)

All 12 ECIP-1121 EIPs implemented on core-geth. On `claude/ecip-1121` branches in core-geth and hive submodules.

**Activation blocks:** Classic mainnet: 21,000,000 | Mordor testnet: 10,500,000

### Implemented EIPs (12/12):
- [x] EIP-1153: Transient Storage (TSTORE/TLOAD) — existed in core-geth, wired
- [x] EIP-5656: MCOPY instruction — existed in core-geth, wired
- [x] EIP-6780: SELFDESTRUCT restriction — existed in core-geth, wired
- [x] EIP-2537: BLS12-381 precompile — existed in core-geth, activation wired
- [x] EIP-7883: MODEXP gas cost increase (200→1000) — new implementation
- [x] EIP-7825: Transaction gas limit cap (2^24) — new implementation
- [x] EIP-7623: Calldata cost floor — new implementation
- [x] EIP-7934: 10 MiB RLP block size limit — new implementation
- [x] EIP-2935: Historical block hashes in state contract — new implementation
- [x] EIP-7910: eth_config JSON-RPC method — new implementation
- [x] EIP-7702: Set EOA account code (delegation) — new implementation
- [x] EIP-7951: secp256r1 ECDSA precompile — new implementation

### Deferred:
- EIP-7935: Set default gas limit to 60 million — deferred per community decision

### NOT included (PoS-specific): EIP-4844, EIP-4788, EIP-7516

### Remaining work
- [ ] Run Hive consensus-etc/ETC_ECIP1121 tests to validate
- [ ] Run full consensus-etc suite to check for regressions
- [ ] Review EIP-7702 authorization processing in state transition (currently handles delegation resolution but not auth list processing)
- [x] Push branches to remote forks

### Reference docs
- `ECIP1121_IMPLEMENTATION_PLAN.md` — detailed implementation spec
- [ECIP-1121 spec](https://ecips.ethereumclassic.org/ECIPs/ecip-1121)

---

## Future: ECIP-1120 and Beyond

See [ECIP-1120](https://ecips.ethereumclassic.org/ECIPs/ecip-1120).

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
