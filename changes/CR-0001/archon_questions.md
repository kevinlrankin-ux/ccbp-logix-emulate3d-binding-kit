\# Archon Questions — CR-0001 (Resolved by FAT/SAT Tests)



\## 1) Safe State Definition (NON-NEGOTIABLE)

Q1: When xEStopOK = FALSE, what is the required state of all Sxx.xCmdRun?

Answer: ALL OFF immediately.

Evidence: tests/fat\_sat\_tests.yaml :: Line\_EStopDominance\_AllOutputsOff



\## 2) Jam Behavior Policy (Resolved)

Q2: If any Sxx.xJamOK = FALSE, what stops?

Answer: Stop the jammed zone AND all upstream zones ONLY.

Downstream zones remain running.

Evidence: Jam\_S03\_StopsS03AndUpstreamOnly



\## 3) Mode/HOA Authority Priority

Q3: How do HOA/mode interact?

Answer: Defer to AOI\_ModeAuthority if implemented; otherwise HOA overrides.

Status: TBD (not covered by current tests)



\## 4) Start/Stop Commands Are Momentary or Maintained?

Q4: Are xStartLine and xStopLine momentary pushbuttons?

Answer: Assume momentary. (Not explicitly tested, but recommended standard.)



\## 5) External Permission Use (Resolved)

Q5: If xLinePermExternal drops while running, do we stop?

Answer: YES — stop all zones.

Evidence: LinePermissiveLoss\_StopsAll



\## 6) Restart After Fault

Q6: Must xResetLine be pressed after a jam/permissive fault clears before restart?

Answer: Recommended YES (not yet enforced by tests).

Status: TBD



\## 7) Sequencing Interlock

Q7: Require downstream feedback (xFbRunning) before starting upstream?

Answer: TBD (not yet enforced by tests).



\## Selected answers for CR-0001

\- Q2 = A

\- Q4 = momentary

\- Q6 = YES

\- Q7 = (pick: YES or NO)

