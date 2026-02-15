param(
  [string]$CrPath = "changes/CR-0001"
)

$RepoRoot = Get-Location

$LabelPath    = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$SimStampPath = Join-Path $RepoRoot (Join-Path $CrPath "sim_stamp.yaml")
$SimApproved  = Join-Path $RepoRoot "plc\approved\SIM-CR-0001_Approved.txt"
$SimBindMan   = Join-Path $RepoRoot "plc\bindings\emulate3d\SIM_binding_manifest.json"
$SimPermit    = Join-Path $RepoRoot "plc\bindings\emulate3d\SIM_run_permit_emulate3d.yaml"

function Fail([string]$Msg) { Write-Host "SIM-SUMMARY BLOCKED: $Msg" -ForegroundColor Red; exit 1 }

if (!(Test-Path $LabelPath)) { Fail "Missing label_oh-01.json (run OH-01_Label.ps1)" }

$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
$Created = $Label.created_utc

$StampStatus = if (Test-Path $SimStampPath) { "PRESENT" } else { "NOT PRESENT" }
$ApprovedStatus = if (Test-Path $SimApproved) { "PRESENT" } else { "NOT PRESENT" }
$BindStatus = if (Test-Path $SimBindMan) { "PRESENT" } else { "NOT PRESENT" }
$PermitStatus = if (Test-Path $SimPermit) { "PRESENT" } else { "NOT PRESENT" }

$Approver = ""
$StampedUtc = ""
if ($StampStatus -eq "PRESENT") {
  $StampText = Get-Content $SimStampPath -Raw
  $Approver = ([regex]::Match($StampText,'approver:\s*"(.*?)"')).Groups[1].Value
  $StampedUtc = ([regex]::Match($StampText,'stamped_utc:\s*"(.*?)"')).Groups[1].Value
}

$OutPath = Join-Path $RepoRoot (Join-Path $CrPath "SIM_validation_summary.md")

$Lines = @()
$Lines += "# SIM Validation Summary"
$Lines += ""
$Lines += "CR Path: $CrPath"
$Lines += "Generated (UTC): $((Get-Date).ToUniversalTime().ToString('o'))"
$Lines += ""
$Lines += "## OH-01 Label"
$Lines += "- label_oh-01.json: PRESENT"
$Lines += "- Structure hash (SHA-256): **$Hash**"
$Lines += "- Label created (UTC): $Created"
$Lines += ""
$Lines += "## SIM Authorization"
$Lines += "- sim_stamp.yaml: **$StampStatus**"
if ($StampStatus -eq "PRESENT") {
  $Lines += "  - Approver: $Approver"
  $Lines += "  - Stamped (UTC): $StampedUtc"
}
$Lines += ""
$Lines += "## SIM Promotion + Binding Evidence"
$Lines += "- SIM approved artifact: **$ApprovedStatus** (plc/approved/SIM-CR-0001_Approved.txt)"
$Lines += "- SIM binding manifest: **$BindStatus** (plc/bindings/emulate3d/SIM_binding_manifest.json)"
$Lines += "- SIM run permit: **$PermitStatus** (plc/bindings/emulate3d/SIM_run_permit_emulate3d.yaml)"
$Lines += ""
$Lines += "## Transition Hook (CR-0002)"
$Lines += "- Set in changes/CR-0002_REALIZATION_REQUEST/envelope.yaml:"
$Lines += "  - execution_gate.external_impact: ""YES"""
$Lines += "  - required_previous_sim_hash: ""$Hash"""
$Lines += ""

($Lines -join "`n") + "`n" | Set-Content -Path $OutPath -Encoding UTF8

Write-Host "WROTE: $CrPath/SIM_validation_summary.md" -ForegroundColor Green
Write-Host "SIM HASH: $Hash" -ForegroundColor Cyan
exit 0
