# Governance Mode Dial (LIGHT <-> ENTERPRISE)

Edit:
- governance/governance.settings.json

Set:
- governance_mode: "LIGHT" or "ENTERPRISE"

## LIGHT (Training)
- Keep it simple.
- Writes JSONL (and CSV mirror if enabled).
- Hash chain writes; enforcement = WARN (does not block).

## ENTERPRISE (Real compliance)
- JSONL + CSV mirror
- Hash chain enforcement = STRICT (blocks on chain break)
- Optional anchors for notarization (tail hash snapshots)
- Optional SQLite hooks for analytics & later “intellectualization”
