# ================================================================
# scripts/SIM-Promote.ps1
# STRICT SIM-Promote (Operational + mirror-lock + SIM-stamp hash)
# + Deterministic ledger append on successful SIM promotion
# ================================================================

param(
  [string]$CrPath = "changes/CR-0001"
)

$RepoRoot     = (Get-Location).Path
$Envelope     = Join-Path $RepoRoot (Join-Path $CrPath "envelope.yaml")
$Draft        = Join-Path $RepoRoot (Join-Path $CrPath "draft_ladder_candidate.txt")
$LabelPath    = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$SimStampPath = Join-Path $RepoRoot (Join-Path $CrPath "sim_stamp.yaml")

$ApprovedDir  = Join-Path $RepoRoot "plc\approved"
$OutFile      = Join-Path $ApprovedDir "SIM-CR-0001_Approved.txt"

$LedgerPath   = Join-Path $RepoRoot "ledger\hash_registry.jsonl"

function Fail([string]$Msg) {
  Write-Host "SIM-PROMOTE BLOCKED: $Msg" -ForegroundColor Red
  exit 1
}

function Ensure-Ledger() {
  $LedgerDir = Join-Path $RepoRoot "ledger"
  if (!(Test-Path $LedgerDir)) { New-Item -ItemType Directory -Path $LedgerDir | Out-Null }
  if (!(Test-Path $LedgerPath)) { New-Item -ItemType File -Path $LedgerPath | Out-Null }
}

function Write-LedgerEvent(
  [string]$EventType,
  [string]$CrPathValue,
  [string]$HashValue,
  [string]$ApprovedPathValue
) {
  try {
    Ensure-Ledger
    $Rec = @{
      scope = "SIM"
      event_type = $EventType
      ts_utc = (Get-Date).ToUniversalTime().ToString("o")
      cr_path = $CrPathValue
      structure_hash_sha256 = $HashValue
      approved_path = $ApprovedPathValue
      label_path = $LabelPath
      sim_stamp_path = $SimStampPath
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
if (!(Test-Path $Envelope))     { Fail "Missing envelope.yaml" }
if (!(Test-Path $Draft))        { Fail "Missing draft_ladder_candidate.txt" }
if (!(Test-Path $LabelPath))    { Fail "Missing label_oh-01.json (run OH-01_Label.ps1)" }
if (!(Test-Path $SimStampPath)) { Fail "Missing sim_stamp.yaml (run SIM-Stamp.ps1)" }

# ----------------------------
# Strict "Operational" check
# ----------------------------
$EnvText = Get-Content $Envelope -Raw
$OpTokens = @("ccbp_assertions:", "authority_boundary_statement:", "risk_flags:", "execution_gate:")
foreach ($t in $OpTokens) {
  if ($EnvText -notmatch [regex]::Escape($t)) { Fail "Not Operational: missing envelope section: $t" }
}

# Optional safety: SIM paths should never declare external impact
# (Primary enforcement is in SIM-Bind; this is a belt-and-suspenders check.)
if ($EnvText -match '(?m)^\s*external_impact\s*:\s*"?YES"?' ) {
  Fail "SIM-Promote refuses: envelope declares external_impact=YES (SIM artifacts must remain non-external)."
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
# Verify SIM-stamp seals to label hash
# ----------------------------
$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
if ([string]::IsNullOrWhiteSpace($Hash)) { Fail "label_oh-01.json missing structure_hash_sha256" }

$StampText = Get-Content $SimStampPath -Raw
if ($StampText -notmatch [regex]::Escape($Hash)) {
  Fail "SIM-Stamp does not match OH-01 label hash. Re-run OH-01 then re-SIM-STAMP."
}

# ----------------------------
# Promote SIM approved artifact
# ----------------------------
if (!(Test-Path $ApprovedDir)) { New-Item -ItemType Directory -Path $ApprovedDir | Out-Null }
Copy-Item $Draft $OutFile -Force

# ----------------------------
# Ledger event (SIM-PROMOTE)
# ----------------------------
Write-LedgerEvent -EventType "SIM-PROMOTE" -CrPathValue $CrPath -HashValue $Hash -ApprovedPathValue $OutFile

Write-Host "SIM-PROMOTED: plc\approved\SIM-CR-0001_Approved.txt" -ForegroundColor Green
exit 0
