param(
  [string]$CrPath = "changes/CR-0001"
)

$RepoRoot    = Get-Location
$Envelope    = Join-Path $RepoRoot (Join-Path $CrPath "envelope.yaml")
$Draft       = Join-Path $RepoRoot (Join-Path $CrPath "draft_ladder_candidate.txt")
$LabelPath   = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$SimStampPath= Join-Path $RepoRoot (Join-Path $CrPath "sim_stamp.yaml")

$ApprovedDir = Join-Path $RepoRoot "plc\approved"
$OutFile     = Join-Path $ApprovedDir "SIM-CR-0001_Approved.txt"

function Fail([string]$Msg) { Write-Host "SIM-PROMOTE BLOCKED: $Msg" -ForegroundColor Red; exit 1 }

if (!(Test-Path $Envelope))   { Fail "Missing envelope.yaml" }
if (!(Test-Path $Draft))      { Fail "Missing draft_ladder_candidate.txt" }
if (!(Test-Path $LabelPath))  { Fail "Missing label_oh-01.json (run OH-01_Label.ps1)" }
if (!(Test-Path $SimStampPath)){ Fail "Missing sim_stamp.yaml (run SIM-Stamp.ps1)" }

# Strict "Operational" check
$Env = Get-Content $Envelope -Raw
$OpTokens = @("ccbp_assertions:", "authority_boundary_statement:", "risk_flags:", "execution_gate:")
foreach ($t in $OpTokens) {
  if ($Env -notmatch [regex]::Escape($t)) { Fail "Not Operational: missing envelope section: $t" }
}

# Mirror-lock references required
$MustRef = @(
  "docs/CLP_LOGIX_MAPPING_CR-0001.md",
  "docs/TAG_BINDING_NORMALIZATION.md",
  "docs/CCBP_BEHAVIOR_CONTRACT_CR-0001.md",
  "changes/CR-0001/archon_questions.md"
)
foreach ($r in $MustRef) {
  if ($Env -notmatch [regex]::Escape($r)) { Fail "Not Operational: missing source_ref: $r" }
  $p = Join-Path $RepoRoot $r
  if (!(Test-Path $p)) { Fail "Not Operational: referenced mirror-lock file missing: $r" }
}

# Verify SIM-stamp seals to label hash
$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
$StampText = Get-Content $SimStampPath -Raw
if ($StampText -notmatch [regex]::Escape($Hash)) {
  Fail "SIM-Stamp does not match OH-01 label hash. Re-run OH-01 then re-SIM-STAMP."
}

if (!(Test-Path $ApprovedDir)) { New-Item -ItemType Directory -Path $ApprovedDir | Out-Null }
Copy-Item $Draft $OutFile -Force

Write-Host "SIM-PROMOTED: plc\approved\SIM-CR-0001_Approved.txt" -ForegroundColor Green
exit 0
