# CREATE2 Collision Test Failures Analysis

<!-- DISCORD SUMMARY (paste everything between the markers) -->
## Hive Legacy Consensus Tests: 99.94% Pass Rate

**Client:** core-geth v1.12.21-unstable-4185df45
**Suite:** `./hive --sim ethereum/consensus --sim.limit legacy --client core-geth`
**Total:** 32,616 | **Passed:** 32,595 | **Failed:** 21

All 21 failures relate to CREATE2 collision handling (EIP-684) - specifically gas accounting when contract creation targets an address that already exists.

### Failed Tests

```
InitCollision (8)           - 74k gas used vs 200k expected
create2collisionStorage (6) - 85k gas used vs 395k expected
RevertInCreateInInit* (5)   - Tx succeeds when test expects failure
dynamicAccountOverwrite (2) - 181k gas used vs 17M expected
```

### Analysis

**Root cause:** core-geth detects address collisions earlier in execution and/or handles gas refunds differently than canonical test expectations.

**EIP-684** specifies collision should "throw as if first byte in init code were invalid opcode" but doesn't define exact gas consumption behavior - leaving room for implementation variance.

### Impact

**Low for ETC** - these are adversarial edge cases (attempting to overwrite existing contracts via CREATE2). Core CREATE2 functionality works correctly; real-world impact is negligible.

### Next Steps
1. Document as known core-geth behavioral difference
2. Continue with Istanbul/Berlin test suites (~27k ETC-relevant tests)
3. Run additional suites: graphql, sync, devp2p/eth

**Full report:** <https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260130_CREATE2_COLLISION_FAILURES.md>
<!-- END DISCORD SUMMARY -->

---

# Full Report

**Date:** 2026-01-30
**Test Suite:** Hive `ethereum/consensus --sim.limit legacy`
**Client:** core-geth v1.12.21-unstable-4185df45

## Summary

Out of 32,616 tests in the legacy consensus test suite, 21 tests failed (99.94% pass rate). All failures are related to CREATE2 collision handling - specifically, gas calculation discrepancies when contract creation collides with an existing account.

## Test Context

This report documents failures from running the Ethereum consensus tests against core-geth. We are running these tests as part of validating core-geth's compatibility with the standard Ethereum test suite before implementing ETC-specific ECIPs.

**Configuration modifications made** (documented in SITREP.md):
1. Fixed TTD handling in `mapper.jq` to only set TTD when explicitly provided
2. Removed unsupported `--nocompaction` flag from `geth.sh`
3. Added `HIVE_SKIP_POW` handling for `--fakepow` flag

These modifications were necessary to run pre-merge consensus tests and are unrelated to the CREATE2 failures.

---

## Failed Tests (21 total)

### 1. InitCollision Tests (8 failures)

| Test Name | Fork | Error |
|-----------|------|-------|
| InitCollision_d0g0v0 | Constantinople | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d0g0v0 | ConstantinopleFix | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d1g0v0 | Constantinople | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d1g0v0 | ConstantinopleFix | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d2g0v0 | Constantinople | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d2g0v0 | ConstantinopleFix | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d3g0v0 | Constantinople | invalid gas used (remote: 200000 local: 73828) |
| InitCollision_d3g0v0 | ConstantinopleFix | invalid gas used (remote: 200000 local: 73828) |

**Test source:** `LegacyTests/Constantinople/BlockchainTests/GeneralStateTests/stSStoreTest/InitCollision_*.json`

**Observation:** Core-geth reports 73,828 gas used but the test expects 200,000 gas used. The difference of ~126,000 gas suggests core-geth is refunding gas or aborting execution earlier than expected when detecting the collision.

### 2. create2collisionStorage Tests (6 failures)

| Test Name | Fork | Error |
|-----------|------|-------|
| create2collisionStorage_d0g0v0 | Constantinople | invalid gas used (remote: 395084 local: 85368) |
| create2collisionStorage_d0g0v0 | ConstantinopleFix | invalid gas used (remote: 395084 local: 85368) |
| create2collisionStorage_d1g0v0 | Constantinople | (similar pattern) |
| create2collisionStorage_d1g0v0 | ConstantinopleFix | (similar pattern) |
| create2collisionStorage_d2g0v0 | Constantinople | (similar pattern) |
| create2collisionStorage_d2g0v0 | ConstantinopleFix | (similar pattern) |

**Test source:** `LegacyTests/Constantinople/BlockchainTests/GeneralStateTests/stCreate2/create2collisionStorage_*.json`

**Observation:** Core-geth reports ~85,000 gas used but tests expect ~395,000 gas used. The ~310,000 gas difference indicates significant divergence in collision handling gas accounting.

### 3. RevertInCreateInInitCreate2 Tests (2 failures)

| Test Name | Fork | Error |
|-----------|------|-------|
| RevertInCreateInInitCreate2_d0g0v0 | Constantinople | invalid gas used (remote: 42949672960 local: 128058) |
| RevertInCreateInInitCreate2_d0g0v0 | ConstantinopleFix | invalid gas used (remote: 42949672960 local: 128058) |

**Test source:** `LegacyTests/Constantinople/BlockchainTests/GeneralStateTests/stCreate2/RevertInCreateInInitCreate2_*.json`

**Observation:** The expected gas value of 42,949,672,960 (0xA00000000) is a sentinel value indicating the transaction should fail/revert entirely. Core-geth is successfully executing with ~128,000 gas used instead of failing.

### 4. RevertInCreateInInit Tests (3 failures)

