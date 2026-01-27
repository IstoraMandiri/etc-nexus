# ETC Nexus

A workspace for developing and testing Ethereum Classic protocol changes using the Hive testing framework, with a focus on AI-assisted development.

## Project Status

**Current Focus**: Getting baseline Hive test suites passing for core-geth before implementing ECIPs.

### Working
- core-geth client builds from fork in Hive
- devp2p tests: 16/16 passing
- smoke/genesis tests: 6/6 passing
- Consensus tests infrastructure (with `--fakepow` for NoProof tests)

### In Progress
- Phase 1: Validate baseline test suites (see [HIVE-TEST-ANALYSIS.md](HIVE-TEST-ANALYSIS.md))
  - `legacy` suite: 32,615 tests (Constantinople and earlier)
  - `consensus` suite: 1,148 tests (Cancun/Prague)
  - `legacy-cancun` suite: 111,983 tests (full fork coverage)
- Phase 2: Develop ETC-specific test configuration

See [TODO.md](TODO.md) for detailed next steps and [SITREP.md](SITREP.md) for current state.

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

## Prior Art

Built on [Ethereum Hive](https://github.com/ethereum/hive), the integration testing framework used by the Ethereum Foundation. See [ETC Community Call #45](https://cc.ethereumclassic.org/calls/45) for background discussion on adapting Hive for ETC.

## Development

Requires VS Code with Dev Containers extension, or a Docker-capable environment.

## License

MIT
