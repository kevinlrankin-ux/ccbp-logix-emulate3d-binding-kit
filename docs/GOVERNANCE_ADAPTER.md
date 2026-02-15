# Governance Adapter (LIGHT ⇄ ENTERPRISE)

This repo uses a single adapter to emit compliance/governance events:

scripts/Write-GovEvent.ps1

## Radio dial
- Config: governance/governance.settings.json
- Set "mode" to:
  - "LIGHT": JSONL only (simple filesystem/excel-friendly)
  - "ENTERPRISE": JSONL + CSV mirror + enforcement hooks ready

## Outputs
- JSONL ledger: ledger/hash_registry.jsonl
- CSV mirror (enterprise): ledger/hash_registry.csv

## Example (manual emit)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Write-GovEvent.ps1 
  -Scope SIM -Event STAMP -CrPath changes/CR-0001 
  -StructureHashSha256 "abc..." -LabelPath "changes/CR-0001/label_oh-01.json" 
  -StampPath "changes/CR-0001/sim_stamp.yaml" -Approver "Kevin Rankin"

## Hook pattern (recommended)
Call the adapter after a lifecycle step succeeds:
- OH-01 label emitted → Event OH-01_LABEL
- Stamp written → Event STAMP
- Promote succeeded → Event PROMOTE / SIM_PROMOTE
- SIM bind succeeded → Event SIM_BIND
- Audit report written → Event AUDIT / TRANSITION_AUDIT
