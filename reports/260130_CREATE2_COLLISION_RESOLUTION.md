# CREATE2 Collision Test Failures: Resolution

<!-- DISCORD SUMMARY (paste everything between the markers) -->
## CREATE2 Test Failures: Resolved (EIP-7610 Edge Case)

**Client:** core-geth v1.12.21 | **Failed:** 21/32,616 tests (99.94% pass)

The 21 CREATE2 collision test failures have been investigated and are **safe to exclude** from ETC testing. These tests target EIP-7610 behavior for "ghost accounts" - a computationally infeasible attack vector.

### Root Cause

```
EIP-7610: Reject contract creation if storage is non-empty
- Targets pre-EIP-161 "ghost accounts" (nonce=0, code=0, storage!=0)
- Only 28 such accounts exist on ETH mainnet
- Exploiting requires keccak256 preimage attack (~$10B+ cost)
```

### Failed Tests (all EIP-7610 related)

```
InitCollision (8)           - stSStoreTest
create2collisionStorage (6) - stCreate2
RevertInCreateInInit* (5)   - stCreate2/stRevertTest
dynamicAccountOverwrite (2) - stExtCodeHash
```

### Resolution

**Status:** Known behavioral difference - exclude from ETC test suite

**Why safe:**
1. Attack requires finding keccak256 collision - computationally infeasible
2. EIP-7610 not yet activated on ETH mainnet (Erigon implementation issues)
3. May be added to future ETC hardfork for consistency

### References
- go-ethereum PR #28912: <https://github.com/ethereum/go-ethereum/pull/28912>
- holiman's test list: <https://github.com/ethereum/go-ethereum/pull/28912#issuecomment-1923769557>

**Full report:** <https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260130_CREATE2_COLLISION_RESOLUTION.md>
<!-- END DISCORD SUMMARY -->

---

# Full Report

**Date:** 2026-01-30
**Related Report:** [CREATE2 Collision Test Failures Analysis](260130_CREATE2_COLLISION_FAILURES.md)
**Investigated by:** diegoll (core-geth maintainer)

## Summary

The 21 CREATE2 collision test failures identified in our Hive consensus testing have been investigated by the core-geth maintainer. These failures are related to **EIP-7610** ("Revert creation in case of non-empty storage") and represent a known behavioral difference that is:

1. **Safe to exclude** from ETC testing
2. **Computationally infeasible** to exploit in practice
3. **Not yet activated** on Ethereum mainnet

## Investigation Timeline

### Initial Finding (2026-01-28)

Running `ethereum/consensus --sim.limit legacy` against core-geth revealed 21 test failures out of 32,616 tests (99.94% pass rate). All failures related to CREATE2 collision handling.

### Developer Investigation (2026-01-29)

The core-geth maintainer (diegoll) investigated and identified the root cause:

> "This is good and I'm relieved... [EIP-7610] formalizes a behavior for a very specific edge case involving pre-EIP-161 'ghost accounts' (28 exist on ETH mainnet with nonce=0, code=0, but storage≠0). Exploiting this would require deploying a contract at one of those specific addresses, which would need a preimage attack on keccak256. Computationally infeasible."

### Key References

1. **go-ethereum PR #28666** - Initial attempt to remove account reset operation
   - Discussion revealed the complexity of handling pre-existing accounts with storage
   - Closed in favor of PR #28912

2. **go-ethereum PR #28912** - EIP-7610 implementation (merged April 2024)
   - Implements "reject contract deployment if destination has non-empty storage"
   - holiman's comment lists exact tests affected (matches our failures)

## Technical Analysis

### What is EIP-7610?

EIP-7610 extends EIP-684 (collision protection) to handle a specific edge case:

| Scenario | EIP-684 | EIP-7610 |
|----------|---------|----------|
| Account has nonzero nonce | Reject | Reject |
| Account has nonzero code | Reject | Reject |
| Account has nonzero storage (but nonce=0, code=0) | **Allow** | **Reject** |

### "Ghost Accounts" Explained

