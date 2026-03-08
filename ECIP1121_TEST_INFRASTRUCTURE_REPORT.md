# ECIP-1121 Test Infrastructure Research Report

## Executive Summary

ECIP-1121 adds three Ethereum Cancun EIPs to Ethereum Classic:
- **EIP-1153**: TSTORE/TLOAD (transient storage opcodes)
- **EIP-5656**: MCOPY (memory copying instruction)
- **EIP-6780**: SELFDESTRUCT gas behavior changes

Testing infrastructure exists at multiple levels with reusable components. **Upstream Cancun test fixtures are already in core-geth** and can be directly reused with block-based fork activation. Hive integration requires adding ECIP-1121-specific fork definitions to the consensus-etc suite.

---

## 1. Existing Cancun Test Fixtures

### Location & Scope

Core-geth already has 38 upstream Cancun tests (Pyspecs):
```
/home/dob/etc-nexus/core-geth/tests/testdata/BlockchainTests/Pyspecs/cancun/
├── eip1153_tstore/          (TSTORE/TLOAD tests)
├── eip5656_mcopy/           (MCOPY tests)
├── eip6780_selfdestruct/     (SELFDESTRUCT behavior)
├── eip4788_beacon_root/      (not needed for ETC)
└── eip7516_blobgasfee/       (not needed for ETC)
```

**Test Coverage by EIP:**

| EIP | Test Count | Examples |
|-----|-----------|----------|
| EIP-1153 | ~8 tests | gas_usage, tload_after_sstore, subcall, reentrant_call |
| EIP-5656 | ~5 tests | valid_mcopy_operations, memory_expansion, no_memory_corruption |
| EIP-6780 | ~5 tests | selfdestruct behavior changes |

### Test Structure

Each test is a JSON file with:
- **Network**: Fork name (e.g., "Cancun")
- **Genesis block**: Account allocations, code, storage
- **Blocks**: Test transactions with expected state transitions
- **Expected output**: Block hash, state root, gas used

Example: `/home/dob/etc-nexus/core-geth/tests/testdata/BlockchainTests/Pyspecs/cancun/eip1153_tstore/gas_usage.json`
- Uses `"Network": "Cancun"` (can be modified for ECIP-1121)
- Contains multiple test cases per file
- Tests marked with `fork=Cancun` in test names

---

## 2. Core-geth Fork Configuration System

### Chain Configuration Structure

**File**: `/home/dob/etc-nexus/core-geth/params/coregeth.json.d/`

Example: `etc_magneto_test.json` shows the pattern for ETC forks:

```json
{
  "config": {
    "chainId": 61,                    // ETC mainnet
    "eip2FBlock": 0,                   // EIP activation blocks
    "eip1153FBlock": <BLOCK_NUMBER>,   // Will use this
    "eip5656FBlock": <BLOCK_NUMBER>,   // Will use this
    "eip6780FBlock": <BLOCK_NUMBER>,   // Will use this
    "ethash": {}                       // PoW consensus
  }
  // ... genesis, alloc, etc
}
```

### EIP Block Configuration Fields

**File**: `/home/dob/etc-nexus/core-geth/params/types/ctypes/configurator_iface.go`

Core-geth has interface definitions for:
- `GetEIP1153TransitionTime() *uint64` (block-based)
- `GetEIP5656TransitionTime() *uint64` (block-based)
- `GetEIP6780TransitionTime() *uint64` (block-based)

**Key Insight**: Core-geth supports **block-based activation** (`eip*FBlock`) for these EIPs via the `*F` suffix convention.

### Test Fork Definitions

**File**: `/home/dob/etc-nexus/core-geth/tests/init.go` (lines 41-56)

Maps fork names to chainspec files:
```go
var MapForkNameChainspecFileState = map[string]string{
    "ETC_Atlantis":   "etc_atlantis_test.json",
    "ETC_Agharta":    "etc_agharta_test.json",
    "ETC_Phoenix":    "etc_phoenix_test.json",
    "ETC_Magneto":    "etc_magneto_test.json",
    // ADD ECIP-1121 fork here
}
```

**Current ETC Forks**: Frontier through Berlin/Magneto only. No Spiral, London, or post-Berlin forks defined.

---

## 3. Hive Consensus-ETC Suite

### Suite Definition

**File**: `/home/dob/etc-nexus/hive/simulators/ethereum/consensus/main.go` (lines 23-29)

