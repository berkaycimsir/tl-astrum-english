param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [Parameter(Mandatory = $true)]
    [string]$LocresPath,

    [string]$Culture = "ru"
)

$ErrorActionPreference = "Stop"
$expectedSha256 = "463BFAC99222991A4268C61740F04F10719FDD07809962D5C26B61F000C305B1"

function Resolve-TLContentRoot {
    param([string]$Root)

    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    foreach ($candidate in @(
        (Join-Path $rootPath "TL\Content"),
        (Join-Path $rootPath "Content")
    )) {
        if (Test-Path -LiteralPath (Join-Path $candidate "Paks")) {
            return $candidate
        }
    }

    throw "Could not find TL\Content\Paks or Content\Paks under: $Root"
}

if (Get-Process -Name TL -ErrorAction SilentlyContinue) {
    throw "TL.exe is running. Close the game before installing localization."
}

if (-not (Test-Path -LiteralPath $LocresPath -PathType Leaf)) {
    throw "Game.locres was not found: $LocresPath"
}

$payloadHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $LocresPath).Hash
if ($payloadHash -ne $expectedSha256) {
    throw "Game.locres failed SHA-256 verification. Expected $expectedSha256 but found $payloadHash."
}

$contentRoot = Resolve-TLContentRoot -Root $GameRoot
$pakDir = Join-Path $contentRoot "Paks"
$targetDir = Join-Path $contentRoot "Localization\Game\$Culture"
$targetLocres = Join-Path $targetDir "Game.locres"
$backupRoot = Join-Path $contentRoot "_localization_mod_backups"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $backupRoot "install_${Culture}_$stamp"

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$hadPreviousLoose = $false
if (Test-Path -LiteralPath $targetDir) {
    $looseBackupDir = Join-Path $backupDir "previous_loose\Game\$Culture"
    New-Item -ItemType Directory -Force -Path $looseBackupDir | Out-Null
    Get-ChildItem -LiteralPath $targetDir -Force |
        Copy-Item -Destination $looseBackupDir -Recurse -Force
    Remove-Item -LiteralPath $targetDir -Recurse -Force
    $hadPreviousLoose = $true
}

$disabledFiles = @()
foreach ($file in @(
    "pakchunk-Localization-$Culture.pak",
    "pakchunk-Localization-$Culture.sig"
)) {
    $path = Join-Path $pakDir $file
    if (Test-Path -LiteralPath $path) {
        Move-Item -LiteralPath $path -Destination (Join-Path $backupDir $file) -Force
        $disabledFiles += $file
    }
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -LiteralPath $LocresPath -Destination $targetLocres -Force

$manifest = [ordered]@{
    installed_at = (Get-Date -Format o)
    game_root = (Resolve-Path -LiteralPath $GameRoot).Path
    content_root = $contentRoot
    culture = $Culture
    payload_sha256 = $payloadHash
    target_locres = $targetLocres
    disabled_pak_files = $disabledFiles
    had_previous_loose_files = $hadPreviousLoose
}

$manifest | ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath (Join-Path $backupDir "manifest.json") -Encoding UTF8

Write-Output "Installed Astrum T1 + T2 English localization."
Write-Output "Localization: $targetLocres"
Write-Output "Backup: $backupDir"
if ($disabledFiles.Count -gt 0) {
    Write-Output "Disabled original files: $($disabledFiles -join ', ')"
}
