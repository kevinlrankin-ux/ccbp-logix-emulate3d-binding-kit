# SIM Validation Summary

CR Path: changes/CR-0001
Generated (UTC): 2026-02-14T21:44:01.9834928Z

## OH-01 Label
- label_oh-01.json: PRESENT
- Structure hash (SHA-256): **e087e397ee1ce88b9a20bc82f6dc46506e62e677ae6d844d88756535ae92f739**
- Label created (UTC): 2026-02-14T20:30:56.8213652Z

## SIM Authorization
- sim_stamp.yaml: **PRESENT**
  - Approver: Kevin Rankin
  - Stamped (UTC): 2026-02-14T20:31:13.6244219Z

## SIM Promotion + Binding Evidence
- SIM approved artifact: **PRESENT** (plc/approved/SIM-CR-0001_Approved.txt)
- SIM binding manifest: **PRESENT** (plc/bindings/emulate3d/SIM_binding_manifest.json)
- SIM run permit: **PRESENT** (plc/bindings/emulate3d/SIM_run_permit_emulate3d.yaml)

## Transition Hook (CR-0002)
- Set in changes/CR-0002_REALIZATION_REQUEST/envelope.yaml:
  - execution_gate.external_impact: "YES"
  - required_previous_sim_hash: "e087e397ee1ce88b9a20bc82f6dc46506e62e677ae6d844d88756535ae92f739"


