# Ledger Adapter Interface (Storage-Agnostic)

## Goal
Emit governance events in a canonical format, then write them to one or more backends
(JSONL always; CSV mirror optional; SQLite hooks optional; Anchors optional).

## Mode Dial
- LIGHT:
  - JSONL append (and optional CSV mirror)
  - Hash-chain is enabled by default but enforcement is soft (warn)
- ENTERPRISE:
  - JSONL append + CSV mirror
  - Hash-chain enforcement is strict (block on chain break)
  - Optional anchors (tail hash snapshots)
  - Optional SQLite hooks

## Event Fields (minimum)
- ts_utc
- scope: SIM | REAL
- event_type: LABEL | STAMP | PROMOTE | SIM_BIND | TRANSITION_AUDIT | CUSTOM
- cr_path
- structure_hash_sha256
- entry_hash_sha256
- prev_entry_hash_sha256 (nullable)

## Hash Chain
entry_hash_sha256 = SHA-256(canonical_json_without_entry_hash)
prev_entry_hash_sha256 = last event entry_hash_sha256 (same ledger)

## Backends
1) JSONL: ledger/hash_registry.jsonl (append-only)
2) CSV mirror: ledger/hash_registry.csv (for Excel/compliance teams)
3) SQLite: ledger/ledger.sqlite (optional)
4) Anchors: ledger/anchors/anchor_<UTC>.txt (optional tail hash snapshots)
