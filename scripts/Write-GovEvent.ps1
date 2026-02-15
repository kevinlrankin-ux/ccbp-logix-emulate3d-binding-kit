param(
  [Parameter(Mandatory=$true)][ValidateSet("SIM","REAL")] [string]$Scope,
  [Parameter(Mandatory=$true)][string]$Event,
  [Parameter(Mandatory=$true)][string]$CrPath,

  [string]$StructureHashSha256 = "",
  [string]$LabelPath = "",
  [string]$StampPath = "",
  [string]$Approver = "",

  [string]$ExternalImpact = "",
  [string]$RequiredPreviousSimHash = "",

  [string]$Outcome = "OK",
  [string]$Notes = "",
  [string[]]$Artifacts = @()
)

$RepoRoot = Get-Location

function Fail([string]$Msg) {
  Write-Host "GOV-ADAPTER BLOCKED: $Msg" -ForegroundColor Red
  exit 1
}

# Load settings
$SettingsFile = Join-Path $RepoRoot "governance\governance.settings.json"
if (!(Test-Path $SettingsFile)) { Fail "Missing governance settings: $SettingsFile (run installer)" }
$Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

$Mode = ($Settings.mode + "").ToUpperInvariant()
if ($Mode -ne "LIGHT" -and $Mode -ne "ENTERPRISE") { Fail "Invalid mode in settings: $($Settings.mode)" }

# Ledger paths (repo-relative)
$JsonlRel = $Settings.ledger.jsonl_path
$CsvRel   = $Settings.ledger.csv_mirror_path
$Jsonl    = Join-Path $RepoRoot $JsonlRel
$Csv      = Join-Path $RepoRoot $CsvRel

# Ensure ledger exists
$LedgerDir = Split-Path $Jsonl -Parent
if (!(Test-Path $LedgerDir)) { New-Item -ItemType Directory -Path $LedgerDir | Out-Null }
if (!(Test-Path $Jsonl)) { New-Item -ItemType File -Path $Jsonl | Out-Null }

# Construct record
$Rec = [ordered]@{
  scope = $Scope
  event = $Event
  ts_utc = (Get-Date).ToUniversalTime().ToString("o")
  cr_path = $CrPath

  structure_hash_sha256 = $StructureHashSha256
  label_path = $LabelPath
  stamp_path = $StampPath
  approver = $Approver

  external_impact = $ExternalImpact
  required_previous_sim_hash = $RequiredPreviousSimHash

  outcome = $Outcome
  notes = $Notes
  artifacts = $Artifacts
}

# Append JSONL
($Rec | ConvertTo-Json -Compress) | Add-Content -Path $Jsonl -Encoding UTF8

# ENTERPRISE: CSV mirror (optional)
$DoCsv = $false
if ($Mode -eq "ENTERPRISE") {
  try { $DoCsv = [bool]$Settings.enterprise.csv_mirror } catch { $DoCsv = $true }
}

if ($DoCsv) {
  $CsvDir = Split-Path $Csv -Parent
  if (!(Test-Path $CsvDir)) { New-Item -ItemType Directory -Path $CsvDir | Out-Null }
  $NeedHeader = !(Test-Path $Csv) -or ((Get-Item $Csv).Length -eq 0)

  $Cols = @(
    "scope","event","ts_utc","cr_path",
    "structure_hash_sha256","label_path","stamp_path","approver",
    "external_impact","required_previous_sim_hash","outcome","notes"
  )

  if ($NeedHeader) {
    ($Cols -join ",") | Set-Content -Path $Csv -Encoding UTF8
  }

  function CsvEscape([string]$s) {
    if ($null -eq $s) { return "" }
    $t = $s.Replace('"','""')
    if ($t -match '[,"\r\n]') { return '"' + $t + '"' }
    return $t
  }

  $Row = @()
  foreach ($c in $Cols) { $Row += (CsvEscape ($Rec[$c] + "")) }
  ($Row -join ",") | Add-Content -Path $Csv -Encoding UTF8
}

Write-Host "GOV EVENT WRITTEN ($Mode): $Scope / $Event -> $JsonlRel" -ForegroundColor Cyan
exit 0