```go
suites := []hivesim.Suite{
    makeSuite("consensus", "BlockchainTests"),
    makeSuite("legacy", "LegacyTests/Constantinople/BlockchainTests"),
    makeSuite("legacy-cancun", "LegacyTests/Cancun/BlockchainTests"),
    makeETCSuite("consensus-etc"),  // ETC-specific suite
}
```

### ETC Suite Architecture

**File**: `/home/dob/etc-nexus/hive/simulators/ethereum/consensus/main.go` (lines 67-160)

- **Purpose**: Run tests only against ETC clients (those with `"etc"` role in hive.yaml)
- **Test Sources**: Loads from multiple directories:
  - `BlockchainTests/`
  - `LegacyTests/Constantinople/BlockchainTests/`
  - `LegacyTests/Cancun/BlockchainTests/`
- **Fork Filtering**: Only runs tests for forks defined in `etcEnvForks` map
- **Env var Setting**: Automatically maps fork names to `HIVE_FORK_*` environment variables

### ETC Fork Env Var Mapping

**File**: `/home/dob/etc-nexus/hive/simulators/ethereum/consensus/etc_forks.go` (lines 3-202)

Maps fork names to HIVE environment variables:
```go
var etcEnvForks = map[string]map[string]int{
    "Berlin": {
        "HIVE_FORK_HOMESTEAD":      0,
        "HIVE_FORK_TANGERINE":      0,
        "HIVE_FORK_SPURIOUS":       0,
        "HIVE_FORK_BYZANTIUM":      0,
        "HIVE_FORK_CONSTANTINOPLE": 0,
        "HIVE_FORK_PETERSBURG":     0,
        "HIVE_FORK_ISTANBUL":       0,
        "HIVE_FORK_BERLIN":         0,
        "HIVE_FORK_LONDON":         2000,  // disabled for ETC
    },
    // ... ETC-specific forks
}
```

**Current Coverage**: Frontier, Homestead, EIP150, EIP158, Byzantium, Constantinople, ConstantinopleFix, Istanbul, Berlin only.

---

## 4. Client-Side Hive Configuration

### Mapper.jq (Genesis Configuration)

**File**: `/home/dob/etc-nexus/hive/clients/core-geth/mapper.jq`

Maps environment variables to genesis JSON config:
```jq
"config": {
    "chainId": env.HIVE_CHAIN_ID|to_int,
    "eip150Block": env.HIVE_FORK_TANGERINE|to_int,
    "eip155Block": env.HIVE_FORK_SPURIOUS|to_int,
    "eip158Block": env.HIVE_FORK_SPURIOUS|to_int,
    "byzantiumBlock": env.HIVE_FORK_BYZANTIUM|to_int,
    // ... existing forks
    "cancunTime": env.HIVE_CANCUN_TIMESTAMP|to_int,
    "pragueTime": env.HIVE_PRAGUE_TIMESTAMP|to_int,
}
```

**Current State**: Has support for Cancun timestamp-based forks (for post-Merge). Does NOT have block-based EIP fields yet.

**Needed for ECIP-1121**:
```jq
"eip1153FBlock": env.HIVE_FORK_EIP1153|to_int,
"eip5656FBlock": env.HIVE_FORK_EIP5656|to_int,
"eip6780FBlock": env.HIVE_FORK_EIP6780|to_int,
```

### Startup Script (geth.sh)

**File**: `/home/dob/etc-nexus/hive/clients/core-geth/geth.sh` (lines 1-171)

Handles environment variables and block imports:
- Configures fork blocks via genesis JSON (via mapper.jq)
- Handles `HIVE_SKIP_POW` for NoProof seal engine tests
- Imports genesis and blocks
- Configures RPC/WebSocket

**No changes needed** to geth.sh itself; mapper.jq changes will flow through.

---

## 5. Core-geth Go Unit Tests

### Test Organization

**Files**:
- `/home/dob/etc-nexus/core-geth/tests/state_test.go` (100+ lines): State transition tests
- `/home/dob/etc-nexus/core-geth/core/vm/*_test.go`: EVM instruction tests
- `/home/dob/etc-nexus/core-geth/core/state/statedb_test.go`: State DB tests

### Test Execution

State tests are run via:
```bash
cd /home/dob/etc-nexus/core-geth/tests
go test -run TestState -v
```

Example from `state_test.go:99`:
```go
func TestState(t *testing.T) {
    t.Parallel()
    // Loads fixtures from testdata/
    // Runs state transition tests against configured forks
}
```

### Available Test Forks

