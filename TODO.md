# TODO

## Current Status

- [x] Project structure created
- [x] Hive fork submoduled (`hive/`)
- [x] core-geth fork submoduled (`core-geth/`)
- [x] GitHub CLI configured with fine-grained PAT
- [x] Walking skeleton: Hive running with core-geth

## Next Steps: Walking Skeleton

The immediate goal is to get Hive running with core-geth as a client, proving the integration works before making any ECIP changes.

### 1. Create core-geth client definition in Hive

Copy and adapt `hive/clients/go-ethereum/` to `hive/clients/core-geth/`:

- [x] `Dockerfile` - For pre-built images
- [x] `Dockerfile.git` - Build from source (primary)
- [x] `hive.yaml` - Client metadata (roles: eth1, eth1_snap)
- [x] `geth.sh` - Startup script (adapted from go-ethereum)
- [x] `enode.sh` - Enode retrieval script
- [x] `mapper.jq` - Genesis transformation
- [x] `genesis.json` - Default genesis

Branch: `istora-core-geth-client` pushed to IstoraMandiri/hive

Key differences from go-ethereum:
- Repository: `etclabscore/core-geth` (or `IstoraMandiri/core-geth`)
- May need ETC-specific fork environment variables (ECIP blocks)
- Network ID defaults (ETC mainnet: 1, Mordor: 7)

### 2. Build and test Hive

```bash
cd hive
go build .
```

- [x] Hive builds successfully

### 3. Run a simple test

```bash
# Test with upstream core-geth
./hive --sim ethereum/sync --client core-geth

# Or build from our fork
./hive --sim ethereum/sync --client core-geth --client.core-geth.dockerfile git
```

- [x] devp2p discv4 tests pass (16/16) with core-geth

### 4. Verify multi-version testing

Test that we can run different core-geth versions against each other:
- Upstream core-geth vs our fork
- Different branches of our fork

## Future Work

### ETC-Specific Simulators

Create `hive/simulators/etc/` with:
- Fork transition tests (ECIP activation)
- ETC consensus rule validation
- Multi-client sync tests

### ECIP Implementation

- [ ] ECIP-1120 implementation in core-geth
- [ ] ECIP-1120 test cases in Hive
- [ ] ECIP-1121 implementation in core-geth
- [ ] ECIP-1121 test cases in Hive

### Additional Clients

- [ ] Hyperledger Besu client definition
- [ ] Fukuii client definition (when ready)

## Notes

- Hive uses Docker extensively; the devcontainer has Docker-in-Docker enabled
- Client containers communicate via environment variables (HIVE_FORK_*, HIVE_NETWORK_ID, etc.)
- Test results are written to `hive/workspace/logs/`