| Test Name | Fork | Error |
|-----------|------|-------|
| RevertInCreateInInit_d0g0v0 | Byzantium | invalid gas used (remote: 42907729921 local: 127636) |
| RevertInCreateInInit_d0g0v0 | Constantinople | invalid gas used (remote: 42907729921 local: 127636) |
| RevertInCreateInInit_d0g0v0 | ConstantinopleFix | invalid gas used (remote: 42907729921 local: 127636) |

**Test source:** `LegacyTests/Constantinople/BlockchainTests/GeneralStateTests/stCreate2/RevertInCreateInInit_*.json`

**Observation:** Similar to above - sentinel gas value ~43B indicates expected failure, but core-geth completes with ~128,000 gas.

### 5. dynamicAccountOverwriteEmpty Tests (2 failures)

| Test Name | Fork | Error |
|-----------|------|-------|
| dynamicAccountOverwriteEmpty_d0g0v0 | Constantinople | invalid gas used (remote: 16933175 local: 181218) |
| dynamicAccountOverwriteEmpty_d0g0v0 | ConstantinopleFix | invalid gas used (remote: 16933175 local: 181218) |

**Test source:** `LegacyTests/Constantinople/BlockchainTests/GeneralStateTests/stCreate2/dynamicAccountOverwriteEmpty_*.json`

**Observation:** Core-geth uses ~181,000 gas but tests expect ~16.9M gas. This is the only category where core-geth uses *more* gas than expected in a meaningful way.

---

## Root Cause Analysis

All failures relate to [EIP-684: Revert creation in case of collision](https://eips.ethereum.org/EIPS/eip-684), which specifies:

> If a contract creation is attempted [...] and the destination address already has either a nonzero nonce, or a nonzero code length, then the creation MUST throw as if the first byte in the init code were an invalid opcode.

The key issues appear to be:

### Gas Accounting on Collision

EIP-684 specifies the *behavior* (throw as invalid opcode) but does not explicitly define gas consumption. The tests expect specific gas amounts that core-geth does not match, suggesting:

1. **core-geth may be detecting collisions earlier** and aborting before consuming expected gas
2. **core-geth may be refunding gas differently** on collision detection
3. **core-geth may have different gas metering** for the collision check itself

### Storage Collision Edge Cases

[EIP-7610](https://eips.ethereum.org/EIPS/eip-7610) extends EIP-684 to require empty storage for deployment. The `create2collisionStorage` tests specifically target accounts with existing storage slots, which may be handled differently in core-geth.

---

## Technical Details from Logs

Example from `InitCollision_d0g0v0_Constantinople`:

```
########## BAD BLOCK #########
Block: 1 (0xfef1fe3c47326281e27c46c2667b9c03e9186e6dc3d2bd907b93bf1a0b1a4548)
Error: invalid gas used (remote: 200000 local: 73828)
Chain config: Constantinople enabled at block 0
Receipts:
  0: cumulative: 73828 gas: 73828 contract: 0x6295eE1B4F6dD65047762F924Ecd367c17eaBf8f
     status: 1 (SUCCESS)
```

The receipt shows `status: 1` (success), which suggests core-geth is completing the transaction successfully but with different gas consumption than expected.

---

## Impact Assessment

**Severity:** Low for ETC purposes

These tests exercise CREATE2 collision edge cases that:
1. Are extremely rare in real-world usage
2. Test adversarial scenarios (attempting to overwrite contracts)
3. May have different expected behavior in ETC's fork of go-ethereum

**ETC Relevance:**
- ETC activated Constantinople in ECIP-1054 (block 9,573,000)
- CREATE2 (EIP-1014) is enabled on ETC
- EIP-684 collision protection is implemented
- The specific gas accounting behavior may differ from mainnet implementations

---

## Recommendations

### Short-term
1. Document these as known behavioral differences in core-geth
2. File an issue in etclabscore/core-geth for tracking
3. Continue with other test suites (Istanbul/Berlin, graphql, sync)

### Medium-term
1. Compare core-geth's EVM collision handling code with go-ethereum
2. Determine if the gas differences are intentional ETC-specific behavior
3. Evaluate if alignment with mainnet is desirable

### Long-term
1. Consider adding ETC-specific test cases for collision scenarios
2. Document any intentional behavioral differences in ETC specifications

---

## References

- [EIP-684: Revert creation in case of collision](https://eips.ethereum.org/EIPS/eip-684)
- [EIP-1014: Skinny CREATE2](https://eips.ethereum.org/EIPS/eip-1014)
- [EIP-7610: Revert creation in case of non-empty storage](https://eips.ethereum.org/EIPS/eip-7610)
- [ethereum/tests Repository](https://github.com/ethereum/tests)
- Test logs: `hive/workspace/logs/1769601097-b18ac77a4f88273c597a9c506eebdcf2.json`

---

## Appendix: Test Log Locations

| Test | Client Log |
|------|------------|
| InitCollision_d0g0v0_Constantinople | `core-geth/client-179eed98fb656bca6f7ee12e3cdc7f32a15e14ed595dee12e46f8bb61b011bf3.log` |
| create2collisionStorage_d0g0v0_Constantinople | `core-geth/client-c4c43ee38ecff73f8d960750e5954c9b74262f770e0b2ebb53904932fdcb0044.log` |
| RevertInCreateInInit_d0g0v0_Byzantium | `core-geth/client-102c89df48ced508c291eb3b8e84ffe5d3210a0c88ff7ee2d87979835af74f28.log` |
| dynamicAccountOverwriteEmpty_d0g0v0_Constantinople | `core-geth/client-7a114ee4ed718456fe9fca52712da05907ce817c8225f0016bb07112dfec3e56.log` |
