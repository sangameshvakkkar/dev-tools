[CmdletBinding()]
param(
    [switch]$IncludeDevOps,
    [ValidateSet('WinGet', 'Scoop', 'Chocolatey', 'All')]
    [string]$PackageManager = 'WinGet',
    [switch]$Update,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$corePackages = @(
    'Microsoft.PowerShell',
    'Microsoft.WindowsTerminal',
    'Git.Git',
    'Starship.Starship',
    'fastfetch-cli.fastfetch',
    'sxyazi.yazi',
    'ajeetdsouza.zoxide',
    'eza-community.eza',
    'sharkdp.bat',
    'sharkdp.fd',
    'BurntSushi.ripgrep.MSVC',
    'junegunn.fzf',
    'JesseDuffield.lazygit',
    'dandavison.delta',
    'GitHub.cli',
    'Microsoft.VisualStudioCode',
    'jqlang.jq',
    'mikefarah.yq'
)

$devOpsPackages = @(
    'Docker.DockerDesktop',
    'Kubernetes.kubectl',
    'Helm.Helm',
    'Hashicorp.Terraform',
    'Amazon.AWSCLI',
    'derailed.k9s'
)

$scoopBuckets = [ordered]@{
    main = $null
    extras = $null
    versions = $null
    'nerd-fonts' = 'https://github.com/matthewjberger/scoop-nerd-fonts'
    psmux = 'https://github.com/psmux/scoop-psmux'
    sc = 'https://github.com/wwvl/Scoop-Cursor'
    'terraform-docs' = 'https://github.com/terraform-docs/scoop-bucket'
}
$scoopPackages = @('7zip', 'bat', 'btop', 'cacert', 'curl', 'cursor', 'eza', 'fd', 'fzf', 'gh', 'git', 'innounp', 'jq', 'k9s', 'lazydocker', 'neovim', 'ripgrep', 'terraform-docs', 'wget', 'yq', 'zoxide')
$chocoPackages = @('awscli', 'bruno', 'docker-desktop', 'github-desktop', 'kubernetes-cli', 'lazygit', 'minikube', 'mobaxterm', 'terraform', 'vscode')

function Invoke-PackageCommand([string]$Description, [scriptblock]$Command) {
    if ($WhatIf) { Write-Host "[WhatIf] $Description" -ForegroundColor Yellow; return }
    Write-Host $Description -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) { Write-Warning "Command returned exit code ${LASTEXITCODE}: $Description" }
}

function Install-WinGetPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'WinGet is required. Update App Installer from Microsoft Store, then run this script again.' }
    $packages = $corePackages
    if ($IncludeDevOps) { $packages += $devOpsPackages }
    foreach ($package in $packages) { Invoke-PackageCommand "Installing WinGet package $package..." { winget install --id $package --exact --silent --accept-package-agreements --accept-source-agreements } }
    if ($Update) { Invoke-PackageCommand 'Upgrading WinGet packages...' { winget upgrade --all --silent --accept-package-agreements --accept-source-agreements } }
}

function Install-ScoopPackages {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { throw 'Scoop is required. Install it first with: irm get.scoop.sh | iex' }
    $scoopState = (scoop export | Out-String | ConvertFrom-Json)
    $installedBuckets = @($scoopState.buckets.Name)
    foreach ($bucket in $scoopBuckets.GetEnumerator()) {
        if ($installedBuckets -notcontains $bucket.Key) {
            if ($bucket.Value) { Invoke-PackageCommand "Adding Scoop bucket $($bucket.Key)..." { scoop bucket add $bucket.Key $bucket.Value } }
            else { Invoke-PackageCommand "Adding Scoop bucket $($bucket.Key)..." { scoop bucket add $bucket.Key } }
        }
    }
    $installedApps = @($scoopState.apps.Name)
    foreach ($package in $scoopPackages) {
        if ($installedApps -contains $package) { Write-Host "Scoop package already installed: $package" -ForegroundColor DarkGray; continue }
        Invoke-PackageCommand "Installing Scoop package $package..." { scoop install $package }
    }
    if ($Update) { Invoke-PackageCommand 'Updating Scoop and installed apps...' { scoop update; scoop update '*' } }
}

function Install-ChocolateyPackages {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { throw 'Chocolatey is required. Install it from https://chocolatey.org/install, then rerun this script as Administrator.' }
    $installedPackages = (choco list --local-only --limit-output | ForEach-Object { ($_ -split '\|')[0] })
    foreach ($package in $chocoPackages) {
        if ($installedPackages -contains $package) { Write-Host "Chocolatey package already installed: $package" -ForegroundColor DarkGray; continue }
        Invoke-PackageCommand "Installing Chocolatey package $package..." { choco install $package --yes --no-progress }
    }
    if ($Update) { Invoke-PackageCommand 'Upgrading Chocolatey packages...' { choco upgrade all --yes --no-progress } }
}

if ($PackageManager -in @('WinGet', 'All')) { Install-WinGetPackages }
if ($PackageManager -in @('Scoop', 'All')) { Install-ScoopPackages }
if ($PackageManager -in @('Chocolatey', 'All')) { Install-ChocolateyPackages }
