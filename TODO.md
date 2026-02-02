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

## Implement ETC-Specific Test Suite in Hive Fork

**Goal:** Create a streamlined way to run only ETC-compatible tests without manual `--sim.limit` filtering.

### Current Problem

Running tests against ETC clients requires haphazard filtering:
```bash
# Must manually filter to supported forks every time
./hive --client core-geth --sim ethereum/consensus \
  --sim.limit "Byzantium|Constantinople|Istanbul|Berlin"
```

Post-merge tests (Paris, Shanghai, Cancun) fail with misleading "unknown client type" errors because ETC clients don't support those forks.

### Architecture Overview

The consensus simulator (`simulators/ethereum/consensus/main.go`) defines suites:
```go
suites := []hivesim.Suite{
    makeSuite("consensus", "BlockchainTests"),
    makeSuite("legacy", "LegacyTests/Constantinople/BlockchainTests"),
    makeSuite("legacy-cancun", "LegacyTests/Cancun/BlockchainTests"),
}
```

Each suite maps to a test directory. The `--sim.limit` pattern is passed via `HIVE_TEST_PATTERN` env var and matched against suite names and test paths.

### Implementation Plan

#### Step 1: Add `etc` Role to Client Definitions (5 min)

Modify client YAML files to add an `etc` role for identification:

**`hive/clients/core-geth/hive.yaml`:**
```yaml
roles:
  - "eth1"
  - "eth1_snap"
  - "etc"  # Add this
```

**`hive/clients/besu-etc/hive.yaml`:**
```yaml
roles:
  - "eth1"
  - "etc"  # Add this
```

#### Step 2: Define ETC Fork Mappings (10 min)

Add to `simulators/ethereum/consensus/forks.go`:
```go
// ETC fork names mapped to their Ethereum equivalents
// (Test files use ETH names internally, we expose ETC names to users)
var etcForkToEthFork = map[string]string{
    // ETC Name      -> ETH Name (used in test files)
    "Frontier":      "Frontier",
    "Homestead":     "Homestead",
    "DieHard":       "EIP150",       // ETC: DieHard = ETH: Tangerine Whistle
    "GothamShield":  "EIP158",       // ETC: Gotham Shield = ETH: Spurious Dragon
    "Atlantis":      "Byzantium",
    "Agharta":       "Constantinople",
    "Phoenix":       "Istanbul",
    "Thanos":        "Berlin",       // ETC: Thanos (ECIP-1099 + Magneto)
    "Magneto":       "Berlin",
    "Mystique":      "London",
    "Spiral":        "London",       // ETC: Spiral = ETH: London (partial)
}

// Reverse map: ETH fork name -> ETC fork name (for display)
var ethForkToEtcFork = map[string]string{
    "Frontier":          "Frontier",
    "Homestead":         "Homestead",
    "EIP150":            "DieHard",
    "EIP158":            "GothamShield",
    "Byzantium":         "Atlantis",
    "Constantinople":    "Agharta",
    "ConstantinopleFix": "Agharta",
    "Istanbul":          "Phoenix",
    "Berlin":            "Magneto",
    "London":            "Spiral",
}

// Set of ETH fork names that ETC supports (for filtering test files)
var etcSupportedEthForks = map[string]bool{
    "Frontier":          true,
    "Homestead":         true,
    "EIP150":            true,
    "EIP158":            true,
    "Byzantium":         true,
    "Constantinople":    true,
    "ConstantinopleFix": true,
    "Istanbul":          true,
    "Berlin":            true,
    "London":            true,
}
```

This allows:
- **Internal filtering**: Use `etcSupportedEthForks` to filter test files (which use ETH names)
- **User-facing `--sim.limit`**: Accept ETC names like `consensus-etc/Atlantis` and translate to `Byzantium`
- **Results display**: Show ETC fork names in test results using `ethForkToEtcFork`

#### Step 3: Create ETC Suite Generator (30 min)

Add to `simulators/ethereum/consensus/main.go`:

```go
// translateETCPattern converts ETC fork names in pattern to ETH equivalents
// e.g., "Phoenix|Atlantis" -> "Istanbul|Byzantium"
func translateETCPattern(pattern string) string {
    result := pattern
    for etcName, ethName := range etcForkToEthFork {
        // Case-insensitive replacement
        re := regexp.MustCompile("(?i)" + regexp.QuoteMeta(etcName))
        result = re.ReplaceAllString(result, ethName)
    }
    return result
}

// makeETCSuite creates a suite that only includes ETC-compatible forks
func makeETCSuite(name, testDir string) hivesim.Suite {
    return hivesim.Suite{
        Name: name,
        Description: fmt.Sprintf("ETC consensus tests from %s (pre-Merge forks only)", testDir),
        Tests: []hivesim.AnyTest{
            hivesim.TestSpec{
                Name:      fmt.Sprintf("test loader (%s)", name),
                AlwaysRun: true,
                Run: func(t *hivesim.T) {
                    clientsByRole := t.Sim.ClientTypes("etc")  // Only ETC clients
                    loadTests(t, testDir, clientsByRole, etcSupportedEthForks, true)
                },
            },
        },
    }
}
```

Modify `loadTests()` to accept fork whitelist and ETC display mode:
```go
func loadTests(t *hivesim.T, testDir string, clients []*hivesim.ClientDefinition,
               forkFilter map[string]bool, useETCNames bool) {
    // ... existing code ...

    // Add filter when processing tests:
    for _, bt := range btests {
        network := bt.json.Network
        if forkFilter != nil && !forkFilter[network] {
            continue  // Skip unsupported forks
        }

        // Use ETC fork name for display if enabled
        displayNetwork := network
        if useETCNames {
            if etcName, ok := ethForkToEtcFork[network]; ok {
                displayNetwork = fmt.Sprintf("%s (%s)", etcName, network)
            }
        }
        // ... rest of processing with displayNetwork ...
    }
}
```

#### Step 4: Register ETC Suites (5 min)

Add to suite list in `main()`:
```go
suites := []hivesim.Suite{
    makeSuite("consensus", "BlockchainTests"),
    makeSuite("legacy", "LegacyTests/Constantinople/BlockchainTests"),
    makeSuite("legacy-cancun", "LegacyTests/Cancun/BlockchainTests"),
    // ETC-specific suites
    makeETCSuite("consensus-etc", "BlockchainTests"),
    makeETCSuite("legacy-etc", "LegacyTests/Constantinople/BlockchainTests"),
}
```

### Usage After Implementation

```bash
# Run all ETC-compatible consensus tests
./hive --client core-geth --sim ethereum/consensus --sim.limit "consensus-etc"

# Run legacy ETC tests
./hive --client besu-etc --sim ethereum/consensus --sim.limit "legacy-etc"

# Filter by ETC fork name (translated internally to ETH equivalent)
./hive --client core-geth --sim ethereum/consensus --sim.limit "consensus-etc/Phoenix"   # Istanbul tests
./hive --client core-geth --sim ethereum/consensus --sim.limit "consensus-etc/Atlantis"  # Byzantium tests
./hive --client core-geth --sim ethereum/consensus --sim.limit "consensus-etc/Magneto"   # Berlin tests

# Multiple ETC forks
./hive --client core-geth --sim ethereum/consensus --sim.limit "consensus-etc/Atlantis|Agharta|Phoenix"
```

Test results would display ETC fork names:
```
Tests for Phoenix (Istanbul equivalent): 1234 passed, 0 failed
Tests for Magneto (Berlin equivalent): 567 passed, 2 failed
```

### Key Files to Modify

| File | Changes |
|------|---------|
| `hive/clients/core-geth/hive.yaml` | Add `etc` role |
| `hive/clients/besu-etc/hive.yaml` | Add `etc` role |
| `hive/simulators/ethereum/consensus/forks.go` | Add `etcSupportedForks` map |
| `hive/simulators/ethereum/consensus/main.go` | Add `makeETCSuite()`, modify `loadTests()` |

### Alternative: Simpler Path-Based Filtering

If full implementation is too complex, a simpler approach using existing `--sim.limit`:

Create a shell wrapper script in the Hive fork:
```bash
#!/bin/bash
# hive/scripts/run-etc-tests.sh
FORK_FILTER="Frontier|Homestead|EIP150|EIP158|Byzantium|Constantinople|Istanbul|Berlin|London"
./hive --sim ethereum/consensus --sim.limit "$FORK_FILTER" "$@"
```

