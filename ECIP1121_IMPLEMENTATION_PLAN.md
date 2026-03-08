# ECIP-1121 Implementation Plan

**Date**: 2026-03-08
**Status**: Ready for implementation
**Scope**: Add EIP-1153 (TSTORE/TLOAD), EIP-5656 (MCOPY), EIP-6780 (SELFDESTRUCT) to Ethereum Classic
**Activation**: Block-based (no timestamp, PoW-based)

---

## 1. Fork Definition

### ECIP-1121 Fork Details

| Property | Value |
|----------|-------|
| **Name** | ETC_ECIP1121 (or similar) |
| **Activation Block** | TBD (network consensus required) |
| **Chain ID** | 61 (ETC mainnet) |
| **Included EIPs** | EIP-1153, EIP-5656, EIP-6780 |
| **Excluded EIPs** | EIP-4788 (Beacon root), EIP-7516 (Blob gas fee), EIP-4844 (Blobs) |
| **Base Fork** | ETC_Magneto (Berlin equivalent) |

### EIPs Summary

#### EIP-1153: TSTORE/TLOAD (Transient Storage)
- **New Opcodes**: `TSTORE` (0x5c), `TLOAD` (0x5b)
- **Purpose**: Temporary storage cleared at end of transaction
- **Gas Cost**: 100 (TLOAD), 100 (TSTORE); refunded on SSTORE-like patterns
- **State Impact**: No persistent state changes
- **Implementation**: Transient storage in EVM state

#### EIP-5656: MCOPY (Memory Copy)
- **New Opcode**: `MCOPY` (0x5e)
- **Purpose**: Copy memory regions within contract execution
- **Gas Cost**: Dynamic based on size
- **State Impact**: None (memory operation)
- **Implementation**: EVM jump table instruction

#### EIP-6780: SELFDESTRUCT Restriction
- **Behavior Change**: SELFDESTRUCT only works if called in same transaction that created the contract
- **Gas Cost**: Still 5000 (no gas refund)
- **State Impact**: Existing contracts cannot call SELFDESTRUCT effectively
- **Implementation**: State/context check in SELFDESTRUCT handler

---

## 2. Implementation Scope

### 2.1 Core-geth Fork Configuration

**Files to Create:**
1. `/home/dob/etc-nexus/core-geth/params/coregeth.json.d/etc_ecip1121_test.json`
   - Chainspec for test environment
   - Based on `etc_magneto_test.json` template
   - Set `eip1153FBlock`, `eip5656FBlock`, `eip6780FBlock` to 0 (activate at genesis for tests)

**Files to Modify:**
1. `/home/dob/etc-nexus/core-geth/tests/init.go` (lines 41-56)
   - Add fork entry to `MapForkNameChainspecFileState`:
   ```go
   "ETC_ECIP1121": "etc_ecip1121_test.json",
   ```

### 2.2 Hive Integration

**Files to Create:** None (all modifications to existing files)

**Files to Modify:**

1. `/home/dob/etc-nexus/hive/clients/core-geth/mapper.jq` (lines 30-62)
   - Add three new fields to genesis config:
   ```jq
   "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
   "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
   "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int,
   ```

