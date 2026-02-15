param(
  [string]$CrPath = "changes/CR-0001",
  [ValidateSet("SIM","REAL")] [string]$Scope = "SIM"
)

$RepoRoot = Get-Location
$Ledger   = Join-Path $RepoRoot "ledger\hash_registry.jsonl"
$LabelPath = Join-Path $RepoRoot (Join-Path $CrPath "label_oh-01.json")

if (!(Test-Path $LabelPath)) {
  Write-Host "BLOCKED: Missing label_oh-01.json at $CrPath" -ForegroundColor Red
  exit 1
}

$Label = Get-Content $LabelPath -Raw | ConvertFrom-Json
$Hash  = $Label.structure_hash_sha256

$StampPath = if ($Scope -eq "SIM") {
  Join-Path $RepoRoot (Join-Path $CrPath "sim_stamp.yaml")
} else {
  Join-Path $RepoRoot (Join-Path $CrPath "stamp.yaml")
}
$Stamped = Test-Path $StampPath

$Record = @{
  ts_utc = (Get-Date).ToUniversalTime().ToString("o")
  scope = $Scope
  cr_path = $CrPath
  structure_hash_sha256 = $Hash
  stamp_present = $Stamped
  stamp_path = if ($Stamped) { $StampPath } else { "" }
}

($Record | ConvertTo-Json -Compress) | Add-Content -Path $Ledger -Encoding UTF8
Write-Host "REGISTERED: $Hash ($Scope) -> ledger/hash_registry.jsonl" -ForegroundColor Green
exit 0