From `/home/dob/etc-nexus/core-geth/tests/init.go:32`:
- Frontier, Homestead, EIP150, EIP158, Byzantium, Constantinople, ConstantinopleFix
- Istanbul, Berlin
- ETC_Atlantis, ETC_Agharta, ETC_Phoenix, ETC_Magneto
- Plus transition forks (e.g., "ByzantiumToConstantinopleAt5")

### How Fork Filtering Works

**File**: `/home/dob/etc-nexus/core-geth/tests/init.go:114-177`

Tests can be filtered by environment variable `CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY`:
- When set, loads fork configs from chainspec JSON files in `coregeth.json.d/`
- Only loads configs where corresponding JSON file exists
- Falls back to hardcoded Go configs otherwise

**For ECIP-1121**: Create `etc_ecip1121_test.json` in `coregeth.json.d/` and tests will automatically discover it.

---

## 6. Test Data Flow & Architecture

```
┌─────────────────────────────────────────────────────────┐
│  ethereum/tests Repository (upstream)                   │
│  - BlockchainTests/                                     │
│  - LegacyTests/Cancun/BlockchainTests/                  │
│  - Pyspecs/cancun/eip*/ (38 test files)                │
└────────────────────────┬────────────────────────────────┘
                         │ (git submodule)
┌────────────────────────▼────────────────────────────────┐
│  core-geth/tests/testdata/                              │
│  └── BlockchainTests/Pyspecs/cancun/                    │
│      ├── eip1153_tstore/  (8 tests)                     │
│      ├── eip5656_mcopy/   (5 tests)                     │
│      └── eip6780_selfdestruct/ (5 tests)                │
└────────────────────────┬────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
  ┌──────────────┐  ┌────────────┐  ┌──────────────┐
  │ go test      │  │ Hive       │  │ Hive         │
  │ (localhost)  │  │ consensus  │  │ consensus-etc│
  │              │  │ (all clients)   (ETC only)   │
  └──────────────┘  └────────────┘  └──────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                         ▼
            ┌──────────────────────┐
            │  Test Results        │
            │  Pass/Fail reports   │
            └──────────────────────┘
```

---

## 7. Test Reuse Strategy for ECIP-1121

### Direct Reuse (No Fixture Changes)

**Upstream Cancun tests CAN be reused directly** with these adaptations:

1. **Map "Cancun" fork name to ECIP-1121 fork**
   - Hive tests use fork name in test metadata (`"Network": "Cancun"`)
   - Add ECIP-1121 to `etcEnvForks` map in Hive
   - Tests will automatically pass through with block-based activation

2. **Block-based vs Timestamp-based**
   - Upstream tests marked `fork=Cancun` expect timestamp-based activation (ETC is PoW, uses blocks)
   - Solution: Core-geth already supports `eip*FBlock` fields
   - Mapper.jq just needs new environment variable mappings:
     ```jq
     "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
     "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
     "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int,
     ```

3. **Chain ID**
   - Tests use `chainId: 1` (Ethereum)
   - ETC consensus suite sets `"HIVE_CHAIN_ID": "1"` anyway (lines 312-314 of main.go)
   - No changes needed

### Test Categorization

| Test Type | Location | How to Run | Reusable? |
|-----------|----------|-----------|-----------|
| Upstream Cancun fixtures | `/core-geth/tests/testdata/BlockchainTests/Pyspecs/cancun/` | `go test` or Hive | YES (with fork naming) |
| Consensus-etc suite | `/hive/simulators/ethereum/consensus/` | `/hive-run` | YES (add fork definition) |
| State transition tests | Go test framework | `go test -run TestState` | YES (fork registration) |
| EVM instruction tests | `/core-geth/core/vm/*_test.go` | `go test ./core/vm` | PARTIAL (may need granular tests) |

---

## 8. Step-by-Step Implementation Plan

### Phase 1: Core-geth Fork Definition (Prep)

**Task 1: Create ECIP-1121 fork config**
- Create `/home/dob/etc-nexus/core-geth/params/coregeth.json.d/etc_ecip1121_test.json`
- Based on `etc_magneto_test.json` as template
- Set:
  - `chainId: 61`
  - `eip1153FBlock: 0` (or activation block)
  - `eip5656FBlock: 0`
  - `eip6780FBlock: 0`
  - All previous forks at block 0 (backward compatibility)

**Task 2: Register fork in tests**
- Add entry to `MapForkNameChainspecFileState` in `/core-geth/tests/init.go`:
  ```go
  "ETC_ECIP1121": "etc_ecip1121_test.json",
  ```

