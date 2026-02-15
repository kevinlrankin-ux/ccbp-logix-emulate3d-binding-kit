param(
  [string]$CrPath = "changes/CR-0001",
  [string]$ApprovedRelPath = "plc\approved\SIM-CR-0001_Approved.txt",
  [string]$OutDirRelPath = "plc\bindings\emulate3d",
  [int]$PermitHours = 168
)

$RepoRoot     = Get-Location
$Approved     = Join-Path $RepoRoot $ApprovedRelPath
$LabelPath    = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$SimStampPath = Join-Path $RepoRoot (Join-Path $CrPath "sim_stamp.yaml")
$EnvelopePath = Join-Path $RepoRoot (Join-Path $CrPath "envelope.yaml")

function Fail([string]$Msg) { Write-Host "SIM-BIND BLOCKED: $Msg" -ForegroundColor Red; exit 1 }

if (!(Test-Path $Approved))     { Fail "Missing SIM-approved artifact (run SIM-Promote.ps1)" }
if (!(Test-Path $LabelPath))    { Fail "Missing label_oh-01.json (run OH-01_Label.ps1)" }
if (!(Test-Path $SimStampPath)) { Fail "Missing sim_stamp.yaml (run SIM-Stamp.ps1)" }
if (!(Test-Path $EnvelopePath)) { Fail "Missing envelope.yaml" }

# ------------------------------------------------
# SIM GUARDRAIL: envelope must declare NO external impact
# ------------------------------------------------
$EnvText = Get-Content $EnvelopePath -Raw

# Accept either: external_impact: "NO" OR external_impact: NO
$NoImpactPattern = '(?ms)execution_gate:.*?external_impact:\s*("?NO"?)\s*$'
if ($EnvText -notmatch $NoImpactPattern) {
  Fail "Guardrail: execution_gate.external_impact is not NO. SIM-Bind refused."
}

# Verify SIM-stamp seals to label hash
$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
$StampText = Get-Content $SimStampPath -Raw
if ($StampText -notmatch [regex]::Escape($Hash)) {
  Fail "SIM-Stamp does not match OH-01 label hash. Re-run OH-01 then re-SIM-STAMP."
}

# Output directory
$OutDir = Join-Path $RepoRoot $OutDirRelPath
if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# Emit SIM binding manifest
$Manifest = @{
  binder = "Emulate3D"
  version = "v0.1"
  scope = "SIMULATION_ONLY"
  guardrail = @{
    required_external_impact = "NO"
    verified = $true
  }
  cr_path = $CrPath
  approved_artifact = $ApprovedRelPath
  sealed_structure_hash_sha256 = $Hash
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  placeholder_bindings = @{
    plc = @(
      @{ tag = "S01_xCmdRun"; comment = "SIM placeholder bind: zone 1 motor" },
      @{ tag = "S02_xCmdRun"; comment = "SIM placeholder bind: zone 2 motor" },
      @{ tag = "S03_xCmdRun"; comment = "SIM placeholder bind: zone 3 motor" },
      @{ tag = "S04_xCmdRun"; comment = "SIM placeholder bind: zone 4 motor" },
      @{ tag = "S05_xCmdRun"; comment = "SIM placeholder bind: zone 5 motor" }
    )
  }
}

$ManifestPath = Join-Path $OutDir "SIM_binding_manifest.json"
($Manifest | ConvertTo-Json -Depth 10) | Set-Content -Path $ManifestPath -Encoding UTF8

# Emit SIM run permit (derived, not extra approval)
$PermitId = "SIM-RUNPERMIT-EMULATE3D-" + (Get-Random -Minimum 100000 -Maximum 999999)
$NowUtc = (Get-Date).ToUniversalTime()
$ExpireUtc = if ($PermitHours -gt 0) { $NowUtc.AddHours($PermitHours).ToString("o") } else { "" }

$PermitLines = @()
$PermitLines += "sim_run_permit:"
$PermitLines += "  permit_id: ""$PermitId"""
$PermitLines += "  scope: ""SIMULATION_ONLY"""
$PermitLines += "  binder: ""Emulate3D"""
$PermitLines += "  derived_from: ""sim_stamp.yaml"""
$PermitLines += "  sealed_structure_hash_sha256: ""$Hash"""
$PermitLines += "  issued_utc: ""$($NowUtc.ToString("o"))"""
if ($PermitHours -gt 0) { $PermitLines += "  expires_utc: ""$ExpireUtc""" }
$PermitLines += "  guardrail_external_impact_required: ""NO"""
$PermitLines += "  notes: ""SIM binding manifest generation only. No PLC download. No external side effects."""
$PermitPath = Join-Path $OutDir "SIM_run_permit_emulate3d.yaml"
($PermitLines -join "`n") + "`n" | Set-Content -Path $PermitPath -Encoding UTF8

Write-Host "SIM-BIND OK (GUARDED):" -ForegroundColor Green
Write-Host "  plc\bindings\emulate3d\SIM_binding_manifest.json" -ForegroundColor Green
Write-Host "  plc\bindings\emulate3d\SIM_run_permit_emulate3d.yaml" -ForegroundColor Green
exit 0
