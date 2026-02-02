# ETC Nexus

A workspace for developing and testing Ethereum Classic protocol changes using the Hive testing framework, with a focus on AI-assisted development.

## Project Status

**See [SITREP.md](SITREP.md)** for current test progress, what's working, and recent updates.

**See [TODO.md](TODO.md)** for planned next steps and future work.

**Current Focus**: Validating baseline Hive test suites for core-geth and besu-etc before implementing ECIPs.

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
│   │   └── core-geth/    # ETC client definition
│   └── simulators/
│       └── etc/          # ETC-specific test suites (planned)
├── core-geth/            # Fork of etclabscore/core-geth
├── .claude/
│   └── skills/           # Claude Code skills for workflow automation
└── .devcontainer/        # Docker-in-Docker dev environment
```

## Submodules

| Submodule | Upstream | Fork | Purpose |
|-----------|----------|------|---------|
| `hive/` | [ethereum/hive](https://github.com/ethereum/hive) | [IstoraMandiri/hive](https://github.com/IstoraMandiri/hive) | Test orchestration, ETC simulators |
| `core-geth/` | [etclabscore/core-geth](https://github.com/etclabscore/core-geth) | [IstoraMandiri/core-geth](https://github.com/IstoraMandiri/core-geth) | ECIP implementation |

Future clients:
- Hyperledger Besu
- [Fukuii](https://github.com/chippr-robotics/fukuii) (Rust)

## Workflow

1. **Implement** - Modify client code in `core-geth/` to implement ECIP
2. **Define** - Add/update client definition in `hive/clients/core-geth/`
3. **Test** - Create test simulator in `hive/simulators/etc/`
4. **Run** - Execute tests via Hive
5. **Iterate** - Fix issues, re-run tests
6. **Push** - Commit and push to respective forks

## Claude Skills

This project includes Claude Code skills for session management:

| Skill | Description |
|-------|-------------|
| `/pickup` | Resume work from previous session (loads SITREP.md, TODO.md) |
| `/handoff` | Prepare for context handoff (update docs, commit) |
| `/wrapup` | End session (run promptlog, commit all changes) |
| `/promptlog` | Generate PROMPTLOG.md from session history |
| `/hive-run` | Build and run Hive integration tests |
| `/submodule-push` | Push submodule changes to fork |

## Multi-Version Testing

Hive supports testing different client versions against each other. Using `Dockerfile.git`, we can specify branches:

```yaml
clients:
  - client: core-geth
    dockerfile: git
    build_args:
      github: etclabscore/core-geth
      tag: master

  - client: core-geth-ecip1121
    dockerfile: git
    build_args:
      github: IstoraMandiri/core-geth
      tag: ecip-1121
```

This validates that ECIP implementations maintain consensus pre-fork and correctly diverge post-fork.

## Test Suites

### Hive Ethereum Consensus Test Suites

The `ethereum/consensus` simulator runs BlockchainTests from [ethereum/tests](https://github.com/ethereum/tests). Tests are organized into three suites:

| Suite | Directory | Total Tests | Description |
|-------|-----------|-------------|-------------|
| `legacy` | LegacyTests/Constantinople/BlockchainTests | 32,616 | Constantinople-era tests (pre-Istanbul) |
| `legacy-cancun` | LegacyTests/Cancun/BlockchainTests | 111,983 | Tests up to Cancun fork |
| `consensus` | BlockchainTests | 1,148 | Current tests (Cancun/Prague) |
| **Total** | | **145,747** | |

### Fork Compatibility

Tests target specific Ethereum forks. ETC clients only support pre-merge forks:

| Fork | ETC Equivalent | ETC Support | Notes |
|------|----------------|-------------|-------|
| Frontier | Frontier | ✅ | Genesis fork |
| Homestead | Homestead | ✅ | |
| EIP150 (Tangerine) | Die Hard | ✅ | |
| EIP158 (Spurious) | Gotham | ✅ | |
| Byzantium | Atlantis | ✅ | |
| Constantinople | Agharta | ✅ | |
| Petersburg | Agharta | ✅ | Bundled with Constantinople in ETC |
| Istanbul | Phoenix | ✅ | |
| Berlin | Magneto | ✅ | |
| London | Spiral | ⚠️ | Partial - EIP-1559 not adopted |
| Paris (Merge) | N/A | ❌ | Proof-of-Stake transition |
| Shanghai | N/A | ❌ | Post-merge |
| Cancun | N/A | ❌ | Post-merge |

### ETC-Applicable Test Suite

Filtering Hive tests for ETC-supported forks (pre-merge only):

| Test Category | Filter Pattern | Tests | Status |
|---------------|----------------|-------|--------|
| **Legacy Suite (Full)** | `--sim.limit legacy` | 32,616 | ✅ 99.94% pass |
| **Berlin tests** | `--sim.limit Berlin` | ~15,000 | ✅ Available |
| **Istanbul tests** | `--sim.limit Istanbul` | ~8,000 | ✅ Available |
| **Constantinople tests** | `--sim.limit Constantinople` | ~5,000 | ✅ Available |
| **Pre-merge combined** | `--sim.limit "Frontier\|Homestead\|EIP150\|EIP158\|Byzantium\|Constantinople\|Istanbul\|Berlin"` | ~60,000 | ✅ Available |

**Excluded from ETC testing:**
- Post-merge forks: Paris, Shanghai, Cancun (~50,000 tests)
- London EIP-1559 tests (base fee mechanics)
- DAO fork tests (ETC rejected the DAO fork)

### Running ETC-Compatible Tests

```bash
# Full legacy suite (Constantinople and earlier)
./hive --sim ethereum/consensus --sim.limit legacy --client core-geth

# Pre-merge tests from legacy-cancun suite
./hive --sim ethereum/consensus --sim.limit legacy-cancun \
  --sim.limit "Berlin|Istanbul" --client core-geth

# All ETC-compatible forks
./hive --sim ethereum/consensus \
  --sim.limit "Frontier|Homestead|EIP150|EIP158|Byzantium|Constantinople|Istanbul|Berlin" \
  --client core-geth
```

### Test Results Summary

| Client | Legacy (32,616) | Berlin/Istanbul | Notes |
|--------|-----------------|-----------------|-------|
| core-geth | 99.94% (32,595/32,616) | 99.9% (111,803/111,893) | 21 CREATE2 edge cases excluded |
| besu-etc | ✅ Running | - | In progress |

See [SITREP.md](SITREP.md) for detailed test results and progress.

## Prior Art

Built on [Ethereum Hive](https://github.com/ethereum/hive), the integration testing framework used by the Ethereum Foundation. See [ETC Community Call #45](https://cc.ethereumclassic.org/calls/45) for background discussion on adapting Hive for ETC.

## Development

Requires VS Code with Dev Containers extension, or a Docker-capable environment.

## License

MIT
