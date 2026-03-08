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

## ECIP-1121 Implementation (Active)

Implement ECIP-1121 on core-geth: next ETC hard fork adding selected Cancun EIPs.

**EIPs included:**
- EIP-1153: Transient Storage (TSTORE/TLOAD opcodes)
- EIP-5656: MCOPY (memory copying instruction)
- EIP-6780: SELFDESTRUCT restriction (only in same transaction)

**NOT included** (PoS-specific): EIP-4844, EIP-4788, EIP-7516

**Status:** EVM implementations already exist in core-geth. Only activation wiring + tests needed.

### Research Complete ✓
- [x] Map EIP scope and implementations (Task #1)
- [x] Map test infrastructure (Task #2)
- [x] Create implementation plan (Task #3)

**Reference docs**:
- `ECIP1121_TEST_INFRASTRUCTURE_REPORT.md` — test architecture & fixtures
- `ECIP1121_IMPLEMENTATION_PLAN.md` — detailed implementation spec

### Phase 1: Core-geth Fork Definition (Task #4)

**Files to modify:**
1. Create `params/coregeth.json.d/etc_ecip1121_test.json`
   - Copy from `etc_magneto_test.json` template
   - Set `eip1153FBlock: 0`, `eip5656FBlock: 0`, `eip6780FBlock: 0`
   - Est: 15 min

2. Edit `tests/init.go:41-56` — add fork entry
   ```go
   "ETC_ECIP1121": "etc_ecip1121_test.json",
   ```
   - Est: 5 min

**Verification**:
```bash
cd /home/dob/etc-nexus/core-geth/tests
CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY=1 go test -run TestState -v 2>&1 | grep ECIP1121
```

**Note**: No changes to `config_classic.go` or `config_mordor.go` needed for testing. Those are for mainnet/testnet activation (block TBD by community).

### Phase 2: Hive/Nexus Integration (Task #7)

**Files to modify:**
1. Edit `hive/clients/core-geth/mapper.jq:58-62` — add 3 new fields
   ```jq
   "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
   "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
   "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int,
   ```
   - Est: 5 min

2. Edit `hive/simulators/ethereum/consensus/etc_forks.go:202+` — add fork entry
   ```go
   "ETC_ECIP1121": {
       "HIVE_FORK_HOMESTEAD":      0,
       "HIVE_FORK_TANGERINE":      0,
       "HIVE_FORK_SPURIOUS":       0,
       "HIVE_FORK_BYZANTIUM":      0,
       "HIVE_FORK_CONSTANTINOPLE": 0,
       "HIVE_FORK_PETERSBURG":     0,
       "HIVE_FORK_ISTANBUL":       0,
       "HIVE_FORK_BERLIN":         0,
       "HIVE_FORK_LONDON":         2000,
       "HIVE_FORK_ECIP1121_EIP1153": 0,
       "HIVE_FORK_ECIP1121_EIP5656": 0,
       "HIVE_FORK_ECIP1121_EIP6780": 0,
   },
   ```
   - Est: 10 min

### Phase 3: Unit Tests (Task #6)

**Files to create:**
1. Create `core/vm/ecip1121_test.go` (~200 lines)
   - Test TSTORE/TLOAD: gas, storage, clearing, nesting
   - Test MCOPY: basic, overlapping, memory expansion
   - Test SELFDESTRUCT: same-tx vs cross-tx restrictions
   - Pattern: Follow `instructions_test.go` and `runtime_test.go`
   - Est: 2 hours

### Phase 4: Integration Testing (Task #8)

**Run tests**:
```bash
# Unit tests
cd /home/dob/etc-nexus/core-geth/core/vm
go test -run ECIP1121 -v

# State tests with fork registration
cd /home/dob/etc-nexus/core-geth/tests
CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY=1 go test -run TestState -v

# Hive ECIP-1121 subset (10+ tests)
cd /home/dob/etc-nexus/hive
./hive --sim ethereum/consensus --sim.limit "consensus-etc/ETC_ECIP1121" --client core-geth --sim.parallelism 4

# Full ETC suite (validation)
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth --sim.parallelism 4
```

**Success criteria**:
- ✓ All ECIP-1121 unit tests pass
- ✓ Hive consensus-etc/ETC_ECIP1121 tests pass (10+ tests)
- ✓ All existing ETC forks (Frontier-Berlin) still pass
- ✓ No regressions

### Summary
- **Total files**: 6 (4 modifications, 2 creations)
- **Total changes**: ~350 lines
- **Estimated effort**: ~4 hours (mostly test execution time)
- **Risk**: Low (config + tests, EIP code already exists)

### Key Notes
- Core-geth has EIP1153/5656/6780 implementations already (synced from upstream geth)
- Only fork activation wiring needed, no EIP implementation code changes
- ETC consensus-etc suite uses `chainId: 1` for test compatibility (upstream fixture compat)
- Upstream Cancun fixtures (38 tests) automatically reusable via fork registration

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
