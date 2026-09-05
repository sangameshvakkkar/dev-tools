[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('All', 'Yazi', 'LazyGit', 'Neovim')]
    [string]$Tool = 'All'
)

$ErrorActionPreference = 'Stop'
$backupRoot = Join-Path $env:LOCALAPPDATA (Join-Path 'dev-environment-backups' (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Install-Directory([string]$Name, [string]$Source, [string]$Destination) {
    if (-not (Test-Path $Source)) { throw "Repository config not found: $Source" }
    if (Test-Path $Destination) {
        $backup = Join-Path $backupRoot $Name
        if ($PSCmdlet.ShouldProcess($Destination, "Back up to $backup and replace")) {
            New-Item -ItemType Directory -Force -Path (Split-Path $backup -Parent) | Out-Null
            Copy-Item -Recurse -Force $Destination $backup
            Remove-Item -Recurse -Force $Destination
        }
    }
    if ($PSCmdlet.ShouldProcess($Destination, "Install $Name configuration")) {
        New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
        Copy-Item -Recurse -Force $Source $Destination
    }
}

if ($Tool -in @('All', 'Yazi')) { Install-Directory 'yazi' (Join-Path $PSScriptRoot 'yazi') (Join-Path $env:APPDATA 'yazi\config') }
if ($Tool -in @('All', 'LazyGit')) { Install-Directory 'lazygit' (Join-Path $PSScriptRoot 'lazygit') (Join-Path $env:LOCALAPPDATA 'lazygit') }
if ($Tool -in @('All', 'Neovim')) { Install-Directory 'nvim' (Join-Path $PSScriptRoot 'neovim') (Join-Path $env:LOCALAPPDATA 'nvim') }

if (Test-Path $backupRoot) { Write-Host "Existing configuration was backed up to $backupRoot" -ForegroundColor Yellow }
