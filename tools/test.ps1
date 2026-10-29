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
    $porcelain = & git status --porcelain
    if ($LASTEXITCODE -ne 0) { $dirty = 'unknown' }
    elseif ([string]::IsNullOrWhiteSpace("$porcelain")) { $dirty = 'clean' }
    else { $dirty = 'dirty' }
} catch { $dirty = 'unknown' }
try { $osName = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription } catch { $osName = 'unknown' }
if (-not $osName) { $osName = 'unknown' }
try {
    $godotHeader = "$((& $engine --headless --version) | Out-String)".Trim()
    if ($LASTEXITCODE -ne 0 -or -not $godotHeader) { $godotHeader = 'unknown' }
} catch { $godotHeader = 'unknown' }
Write-Output "commit: $commit"
Write-Output "branch: $branch"
Write-Output "dirty: $dirty"
Write-Output "os: $osName"
Write-Output "godot: $godotHeader"
$version = & $engine --headless --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$version | Tee-Object artifacts/version.log
if ($version -notmatch '^4\.7\.2\.stable\.') { throw 'Godot 4.7.2 stable required' }
git rev-parse HEAD | Set-Content artifacts/commit.log
[System.Runtime.InteropServices.RuntimeInformation]::OSDescription | Set-Content artifacts/platform.log
function Invoke-Engine([string]$LogFile, [string[]]$EngineArgs) {
    $ErrorActionPreference = 'Continue'
    & $engine @EngineArgs 2>&1 | Tee-Object $LogFile
    $code = $LASTEXITCODE
    if ($code -ne 0) { exit $code }
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
