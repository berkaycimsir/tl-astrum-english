param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$Culture = "ru"
)

$ErrorActionPreference = "Stop"

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
    throw "TL.exe is running. Close the game before restoring localization."
}

$contentRoot = Resolve-TLContentRoot -Root $GameRoot
$pakDir = Join-Path $contentRoot "Paks"
$targetDir = Join-Path $contentRoot "Localization\Game\$Culture"
$backupRoot = Join-Path $contentRoot "_localization_mod_backups"
$files = @(
    "pakchunk-Localization-$Culture.pak",
    "pakchunk-Localization-$Culture.sig"
)
$restoreSources = @{}

foreach ($file in $files) {
    $destination = Join-Path $pakDir $file
    $backupFile = Get-ChildItem -LiteralPath $backupRoot -Recurse -File -Filter $file -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($backupFile) {
        $restoreSources[$file] = $backupFile.FullName
    }
    elseif (-not (Test-Path -LiteralPath $destination)) {
        throw "Could not find the original $file in Paks or any localization backup. Use the Astrum launcher repair function."
    }
}

if (Test-Path -LiteralPath $targetDir) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $removedDir = Join-Path $backupRoot "removed_${Culture}_$stamp\Game"
    New-Item -ItemType Directory -Force -Path $removedDir | Out-Null
    Move-Item -LiteralPath $targetDir -Destination (Join-Path $removedDir $Culture)
}

$restored = @()
foreach ($file in $files) {
    if ($restoreSources.ContainsKey($file)) {
        $destination = Join-Path $pakDir $file
        Copy-Item -LiteralPath $restoreSources[$file] -Destination $destination -Force
        $restored += $destination
    }
}

Write-Output "Restored the original Russian localization."
if ($restored.Count -gt 0) {
    Write-Output "Restored files: $($restored -join ', ')"
}
