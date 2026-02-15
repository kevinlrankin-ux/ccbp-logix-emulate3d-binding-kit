# Demarcation Policy — SIM vs REAL

## Constitutional Switch
The demarcation line is:

execution_gate.external_impact

- NO  → SIM jurisdiction
- YES → REAL jurisdiction

## Non-Negotiable Rules

1. SIM artifacts must never deploy to physical systems.
2. REAL artifacts must reference validated SIM structure hash.
3. Prefixes (SIM-) never drop automatically.
4. Transition requires a new envelope and new STAMP.
5. REAL promotion requires SIM validation traceability.

## Lifecycle Summary

SIM → Validation → Transition Envelope → REAL STAMP → REAL Promotion

No automatic morphing.
No silent scope escalation.
No prefix stripping.

## Safety Rationale

This prevents:
- Simulation-to-production drift
- Audit ambiguity
- Governance bypass
- Deployment without validation
- Hash mismatch tampering

End of Policy
