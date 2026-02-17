<!-- DISCORD SUMMARY (paste everything between the markers) -->
### Nethermind ETC Plugin: TypeDiscovery Conflict Fix

**Change:** 1 line in 1 file

The plugin's base class (`EthashChainSpecEngineParametersBase`) implements `IChainSpecEngineParameters` with `EngineName => "Ethash"`. Nethermind already has a built-in class with the same interface and engine name. When both are loaded, startup fails.

### The Problem

Nethermind's `TypeDiscovery` scans **all loaded assemblies** for concrete `IChainSpecEngineParameters` classes, then instantiates every one via `Activator.CreateInstance()` — before checking which matches the chainspec.

```
Built-in:  EthashChainSpecEngineParameters    → "Ethash"
Plugin:    EthashChainSpecEngineParametersBase → "Ethash"   ← CONFLICT
Plugin:    EtchashChainSpecEngineParameters    → "Etchash"  ← OK
```

Two classes with `"Ethash"` → **"Multiple seal engines"** error at startup.

### The Fix

Remove `: IChainSpecEngineParameters` from the base class:

```diff
-public class EthashChainSpecEngineParametersBase : IChainSpecEngineParameters
+public class EthashChainSpecEngineParametersBase
```

`EtchashChainSpecEngineParameters` still explicitly implements the interface. The base class keeps its methods as `virtual` methods callable via `base.Method()`. TypeDiscovery now only finds the Etchash engine.

### Why It May Not Always Reproduce

The error only occurs when the plugin DLL is loaded into a Nethermind build that **includes** the built-in `Nethermind.Consensus.Ethash` assembly. Testing with a custom build that excludes the Ethash module would not trigger it.

**Fork:** <https://github.com/IstoraMandiri/nethermind-etc-plugin>
**Full report:** <https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260217_NETHERMIND_PLUGIN_FORK.md>
<!-- END DISCORD SUMMARY -->

---

# Nethermind ETC Plugin: TypeDiscovery Conflict Fix

