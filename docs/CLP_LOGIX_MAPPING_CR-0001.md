# CLP → LOGIX Mapping (CR-0001)

## Source of Truth
- spec/conveyor_line_5zone.yaml
- tests/fat_sat_tests.yaml (behavioral authority)

---

## CCBP Posture
- Non-executable: produces DRAFT logic only.
- No silent escalation.
- No modification of safety tags.
- Authority remains human.
- Behavioral binding is test-defined (FAT/SAT is authoritative).

---

# A) Canonical Tags (from spec/tag_dictionary)

## Inputs (Permissives)
- xEStopOK : BOOL
- xLinePermExternal : BOOL

## Operator Commands
- xStartLine : BOOL
- xStopLine : BOOL
- xResetLine : BOOL
- xMaintReq : BOOL
- HOA.xHand / HOA.xOff / HOA.xAuto : BOOL
- Authority.xLocalSel / Authority.xRemoteSel : BOOL

## Section Feedback (each S01..S05)
- Sxx.xFbRunning : BOOL
- Sxx.xJamOK : BOOL
- Sxx.xPE_Entry : BOOL
- Sxx.xPE_Exit : BOOL

## Outputs (each S01..S05)
- Sxx.xCmdRun : BOOL

---

# B) Derived Control Bits (Controller Scoped)

- xLinePermissiveOK := xEStopOK AND xLinePermExternal
- xStopReq := xStopLine OR (NOT xLinePermissiveOK)
- xStartReq := xStartLine AND xLinePermissiveOK

---

# C) Sequencing (Spec-defined)

Start order (downstream-first):
[S05, S04, S03, S02, S01]

Stop order (upstream-first):
[S01, S02, S03, S04, S05]

NOTE:
Current FAT/SAT validates ordering intent, not timing fidelity.
Timer implementation (500ms start / 200ms stop) may be added after baseline validation.

---

# D) Jam Handling Policy (FAT/SAT Bound — NON-NEGOTIABLE)

Rule:
If zone k jams (Skk.xJamOK == FALSE):

- Stop zone k
- Stop all upstream zones (lower index)
- Downstream zones remain running (if permissives OK)

Example:
If S03.xJamOK == FALSE:
- S03.xCmdRun = FALSE
- S02.xCmdRun = FALSE
- S01.xCmdRun = FALSE
- S04.xCmdRun remains TRUE (if permissives OK)
- S05.xCmdRun remains TRUE (if permissives OK)

This behavior is REQUIRED by:
Jam_S03_StopsS03AndUpstreamOnly (FAT/SAT)

---

# E) Dominant Stop Conditions (Highest Priority)

1) If xEStopOK == FALSE:
   → ALL S01..S05.xCmdRun = FALSE immediately

2) If xLinePermExternal == FALSE:
   → ALL S01..S05.xCmdRun = FALSE

These override all sequencing logic.

---

# F) Output Command Computation Model

Each zone output must be computed as:

Skk.xCmdRun :=
    xLinePermissiveOK
    AND StartSequenceEnabledForZone(k)
    AND UpstreamJamAllowsZone(k)

Where:

UpstreamJamAllowsZone(k) :=
    TRUE for S05
    S05.xJamOK for S04
    S05.xJamOK AND S04.xJamOK for S03
    S05.xJamOK AND S04.xJamOK AND S03.xJamOK for S02
    S05.xJamOK AND S04.xJamOK AND S03.xJamOK AND S02.xJamOK for S01

This produces:
- Correct downstream-first start
- Correct jam-upstream-only stop
- Correct global permissive dominance

---

# G) HMI Policy (NO_AOI_INTERNALS)

HMI must bind only to public status tags.

Expose only:
- LineStatus.xPermissiveOK
- LineStatus.xRunning
- LineStatus.xFaulted
- LineStatus.xAnyJamFault
- SectionStatus.S01..S05 (xCmdRun, xFbRunning, xJamOK)

Do NOT expose:
- Internal step bits
- Timer members (.ACC, .PRE, .EN)
- AOI internal members



