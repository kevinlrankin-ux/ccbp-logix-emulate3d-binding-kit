param(
  [string]$TransitionCrPath = "changes/CR-0002_REALIZATION_REQUEST"
)

$RepoRoot = Get-Location
$EnvPath  = Join-Path $RepoRoot (Join-Path $TransitionCrPath "envelope.yaml")
function Fail([string]$Msg) { Write-Host "AUDIT BLOCKED: $Msg" -ForegroundColor Red; exit 1 }

if (!(Test-Path $EnvPath)) { Fail "Missing transition envelope.yaml" }

$Env = Get-Content $EnvPath -Raw
if ($Env -notmatch 'external_impact:\s*"?YES"?' ) { Fail "external_impact must be YES" }

$Match = [regex]::Match($Env,'required_previous_sim_hash:\s*"?(.+?)"?')
if (!$Match.Success) { Fail "required_previous_sim_hash missing" }

$SimHash = $Match.Groups[1].Value.Trim()

$LabelHits = @()
Get-ChildItem -Path $RepoRoot -Recurse -Filter "label_oh-01.json" | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  if ($t -match [regex]::Escape($SimHash)) { $LabelHits += $_.FullName }
}

$HashFound = ($LabelHits.Count -gt 0)

$SimSummary = Join-Path $RepoRoot "changes\CR-0001\SIM_validation_summary.md"
$SimBindMan = Join-Path $RepoRoot "plc\bindings\emulate3d\SIM_binding_manifest.json"
$SimPermit  = Join-Path $RepoRoot "plc\bindings\emulate3d\SIM_run_permit_emulate3d.yaml"

$OutPath = Join-Path $RepoRoot (Join-Path $TransitionCrPath "transition_audit_report.md")

$Lines = @()
$Lines += "# Transition Audit Report (SIM → REAL)"
$Lines += ""
$Lines += "Generated (UTC): $((Get-Date).ToUniversalTime().ToString('o'))"
$Lines += "Transition CR Path: $TransitionCrPath"
$Lines += ""
$Lines += "## Required SIM Hash"
$Lines += "- required_previous_sim_hash: **$SimHash**"
$Lines += "- Found in repo labels: **$HashFound**"
if ($HashFound) {
  $Lines += "- Matching label files:"
  foreach ($h in $LabelHits) { $Lines += "  - $h" }
} else {
  $Lines += "- Matching label files: NONE"
}
$Lines += ""
$Lines += "## Evidence Pack Presence"
$Lines += "- SIM validation summary present: " + (Test-Path $SimSummary)
$Lines += "- SIM binding manifest present: " + (Test-Path $SimBindMan)
$Lines += "- SIM run permit present: " + (Test-Path $SimPermit)
$Lines += ""
$Lines += "## Decision"
if ($HashFound) {
  $Lines += "- Transition is traceable to a SIM hash. REAL governance may proceed."
} else {
  $Lines += "- BLOCK: Fix required_previous_sim_hash or ensure SIM label evidence exists."
}
$Lines += ""

($Lines -join "`n") + "`n" | Set-Content -Path $OutPath -Encoding UTF8
Write-Host "WROTE: $TransitionCrPath/transition_audit_report.md" -ForegroundColor Green
exit 0


# ---------------------------
# LEDGER CHECK (HARDENING)
# ---------------------------
$LedgerPath = Join-Path $RepoRoot "ledger\hash_registry.jsonl"
$LedgerFoundSim = $false
if (Test-Path $LedgerPath) {
  $LedgerLines = Get-Content $LedgerPath -ErrorAction SilentlyContinue
  foreach ($ln in $LedgerLines) {
    if ($ln -match [regex]::Escape($SimHash)) {
      if ($ln -match '"scope":"SIM"' -or $ln -match '"scope"\s*:\s*"SIM"') {
        $LedgerFoundSim = $true
        break
      }
    }
  }
}

$Lines += ""
$Lines += "## Ledger Check (HARDENING)"
$Lines += "- ledger/hash_registry.jsonl present: " + (Test-Path $LedgerPath)
$Lines += "- SIM hash registered in ledger (scope=SIM): **$LedgerFoundSim**"

if (-not $LedgerFoundSim) {
  $Lines += "- BLOCK: Transition hash must be registered in ledger as SIM before REAL progression."
}
# LEDGER CHECK
