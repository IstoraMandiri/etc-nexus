# ETC Nexus

A workspace for developing and testing Ethereum Classic protocol changes using the Hive testing framework, with a focus on AI-assisted development.

## Project Status

**See [SITREP.md](SITREP.md)** for current test progress, what's working, and recent updates.

**See [TODO.md](TODO.md)** for planned next steps and future work.

### Test Results

Three ETC clients validated against the ethereum/tests consensus suite:

| Client | Suite | Tests | Passed | Pass Rate | Status |
|--------|-------|-------|--------|-----------|--------|
| core-geth | legacy | 32,616 | 32,595 | 99.94% | Complete |
| core-geth | legacy-cancun | 111,983 | 111,893 | 99.92% | Complete |
| besu-etc | legacy | 32,616 | 32,613 | 99.99% | Complete |
| nethermind-etc | consensus-etc (partial) | 167 | 166 | 99.4% | In progress |

### ETC Clients

| Client | Language | Fork Support | Status |
|--------|----------|-------------|--------|
| [core-geth](https://github.com/etclabscore/core-geth) | Go | Frontier — Spiral | Baseline complete |
| [besu-etc](https://github.com/hyperledger/besu) | Java | Frontier — Berlin | Baseline complete |
| [nethermind-etc](https://github.com/ETCCooperative/nethermind-etc-plugin/releases) | C# | Frontier — Berlin | Initial tests passing |

## Purpose

ETC Nexus enables AI-assisted development and testing of ECIP implementations. By submoduling both the Hive testing framework and ETC clients, an agent can:

- Implement protocol changes in client code
- Create corresponding test cases in Hive
- Run tests and iterate on fixes
- Push changes to respective repositories

Target ECIPs:
- **ECIP-1120** - Implementation and testing
- **ECIP-1121** - Implementation and testing

## Architecture

```
etc-nexus/
├── hive/                 # Fork of ethereum/hive
│   ├── clients/
│   │   ├── core-geth/    # ETC client definition
│   │   ├── besu-etc/     # ETC client definition
│   │   └── nethermind-etc/ # ETC client definition
│   └── simulators/
│       └── ethereum/consensus/  # Includes consensus-etc suite
├── core-geth/            # Fork of etclabscore/core-geth
├── nethermind-etc-plugin/ # Nethermind ETC plugin
├── .claude/
│   └── skills/           # Claude Code skills for workflow automation
└── .devcontainer/        # Docker-in-Docker dev environment
```

## Submodules

| Submodule | Upstream | Fork | Purpose |
|-----------|----------|------|---------|
| `hive/` | [ethereum/hive](https://github.com/ethereum/hive) | [IstoraMandiri/hive](https://github.com/IstoraMandiri/hive) | Test orchestration, ETC simulators |
| `core-geth/` | [etclabscore/core-geth](https://github.com/etclabscore/core-geth) | [IstoraMandiri/core-geth](https://github.com/IstoraMandiri/core-geth) | ECIP implementation |
| `nethermind-etc-plugin/` | [ETCCooperative/nethermind-etc-plugin](https://github.com/ETCCooperative/nethermind-etc-plugin) | [IstoraMandiri/nethermind-etc-plugin](https://github.com/IstoraMandiri/nethermind-etc-plugin) | Nethermind ETC support |

### Fork Changes

**hive** (6 commits ahead of upstream):
- Added `core-geth` client definition with ETC-specific configuration (genesis mapper, `--fakepow` support, TTD fix for pre-merge tests)
- Added `besu-etc` client definition with ETC fork mappings (Atlantis, Agharta, Phoenix, Thanos, Magneto, Mystique, Spiral)
- Added `nethermind-etc` client definition using [diega/nethermind_etc](https://github.com/diega/nethermind_etc) binary with ETC plugin
- Implemented `consensus-etc` test suite that auto-filters to ETC-compatible forks (Frontier through Berlin) and targets clients with the `etc` role
- Added `etc_forks.go` with ETC fork environment variable mappings

**core-geth** (mirror of upstream, 0 commits ahead):
- No changes — fork exists as a stable reference for Hive client builds

**nethermind-etc-plugin** (1 commit ahead of [upstream releases](https://github.com/ETCCooperative/nethermind-etc-plugin/releases)):
- Fixed plugin conflict where `EthashChainSpecEngineParametersBase` implemented `IChainSpecEngineParameters` with EngineName "Ethash", colliding with Nethermind's built-in engine and causing "Multiple seal engines in chain spec" errors
- Solution: removed interface from base class so only `EtchashChainSpecEngineParameters` (EngineName "Etchash") is discovered by Nethermind's type system

## Hive Test Suites

### consensus-etc (ETC-specific)

The `consensus-etc` suite automatically filters ethereum/tests to forks supported by ETC (Frontier through Berlin) and runs only against clients with the `etc` role. No manual `--sim.limit` filtering needed.

```bash
# Run all ETC-compatible consensus tests (use --sim.parallelism for speed)
./hive --sim ethereum/consensus --sim.limit consensus-etc --client core-geth --sim.parallelism 4

# Filter by fork or test category
./hive --sim ethereum/consensus --sim.limit "consensus-etc/Berlin" --client core-geth --sim.parallelism 4
./hive --sim ethereum/consensus --sim.limit "consensus-etc/.*bcValidBlockTest" --client nethermind-etc --sim.parallelism 4
```

### Legacy ETH Suites

| Suite | Directory | Total Tests | Description |
|-------|-----------|-------------|-------------|
| `legacy` | LegacyTests/Constantinople/BlockchainTests | 32,616 | Constantinople-era tests |
| `legacy-cancun` | LegacyTests/Cancun/BlockchainTests | 111,983 | Tests up to Cancun fork |
| `consensus` | BlockchainTests | 1,148 | Current tests (Cancun/Prague) |

### Fork Compatibility

| ETH Fork | ETC Equivalent | Supported |
|----------|----------------|-----------|
| Frontier | Frontier | Yes |
| Homestead | Homestead | Yes |
| EIP150 (Tangerine) | Die Hard | Yes |
| EIP158 (Spurious) | Gotham | Yes |
| Byzantium | Atlantis | Yes |
| Constantinople | Agharta | Yes |
| Petersburg | Agharta | Yes |
| Istanbul | Phoenix | Yes |
| Berlin | Magneto | Yes |
| London | Spiral | Partial |
| Paris (Merge) | N/A | No |

## Workflow

1. **Implement** - Modify client code to implement ECIP
2. **Define** - Add/update client definition in `hive/clients/`
3. **Test** - Run tests via `consensus-etc` suite
4. **Iterate** - Fix issues, re-run tests
5. **Push** - Commit and push to respective forks

## Claude Skills

| Skill | Description |
|-------|-------------|
| `/pickup` | Resume work from previous session |
| `/handoff` | Prepare for context handoff |
| `/wrapup` | End session (commit all changes) |
| `/hive-run` | Build and run Hive integration tests |
| `/submodule-push` | Push submodule changes to fork |
| `/report` | Create structured reports |

## Prior Art

Built on [Ethereum Hive](https://github.com/ethereum/hive), the integration testing framework used by the Ethereum Foundation. See [ETC Community Call #45](https://cc.ethereumclassic.org/calls/45) for background discussion on adapting Hive for ETC.

## Development

Requires VS Code with Dev Containers extension, or a Docker-capable environment.

## License

MIT
