# Claude Agent Instructions

This file contains context and instructions for AI agents working on this project.

## Evolving This Document

**This file (CLAUDE.md) should evolve over time.** When you encounter issues, gotchas, or discover important patterns:

1. **Document problems and solutions** - If you hit an error or unexpected behavior, add it to the "Lessons Learned" section below
2. **Update outdated information** - If instructions no longer work, fix them
3. **Add missing context** - If you needed information that wasn't here, add it for next time

This helps future sessions avoid repeating the same mistakes.

## Lessons Learned

### [RESOLVED] TTD and Fake PoW for Pre-Merge Tests (2026-01-27)

**Problem:** Consensus tests failed for two reasons:
1. TTD was always set (defaulted to max int) causing beacon sync mode
2. Tests with `SealEngine: "NoProof"` failed PoW verification

**Solution Applied:**
1. Modified `mapper.jq` to only set TTD when `HIVE_TERMINAL_TOTAL_DIFFICULTY` is explicitly provided
2. Added `HIVE_SKIP_POW` handling in `geth.sh` to enable `--fakepow` flag

### [RESOLVED] Unknown Flag: `--nocompaction` (2026-01-27)

**Problem:** `flag provided but not defined: -nocompaction`

**Solution:** Removed `--nocompaction` from `geth.sh` block import command.

### Core-geth Has `--fakepow` Flag

Core-geth supports `--fakepow` to skip PoW verification during block import. This is essential for running ethereum/tests consensus tests which use `SealEngine: "NoProof"`.

### Hive Environment Variables for core-geth

Key environment variables the client should handle:
- `HIVE_SKIP_POW` - Set when tests use NoProof seal engine (enable `--fakepow`)
- `HIVE_TERMINAL_TOTAL_DIFFICULTY` - Only set for post-merge tests
- `HIVE_CHAIN_ID`, `HIVE_NETWORK_ID` - Chain configuration
- `HIVE_FORK_*` - Fork block numbers

## Available Skills

Project-specific skills are defined in `.claude/skills/`:

- `/pickup` - Resume work from previous session: load SITREP.md, TODO.md, summarize state
- `/handoff` - Prepare for context handoff: update SITREP.md, TODO.md, and commit (run when context is getting full)
- `/wrapup [message]` - Update prompt log and commit all changes (run at end of significant sessions)
- `/promptlog` - Generate PROMPTLOG.md from session history
- `/submodule-push [name]` - Push submodule changes to fork
- `/hive-run [simulator] [--client name]` - Build and run Hive integration tests
- `/hive-progress [--update]` - Check progress of running Hive tests and update docs with estimates

**End of session:** Run `/wrapup` to commit changes, or `/handoff` if context is full and work will continue in a new session.

## GitHub Access

The `gh` CLI is configured with a fine-grained Personal Access Token scoped to specific repositories.

### Authorized Repositories

- `IstoraMandiri/etc-nexus` (this repo)
- `IstoraMandiri/hive` (Hive fork)
- `IstoraMandiri/core-geth` (core-geth fork)

### Token Permissions

- **Contents**: Read and write (push commits, create branches)
- **Metadata**: Read (required)

Use `/submodule-push` skill for pushing changes in submodules.

## Project Structure

```
etc-nexus/
├── hive/           # Submodule: IstoraMandiri/hive (fork of ethereum/hive)
├── core-geth/      # Submodule: IstoraMandiri/core-geth (fork of etclabscore/core-geth)
├── .devcontainer/  # Docker-in-Docker dev environment
├── .claude/
│   ├── skills/     # Project-specific Claude skills
│   ├── hooks/      # Hook scripts (session reminders, etc.)
│   └── settings.json
├── CLAUDE.md       # This file
├── TODO.md         # Current tasks and next steps
├── PROMPTLOG.md    # Session prompt history
└── README.md       # Project overview
```

## Key Context

- **Goal**: Test ECIP-1120 and ECIP-1121 implementations using Hive
- **Hive**: Ethereum's integration testing framework using Docker containers
- **core-geth**: The primary ETC client implementation (Go)
- Hive orchestrates client containers and runs test simulators against them
- We need to add a `core-geth` client definition to Hive (doesn't exist upstream)

## Hive Basics

- Client definitions live in `hive/clients/<name>/`
- Simulators live in `hive/simulators/<category>/<name>/`
- Clients are Docker containers configured via environment variables (HIVE_*)
- Use `/hive-run` skill to build and run tests

## References

- [Hive Documentation](https://github.com/ethereum/hive/tree/master/docs)
- [ETC Community Call #45](https://cc.ethereumclassic.org/calls/45) - Background on Hive for ETC
- [ECIP-1120](https://ecips.ethereumclassic.org/ECIPs/ecip-1120)
- [ECIP-1121](https://ecips.ethereumclassic.org/ECIPs/ecip-1121)