**Pros:** No Go code changes
**Cons:** Still runs against all clients, doesn't leverage role system

### Future: ETC-Divergent Forks (ECIP-1120, ECIP-1121, etc.)

Eventually ETC will have forks with no Ethereum equivalent. These require a different approach:

#### 1. Create ETC-Specific Test Directory

```
hive/simulators/ethereum/consensus/tests/
├── BlockchainTests/           # Existing ETH tests
├── LegacyTests/               # Existing ETH legacy tests
└── ETCTests/                  # NEW: ETC-specific tests
    ├── ECIP1120/              # EOF for ETC
    │   ├── validEOFCode.json
    │   └── ...
    ├── ECIP1121/              # EVM Versioning
    │   └── ...
    └── Spiral/                # ETC-specific Spiral behavior
        └── ...
```

#### 2. Define ETC-Only Forks in `forks.go`

```go
// ETC-only forks (no ETH equivalent)
var etcOnlyForks = map[string]func(genesis *core.Genesis){
    "ECIP1120": func(g *core.Genesis) {
        // EOF activation parameters for ETC
        g.Config.ECIP1120Block = big.NewInt(0)
    },
    "ECIP1121": func(g *core.Genesis) {
        // EVM versioning parameters
        g.Config.ECIP1121Block = big.NewInt(0)
    },
    "Spiral+ECIP1120": func(g *core.Genesis) {
        // Combined fork for realistic testing
        applyFork(g, "Spiral")
        g.Config.ECIP1120Block = big.NewInt(0)
    },
}

// Environment variables for ETC-only forks
var etcEnvForks = map[string]map[string]string{
    "ECIP1120": {
        "HIVE_FORK_ECIP1120": "0",
        // Include all pre-reqs
        "HIVE_FORK_BERLIN": "0",
        "HIVE_FORK_LONDON": "0",
    },
    "ECIP1121": {
        "HIVE_FORK_ECIP1121": "0",
    },
}
```

#### 3. Create ETC Test Generator

New test files would need to be created (not mapped from ETH). Options:

**Option A: Manual Test Writing**
- Write JSON test files in ethereum/tests format
- Place in `ETCTests/ECIP1120/` directory
- Most control, most effort

**Option B: Test Generation from Reference Implementation**
```go
// Generate tests from core-geth reference implementation
func generateECIP1120Tests() {
    // Run EVM with ECIP-1120 enabled
    // Capture state transitions
    // Output as blockchain test JSON
}
```

**Option C: Extend State Test Generator**
- Modify `cmd/evm/t8n_test.go` in core-geth to output Hive-compatible tests
- Run against known ECIP-1120 test vectors

#### 4. Register ETC-Only Suite

```go
suites := []hivesim.Suite{
    // ... existing suites ...
    makeETCSuite("consensus-etc", "BlockchainTests"),
    // NEW: ETC-divergent tests
    makeSuite("ecip-1120", "ETCTests/ECIP1120"),
    makeSuite("ecip-1121", "ETCTests/ECIP1121"),
    makeETCSuite("consensus-etc-full", "ETCTests"),  // All ETC-specific
}
```

#### 5. Client Support Requirements

ETC clients need to handle new HIVE env vars:
```bash
# In core-geth's geth.sh / mapper.jq
HIVE_FORK_ECIP1120  -> config.ecip1120Block
HIVE_FORK_ECIP1121  -> config.ecip1121Block
```

#### Summary: ETH-Equivalent vs ETC-Divergent

| Aspect | ETH-Equivalent Forks | ETC-Divergent Forks |
|--------|---------------------|---------------------|
| Test source | Existing `BlockchainTests/` | New `ETCTests/` directory |
| Fork config | Map to ETH env vars | New `HIVE_FORK_ECIP*` vars |
| Client support | Already works | Needs client updates |
| Example | Phoenix → Istanbul | ECIP-1120 (no equivalent) |

### Related

- [ ] Document ETC test suite usage in Hive fork README
- [ ] Consider adding `--etc-only` CLI flag to Hive binary

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
