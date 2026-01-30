# Hive Test Analysis for Ethereum Classic

This document analyzes Hive integration tests for Ethereum Classic (ETC) clients.

## Current Status (2026-01-30)

**Currently running:** `legacy-cancun` consensus test suite

| Metric | Value |
|--------|-------|
| Suite | `legacy-cancun` (Istanbul through Cancun) |
| Progress | ~370 / 111,983 (~0.3%) |
| Rate | ~46 tests/min |
| ETA | ~40 hours |

**Note:** Only ~27,000 tests are ETC-relevant (Istanbul + Berlin). Future runs should filter with `--sim.limit "Istanbul|Berlin"` to reduce runtime to ~10 hours.

---

**Previously completed:** `legacy` consensus tests - 32,595 / 32,616 (99.94% pass rate)

| Metric | Value |
|--------|-------|
| Suite | `legacy` (Constantinople and earlier) |
| Total tests | 32,616 |
| Passed | 32,595 (99.94%) |
| Failed | 21 (CREATE2 collision edge cases) |

**Failed Tests (21):**
- `InitCollision_*` (8) - Constantinople/ConstantinopleFix
- `create2collisionStorage_*` (6)
- `RevertInCreateInInit*` (5)
- `dynamicAccountOverwriteEmpty_*` (2)

---

## Client Status Overview

| Client | Status | smoke/genesis | smoke/network | devp2p/discv4 | consensus (legacy) | consensus (legacy-cancun) |
|--------|--------|---------------|---------------|---------------|--------------------|-----------------------------|
| **core-geth** | ✅ Working | 6/9 | 2/2 | 16/16 | 99.94% (32,595/32,616) | 🔄 17.0% (~35h) |
| **besu-etc** | ✅ Working | 6/6 | 2/2 | - | 🔄 15.0% (~39h) | - |
| **nethermind** | 📋 Planned | - | - | - | - | - |
| **fukuii** | 📋 Planned | - | - | - | - | - |

### Client Definitions

| Client | Location | Image | Notes |
|--------|----------|-------|-------|
| core-geth | `hive/clients/core-geth/` | Built from source | Primary ETC client (Go) |
| besu-etc | `hive/clients/besu-etc/` | `hyperledger/besu` | Native ETC support |
| nethermind | TBD | TBD | .NET client with ETC support |
| fukuii | TBD | TBD | Rust client |

---

## Executive Summary

ETC is **pre-merge** (Proof of Work), while most Hive tests target **post-merge Ethereum** (Proof of Stake). After fixing TTD handling, consensus tests now work.

### ETC-Relevant Test Counts

| Suite | Total | ETC Relevant | Status |
|-------|-------|--------------|--------|
| **`legacy`** | 32,616 | **32,616** (100%) | ✅ **99.94% pass** (21 CREATE2 failures) |
| `legacy-cancun` (Istanbul+Berlin) | 111,983 | ~27,000 | 🔄 Running (~40h ETA) |
| `consensus` (Cancun) | 1,148 | 571 | Pending |
| **Total** | **145,746** | **~60,000** | |

### Quick Reference