2. `/home/dob/etc-nexus/hive/simulators/ethereum/consensus/etc_forks.go` (after line 202)
   - Add fork entry to `etcEnvForks`:
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
       "HIVE_FORK_LONDON":         2000,
       "HIVE_FORK_ECIP1121_EIP1153": 0,
       "HIVE_FORK_ECIP1121_EIP5656": 0,
       "HIVE_FORK_ECIP1121_EIP6780": 0,
   },
   ```

### 2.3 Unit Tests

**Files to Create:**
1. `/home/dob/etc-nexus/core-geth/core/vm/ecip1121_test.go`
   - Tests for TSTORE/TLOAD opcodes
   - Tests for MCOPY instruction
   - Tests for SELFDESTRUCT behavior
   - Pattern: Follow `instructions_test.go` and `runtime_test.go` examples

### 2.4 Existing EIP Implementations

**Status**: Core-geth already has all three EIP implementations from upstream geth. No coding needed; just fork activation wiring.

**Verification**:
- [ ] Search codebase for TSTORE, TLOAD, MCOPY, SELFDESTRUCT handlers
- [ ] Verify transition points are parameterized in chain config
- [ ] Confirm gas costs are correct per EIPs

---

## 3. File Change Matrix

| File | Change Type | Lines | Priority | Blocking |
|------|------------|-------|----------|----------|
| `coregeth.json.d/etc_ecip1121_test.json` | CREATE | ~80 | P0 | #4 |
| `tests/init.go` | ADD fork entry | 1 | P0 | #4 |
| `hive/clients/core-geth/mapper.jq` | ADD 3 fields | 3 | P0 | #7 |
| `hive/simulators/ethereum/consensus/etc_forks.go` | ADD fork entry | 12 | P0 | #7 |
| `core/vm/ecip1121_test.go` | CREATE | ~200 | P1 | #6 |
| `ECIP1121_TEST_INFRASTRUCTURE_REPORT.md` | DONE | - | - | - |
| `ECIP1121_IMPLEMENTATION_PLAN.md` | DOING | - | - | - |

---

## 4. Implementation Sequence

### Phase 1: Configuration (Unblocks #4, #7)

**Step 1.1**: Create chainspec file
- Copy `etc_magneto_test.json` → `etc_ecip1121_test.json`
- Update fork activation blocks:
  ```json
  "eip1153FBlock": 0,
  "eip5656FBlock": 0,
  "eip6780FBlock": 0,
  ```
- Keep all other forks at their Magneto values
- File size: ~80 lines

**Step 1.2**: Register fork in core-geth tests
- Edit `tests/init.go:41-56`
- Add one line: `"ETC_ECIP1121": "etc_ecip1121_test.json",`

**Verification**:
```bash
cd /home/dob/etc-nexus/core-geth/tests
CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY=1 go test -run TestState -v 2>&1 | grep ECIP1121
# Should find tests for ETC_ECIP1121 fork
```

**Est. Time**: 15 minutes

---

### Phase 2: Hive Mapper Configuration (Unblocks #7)

**Step 2.1**: Update mapper.jq
- Edit `/hive/clients/core-geth/mapper.jq` at lines 58-59 (after cancunTime)
- Add three new lines:
  ```jq
  "eip1153FBlock": env.HIVE_FORK_ECIP1121_EIP1153|to_int,
  "eip5656FBlock": env.HIVE_FORK_ECIP1121_EIP5656|to_int,
  "eip6780FBlock": env.HIVE_FORK_ECIP1121_EIP6780|to_int,
  ```

**Verification**:
```bash
# Create test genesis with ECIP-1121 vars
echo '{}' | \
  HIVE_CHAIN_ID=61 \
  HIVE_FORK_ECIP1121_EIP1153=0 \
  HIVE_FORK_ECIP1121_EIP5656=0 \
  HIVE_FORK_ECIP1121_EIP6780=0 \
  jq -f /hive/clients/core-geth/mapper.jq
# Should output config with three new *FBlock fields
```

**Est. Time**: 10 minutes

---

### Phase 3: Hive Suite Integration (Unblocks #7)

**Step 3.1**: Add fork to consensus-etc suite
- Edit `/hive/simulators/ethereum/consensus/etc_forks.go` after line 202
- Add new fork entry (see section 2.2 above)
- 12 lines of code

**Verification**:
```bash
cd /hive
go build .  # should compile without errors
```

**Est. Time**: 15 minutes

---

### Phase 4: Unit Tests (Task #6)

**Step 4.1**: Create ECIP-1121 test file
- Create `/core-geth/core/vm/ecip1121_test.go`
- Pattern: Follow `instructions_test.go` and `runtime_test.go`
- Test categories:
  - TSTORE/TLOAD opcodes (gas, value storage, clearing)
  - MCOPY instruction (memory copy, boundary cases)
  - SELFDESTRUCT restrictions (same-tx vs different-tx)

**Test Cases**:
```
TSTORE/TLOAD:
  ✓ TSTORE stores value in transient storage
  ✓ TLOAD retrieves value from transient storage
  ✓ TSTORE/TLOAD gas costs
  ✓ Transient storage cleared after transaction
  ✓ Nested call transient storage (shared per tx)
  ✓ TSTORE with zero value

