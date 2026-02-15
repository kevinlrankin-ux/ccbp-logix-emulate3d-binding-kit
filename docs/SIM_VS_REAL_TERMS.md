# SIM vs REAL Lifecycle Terms — Cheat Sheet

## Purpose
This document clarifies terminology for simulation (sandbox) versus
real-world operational environments.

The verbs remain the same.
The prefix defines the environment.

---

# Core Principle

Same lifecycle.
Different scope.

- REAL = Physical / Production / External Impact Possible
- SIM  = Simulation / Sandbox / No Physical Deployment

---

# Lifecycle Vocabulary

| Phase        | REAL Term     | SIM Term        | Meaning |
|--------------|--------------|----------------|---------|
| Structure    | OH-01 Label  | OH-01 Label    | Structural hash validation |
| Authorization| STAMP        | SIM-STAMP      | Human approval event |
| Promotion    | PROMOTE      | SIM-PROMOTE    | Move to approved path |
| Binding      | BIND         | SIM-BIND       | Generate environment-specific artifact |

---

# What Changes?

Only the SCOPE.

REAL:
- May eventually connect to physical PLCs
- May influence real equipment
- Requires higher operational discipline

SIM:
- Emulate3D only
- No PLC download
- No external messaging
- No real-world side effects

---

# Artifact Naming Pattern

REAL:
- stamp.yaml
- plc/approved/CR-0001_Approved.txt
- binding_manifest.json

SIM:
- sim_stamp.yaml
- plc/approved/SIM-CR-0001_Approved.txt
- SIM_binding_manifest.json
- SIM_run_permit_emulate3d.yaml

Prefix = Environment Boundary

---

# Safety Model

STAMP is the only human authorization event.

SIM-STAMP does NOT duplicate approval.
It encodes scope limitation.

Both seal the envelope to the same OH-01 structure hash.

---

# Mental Model

Think of SIM as:

Training Mode.
Wind Tunnel.
Flight Simulator.

Same aircraft design.
Different consequences.

---

# Non-Negotiable Rule

If it says SIM — it must never:
- Download to PLC hardware
- Message external systems
- Affect physical equipment

If it says REAL — promotion path must reflect operational controls.

---

End of Document

---

## ASCII (Quick Reference)

        +-----------+
        |  Abstract |
        +-----------+
              |
              | (CCBP triad + mirror-lock present)
              v
      +----------------+
      |  Operational   |
      +----------------+
              |
              | (OH-01 Label passes; hash emitted)
              v
        +-----------+
        |  Labeled  |
        +-----------+
           /     \
          /       \
 SIM path /         \ REAL path
        v             v
 +--------------+   +-----------+
 | SIM-Stamped  |   | Stamped   |
 +--------------+   +-----------+
        |             |
        |             |
        v             v
 +--------------+   +-----------+
 | SIM-Promoted |   | Promoted  |
 +--------------+   +-----------+
        |             |
        |             |
        v             v
 +--------------+   +-----------+
 |  SIM-Bound   |   |   Bound   |
 +--------------+   +-----------+