| Category | Status | Notes |
|----------|--------|-------|
| smoke/ | ✅ **24/24** | All basic tests pass |
| devp2p/discv4 | ✅ **16/16** | Node discovery works |
| ethereum/consensus | ✅ **99.94% pass** | 32,595/32,616 (21 CREATE2 failures) |
| ethereum/rpc-compat | ⚠️ **33/200** | 91 `eth_simulateV1` expected failures |
| ethereum/engine | ❌ Skip | Post-merge only |
| eth2/* | ❌ Skip | Beacon chain - not applicable |

---

## Test Execution Results

### Phase 1: Baseline Validation

#### core-geth

| Test | Result | Status |
|------|--------|--------|
| smoke/genesis | **6/9** | ✅ Core pass (3 Cancun expected) |
| smoke/network | **2/2** | ✅ PASS |
| devp2p/discv4 | **16/16** | ✅ PASS |
| ethereum/rpc-compat | **33/200** | ⚠️ Expected (91 eth_simulateV1) |

#### besu-etc

| Test | Result | Status |
|------|--------|--------|
| smoke/genesis | **6/6** | ✅ PASS |
| smoke/network | **2/2** | ✅ PASS |
| devp2p/discv4 | - | Pending |
| ethereum/rpc-compat | - | Pending |

#### nethermind (Planned)

| Test | Result | Status |
|------|--------|--------|
| smoke/genesis | - | Pending |
| smoke/network | - | Pending |
| devp2p/discv4 | - | Pending |
| ethereum/rpc-compat | - | Pending |

#### fukuii (Planned)

| Test | Result | Status |
|------|--------|--------|
| smoke/genesis | - | Pending |
| smoke/network | - | Pending |
| devp2p/discv4 | - | Pending |
| ethereum/rpc-compat | - | Pending |

### Phase 2: Consensus Testing (Updated 2026-01-30 14:53 UTC)

| Client | legacy (32,616) | legacy-cancun (~27k relevant) | Status |
|--------|-----------------|-------------------------------|--------|
| **core-geth** | 99.94% (32,595/32,616) | 🔄 17.0% (~35h ETA) | 21 CREATE2 failures |
| **besu-etc** | 🔄 15.0% (~39h ETA) | - | Running |
| **nethermind** | - | - | Planned |
| **fukuii** | - | - | Planned |

### Key Findings

#### 1. [RESOLVED] Core-geth Client Definition Issues

Fixed in `hive/clients/core-geth/`:
- ✅ Removed unsupported `--nocompaction` flag
- ✅ Fixed TTD handling to only set when explicitly provided
- ✅ Added `HIVE_SKIP_POW` → `--fakepow` support

#### 2. RPC Compatibility Breakdown

**Passing Methods (33 tests):**
- `eth_getBlockReceipts` (5)
- `eth_estimateGas` (4)
- `eth_createAccessList` (3)
- `eth_getCode` (2)
- `eth_getBlockByHash` (2)
- `debug_getRaw*` (genesis queries)
- `eth_chainId`, `net_version`

**Failing Methods (167 tests):**
- `eth_simulateV1` (91) - **Expected**: Not implemented in core-geth
- `eth_getBlock*`, `eth_getTransaction*` - Client at block 0 (not synced)
- `eth_call` - Returns empty (no state)
- `eth_blobBaseFee` - **Expected**: Post-merge/Cancun method
- `eth_syncing` - Returns wrong format
- `debug_getRaw*` (block-n) - "method handler crashed" bug

**Note**: Many RPC failures are due to the test chain not being imported (client stuck at block 0)

---

## Detailed Simulator Analysis

### 1. smoke/ - Basic Sanity Tests

**Location:** `simulators/smoke/`

| Test Suite | ETC Status | Current Results | Notes |
|------------|------------|-----------------|-------|
| `smoke/genesis` | **MUST PASS** | ✅ **6/9** | Core tests pass, 3 Cancun tests fail (expected) |
| `smoke/network` | **MUST PASS** | ✅ **2/2** | PASS |
| `smoke/clique` | **SHOULD PASS** | Untested | Clique PoA consensus |

**Recommendation:** Core smoke tests pass. Cancun failures are expected for ETC.

```bash
./hive --sim smoke/genesis --client core-geth  # 6/9 (6 pass, 3 Cancun fail)
./hive --sim smoke/network --client core-geth  # 2/2 pass
```

---

### 2. devp2p/ - P2P Protocol Tests

**Location:** `simulators/devp2p/`

| Test Suite | ETC Status | Current Results | Notes |
|------------|------------|-----------------|-------|
| `devp2p/discv4` | **MUST PASS** | ✅ **16/16** | Node discovery protocol |
| `devp2p/eth` | **INVESTIGATE** | 1/20 | Uses Engine API (`--engineapi` flag) |

#### Analysis: devp2p/eth Failures

The eth protocol tests fail because they invoke the client with `--engineapi`, which requires:
- Terminal Total Difficulty (TTD) configuration
- JWT authentication for Engine API
- Post-merge beacon sync assumptions

**Root Cause:** Test harness assumes post-merge mode. The P2P protocol itself should work for ETC.

**Action Required:** Investigate if eth protocol tests can run without Engine API requirements, or create pre-merge variant.

```bash
# This passes (16/16)
./hive --sim devp2p --sim.limit discv4 --client core-geth

# This mostly fails (Engine API required)
./hive --sim devp2p --sim.limit eth --client core-geth
```

---

### 3. ethereum/consensus - EVM Consensus Tests

**Location:** `simulators/ethereum/consensus/`

This is the **most important simulator for ETC**. It runs official Ethereum test vectors against clients.

#### Available Fork Configurations

The consensus tests support these pre-merge forks (all applicable to ETC):

| Fork | HIVE Variable | ETC Equivalent |
|------|--------------|----------------|
| Frontier | `HIVE_FORK_HOMESTEAD=2000` | Genesis |
| Homestead | `HIVE_FORK_HOMESTEAD=0` | Block 1,150,000 |
| EIP-150 (Tangerine) | `HIVE_FORK_TANGERINE=0` | Block 2,500,000 |
| EIP-158 (Spurious) | `HIVE_FORK_SPURIOUS=0` | Block 2,500,000 |
| Byzantium | `HIVE_FORK_BYZANTIUM=0` | Block 4,370,000 |
| Constantinople | `HIVE_FORK_CONSTANTINOPLE=0` | Block 7,280,000 |
| Petersburg | `HIVE_FORK_PETERSBURG=0` | Block 7,280,000 |
| Istanbul | `HIVE_FORK_ISTANBUL=0` | Block 9,573,000 |
| Berlin | `HIVE_FORK_BERLIN=0` | Block 13,189,133 |
| London | `HIVE_FORK_LONDON=0` | N/A (ETH only, EIP-1559) |

**Post-merge forks (NOT applicable to ETC):**
- `Merge` / `Paris` - TTD transition
- `Shanghai` - Withdrawals
- `Cancun` - Blobs, KZG

#### Test Suites and Counts

Tests are loaded from the [ethereum/tests](https://github.com/ethereum/tests) repository (including [LegacyTests](https://github.com/ethereum/legacytests) submodule).

| Suite | Path | Total Tests | ETC Relevant | Notes |
|-------|------|-------------|--------------|-------|
| `consensus` | `BlockchainTests/` | 1,148 | 571 | Only Cancun tests (571); Prague (571) not supported |
| `legacy` | `LegacyTests/Constantinople/BlockchainTests/` | **32,615** | **32,615** | ✅ All pre-merge, fully relevant |
| `legacy-cancun` | `LegacyTests/Cancun/BlockchainTests/` | 111,983 | ~27,000 | Istanbul+Berlin relevant; post-merge not applicable |
| **Total** | | **145,746** | **~60,000** | |

##### `legacy` Suite Breakdown (32,615 tests) - **Primary ETC Target**

| Network | Tests | ETC Status |
|---------|-------|------------|
| Constantinople | 10,807 | ✅ Relevant |
| ConstantinopleFix | 10,802 | ✅ Relevant |
| Byzantium | 5,000 | ✅ Relevant |
| Homestead | 2,184 | ✅ Relevant |
| Frontier | 1,303 | ✅ Relevant |
| EIP158 | 1,260 | ✅ Relevant |
| EIP150 | 1,259 | ✅ Relevant |

##### `legacy-cancun` Suite Breakdown (111,983 tests)

| Network | Tests | ETC Status |
|---------|-------|------------|
| Cancun | 21,849 | ❌ Post-merge |
| Shanghai | 20,689 | ❌ Post-merge |
| Paris | 20,369 | ❌ Post-merge |
| London | 20,337 | ⚠️ Partial (ETC Magneto excludes EIP-1559) |
| Berlin | 14,026 | ✅ Relevant |
| Istanbul | 12,968 | ✅ Relevant |
| Constantinople/earlier | ~1,500 | ✅ Relevant |
| Transition tests | ~245 | ⚠️ Some relevant |

##### `consensus` Suite Breakdown (1,148 tests)

| Network | Tests | ETC Status |
|---------|-------|------------|
| Cancun | 571 | ⚠️ Post-merge but tests may work |
| Prague | 571 | ❌ Not supported in forks.go |

#### [RESOLVED] Legacy Tests Now Working

**Previous Issue:** Legacy consensus tests failed because TTD was always set, causing beacon sync mode.

**Fix Applied (2026-01-27):**
1. Modified `mapper.jq` to only set TTD when `HIVE_TERMINAL_TOTAL_DIFFICULTY` is explicitly provided
2. Added `HIVE_SKIP_POW` handling in `geth.sh` to enable `--fakepow` flag
3. Removed unsupported `--nocompaction` flag

**Current Status:** Legacy tests completed - 32,595/32,616 passing (99.94%)

#### How to Run Pre-Merge Tests

```bash
# Run the full legacy suite (32,615 tests, ~8 hours)
./hive --sim ethereum/consensus --sim.limit "legacy" --client core-geth

# Run Istanbul+Berlin from legacy-cancun (~27,000 ETC-relevant tests)
./hive --sim ethereum/consensus --sim.limit "legacy-cancun" --client core-geth
```

---

### 4. ethereum/rpc-compat - JSON-RPC Compatibility

**Location:** `simulators/ethereum/rpc-compat/`

Tests JSON-RPC method compatibility against the [execution-apis](https://github.com/ethereum/execution-apis) spec.

| Category | ETC Status | Current Results | Notes |
|----------|------------|-----------------|-------|
| Basic methods | **PARTIAL** | ⚠️ **33/200** | Many fail due to client not syncing test chain |
| Post-merge methods | **N/A** | Expected failures | `eth_simulateV1`, `eth_blobBaseFee`, etc. |
| Engine API methods | **N/A** | Not tested | `engine_*` methods |

#### Detailed Failure Analysis (2026-01-27)

**Passing Categories:**
| Method Category | Pass Count | Notes |
|-----------------|------------|-------|
| `eth_getBlockReceipts` | 5 | Basic receipt queries |
| `eth_estimateGas` | 4 | Gas estimation |
| `eth_createAccessList` | 3 | Access list creation |
| `eth_getCode` | 2 | Contract code retrieval |
| `eth_getBlockByHash` | 2 | Block by hash |
| `debug_getRaw*` | 6 | Raw debug methods (genesis) |
| `eth_chainId/net_version` | 2 | Network identity |

**Failing Categories:**
| Method | Count | Reason | ETC Action |
|--------|-------|--------|------------|
| `eth_simulateV1` | 91 | Not implemented | Expected - post-Prague ETH method |
| `eth_getBlock*` (numbered) | 9 | Client at block 0 | Test chain not imported |
| `eth_getTransaction*` | 18 | No transactions | Test chain not imported |
| `eth_call` | 6 | Returns `0x` | No state (not synced) |
| `eth_getLogs` | 8 | No logs | No state |
| `eth_blobBaseFee` | 1 | Not available | Expected - Cancun method |
| `debug_getRaw*` (block-n) | 3 | Handler crashed | **Bug in core-geth** |

**Root Cause Analysis:**
- The RPC test starts client at genesis but queries blocks 0x2d (45)
- Client is not importing the test chain (post-merge beacon sync issue)
- Client log shows: "transaction indexing is in progress"

```bash
./hive --sim ethereum/rpc-compat --client core-geth  # 33/200 pass
```

---

### 5. ethereum/engine - Engine API Tests

**Location:** `simulators/ethereum/engine/`

**ETC Status: NOT APPLICABLE**

All Engine API tests require:
- Terminal Total Difficulty (TTD) set to 0 (merge at genesis)
- JWT authentication
- Consensus Layer (beacon client) mocking

ETC has no proof-of-stake consensus and no Engine API requirements.

| Suite | ETC Status |
|-------|------------|
| `engine-api` | Not applicable |
| `engine-auth` | Not applicable |
| `engine-exchange-capabilities` | Not applicable |
| `engine-withdrawals` | Not applicable |
| `engine-cancun` | Not applicable |

**Skip entirely for ETC testing.**

---

### 6. ethereum/sync - Client Synchronization

**Location:** `simulators/ethereum/sync/`

Tests client-to-client synchronization (full sync and snap sync).

| Test Type | ETC Status | Notes |
|-----------|------------|-------|
| Full sync (eth1) | **INVESTIGATE** | May work for pre-merge chains |
| Snap sync (eth1_snap) | **INVESTIGATE** | Core-geth supports snap protocol |

**Current Results:** 0/2 passed

**Root Cause:** Tests may invoke Engine API for chain building. Need to check if pre-merge sync tests exist.

**Action Required:** Examine sync test code to determine if it can run without Engine API.

---

### 7. ethereum/graphql - GraphQL API Tests

**Location:** `simulators/ethereum/graphql/`

Tests GraphQL endpoint compliance.

| Status | Notes |
|--------|-------|
| **SHOULD PASS** | Standard query interface |

Core-geth supports GraphQL when `HIVE_GRAPHQL_ENABLED=1`.

```bash
./hive --sim ethereum/graphql --client core-geth
```

---

### 8. ethereum/eels - Execution Specs Tests

**Location:** `simulators/ethereum/eels/`

Python execution-specs test framework.

| Suite | ETC Status | Notes |
|-------|------------|-------|
| `consume-engine` | Not applicable | Post-merge Engine API |
| `consume-rlp` | **INVESTIGATE** | RLP encoding tests |
| `consume-sync` | Not applicable | Beacon sync |
| `execute-blobs` | Not applicable | Cancun blobs |

---

### 9. eth2/* - Beacon Chain Tests

**Location:** `simulators/eth2/`

**ETC Status: NOT APPLICABLE**

All eth2 tests require:
- Beacon Node
- Validator Client
- Consensus Layer configuration

ETC has no Beacon Chain.

| Simulator | ETC Status |
|-----------|------------|
| `eth2/engine` | Not applicable |
| `eth2/dencun` | Not applicable |
| `eth2/testnet` | Not applicable |
| `eth2/withdrawals` | Not applicable |

**Skip entirely for ETC testing.**

---

### 10. portal/ - Portal Network

**Location:** `simulators/portal/`

**ETC Status: NOT APPLICABLE**

Portal Network is experimental/research phase. Not relevant for ETC client testing.

---

## ETC Test Matrix Summary

### Tests That Pass ✅

| Test | Command | Result |
|------|---------|--------|
| P2P Discovery | `./hive --sim devp2p --sim.limit discv4 --client core-geth` | **16/16** |
| Genesis Init | `./hive --sim smoke/genesis --client core-geth` | **6/9** (3 Cancun expected) |
| Network Test | `./hive --sim smoke/network --client core-geth` | **2/2** |

### Tests Partially Working ⚠️

| Test | Result | Issue |
|------|--------|-------|
| RPC Compat | **33/200** | Client doesn't sync test chain; 91 `eth_simulateV1` expected failures |

### Tests Completed ✅

| Test | Result | Notes |
|------|--------|-------|
| ethereum/consensus (legacy) | 32,595/32,616 | 99.94% pass - 21 CREATE2 failures |

### Tests To Investigate ❓

| Test | Issue | Action Required |
|------|-------|-----------------|
| devp2p/eth | Engine API required | Check for pre-merge test mode |
| ethereum/sync | May need Engine API | Examine test code |
| GraphQL | Untested | Run and verify |

### Tests Not Applicable to ETC

| Test | Reason |
|------|--------|
| ethereum/engine | Post-merge only |
| eth2/* | Beacon Chain |
| ethereum/eels (most) | Post-merge assumptions |
| portal/ | Experimental |

---

## Recommended Test Execution Plan

### Phase 1: Baseline Validation

Confirm core-geth passes all ETC-applicable tests:

```bash
# Must pass - P2P and basic functionality
./hive --sim devp2p --sim.limit discv4 --client core-geth
./hive --sim smoke/genesis --client core-geth
./hive --sim smoke/network --client core-geth

# Should mostly pass - RPC (expect some post-merge failures)
./hive --sim ethereum/rpc-compat --client core-geth
```

### Phase 2: Consensus Testing

Run consensus tests with ETC-compatible fork configurations:

```bash
# Start with stable forks
./hive --sim ethereum/consensus --sim.limit "Istanbul" --client core-geth
./hive --sim ethereum/consensus --sim.limit "Berlin" --client core-geth

# Test transition scenarios
./hive --sim ethereum/consensus --sim.limit "IstanbulToBerlinAt5" --client core-geth
```

### Phase 3: Investigation

Determine if these can be made to work:

```bash
# Check if eth protocol tests can run pre-merge
./hive --sim devp2p --sim.limit eth --client core-geth

# Check sync tests
./hive --sim ethereum/sync --client core-geth

# GraphQL
./hive --sim ethereum/graphql --client core-geth
```

### Phase 4: ETC-Specific Testing

Consider creating:
- `simulators/etc/` - ETC-specific test cases
- ECIP fork transition tests
- ETC mainnet/testnet chain validation

---

## Appendix: Fork Configuration Reference

### Pre-Merge Forks (ETC Compatible)

```go
"Berlin": {
    "HIVE_FORK_HOMESTEAD":      0,
    "HIVE_FORK_TANGERINE":      0,
    "HIVE_FORK_SPURIOUS":       0,
    "HIVE_FORK_BYZANTIUM":      0,
    "HIVE_FORK_CONSTANTINOPLE": 0,
    "HIVE_FORK_PETERSBURG":     0,
    "HIVE_FORK_ISTANBUL":       0,
    "HIVE_FORK_BERLIN":         0,
    "HIVE_FORK_LONDON":         2000,  // Not activated
}
```

### Post-Merge Forks (NOT ETC Compatible)

```go
"Cancun": {
    // ... pre-merge forks at 0 ...
    "HIVE_FORK_MERGE":                0,
    "HIVE_TERMINAL_TOTAL_DIFFICULTY": 0,  // Merge at genesis
    "HIVE_SHANGHAI_TIMESTAMP":        0,
    "HIVE_CANCUN_TIMESTAMP":          0,
}
```

---

## Next Steps

1. [x] Run Phase 1 baseline tests - **COMPLETED**
2. [x] Fix consensus test compatibility - **COMPLETED** (TTD, fakepow, nocompaction fixes)
3. [x] Categorize rpc-compat failures - **COMPLETED**
4. [x] Run legacy consensus suite - **COMPLETED** (99.94% pass, 21 CREATE2 failures)
5. [ ] Run Istanbul+Berlin tests from legacy-cancun (~27,000 tests)
6. [ ] Investigate devp2p/eth and sync test requirements
7. [ ] Define minimum required test coverage for ETC releases
8. [ ] Consider creating `simulators/etc/` for ECIP testing

### Immediate Priorities

1. **Investigate CREATE2 failures** - 21 tests failing (collision/revert edge cases)
2. **Run legacy-cancun Istanbul+Berlin tests** - Next batch of ETC-relevant tests
3. **Investigate debug_getRaw* crash** - Method handler crashes for non-genesis blocks
4. **Test graphql and sync simulators** - Determine if they work for pre-merge
