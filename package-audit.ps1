[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'inventory')
)

$ErrorActionPreference = 'Stop'

function Get-CommandVersion([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { return $null }
    try { return (& $Name --version 2>$null | Select-Object -First 1) } catch { return $command.Version.ToString() }
}

function Invoke-TextCommand([scriptblock]$Command) {
    try { return (& $Command 2>&1 | Out-String).Trim() } catch { return "ERROR: $($_.Exception.Message)" }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$audit = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    computerName = $env:COMPUTERNAME
    packageManagers = [ordered]@{
        chocolatey = [ordered]@{
            installed = [bool](Get-Command choco -ErrorAction SilentlyContinue)
            version = Get-CommandVersion 'choco'
            sources = if (Get-Command choco -ErrorAction SilentlyContinue) { Invoke-TextCommand { choco source list } }
            packages = if (Get-Command choco -ErrorAction SilentlyContinue) { Invoke-TextCommand { choco list --local-only --limit-output } }
            outdated = if (Get-Command choco -ErrorAction SilentlyContinue) { Invoke-TextCommand { choco outdated --limit-output } }
        }
        scoop = [ordered]@{
            installed = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
            version = Get-CommandVersion 'scoop'
            status = if (Get-Command scoop -ErrorAction SilentlyContinue) { Invoke-TextCommand { scoop status } }
            export = if (Get-Command scoop -ErrorAction SilentlyContinue) { Invoke-TextCommand { scoop export } }
        }
    }
}

$jsonPath = Join-Path $OutputDirectory 'package-audit.json'
$markdownPath = Join-Path $OutputDirectory 'package-audit.md'
$audit | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 $jsonPath

$report = @(
    '# Windows package-manager audit'
    ''
    "Generated: $($audit.generatedAt)"
    ''
    '## Chocolatey'
    "Installed: $($audit.packageManagers.chocolatey.installed)"
    "Version: $($audit.packageManagers.chocolatey.version)"
    ''
    '### Sources'
    '```text'
    $audit.packageManagers.chocolatey.sources
    '```'
    '### Installed packages'
    '```text'
    $audit.packageManagers.chocolatey.packages
    '```'
    '### Available upgrades'
    '```text'
    $audit.packageManagers.chocolatey.outdated
    '```'
    '## Scoop'
    "Installed: $($audit.packageManagers.scoop.installed)"
    "Version: $($audit.packageManagers.scoop.version)"
    ''
    '### Status'
    '```text'
    $audit.packageManagers.scoop.status
    '```'
    '### Export (buckets and installed apps)'
    '```json'
    $audit.packageManagers.scoop.export
    '```'
)
$report | Set-Content -Encoding utf8 $markdownPath

Write-Host "Wrote $jsonPath" -ForegroundColor Green
Write-Host "Wrote $markdownPath" -ForegroundColor Green
