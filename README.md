# Windows developer environment

This repository is the portable, reviewable record of this Windows development setup. It separates **what is installed** from **how tools are configured**, avoids credentials and runtime history, and makes a new-machine setup repeatable.

## What this repository tracks

| Area | Source of truth | Purpose |
| --- | --- | --- |
| Packages | `bootstrap.ps1` | Curated WinGet, Scoop, and Chocolatey installs |
| Package audit | `package-audit.ps1` | Live local inventory; generated files are ignored |
| Yazi | `yazi/` | Current portable file-manager settings, keymap, and flavor lockfile |
| LazyGit | `lazygit/config.yml` | Portable settings only; never recent repository history |
| Neovim | `neovim/` | Reserved for an `init.lua` and Lua modules when a configuration exists |
| Config installer | `install-config.ps1` | Backs up then deploys tracked configuration |

Do not commit passwords, API tokens, `.env` files, package caches, editor plugin downloads, or application history.

## First-time setup

Open an elevated PowerShell only when Chocolatey or an individual installer asks for elevation. In the repository root, review the scripts and run the profile you want:

```powershell
Set-ExecutionPolicy -Scope Process Bypass

# Preview a profile without changing the machine
.\bootstrap.ps1 -PackageManager Scoop -WhatIf

# Install portable CLI tools managed by Scoop
.\bootstrap.ps1 -PackageManager Scoop

# Install desktop/system tooling managed by Chocolatey
.\bootstrap.ps1 -PackageManager Chocolatey

# Keep the original WinGet curated profile
.\bootstrap.ps1 -PackageManager WinGet
```

`All` runs all three profiles. It is useful for reproducing the recorded machine state, but can install duplicate tools; use one manager where practical.

### Package ownership

Scoop owns portable command-line programs such as Git, Neovim, Yazi, ripgrep, fd, bat, fzf, jq, yq, zoxide, k9s, and LazyDocker. Chocolatey owns system and desktop software such as Docker Desktop, VS Code, GitHub Desktop, MobaXterm, Minikube, kubectl, Terraform, AWS CLI, Bruno, and LazyGit.

This computer already has overlap (notably Git and LazyGit) across package managers. Before removing one, confirm which executable wins with `Get-Command git` or `Get-Command lazygit` and choose a single owner. Do not blindly uninstall a duplicate while an active workflow depends on its PATH location.

## Configure Yazi, LazyGit, and Neovim

Inspect the change first:

```powershell
.\install-config.ps1 -WhatIf
```

Install every tracked configuration, or just one tool:

```powershell
.\install-config.ps1
.\install-config.ps1 -Tool Yazi
.\install-config.ps1 -Tool LazyGit
.\install-config.ps1 -Tool Neovim
```

The installer backs up any existing destination below `%LOCALAPPDATA%\dev-environment-backups` before replacing it. It deploys Yazi to `%APPDATA%\yazi\config`, LazyGit to `%LOCALAPPDATA%\lazygit`, and Neovim to `%LOCALAPPDATA%\nvim`.

### Yazi

`yazi/` is copied from the active configuration and includes `yazi.toml`, `keymap.toml`, `init.lua`, `theme.toml`, and `package.toml`. The latter pins the Catppuccin Mocha and Tokyo Night flavors; after installation, run the package manager command supported by your installed Yazi version if those flavor assets have not yet been downloaded:

```powershell
ya pkg install
```

Downloaded `flavors/` assets are intentionally not stored here because `package.toml` is the reproducible declaration. Yazi runtime state is excluded.

### LazyGit

Only `config.yml` belongs in source control. Keep `state.yml` local: it contains recent repository paths and command history. Add theme, keybinding, Git integration, or custom-command preferences to the tracked config file, then run `install-config.ps1 -Tool LazyGit` to deploy it.

### Neovim

Neovim is installed, but no configuration was found on this computer at audit time. Add `neovim/init.lua` and any `neovim/lua/` modules when you decide on a setup. Keep plugin managers, downloaded plugins, swap files, sessions, and cache out of this repository; they are rebuilt after Neovim starts.

## Audit and update packages

Generate a fresh, machine-readable and readable package snapshot:

```powershell
.\package-audit.ps1
```

It writes `inventory/package-audit.json` and `inventory/package-audit.md`, including Chocolatey sources, installed packages and upgrade candidates, plus Scoop buckets and apps. These reports are intentionally ignored because they change with the machine.

To update a recorded profile:

```powershell
.\bootstrap.ps1 -PackageManager Scoop -Update
.\bootstrap.ps1 -PackageManager Chocolatey -Update
```

For discovery, use `scoop search <name>` and `choco search <name>`. Add only tools that belong on every developer machine to `bootstrap.ps1`; a one-off experiment should remain outside the curated profile.

## Keeping this repository healthy

1. Make a configuration change in this repository, not only in `%APPDATA%` or `%LOCALAPPDATA%`.
2. Deploy it with `install-config.ps1` and test the relevant application.
3. Run `package-audit.ps1` after material package changes.
4. Review `git diff` before committing, especially for paths, usernames, tokens, or generated state.
5. Commit the declarative scripts and settings—not downloads, secrets, or machine-specific history.