### Phase 2: Hive Fork Definition (Mapper & Suite)

**Task 3: Update mapper.jq**
- Add three new config fields to `/hive/clients/core-geth/mapper.jq`:
  ```jq
  "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
  "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
  "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int,
  ```

**Task 4: Add ECIP-1121 to consensus-etc suite**
- Add to `etcEnvForks` in `/hive/simulators/ethereum/consensus/etc_forks.go`:
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
      "HIVE_FORK_LONDON":         2000,       // disabled for ETC
      "HIVE_FORK_ECIP1121_EIP1153": 0,        // NEW
      "HIVE_FORK_ECIP1121_EIP5656": 0,        // NEW
      "HIVE_FORK_ECIP1121_EIP6780": 0,        // NEW
  },
  ```

### Phase 3: Test Reuse & Fixture Adaption (Parallel)

**Task 5: Copy/reference Cancun test fixtures**
- Tests are already in `/core-geth/tests/testdata/BlockchainTests/Pyspecs/cancun/`
- No copying needed; direct reuse via fork registration
- Hive will find them automatically through `etcTestDirectories`

**Task 6: Create adapter for Cancun→ECIP-1121 mapping**
- Implement in Hive or core-geth tests:
  - Map `"Network": "Cancun"` → `"ETC_ECIP1121"`
  - OR create new test variant files with updated network name
  - Recommendation: Use simple file copy + sed for network field update

### Phase 4: Unit Tests & Validation

**Task 7: Add granular unit tests**
- Create `/core-geth/core/vm/ecip1121_test.go` with:
  - TSTORE/TLOAD opcode behavior
  - MCOPY memory operations
  - SELFDESTRUCT restrictions
- Tests for state machine compatibility

**Task 8: Validate test execution**
```bash
# Unit tests (localhost)
cd /core-geth/tests
go test -run TestState -v

# Full Hive consensus-etc suite
cd /hive
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth --sim.parallelism 4
```

### Phase 5: Integration & Cleanup

**Task 9: Verify all three EIPs work together**
- Create multi-EIP test cases
- Ensure no conflicts (SELFDESTRUCT + MCOPY, TSTORE + MCOPY, etc.)

**Task 10: Document test procedures**
- Update README with test running instructions
- Add to CLAUDE.md for future reference

---

## 9. Running Tests During Development

### Fastest Path: Unit Tests First

```bash
# Test fork registration (no block import)
cd /home/dob/etc-nexus/core-geth/tests
CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY=1 \
  go test -run TestState -v -count=1 2>&1 | grep ECIP1121

# Test EVM instruction behavior
cd /home/dob/etc-nexus/core-geth/core/vm
go test -run "TestEIP1153\|TestEIP5656\|TestEIP6780" -v -count=1
```

### Medium: Consensus Tests (Hive)

```bash
# Build client
cd /home/dob/etc-nexus/hive
docker build -t coregeth:ecip1121 clients/core-geth/

# Run consensus-etc suite
./hive --sim ethereum/consensus \
  --sim.limit "consensus-etc/ETC_ECIP1121" \
  --client core-geth \
  --sim.parallelism 4
```

### Full: End-to-End Hive Suite

```bash
# All ETC forks (30+ minutes)
./hive --sim ethereum/consensus \
  --sim.limit consensus-etc \
  --client core-geth \
  --sim.parallelism 4
