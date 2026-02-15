# Envelope State Contract
(Operationality, Labeling, Stamping, Promotion)

## Definitions

### Abstract (Read-only)
Envelope is Abstract if required CCBP invariants/structure are missing.
Not eligible for labeling, stamping, or promotion.

### Operational (CCBP-complete)
Envelope is Operational only if it contains, in required structure:
- Book I invariants
- Book II invariants
- Appendix A invariants
- Payload artifacts arranged to prevent drift ("locking mirrors" posture)

Operationality is a CCBP property.

### Labeled (OH-01 passed)
OH-01 ("Label") validates envelope + draft structure (anti-mimicry) and emits:
- label_oh-01.json
- structure_hash_sha256

Labeling is structural attestation, not authorization.

### Stamped (Human authorization; sealed)
Stamp is the human authorization event.
Stamp seals the envelope to the OH-01 structure hash.

### Promoted (Approved path)
Promotion moves draft artifacts into approved operational path only if:
Operational + Labeled + Stamped.

## Minimal State Machine
Abstract → Operational → Labeled → Stamped → Promoted
No skipping states.
