# dotfiles

A repository to bootstrap a fresh macOS environment.
Includes essential apps, coding configurations, and post-install setup steps.

## Start Here

Download and run `bootstrap.sh`. The script will prompt for credentials interactively.

```bash
# Simple (script prompts for all values):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/handshou/dotfiles/HEAD/bootstrap.sh)"

# Or pre-set variables (script prompts if not set):
STRAP_GIT_NAME="handshou" \
STRAP_GIT_EMAIL="handshou@users.noreply.github.com" \
STRAP_GITHUB_USER="handshou" \
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/handshou/dotfiles/HEAD/bootstrap.sh)"

# For work account, also set:
STRAP_GIT_NAME_WORK="your-work-name" \
STRAP_GIT_EMAIL_WORK="your-work@users.noreply.github.com" \
STRAP_GITHUB_USER_WORK="your-work-username"
```

## What the Script Does

1. Prompts for git credentials (personal + optional work)
2. Generates SSH keys (ed25519) for personal and work GitHub accounts
3. Installs Homebrew
4. Checks out dotfiles via bare git repo to `~/.cfg`
5. Installs packages from Brewfile
6. Initializes neovim submodule
7. Applies macOS defaults via `scripts/macos-setup.sh`
8. Runs headless neovim plugin install
9. Displays post-install checklist

## Post-Install Checklist

After bootstrap completes, follow these 9 steps:

1. **SSH keys** - Add to GitHub: `cat ~/.ssh/id_ed25519.pub`
2. **nvim submodule** - `config submodule update --init --recursive`
3. **Neovim plugins** - Open nvim and run `:Lazy sync`
4. **Alacritty** - Run `alacritty migrate` if needed
5. **skhd** - Start service: `/opt/homebrew/bin/skhd --start-service`
6. **yabai** - Requires partial SIP disable (see bootstrap output for instructions)
7. **Tmux plugins** - `prefix + I` to install TPM plugins
8. **Node.js** - Install via nvm: `nvm install --lts`
9. **Restart terminal** - Apply shell configuration changes

## Config Commands

```bash
# Show dotfiles status
config status

# Pull latest changes
config pull

# Add and commit changes
config add <file>
config commit -m "message"
config push
```

### Hide untracked files for `config status`

```bash
config config --local status.showUntrackedFiles no
```

### Connect config with remote by ssh

```bash
config remote set-url origin git@github.com:handshou/dotfiles.git
```

### Folder-based Git identity

| Git directory | Author / GitHub account | Signing key | SSH authentication key |
|:---|:---|:---|:---|
| `~/g/` and `~/.cfg/` | `handshou` / `handshou@users.noreply.github.com` | `~/.ssh/id_ed25519.pub` | `~/.ssh/id_ed25519` |
| `~/Developer/` | `hanselse` / `190053598+hanselse@users.noreply.github.com` | `~/.ssh/id_ed25519_work.pub` | `~/.ssh/id_ed25519_work` |

The trailing-slash `includeIf gitdir` conditions cover regular repositories,
canonical `<repo>/.bare` roots, and linked worktrees whose Git directories live
under those roots. Selection follows the Git directory, not the shell's current
directory or remote owner. Repositories outside these folders retain the existing
personal defaults. Repository-local and command-line overrides remain authoritative;
`git setup-work` remains available for explicit per-repository overrides.

Author identity, SSH commit/tag signing, and remote SSH authentication are separate.
The folder profiles choose the author and public signing key; Git's SSH profiles
select the private authentication key without reading or storing its contents.
For GitHub, `IdentitiesOnly yes` prevents the agent's other account keys from being
offered. Both profiles support `github.com`, `work.github.com`, `github-public`, and
`github-personal`; within mapped folders the folder determines the account, even
when an old remote uses a different alias. Non-GitHub hosts retain the user's and
system's SSH configuration. HTTPS remotes still use the existing credential helper,
not these SSH profiles. An explicit `GIT_SSH_COMMAND` takes precedence.

Deploy `.gitconfig` and all four `.config/git/{identity-personal,identity-work,ssh-personal,ssh-work}`
files together through the HOME dotfiles checkout. Review `config status` first and
preserve local changes; implementing this in a linked worktree does not install it
in HOME. No doctor command is included.

Inspect effective settings from a repository:

```bash
git config --show-origin --get-regexp '^(user\.|github\.|core.sshCommand|gpg\.|commit.gpgsign|tag.gpgsign)'
ssh -T -F ~/.config/git/ssh-personal git@github.com
ssh -T -F ~/.config/git/ssh-work git@github.com
```

GitHub's successful SSH greeting exits with status 1 because it provides no shell.
Run the isolated configuration tests on macOS with Python, Git, and OpenSSH:

```bash
python3 -m unittest discover -s scripts/tests -v
```

### Todo: manual app configurations (Cider from itch.io)

## Claude Code Setup

### Install
```bash
brew install --cask claude-code
```

### Configure Enter for Newline
By default, Enter submits. To use Enter for newline and require Cmd+Enter to submit:

```bash
claude config set --global preferredSubmitKey "cmd+enter"
```

### First Run
```bash
claude
# Follow prompts to authenticate with Anthropic
```

## Submodules

|Name|Repo|Location|
|:---|:---|:-------|
|Nvim Config|init.lua|.config/nvim|

### Update Submodules
```bash
config submodule update --init --recursive
config submodule update --remote --merge
```

### Add Submodule
```bash
config submodule add <clone address> <directory>
```

## macOS Defaults (`scripts/macos-setup.sh`)

Applies opinionated system preferences via `defaults write`. Backs up your
current defaults to `~/Desktop/macos-defaults-<timestamp>.txt` first.

