param(
  [Parameter(Mandatory=$true)] [ValidateSet("SIM","REAL")] [string]$Scope,
  [Parameter(Mandatory=$true)] [ValidateSet("LABEL","STAMP","PROMOTE","SIM_BIND","TRANSITION_AUDIT","CUSTOM")] [string]$EventType,
  [Parameter(Mandatory=$true)] [string]$CrPath,
  [Parameter(Mandatory=$true)] [string]$StructureHashSha256,

  [string]$LabelPath = "",
  [string]$StampPath = "",
  [string]$Approver  = "",
  [string]$Notes     = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Sha256Hex([string]$Text) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash  = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($hash) -replace "-","").ToLowerInvariant()
  } finally { $sha.Dispose() }
}

function CanonicalJson([hashtable]$Obj) {
  # deterministic: sort keys at top-level only (good enough for our stable record)
  $keys = $Obj.Keys | Sort-Object
  $ordered = [ordered]@{}
  foreach ($k in $keys) { $ordered[$k] = $Obj[$k] }
  return ($ordered | ConvertTo-Json -Compress)
}

$RepoRoot = (Get-Location).Path
$SettingsPath = Join-Path $RepoRoot "governance\governance.settings.json"
if (!(Test-Path $SettingsPath)) { throw "Missing governance settings: $SettingsPath" }

$Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
$Mode     = [string]$Settings.governance_mode

$JsonlRel = [string]$Settings.ledger.jsonl_path
$CsvRel   = [string]$Settings.ledger.csv_path
$EnableCsv = [bool]$Settings.ledger.enable_csv_mirror
$EnableChain = [bool]$Settings.ledger.enable_hash_chain
$EnableAnchor = [bool]$Settings.ledger.enable_anchor
$AnchorEveryN = [int]$Settings.ledger.anchor_every_n_events

$LedgerJsonl = Join-Path $RepoRoot $JsonlRel
$LedgerCsv   = Join-Path $RepoRoot $CsvRel

$LedgerDir = Split-Path $LedgerJsonl -Parent
$AnchorDir = Join-Path $RepoRoot "ledger\anchors"

if (!(Test-Path $LedgerDir)) { New-Item -ItemType Directory -Path $LedgerDir | Out-Null }
if (!(Test-Path $LedgerJsonl)) { New-Item -ItemType File -Path $LedgerJsonl | Out-Null }

# Determine prev hash (tail)
$Prev = $null
$Tail = Get-Content $LedgerJsonl -ErrorAction SilentlyContinue | Select-Object -Last 1
if ($Tail) {
  try {
    $TailObj = $Tail | ConvertFrom-Json
    $Prev = $TailObj.entry_hash_sha256
  } catch { $Prev = $null }
}

# Build record WITHOUT entry_hash first
$Record = @{
  ts_utc = (Get-Date).ToUniversalTime().ToString("o")
  scope  = $Scope
  event_type = $EventType
  repo_root = $RepoRoot
  cr_path   = $CrPath
  structure_hash_sha256 = $StructureHashSha256
  label_path = $LabelPath
  stamp_path = $StampPath
  approver   = $Approver
  notes      = $Notes
  prev_entry_hash_sha256 = $Prev
  mode = $Mode
}

$Canon = CanonicalJson $Record
$EntryHash = Sha256Hex $Canon
$Record["entry_hash_sha256"] = $EntryHash

# Hash-chain enforcement
if ($EnableChain -and $Mode -eq "ENTERPRISE") {
  # if there is a tail and it doesn't parse, block (ledger corruption)
  if ($Tail -and -not $Prev) {
    throw "ENTERPRISE BLOCK: ledger tail is not parseable JSON (hash chain cannot be trusted)."
  }
}

# Append JSONL
($Record | ConvertTo-Json -Compress) | Add-Content -Path $LedgerJsonl -Encoding UTF8

# Optional CSV mirror (Excel-friendly)
if ($EnableCsv) {
  if (!(Test-Path $LedgerCsv)) {
    # header row
    "ts_utc,scope,event_type,cr_path,structure_hash_sha256,prev_entry_hash_sha256,entry_hash_sha256,approver,notes" |
      Set-Content -Path $LedgerCsv -Encoding UTF8
  }
  $csvLine = ('"{0}","{1}","{2}","{3}","{4}","{5}","{6}","{7}","{8}"' -f
    $Record.ts_utc,
    $Record.scope,
    $Record.event_type,
    ($Record.cr_path -replace '"','""'),
    $Record.structure_hash_sha256,
    ($Record.prev_entry_hash_sha256 ?? ""),
    $Record.entry_hash_sha256,
    ($Record.approver -replace '"','""'),
    ($Record.notes -replace '"','""')
  )
  Add-Content -Path $LedgerCsv -Value $csvLine -Encoding UTF8
}

# Optional anchoring (tail-hash snapshots)
if ($EnableAnchor) {
  if (!(Test-Path $AnchorDir)) { New-Item -ItemType Directory -Path $AnchorDir | Out-Null }

  $Count = (Get-Content $LedgerJsonl -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($Count -gt 0 -and ($Count % $AnchorEveryN) -eq 0) {
    $AnchorFile = Join-Path $AnchorDir ("anchor_" + (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss") + "Z.txt")
    @(
      "ANCHOR (TAIL HASH SNAPSHOT)",
      "ts_utc=" + (Get-Date).ToUniversalTime().ToString("o"),
      "mode=" + $Mode,
      "scope=" + $Scope,
      "event_type=" + $EventType,
      "cr_path=" + $CrPath,
      "tail_entry_hash_sha256=" + $EntryHash
    ) | Set-Content -Path $AnchorFile -Encoding UTF8
  }
}

Write-Host ("LEDGER OK: {0} event={1} scope={2} hash={3}" -f $CrPath,$EventType,$Scope,$EntryHash) -ForegroundColor Green
exit 0