**Date:** 2026-02-17
**Plugin:** [ETCCooperative/nethermind-etc-plugin](https://github.com/ETCCooperative/nethermind-etc-plugin)
**Fork:** [IstoraMandiri/nethermind-etc-plugin](https://github.com/IstoraMandiri/nethermind-etc-plugin)
**Fork commit:** `bc99146` (1 commit ahead of upstream `37c5275`)

## Executive Summary

The upstream `nethermind-etc-plugin` contains a base class (`EthashChainSpecEngineParametersBase`) that implements `IChainSpecEngineParameters` with `EngineName => "Ethash"`. When loaded as a plugin into a standard Nethermind build, this conflicts with Nethermind's built-in `EthashChainSpecEngineParameters` (same interface, same engine name), causing a "Multiple seal engines in chain spec" startup error. The fix removes the interface from the base class — a single-line change with no behavioral impact on the derived Etchash engine.

## Context

The ETC plugin provides Etchash consensus support for Nethermind. It uses an inheritance pattern where:

- `EthashChainSpecEngineParametersBase` — a standalone copy of Nethermind's Ethash chain spec logic (to avoid a dependency on `Nethermind.Consensus.Ethash`)
- `EtchashChainSpecEngineParameters` — extends the base class with ETC-specific parameters (ECIP-1099, Spiral fork transitions, ECIP-1017 era rounds, etc.)

The upstream plugin was designed as a standalone project and both classes implement `IChainSpecEngineParameters`. This works in isolation but creates a conflict when loaded alongside Nethermind's own Ethash implementation.

## Detailed Findings

### Nethermind's Type Discovery Mechanism

Nethermind uses reflection-based type discovery at startup:

1. `TypeDiscovery.FindNethermindBasedTypes(typeof(IChainSpecEngineParameters))` scans **all loaded assemblies** (including plugin DLLs from `plugins/`) for concrete classes implementing `IChainSpecEngineParameters`
2. `InitializeInstances()` calls `Activator.CreateInstance()` on **every** discovered type
3. Only after instantiation does it check which engine matches the chainspec

### The Conflict

When the plugin DLL is loaded into a standard Nethermind build:

| Source | Class | EngineName | Result |
|--------|-------|------------|--------|
| Nethermind built-in | `EthashChainSpecEngineParameters` | `"Ethash"` | Discovered |
| Plugin (upstream) | `EthashChainSpecEngineParametersBase` | `"Ethash"` | Discovered — **DUPLICATE** |
| Plugin | `EtchashChainSpecEngineParameters` | `"Etchash"` | Discovered — OK |

Two classes with `EngineName "Ethash"` triggers a hard error during initialization.

### The Fix (1 line, 1 file)

**File:** `src/Nethermind.EthereumClassic/EthashChainSpecEngineParametersBase.cs`

```diff
-public class EthashChainSpecEngineParametersBase : IChainSpecEngineParameters
+public class EthashChainSpecEngineParametersBase
```

**Why this works:**
- `EtchashChainSpecEngineParameters` uses **explicit interface implementation** (`void IChainSpecEngineParameters.ApplyToReleaseSpec(...)`) which directly satisfies the interface contract without relying on the base class
- The base class methods remain as regular `public virtual` methods, still callable via `base.Method()` from the derived class
- TypeDiscovery no longer sees the base class, only the Etchash engine

**Why `abstract` was not used:** Making the base class `abstract` was also considered. However, Nethermind's TypeDiscovery still attempts to instantiate abstract classes (and fails with an error). Removing the interface entirely is cleaner — the class is removed from discovery altogether.

### Alternatives Considered

| Approach | Outcome |
|----------|---------|
| Make base class `abstract` | TypeDiscovery still tries to instantiate it → error |
| Add `[SkipTypeDiscovery]` attribute | No such attribute exists in Nethermind |
| Remove base class entirely | Would require duplicating all Ethash logic in `EtchashChainSpecEngineParameters` |
| **Remove interface from base class** | **Clean fix — base class invisible to TypeDiscovery** |

## Reproducibility

The error **only occurs** when the plugin is loaded into a Nethermind build that includes `Nethermind.Consensus.Ethash`. This is the standard configuration — the Ethash consensus module ships with all Nethermind releases.

If testing with a custom Nethermind build that excludes the Ethash module (e.g., a build specifically for ETC that removes ETH consensus), the conflict would not appear. This may explain why the issue was not encountered during upstream development.

## Impact Assessment

**Low severity, high importance for deployment.** The plugin cannot be loaded into a standard Nethermind build without this fix. The change is minimal (1 line) and has no behavioral impact on the Etchash engine or any ETC-specific logic.

## Test Results After Fix

After applying this fix in the Hive testing framework:

| Test Category | Result |
|--------------|--------|
| Smoke/genesis tests | 6/6 pass |
| bcValidBlockTest | 166/167 pass |
| Full consensus-etc suite | 61,098/61,328 pass (99.62%) |

The 230 failures in the full suite are unrelated to this fix — they are systematic issues with chain reorg handling, precompile edge cases, and Istanbul/Berlin-specific behavior in Nethermind's ETC implementation.

## Recommendation

This single-line change should be merged upstream into `ETCCooperative/nethermind-etc-plugin`. It:
- Fixes a real deployment issue with standard Nethermind builds
- Has zero behavioral impact on ETC functionality
- Is the minimal correct fix for Nethermind's TypeDiscovery architecture

## References

- [Nethermind TypeDiscovery source](https://github.com/NethermindEth/nethermind/blob/master/src/Nethermind/Nethermind.Core/TypeDiscovery.cs)
- [Fork commit bc99146](https://github.com/IstoraMandiri/nethermind-etc-plugin/commit/bc99146)
- [Upstream repo](https://github.com/ETCCooperative/nethermind-etc-plugin)
- [Hive consensus-etc test results](https://github.com/IstoraMandiri/etc-nexus/blob/main/reports/260214_CONSENSUS_ETC_FINAL.md)