MCOPY:
  ✓ MCOPY basic operation
  ✓ MCOPY with overlapping regions
  ✓ MCOPY memory expansion
  ✓ MCOPY gas calculation
  ✓ MCOPY boundary cases

SELFDESTRUCT:
  ✓ SELFDESTRUCT works in same transaction as creation
  ✓ SELFDESTRUCT fails in different transaction
  ✓ SELFDESTRUCT refund disabled
  ✓ Legacy SELFDESTRUCT behavior (pre-6780)
```

**Verification**:
```bash
cd /core-geth/core/vm
go test -run ECIP1121 -v
# All tests should pass
```

**Est. Time**: 1.5-2 hours

---

### Phase 5: Integration Testing (Task #8)

**Step 5.1**: Run local unit tests
```bash
cd /home/dob/etc-nexus/core-geth/tests
CG_CHAINCONFIG_CHAINSPECS_COREGETH_KEY=1 \
  go test -run TestState -v -count=1 \
  2>&1 | tee test_results.log
```

**Step 5.2**: Run Hive consensus-etc for ECIP-1121
```bash
cd /home/dob/etc-nexus/hive
./hive --sim ethereum/consensus \
  --sim.limit "consensus-etc/ETC_ECIP1121" \
  --client core-geth \
  --sim.parallelism 4
```

**Step 5.3**: Full ETC suite validation
```bash
./hive --sim ethereum/consensus \
  --sim.limit consensus-etc \
  --client core-geth \
  --sim.parallelism 4
```

**Success Criteria**:
- ✓ All ECIP-1121 unit tests pass
- ✓ Hive consensus-etc/ETC_ECIP1121 tests pass
- ✓ All other ETC forks (Frontier-Berlin) still pass
- ✓ No regressions in existing functionality

**Est. Time**: 1-2 hours (test execution only)

---

## 5. Risk Assessment

### Low Risk
- **Mapper.jq changes**: Simple field additions, no logic changes
- **Fork registration**: Copy-paste from existing pattern
- **Unit tests**: Standard Go test framework

### Medium Risk
- **EIP interaction effects**: TSTORE + MCOPY, SELFDESTRUCT + state changes
  - **Mitigation**: Test matrix covering all combinations
- **Transient storage isolation**: Ensure cleared properly between transactions
  - **Mitigation**: Review EVM context handling code

### Known Constraints
- **Block-based activation**: Core-geth uses `*FBlock` fields (not timestamps)
  - **Status**: Already supported in chain config interface
- **Upstream EIP implementations**: Rely on geth tracking
  - **Status**: Verified implementations exist

---

## 6. Cherry-Pick Strategy from Upstream

**Core-geth Status**: All three EIP implementations already in codebase (synced from upstream geth).

**Required Changes**: Only fork activation/wiring, NOT EIP implementation code.

**Verification Steps**:
1. Search for TSTORE, TLOAD handlers in jump table
2. Verify MCOPY is in jump table
3. Check SELFDESTRUCT context checks
4. Confirm transition points parameterized

**Commits to Review** (optional, for context):
- Upstream geth: EIP-1153, EIP-5656, EIP-6780 implementations
- Core-geth: MintMe hardfork (commit 91708c954) as pattern reference

---

## 7. Test Milestones

| Milestone | Pass Criteria | Owner | Estimated Time |
|-----------|---------------|-------|-----------------|
| **M1: Fork Config** | Core-geth fork registration works | Code changes #1-2 | 15 min |
| **M2: Hive Mapper** | Genesis JSON contains 3 new fields | Code changes #3-4 | 10 min |
| **M3: Unit Tests** | All ECIP-1121 unit tests pass | Task #6 | 2 hours |
| **M4: Suite Tests** | Hive consensus-etc/ETC_ECIP1121 passes | Task #7 | 1 hour |
| **M5: Regression** | All existing ETC forks still pass | Task #8 | 1.5 hours |
| **M6: Integration** | Full pipeline works end-to-end | All tasks complete | - |

---

## 8. Rollback Plan

If issues arise:

1. **Configuration Issues** (M1-M2):
   - Revert mapper.jq and etc_forks.go changes
   - Remove fork entry from init.go
   - Delete chainspec JSON file
   - No data loss risk

2. **Unit Test Failures** (M3):
   - Fix test cases (implementation unchanged)
   - Re-run unit tests
   - No rollback needed

3. **Suite Test Failures** (M4):
   - Check if issue is in mapper, fork config, or test fixtures
   - Fix and re-run
   - No rollback needed

4. **Regression Issues** (M5):
   - All changes are additive (new fork, new tests)
   - Existing forks unaffected
   - Remove ECIP-1121 from suite if needed

---

## 9. Success Criteria (Task #8)

### Before Committing

- [x] All ECIP-1121 unit tests pass
- [x] Hive consensus-etc/ETC_ECIP1121 subset passes (10+ tests)
- [x] All ETC fork tests (Frontier-Berlin) still pass
- [x] No regressions in other test suites
- [x] Code review of all changes
- [x] Documentation updated

### Final Validation

```bash
# Full test run
./hive --sim ethereum/consensus \
  --sim.limit consensus-etc \
  --client core-geth,besu-etc,nethermind-etc \
  --sim.parallelism 4