| Section | Configures |
|:---|:---|
| UI/UX | Dark mode + graphite accent, metric units, save-to-disk default, instant window resize |
| Trackpad/Keyboard | Tap-to-click, fastest key repeat, full keyboard tab nav, autocorrect off |
| Finder | Hidden files, all extensions, list view, folders-first sort, no `.DS_Store` on network/USB |
| Dock & Mission Control | Auto-hide menu bar + dock, no recent apps, all 4 hot corners disabled, **Ctrl+1..9 → Switch to Desktop N** |
| Mail | Plain-text compose, no animations, newest-first, no remote content |
| Spotlight | Custom indexing order — apps and conversion first, fonts/messages/contacts/etc. off |
| Networking | Auto-DHCP for Ethernet, ProtonVPN auto-connect on boot |
| TextEdit | Plain text mode, UTF-8 |
| Transmission | Encryption required, blocklist auto-update, peer limits, prevent sleep |
| Magnet | Clears default hotkeys (keeps center/restore/maximize) |
| iTerm2 | Imports tokyonight-storm theme |

Run manually after edits:
```bash
sh ~/scripts/macos-setup.sh
killall cfprefsd Dock Finder   # apply changes immediately
```

## Brewfile

Packages are split into three Brewfiles. Bootstrap installs `Brewfile` automatically and prompts for optional bundles.

| File | Description | Install |
|:-----|:------------|:--------|
| `Brewfile` | Core development tools and daily apps | Auto |
| `Brewfile.work` | Work packages (Slack, MS Office, GCloud) | Prompted |
| `Brewfile.optional` | Photography, media, games | Prompted |

Manual install after bootstrap:
```bash
brew bundle --file=Brewfile.work
brew bundle --file=Brewfile.optional
```

### Core CLI Apps (Brewfile)

| App | Description |
|:----|:------------|
| neovim | Editor |
| node, deno, pnpm | JavaScript runtimes |
| python@3.11 | Python |
| rustup, goenv | Language version managers |
| tmux, tpm | Terminal multiplexer |
| ripgrep, fzf, tree, chafa | CLI utilities |
| pgcli | Database tools |
| stylua | Lua formatter |
| yabai, skhd-zig | Window management |

### Core GUI Apps (Brewfile)

| App | Description |
|:----|:------------|
| iterm2, alacritty | Terminals |
| firefox, zen | Browsers |
| alfred, obsidian | Productivity |
| claude-code | AI assistant |
| figma | Design |
| 1password, 1password-cli | Password manager |
| protonvpn | VPN |
| karabiner-elements | Keyboard remapping |
| hiddenbar, stats | Menu bar utilities |
| font-hack-nerd-font | Nerd font |

### Work Apps (Brewfile.work)

| App | Description |
|:----|:------------|
| docker, docker-compose | Containers |
| supabase | Database |
| slack | Work communication |
| visual-studio-code | Editor |
| microsoft-word/excel/powerpoint | Office suite |
| postman | API testing |
| google-cloud-sdk | GCloud CLI |
| pulumi | Infrastructure as code |
| trello (App Store) | Project management |

### Optional Apps (Brewfile.optional)

| App | Description |
|:----|:------------|
| rawtherapee, gimp | Photography/image editing |
| subler, transmission | Media tools |
| love | Game engine |
| hazel | Automation |
| discord, telegram | Communication |

### App Store (Brewfile)

| App | ID |
|:----|:---|
| Things 3 | 904280696 |
| Magnet | 441258766 |
| Dropover | 1355679052 |
| 1password for Safari | 1569813296 |
| Keys for Safari | 1494642810 |
| Vinegar | 1591303229 |
| Baking Soda | 1601151613 |
| Refined GitHub | 1519867270 |
| DeArrow | 6451469297 |
| Wappalyzer | 1520333300 |

## Manual Installs

Apps not available via Homebrew:

|App            |Source         |
|:--------------|:--------------|
|Cider 2        |https://cidercollective.itch.io/cider |
|Photo Mechanic |https://home.camerabits.com/ (commercial) |

## Learning

Using `test` to check file conditionals. Read more with `man test`.

## Caveats

Some apps will regress.

1Password issues.

## Changelog

### 2026-04-30
- Bootstrap now auto-runs `scripts/macos-setup.sh` after Brewfile install
- Added Ctrl+1..9 → Switch to Desktop N hotkeys to macos-setup.sh
- Removed `node` from Brewfile (use nvm-managed node instead)
- Added `tag.gpgsign = true` and `gpg.ssh.allowedSignersFile` to gitconfig
- Switched hardcoded `/Users/h` paths in dotfiles to `~`/`$HOME` for portability
- Removed leftover Windsurf PATH entries from .zshrc
- Split Brewfile into core, work, and optional bundles
- Added interactive prompts in bootstrap for optional package installs
- Removed darktable from Brewfile
- Added 9-step post-install checklist with detailed SIP disable instructions
- Migrated from koekeishiya/skhd to jackielii/skhd-zig
- Updated nvim config for neovim 0.12 (removed lsp-zero, use native LSP)
- Added global caps_lock to left_control in Karabiner
- Fixed TPM path in tmux.conf (hardcoded /opt/homebrew)
- Added brew shellenv to .zshrc

### 2026-04-29
- Removed discontinued apps: Effortless, Omnivore, Duolingo, Wireless@SG
- Removed unavailable brew packages: codex, overlayed
- Added Zen browser, rawtherapee to Brewfile

### Earlier
- Initial bootstrap script with interactive prompts
- Dual SSH key support (personal + work GitHub accounts)
