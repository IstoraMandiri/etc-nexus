# Claude Agent Instructions

This file contains context and instructions for AI agents working on this project.

## GitHub Access

The `gh` CLI is configured with a fine-grained Personal Access Token scoped to specific repositories.

### Authorized Repositories

- `IstoraMandiri/etc-nexus` (this repo)
- `IstoraMandiri/hive` (Hive fork)
- `IstoraMandiri/core-geth` (core-geth fork)

### Token Permissions

- **Contents**: Read and write (push commits, create branches)
- **Metadata**: Read (required)
- **Pull requests**: Read and write (create PRs)

### Usage

```bash
# Check auth status
gh auth status

# Push to submodules
cd hive && git push origin <branch>
cd core-geth && git push origin <branch>

# Create PRs
gh pr create --repo IstoraMandiri/hive --title "..." --body "..."
```

## Project Structure

```
etc-nexus/
├── hive/           # Submodule: IstoraMandiri/hive (fork of ethereum/hive)
├── core-geth/      # Submodule: IstoraMandiri/core-geth (fork of etclabscore/core-geth)
├── .devcontainer/  # Docker-in-Docker dev environment
├── CLAUDE.md       # This file
├── TODO.md         # Current tasks and next steps
└── README.md       # Project overview
```

## Submodule Workflow

When making changes to submodules:

1. Navigate into the submodule directory
2. Create a branch, make changes, commit
3. Push to the fork using `git push origin <branch>`
4. Optionally create a PR via `gh pr create`
5. Update the parent repo's submodule reference if needed

## Key Context

- **Goal**: Test ECIP-1120 and ECIP-1121 implementations using Hive
- **Hive**: Ethereum's integration testing framework using Docker containers
- **core-geth**: The primary ETC client implementation (Go)
- Hive orchestrates client containers and runs test simulators against them
- We need to add a `core-geth` client definition to Hive (doesn't exist upstream)

## Hive Basics

- Build: `cd hive && go build .`
- Run: `./hive --sim <simulator> --client <client>`
- Client definitions live in `hive/clients/<name>/`
- Simulators live in `hive/simulators/<category>/<name>/`
- Clients are Docker containers configured via environment variables (HIVE_*)

## References

- [Hive Documentation](https://github.com/ethereum/hive/tree/master/docs)
- [ETC Community Call #45](https://cc.ethereumclassic.org/calls/45) - Background on Hive for ETC
- [ECIP-1120](https://ecips.ethereumclassic.org/ECIPs/ecip-1120)
- [ECIP-1121](https://ecips.ethereumclassic.org/ECIPs/ecip-1121)
