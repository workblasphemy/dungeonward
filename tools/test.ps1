$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
New-Item -ItemType Directory -Force artifacts | Out-Null
$engine = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { 'godot' }
$commit = 'unknown'
$branch = 'unknown'
$dirty = 'unknown'
$osName = 'unknown'
$godotHeader = 'unknown'
try { $commit = "$((git rev-parse HEAD) | Out-String)".Trim() } catch { $commit = 'unknown' }
if (-not $commit) { $commit = 'unknown' }
try { $branch = "$((git rev-parse --abbrev-ref HEAD) | Out-String)".Trim() } catch { $branch = 'unknown' }
if (-not $branch) { $branch = 'unknown' }
try {
    $global:LASTEXITCODE = $null
    $porcelain = & git status --porcelain
    if ($LASTEXITCODE -ne 0) { $dirty = 'unknown' }
    elseif ([string]::IsNullOrWhiteSpace("$porcelain")) { $dirty = 'clean' }
    else { $dirty = 'dirty' }
} catch { $dirty = 'unknown' }
try { $osName = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription } catch { $osName = 'unknown' }
if (-not $osName) { $osName = 'unknown' }
try {
    $global:LASTEXITCODE = $null
    $godotHeader = "$((& $engine --headless --version) | Out-String)".Trim()
    if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -ne 0 -or -not $godotHeader) { $godotHeader = 'unknown' }
} catch { $godotHeader = 'unknown' }
Write-Output "commit: $commit"
Write-Output "branch: $branch"
Write-Output "dirty: $dirty"
Write-Output "os: $osName"
Write-Output "godot: $godotHeader"
$consoleHint = 'set GODOT_BIN to the Godot 4.7.2 *_console.exe build'
if ($commit -eq 'unknown' -or $branch -eq 'unknown' -or $dirty -eq 'unknown') {
    [Console]::Error.WriteLine('FAIL: git provenance is unknown; run from a git checkout with git on PATH')
    exit 1
}
if ($godotHeader -eq 'unknown') {
    [Console]::Error.WriteLine("FAIL: Godot did not report a version and exit code; $consoleHint")
    exit 1
}
function Assert-EngineExit([string]$What) {
    if ($null -eq $global:LASTEXITCODE) {
        [Console]::Error.WriteLine("FAIL: Godot returned no exit code ($What); $consoleHint")
        exit 1
    }
    if ($global:LASTEXITCODE -ne 0) { exit $global:LASTEXITCODE }
}
$global:LASTEXITCODE = $null
$version = & $engine --headless --version
Assert-EngineExit 'version'
$version | Tee-Object artifacts/version.log
if ($version -notmatch '^4\.7\.2\.stable\.') { throw 'Godot 4.7.2 stable required' }
git rev-parse HEAD | Set-Content artifacts/commit.log
[System.Runtime.InteropServices.RuntimeInformation]::OSDescription | Set-Content artifacts/platform.log
function Invoke-Engine([string]$LogFile, [string[]]$EngineArgs) {
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = $null
    & $engine @EngineArgs 2>&1 | Tee-Object $LogFile
    Assert-EngineExit $LogFile
    if (Select-String -Path $LogFile -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet) {
        throw "Godot reported errors: $LogFile"
    }
}
Invoke-Engine 'artifacts/import.log' @('--headless', '--path', '.', '--editor', '--import')
Invoke-Engine 'artifacts/tests.log' (@('--headless', '--path', '.', '--script', 'res://tests/run_all.gd', '--') + $args)
if (-not (Select-String -Path artifacts/tests.log -Pattern '^RESULT: [1-9][0-9]* checks, 0 failures$' -Quiet)) {
    throw 'Missing successful nonempty test summary'
}
Invoke-Engine 'artifacts/startup.log' @('--headless', '--path', '.', '--quit-after', '2')
