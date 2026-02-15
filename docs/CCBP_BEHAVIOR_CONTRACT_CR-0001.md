\# CCBP Behavior Contract — CR-0001  

(Spec + FAT/SAT Bound)



This document defines the authoritative behavioral model for CR-0001.

All logic generation must satisfy tests/fat\_sat\_tests.yaml.



---



\# 1) Dominance Hierarchy (Highest Priority First)



1\. E-Stop Dominance  

&nbsp;  If xEStopOK == FALSE  

&nbsp;  → ALL S01..S05\_xCmdRun = FALSE immediately.



2\. Line Permissive Loss  

&nbsp;  If xLinePermExternal == FALSE  

&nbsp;  → ALL S01..S05\_xCmdRun = FALSE.



3\. Operator Stop  

&nbsp;  If xStopLine asserted  

&nbsp;  → Initiate stop sequence (upstream-first).



No sequencing logic may override items 1 or 2.



---



\# 2) Preconditions to Run



For any zone output to be TRUE:



\- xEStopOK == TRUE

\- xLinePermExternal == TRUE

\- Zone permitted by sequencing

\- Zone permitted by jam policy



---



\# 3) Start Sequencing (Downstream-First)



Configured start order (test-bound):



\[S05\_DISCHARGE, S04\_ZONE4, S03\_ZONE3, S02\_ZONE2, S01\_INFEED]



NOTE:

Spec defines 500ms inter-step delay.

Current FAT/SAT validates ordering intent only.

Timer fidelity may be added after baseline pass.



---



\# 4) Stop Sequencing (Upstream-First)



Configured stop order:



\[S01\_INFEED, S02\_ZONE2, S03\_ZONE3, S04\_ZONE4, S05\_DISCHARGE]



Spec defines 200ms inter-step delay.

Timing enforcement optional for CR-0001 baseline.



---



\# 5) Jam Policy (FAT/SAT Bound — Non-Negotiable)



If zone k jams (Skk\_xJamOK == FALSE):



\- Stop zone k

\- Stop all upstream zones (lower-numbered)

\- Downstream zones remain running if permissives remain TRUE



Example (from FAT/SAT):

If S03\_xJamOK == FALSE:

\- S03, S02, S01 → xCmdRun = FALSE

\- S04, S05 → remain TRUE (if permissives OK)



This behavior is REQUIRED by:

Jam\_S03\_StopsS03AndUpstreamOnly



---



\# 6) Output Computation Model



For each zone k:



Skk\_xCmdRun =

&nbsp;   xEStopOK

&nbsp;   AND xLinePermExternal

&nbsp;   AND StartSequenceAllows(k)

&nbsp;   AND UpstreamJamAllows(k)



Where:



UpstreamJamAllows(k) blocks the jammed zone and upstream only.



---



\# 7) Draft-Only Constraint



This contract defines expected behavior only.

It authorizes no execution, deployment, or real-world control action.

All outputs remain DRAFT until explicitly promoted under CCBP execution gate.