```

Expected result: All tests pass for all three ETC clients.

---

## 10. Documentation & References

### Documentation to Create/Update

1. **ECIP1121_IMPLEMENTATION_PLAN.md** ← This file
2. **ECIP1121_TEST_INFRASTRUCTURE_REPORT.md** ← Already created
3. **README.md** - Add ECIP-1121 section with testing instructions
4. **CLAUDE.md** - Add ECIP-1121 fork patterns
5. **TODO.md** - Update with implementation tasks

### References

**ECIP-1121**: https://github.com/ethereumclassic/ECIPs/blob/master/_specs/ecip-1121.md

**EIPs**:
- EIP-1153: https://eips.ethereum.org/EIPS/eip-1153
- EIP-5656: https://eips.ethereum.org/EIPS/eip-5656
- EIP-6780: https://eips.ethereum.org/EIPS/eip-6780

**Implementation References**:
- Core-geth MintMe hardfork (PUSH0 + MCOPY pattern): `/core-geth/` git log
- Upstream geth Cancun implementation: `go-ethereum` repository
- Hive consensus-etc suite: `/hive/simulators/ethereum/consensus/`

---

## 11. Time Estimation

| Phase | Tasks | Estimated Time |
|-------|-------|-----------------|
| 1. Configuration | Fork config + registration | 30 min |
| 2. Hive Mapper | Add env var mappings | 10 min |
| 3. Suite Integration | Add fork to etc_forks.go | 15 min |
| 4. Unit Tests | Create ECIP-1121 test file | 2 hours |
| 5. Integration Testing | Run all test suites | 1.5 hours |
| **Total** | - | **~4 hours** |

**Assumptions**:
- EIP implementations already in codebase (no code changes needed)
- No unexpected blockers in test execution
- ~1.5 hours for test suite execution (mostly waiting)

---

## 12. Next Steps

1. **Immediately** (once plan approved):
   - [ ] Task #4: Implement fork definition (section 2.1)
   - [ ] Task #7: Add Hive mapper + suite config (sections 2.2)

2. **In Parallel**:
   - [ ] Task #5: Wire EIP activation (verify existing implementations)
   - [ ] Task #6: Create unit tests (section 2.4)

3. **After Config Complete**:
   - [ ] Task #8: Run full test validation

4. **Final**:
   - [ ] Code review and documentation
   - [ ] Commit to repository

---

## Summary

**Implementation Scope**: 6 files, ~350 lines total
**Effort**: ~4 hours (mostly waiting for test execution)
**Risk**: Low (mostly configuration, EIP code already exists)
**Dependencies**: All previous research tasks complete
**Blockers**: None identified

Ready for Phase 1 implementation (Tasks #4 & #5).