Pre-EIP-161 (Spurious Dragon), accounts could exist with:
- `nonce = 0`
- `code = empty`
- `storage ≠ empty`

These "ghost accounts" are artifacts of historical contract interactions before state cleanup rules were tightened. Only **28 such accounts** exist on Ethereum mainnet.

### Attack Feasibility

To exploit this edge case, an attacker would need to:

1. Find a CREATE2 salt that produces one of the 28 ghost account addresses
2. This requires finding a keccak256 preimage - a 160-bit hash collision
3. Estimated cost: **~$10 billion** (per go-ethereum PR discussion)
4. Conclusion: **Computationally infeasible**

## Failed Tests Mapping

All 21 failing tests match exactly with holiman's list in PR #28912:

| Test File | Category | Count |
|-----------|----------|-------|
| `stSStoreTest/InitCollision.json` | Storage collision | 8 |
| `stCreate2/create2collisionStorage.json` | CREATE2 with storage | 6 |
| `stCreate2/RevertInCreateInInitCreate2.json` | Revert in init | 2 |
| `stRevertTest/RevertInCreateInInit.json` | Revert in init | 3 |
| `stExtCodeHash/dynamicAccountOverwriteEmpty.json` | Dynamic overwrite | 2 |
| **Total** | | **21** |

## Resolution

### For ETC Test Suite

These tests should be **excluded** from the ETC-specific Hive test suite with documentation explaining:

1. Tests target EIP-7610 behavior not yet activated on any network
2. Edge case is computationally infeasible to exploit
3. Tests will be re-added if/when EIP-7610 is adopted by ETC

### For Future ETC Hardforks

EIP-7610 could be considered for a future ETC hardfork for consistency, but:

> "For an upcoming hard fork, if we are adding ECIP-1120, I would say that it should only have that to minimize uncertainties. ECIP-1120 and any other ECIP that this one needs (like the system contract)." - diegoll

### Implementation Status

| Network | EIP-7610 Status |
|---------|-----------------|
| Ethereum Mainnet | Not activated (Erigon implementation issues) |
| Ethereum Classic | Not adopted |
| go-ethereum | Implemented in PR #28912 |
| core-geth | Follows pre-EIP-7610 behavior |

## Recommendations

### Immediate

1. ✅ Document as known behavioral difference (this report)
2. Create ETC-specific test exclusion list in Hive fork
3. Continue with other test suites without blocking on these failures

### Medium-term

1. Track EIP-7610 activation on Ethereum mainnet
2. Evaluate inclusion in future ETC hardfork (post-ECIP-1120)
3. Re-add tests to suite if/when EIP-7610 is adopted

### Long-term

1. Maintain alignment documentation between ETC and ETH specifications
2. Consider formalizing ETC's position on edge-case EIPs

## References

- [EIP-7610: Revert creation in case of non-empty storage](https://eips.ethereum.org/EIPS/eip-7610)
- [EIP-684: Revert creation in case of collision](https://eips.ethereum.org/EIPS/eip-684)
- [go-ethereum PR #28912: EIP-7610 implementation](https://github.com/ethereum/go-ethereum/pull/28912)
- [go-ethereum PR #28666: Account reset discussion](https://github.com/ethereum/go-ethereum/pull/28666)
- [holiman's test list comment](https://github.com/ethereum/go-ethereum/pull/28912#issuecomment-1923769557)
- [Original failure analysis](260130_CREATE2_COLLISION_FAILURES.md)

## Appendix: Discord Discussion Summary

Key quotes from the core-geth maintainer investigation:

> "EIP-7610 formalizes a behavior for a very specific edge case involving pre-EIP-161 'ghost accounts' (28 exist on ETH mainnet with nonce=0, code=0, but storage≠0). Exploiting this would require deploying a contract at one of those specific addresses, which would need a preimage attack on keccak256. Computationally infeasible."

> "We could eventually add that EIP for consistency but it has not even been added into ETH yet. I think that's b/c Erigon had some problems implementing it."

> "For an upcoming hard fork, if we are adding ECIP-1120, I would say that it should only have that to minimize uncertainties."