```

---

## 10. Test Milestones & Success Criteria

| Milestone | Success Criteria | Validation Method |
|-----------|-----------------|-------------------|
| **Phase 1: Config** | Fork registered in core-geth | `go test -run TestState` passes for ETC_ECIP1121 |
| **Phase 2: Hive Mapper** | Env vars map to genesis.json | Manual JSON inspection in Hive logs |
| **Phase 3: Suite Integration** | Tests run against ECIP-1121 fork | `./hive --sim.limit consensus-etc/ETC_ECIP1121` completes |
| **Phase 4: Unit Tests** | All three EIP opcodes pass | `go test ./core/vm` passes |
| **Phase 5: Full Integration** | All ETC forks (Berlin + ECIP-1121) pass | `./hive --sim.limit consensus-etc` passes all tests |

---

## 11. Known Constraints & Gotchas

### Block-based vs Timestamp-based
- **ETC uses block numbers** (PoW-based)
- **Cancun (Ethereum) uses timestamps** (PoS-based)
- Solution: Core-geth supports both; map appropriately in configs
- Hive mapper.jq needs both `HIVE_FORK_ECIP1121_EIP*` and time-based variants

### Test Fork Name Mismatch
- Upstream tests marked `fork=Cancun` (capitalized)
- ETC forks named `ETC_ECIP1121` (convention)
- Solution: Add fork alias or mapping in Hive suite

### Chain ID
- Upstream tests use `chainId: 1` (Ethereum mainnet)
- ETC mainnet is `61`
- ETC consensus suite already overrides to `1` for test compatibility
- No changes needed

### ParentBeaconBlockRoot
- EIP-4788 (Beacon root in EVM) is NOT part of ECIP-1121
- Upstream Cancun tests may reference it (e.g., test block headers)
- Solution: Filter out EIP-4788 tests or handle gracefully
- Core-geth EVM should ignore unknown block header fields

---

## 12. Files to Modify

| File | Changes |
|------|---------|
| `/core-geth/params/coregeth.json.d/etc_ecip1121_test.json` | CREATE |
| `/core-geth/tests/init.go` | ADD fork registration (2 lines) |
| `/hive/clients/core-geth/mapper.jq` | ADD 3 new jq fields |
| `/hive/simulators/ethereum/consensus/etc_forks.go` | ADD fork entry to etcEnvForks |
| `/core-geth/core/vm/ecip1121_test.go` | CREATE (unit tests) |
| `ECIP1121_TEST_INFRASTRUCTURE.md` | CREATE (documentation) |

---

## 13. Detailed File Locations

**Core-geth**:
```
/home/dob/etc-nexus/core-geth/
├── params/
│   ├── coregeth.json.d/      # Fork chainspecs
│   └── types/ctypes/         # Fork config interfaces (already has EIP1153/5656/6780)
├── tests/
│   ├── init.go               # Fork registration for state tests
│   ├── state_test.go         # State test runner
│   └── testdata/BlockchainTests/Pyspecs/cancun/  # Test fixtures (38 files)
└── core/vm/
    ├── instructions_test.go  # EVM instruction tests pattern
    └── runtime/runtime_test.go # Runtime tests pattern
```

**Hive**:
```
/home/dob/etc-nexus/hive/
├── simulators/ethereum/consensus/
│   ├── main.go               # Suite definitions
│   ├── etc_forks.go          # ETC fork env var mappings
│   └── forks.go              # ETH fork env var mappings
└── clients/core-geth/
    ├── mapper.jq             # Genesis JSON config mapper
    ├── geth.sh               # Client startup script
    └── hive.yaml             # Client metadata (has "etc" role)
```

---

## 14. Resources & References

**ECIP-1121**: https://github.com/ethereumclassic/ECIPs/blob/master/_specs/ecip-1121.md

**Test Data**:
- Upstream: https://github.com/ethereum/tests/tree/develop/BlockchainTests/Pyspecs/cancun
- Local copy: `/home/dob/etc-nexus/core-geth/tests/testdata/BlockchainTests/Pyspecs/cancun/`

**Implementation References**:
- EIP-1153: https://eips.ethereum.org/EIPS/eip-1153
- EIP-5656: https://eips.ethereum.org/EIPS/eip-5656
- EIP-6780: https://eips.ethereum.org/EIPS/eip-6780

**Core-geth Docs**:
- Fork configuration: `/core-geth/params/coregeth.json.d/` (examples)
- Test framework: `/core-geth/tests/` (state test runner)

**Hive Docs**:
- Consensus suite: `/hive/simulators/ethereum/consensus/README.md`
- Client definitions: `/hive/clients/*/hive.yaml`

---

## Summary Table

| Component | Current State | Needed for ECIP-1121 |
|-----------|---------------|----------------------|
| **Test Fixtures** | 38 Cancun tests exist | Rename/map fork; reuse as-is |
| **Core-geth Fork Config** | Magneto defined | Create etc_ecip1121_test.json |
| **Tests Fork Registry** | Berlin is latest ETC | Add "ETC_ECIP1121" entry |
| **Hive Mapper** | Supports Cancun timestamps | Add 3 block-based EIP fields |
| **ETC Fork Suite** | Berlin defined | Add ETC_ECIP1121 fork entry |
| **Unit Tests** | EVM tests exist | Create granular ECIP-1121 tests |
| **Documentation** | CLAUDE.md + README | Add this report + test guide |

**Total Changes**: ~6-7 files, mostly additions (50-100 lines total).
**Estimated Time**: Configuration (1-2 hours) + Test validation (2-3 hours).

