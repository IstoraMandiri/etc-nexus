# Claude Agent Instructions

This file contains context and instructions for AI agents working on this project.

## Evolving This Document

**This file (CLAUDE.md) should evolve over time.** When you encounter issues, gotchas, or discover important patterns:

1. **Document problems and solutions** - If you hit an error or unexpected behavior, add it to the "Lessons Learned" section below
2. **Update outdated information** - If instructions no longer work, fix them
3. **Add missing context** - If you needed information that wasn't here, add it for next time

This helps future sessions avoid repeating the same mistakes.

## Lessons Learned

### Hive Legacy Tests Fail Due to Post-Merge Configuration (2026-01-27)

**Problem:** Running `./hive --sim ethereum/consensus --sim.limit legacy` results in all pre-merge tests (Homestead, Byzantium, etc.) failing, even though they should work for ETC.

**Root Cause:** The Hive test framework sets `HIVE_TERMINAL_TOTAL_DIFFICULTY` (TTD) in chain configs, which causes core-geth to enter post-merge "beacon sync" mode. The client then waits for Engine API calls instead of processing PoW blocks.

**Evidence:** Client logs show:
```
Consensus: Beacon (proof-of-stake), merged from Ethash (proof-of-work)
Chain post-merge, sync via beacon client
```

**Solution Options:**
1. Modify `hive/clients/core-geth/mapper.jq` to not set TTD for pre-merge tests
2. Fork hive consensus simulator to support pure PoW testing
3. Investigate if hive has a pre-merge test mode flag

### Unknown Flag: `--nocompaction` in core-geth Client (2026-01-27)

**Problem:** Client logs show `flag provided but not defined: -nocompaction`

**Root Cause:** `hive/clients/core-geth/geth.sh:112` passes `--nocompaction` to `geth import`, but core-geth doesn't support this flag (upstream geth does).

**Solution:** Remove `--nocompaction` from the import command in `geth.sh`.

## Available Skills

Project-specific skills are defined in `.claude/skills/`:

- `/pickup` - Resume work from previous session: load SITREP.md, TODO.md, summarize state
- `/handoff` - Prepare for context handoff: update SITREP.md, TODO.md, and commit (run when context is getting full)
- `/wrapup [message]` - Update prompt log and commit all changes (run at end of significant sessions)
- `/promptlog` - Generate PROMPTLOG.md from session history
- `/submodule-push [name]` - Push submodule changes to fork
- `/hive-run [simulator] [--client name]` - Build and run Hive integration tests

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
