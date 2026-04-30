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
7. Runs headless neovim plugin install
8. Displays post-install checklist

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
