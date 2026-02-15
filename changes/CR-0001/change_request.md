\# CR-0001 — CLP Narrative Input (Deterministic)



\## Objective

Generate a DRAFT ladder logic candidate for the 5-zone conveyor system

defined in:



\- spec/conveyor\_line\_5zone.yaml

\- tests/fat\_sat\_tests.yaml



This draft must satisfy all defined FAT/SAT behavioral tests.



---



\## Authoritative Behavioral Requirements (Test-Bound)



1\. E-Stop Dominance  

&nbsp;  If xEStopOK == FALSE → ALL S01..S05 xCmdRun = FALSE immediately.



2\. Line Permissive Loss  

&nbsp;  If xLinePermExternal == FALSE → ALL S01..S05 xCmdRun = FALSE.



3\. Start Order  

&nbsp;  Downstream-first start sequence:

&nbsp;  \[S05\_DISCHARGE, S04\_ZONE4, S03\_ZONE3, S02\_ZONE2, S01\_INFEED]



4\. Jam Policy  

&nbsp;  If zone k jams:

&nbsp;  - Stop zone k

&nbsp;  - Stop all upstream zones

&nbsp;  - Downstream zones continue running (if permissives remain OK)



&nbsp;  Example:

&nbsp;  If S03\_xJamOK == FALSE:

&nbsp;  - S03,S02,S01 stop

&nbsp;  - S04,S05 remain running



---



\## Implementation Scope (CLP Guardrails Active)



The system MAY:

\- Generate candidate ladder rungs (XIC/XIO/OTE/OTL/OTU/TON only)

\- Propose derived control bits

\- Propose sequencing structure

\- Propose test-mapping annotations



The system MUST NOT:

\- Bypass safety logic

\- Modify safety tags

\- Force outputs

\- Escalate authority

\- Execute deployment

\- Modify spec or tests



---



\## Required Draft Output Artifact



The generated file must be written to:



changes/CR-0001/draft\_ladder\_candidate.txt



The draft must include:



1\. Tag list used

2\. Derived internal bits

3\. Rung-by-rung logic description (plain English)

4\. Mapping of each rung group to specific FAT/SAT tests

5\. Explicit jam-handling logic

6\. Explicit global-stop logic



No execution. No PLC download. No external side effects.



---



\## Reversibility



Rollback = revert spec file + revert draft artifacts.

Validation = re-run tests/fat\_sat\_tests.yaml in Emulate3D.



