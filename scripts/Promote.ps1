# ================================================================
# scripts/Promote.ps1
# STRICT Promote + SIM-ledger enforcement (when external_impact=YES)
# + Deterministic ledger append on successful promotion
# ================================================================

param(
  [string]$CrPath = "changes/CR-0001"
)

$RepoRoot    = (Get-Location).Path
$Envelope    = Join-Path $RepoRoot (Join-Path $CrPath "envelope.yaml")
$Draft       = Join-Path $RepoRoot (Join-Path $CrPath "draft_ladder_candidate.txt")
$LabelPath   = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$StampPath   = Join-Path $RepoRoot (Join-Path $CrPath "stamp.yaml")
$ApprovedDir = Join-Path $RepoRoot "plc\approved"
$LedgerPath  = Join-Path $RepoRoot "ledger\hash_registry.jsonl"

function Fail([string]$Msg) {
  Write-Host "PROMOTE BLOCKED: $Msg" -ForegroundColor Red
  exit 1
}

function Ensure-Ledger() {
  $LedgerDir = Join-Path $RepoRoot "ledger"
  if (!(Test-Path $LedgerDir)) { New-Item -ItemType Directory -Path $LedgerDir | Out-Null }
  if (!(Test-Path $LedgerPath)) { New-Item -ItemType File -Path $LedgerPath | Out-Null }
}

function Write-LedgerEvent(
  [string]$Scope,
  [string]$EventType,
  [string]$CrPathValue,
  [string]$HashValue,
  [string]$ApprovedPathValue
) {
  try {
    Ensure-Ledger
    $Rec = @{
      scope = $Scope
      event_type = $EventType
      ts_utc = (Get-Date).ToUniversalTime().ToString("o")
      cr_path = $CrPathValue
      structure_hash_sha256 = $HashValue
      approved_path = $ApprovedPathValue
      label_path = $LabelPath
      stamp_path = $StampPath
    }
    ($Rec | ConvertTo-Json -Compress) | Add-Content -Path $LedgerPath -Encoding UTF8
    Write-Host "LEDGER APPENDED: $LedgerPath" -ForegroundColor Cyan
  } catch {
    Write-Host ("LEDGER WARN: failed to append (" + $_.Exception.Message + ")") -ForegroundColor Yellow
  }
}

# ----------------------------
# Preconditions
# ----------------------------
if (!(Test-Path $Envelope))  { Fail "Missing envelope.yaml" }
if (!(Test-Path $Draft))     { Fail "Missing draft_ladder_candidate.txt" }
if (!(Test-Path $LabelPath)) { Fail "Missing label_oh-01.json (run OH-01_Label.ps1)" }
if (!(Test-Path $StampPath)) { Fail "Missing stamp.yaml (run Stamp.ps1)" }

# ----------------------------
# STRICT Operational check: envelope core governance sections must exist
# ----------------------------
$EnvText = Get-Content $Envelope -Raw
$OpTokens = @("ccbp_assertions:", "authority_boundary_statement:", "risk_flags:", "execution_gate:")
foreach ($t in $OpTokens) {
  if ($EnvText -notmatch [regex]::Escape($t)) {
    Fail "Not Operational: missing envelope section: $t"
  }
}

# ----------------------------
# Mirror-lock references required
# ----------------------------
$MustRef = @(
  "docs/CLP_LOGIX_MAPPING_CR-0001.md",
  "docs/TAG_BINDING_NORMALIZATION.md",
  "docs/CCBP_BEHAVIOR_CONTRACT_CR-0001.md",
  "changes/CR-0001/archon_questions.md"
)
foreach ($r in $MustRef) {
  if ($EnvText -notmatch [regex]::Escape($r)) { Fail "Not Operational: missing source_ref: $r" }
  $p = Join-Path $RepoRoot $r
  if (!(Test-Path $p)) { Fail "Not Operational: referenced mirror-lock file missing: $r" }
}

# ----------------------------
# Verify stamp seals to label hash
# ----------------------------
$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
if ([string]::IsNullOrWhiteSpace($Hash)) { Fail "label_oh-01.json missing structure_hash_sha256" }

$StampText = Get-Content $StampPath -Raw
if ($StampText -notmatch [regex]::Escape($Hash)) {
  Fail "Stamp does not match OH-01 label hash. Re-run OH-01 then re-stamp."
}

# ------------------------------------------------
# LEDGER SIM REQUIRED (REAL TRANSITION ENFORCEMENT)
# If envelope declares external_impact: YES, it MUST declare required_previous_sim_hash,
# and that hash MUST appear in ledger/hash_registry.jsonl with scope=SIM.
# ------------------------------------------------
if ($EnvText -match '(?m)^\s*external_impact\s*:\s*"?YES"?' ) {

  if (!(Test-Path $LedgerPath)) { Fail "Missing ledger/hash_registry.jsonl for REAL transition enforcement." }

  $m = [regex]::Match($EnvText,'(?m)^\s*required_previous_sim_hash\s*:\s*"?(.+?)"?\s*$')
  if (!$m.Success) { Fail "REAL transition requires required_previous_sim_hash in envelope.yaml" }
  $SimHash = $m.Groups[1].Value.Trim()

  $LedgerFoundSim = $false
  $LedgerLines = Get-Content $LedgerPath -ErrorAction SilentlyContinue
  foreach ($ln in $LedgerLines) {
    if ($ln -match [regex]::Escape($SimHash)) {
      if ($ln -match '"scope"\s*:\s*"SIM"' -or $ln -match '"scope":"SIM"') {
        $LedgerFoundSim = $true
        break
      }
    }
  }

  if (-not $LedgerFoundSim) {
    Fail "SIM hash not registered in ledger (scope=SIM). Run scripts/Register-Hash.ps1 -Scope SIM (or re-SIM-stamp with auto-ledger)."
  }
}

# ----------------------------
# Promote artifact
# ----------------------------
if (!(Test-Path $ApprovedDir)) { New-Item -ItemType Directory -Path $ApprovedDir | Out-Null }

$Out = Join-Path $ApprovedDir ("CR-0001_Approved.txt")
Copy-Item $Draft $Out -Force

# ----------------------------
# Ledger event (PROMOTE)
# ----------------------------
Write-LedgerEvent -Scope "REAL" -EventType "PROMOTE" -CrPathValue $CrPath -HashValue $Hash -ApprovedPathValue $Out

Write-Host "PROMOTED: $Out" -ForegroundColor Green
exit 0
