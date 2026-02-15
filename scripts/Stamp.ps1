param(
  [string]$CrPath = "changes/CR-0001",
  [string]$Approver = "Kevin Rankin"
)

$RepoRoot  = Get-Location
$LabelPath = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")
$StampName = if ("REAL" -eq "SIM") { "sim_stamp.yaml" } else { "stamp.yaml" }
$StampPath = Join-Path $RepoRoot (Join-Path $CrPath $StampName)

function Fail([string]$Msg) { Write-Host "STAMP BLOCKED: $Msg" -ForegroundColor Red; exit 1 }

if (!(Test-Path $LabelPath)) { Fail "Missing label_oh-01.json (run scripts/OH-01_Label.ps1 first) :: $LabelPath" }

$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256
if ([string]::IsNullOrWhiteSpace($Hash)) { Fail "label_oh-01.json missing structure_hash_sha256" }

$Confirm = Read-Host "Type STAMP to authorize and seal (REAL) envelope at hash $Hash"
if ($Confirm -ne "STAMP") {
  Write-Host "Stamp cancelled." -ForegroundColor Yellow
  exit 1
}

# ----------------------------
# Write stamp YAML
# ----------------------------
$Yaml = @()
$Yaml += "stamp:"
$Yaml += "  scope: ""REAL"""
$Yaml += "  approver: ""$Approver"""
$Yaml += "  cr_path: ""$CrPath"""
$Yaml += "  oh_step: ""OH-01"""
$Yaml += "  sealed_structure_hash_sha256: ""$Hash"""
$Yaml += "  stamped_utc: ""$((Get-Date).ToUniversalTime().ToString("o"))"""
($Yaml -join "
") + "
" | Set-Content -Path $StampPath -Encoding UTF8

Write-Host "STAMPED: $StampPath" -ForegroundColor Green

# ----------------------------
# AUTO LEDGER APPEND (JSONL)
# ----------------------------
try {
  $LedgerDir  = Join-Path $RepoRoot "ledger"
  if (!(Test-Path $LedgerDir)) { New-Item -ItemType Directory -Path $LedgerDir | Out-Null }
  $LedgerPath = Join-Path $LedgerDir "hash_registry.jsonl"
  if (!(Test-Path $LedgerPath)) { New-Item -ItemType File -Path $LedgerPath | Out-Null }

  $Rec = @{
    scope = "REAL"
    ts_utc = (Get-Date).ToUniversalTime().ToString("o")
    cr_path = "$CrPath"
    structure_hash_sha256 = "$Hash"
    approver = "$Approver"
    label_path = "$LabelPath"
    stamp_path = "$StampPath"
  }

  ($Rec | ConvertTo-Json -Compress) | Add-Content -Path $LedgerPath -Encoding UTF8
  Write-Host "LEDGER APPENDED: $LedgerPath" -ForegroundColor Cyan
} catch {
  Write-Host ("LEDGER WARN: failed to append (" + $_.Exception.Message + ")") -ForegroundColor Yellow
}

exit 0
