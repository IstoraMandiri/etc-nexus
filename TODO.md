# TODO

## Next Up

### ECIP Implementation

- [ ] ECIP-1120 implementation in core-geth
- [ ] ECIP-1120 test cases in Hive
- [ ] ECIP-1121 implementation in core-geth
- [ ] ECIP-1121 test cases in Hive

### ETC-Specific Hive Simulators

Create `hive/simulators/etc/` with:
- Fork transition tests (ECIP activation)
- ETC consensus rule validation
- Multi-client sync tests

### Additional Clients (Later)

- [ ] Hyperledger Besu client definition
- [ ] Fukuii client definition (when ready)

## Quick Reference

### Running Hive Tests

```bash
cd hive
go build .
./hive --sim devp2p --client core-geth
```

### Submodule Branches

| Repo | Branch |
|------|--------|
| hive | `istora-core-geth-client` |
| core-geth | `master` (no changes yet) |

### Key Files

- `hive/clients/core-geth/` - Hive client definition (builds from IstoraMandiri/core-geth)
- `hive/clients/core-geth/mapper.jq` - Genesis config transformation (add ECIP forks here)
- `core-geth/params/config_classic.go` - ETC chain config with ECIP block numbers

### Hive Environment Variables

Clients receive fork configuration via `HIVE_FORK_*` env vars. For ETC-specific forks, we may need to add new variables and handle them in `mapper.jq` and `geth.sh`.
