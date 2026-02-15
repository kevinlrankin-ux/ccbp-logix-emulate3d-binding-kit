# Governance Event Schema (Adapter)

This repo emits governance events through a single adapter entrypoint:
scripts/Write-GovEvent.ps1

## Required fields (all modes)
- scope: "SIM" | "REAL"
- event: "OH-01_LABEL" | "STAMP" | "PROMOTE" | "SIM_PROMOTE" | "SIM_BIND" | "AUDIT" | "TRANSITION_AUDIT"
- ts_utc: ISO-8601 UTC timestamp
- cr_path: changes/CR-xxxx
- structure_hash_sha256: hash of the labeled structure (from label_oh-01.json) when available
- label_path: path to label_oh-01.json when available
- stamp_path: path to stamp yaml when available
- approver: human approver when available

## Optional fields
- notes: freeform string
- artifacts: array of related files
- external_impact: "NO" | "YES" (usually from transition envelope)
- required_previous_sim_hash: when external_impact is YES
- outcome: "OK" | "BLOCKED"

## Modes
### LIGHT
- Append JSONL to ledger/hash_registry.jsonl

### ENTERPRISE
- Append JSONL + mirror CSV row
- Provide enforcement hooks for SIM→REAL chain (no DB required yet)
- Optional SQLite/anchor hooks can be enabled later without changing lifecycle scripts
