# Hive Test Analysis for Ethereum Classic

This document analyzes all Hive integration tests for their applicability to Ethereum Classic (ETC) testing with core-geth.

## Executive Summary

Hive contains **5 simulator categories** with **~15 distinct test suites**. The framework is heavily focused on **post-merge Ethereum** (Proof of Stake), while ETC remains **pre-merge** (Proof of Work). This creates a fundamental compatibility gap.

### Quick Reference

| Category | ETC Applicable | Not Applicable | Notes |
|----------|---------------|----------------|-------|
| smoke/ | 3/3 | 0/3 | ✅ All basic tests work |
| devp2p/ | 1/2 | 1/2 | ✅ discv4 works, eth needs Engine API |
| ethereum/consensus | Partial | Partial | ⚠️ Legacy tests fail due to post-merge config |
| ethereum/rpc-compat | Partial | Partial | ⚠️ 33/200 pass, most failures expected |
| ethereum/engine | 0/all | All | Post-merge only |
| ethereum/sync | Maybe | Maybe | Needs investigation |
| eth2/* | 0/all | All | Beacon chain - not applicable |

---

## Test Execution Results (2026-01-27)

### Phase 1: Baseline Validation

| Test | Result | Status |
|------|--------|--------|
| smoke/genesis | **6/9** (6 core + 3 Cancun failures) | ✅ Core tests pass |
| smoke/network | **2/2** | ✅ PASS |
| devp2p/discv4 | **16/16** | ✅ PASS |
| ethereum/rpc-compat | **33/200** | ⚠️ Expected failures |

### Key Findings

#### 1. Core-geth Client Definition Issues

The `hive/clients/core-geth/` client definition has some issues:
- **Unknown flag**: `-nocompaction` is not recognized by core-geth
- **Post-merge mode**: Chain configs with TTD trigger "sync via beacon client" mode

#### 2. Consensus Tests Issue

Legacy/pre-merge consensus tests (Homestead, Byzantium, etc.) **fail** because:
- Hive sets `HIVE_TERMINAL_TOTAL_DIFFICULTY` in chain config
- Core-geth sees TTD and enters post-merge beacon sync mode
- Client waits for Engine API calls instead of processing PoW blocks

**Root Cause**: The consensus test harness always includes merge configuration even for pre-merge fork tests.

#### 3. RPC Compatibility Breakdown

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

#### Critical Issue: Legacy Tests Fail

**Status:** Legacy consensus tests (Homestead, Byzantium, Constantinople, etc.) **fail** even though they are pre-merge tests.

**Root Cause:** The consensus test harness configures chains with `HIVE_TERMINAL_TOTAL_DIFFICULTY`, which causes core-geth to enter post-merge beacon sync mode. The client log shows:

```
Chain ID:  1 (mainnet)
Consensus: Beacon (proof-of-stake), merged from Ethash (proof-of-work)
TTD: 9223372036854775807
...
Chain post-merge, sync via beacon client
```

**The client waits for Engine API (beacon) to drive chain progress instead of processing the PoW test blocks.**

**Observed Behavior:**
- Cancun tests (suite 1): Pass - client expects post-merge
- Legacy tests (suite 0): Fail - client is in beacon mode, ignores PoW blocks

#### How to Run Pre-Merge Tests

```bash
# These currently FAIL due to post-merge chain config issue:
./hive --sim ethereum/consensus --sim.limit "legacy" --client core-geth  # Fails
./hive --sim ethereum/consensus --sim.limit "Berlin" --client core-geth  # No tests match
```

**Action Required:**
1. ~~Run consensus tests with pre-merge fork filters~~ - BLOCKED
2. **Modify hive client definition or test harness** to avoid setting TTD for pre-merge tests
3. Consider forking hive simulator to support pure pre-merge testing

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

### Tests Currently Blocked ❌

| Test | Issue | Action Required |
|------|-------|-----------------|
| ethereum/consensus (legacy) | Post-merge chain config | Fix TTD handling in client or harness |
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

1. [x] Run Phase 1 baseline tests and document results - **COMPLETED**
2. [ ] ~~Run Phase 2 consensus tests per fork~~ - **BLOCKED** (post-merge config issue)
3. [ ] Investigate devp2p/eth and sync test requirements
4. [x] Categorize rpc-compat failures (expected vs bug) - **COMPLETED**
5. [ ] Define minimum required test coverage for ETC releases
6. [ ] Consider creating `simulators/etc/` for ECIP testing

### Immediate Priorities

1. **Fix consensus test compatibility** - The main blocker is that Hive sets TTD for all chains, causing core-geth to enter beacon sync mode. Options:
   - Modify `hive/clients/core-geth/` to handle pre-merge configs differently
   - Fork hive consensus simulator to support pure PoW testing
   - Investigate if hive has a pre-merge test mode

2. **Fix `-nocompaction` flag** - Remove unknown flag from client definition

3. **Investigate debug_getRaw* crash** - Method handler crashes for non-genesis blocks

4. **Test graphql and sync simulators** - Determine if they have similar post-merge issues
