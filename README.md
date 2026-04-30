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

### Apps with command line interface

|CLI Apps       |Links        |
|:--------------|:------------|
|docker         |https://formulae.brew.sh/formula/docker |
|docker-compose |https://formulae.brew.sh/formula/docker-compose |
|neovim         |https://formulae.brew.sh/formula/neovim |
|node           |https://formulae.brew.sh/formula/node |
|python@3.11    |https://formulae.brew.sh/formula/python@3.11 |
|pgcli          |https://formulae.brew.sh/formula/pgcli |
|ripgrep        |https://formulae.brew.sh/formula/ripgrep |
|tree           |https://formulae.brew.sh/formula/tree |
|bash           |https://formulae.brew.sh/formula/bash |
|tmux           |https://formulae.brew.sh/formula/tmux |
|tpm            |https://formulae.brew.sh/formula/tpm |
|deno           |https://formulae.brew.sh/formula/deno |
|pnpm           |https://formulae.brew.sh/formula/pnpm |
|fzf            |https://formulae.brew.sh/formula/fzf |
|chafa          |https://formulae.brew.sh/formula/chafa |
|stylua         |https://formulae.brew.sh/formula/stylua |
|fileicon       |https://formulae.brew.sh/formula/fileicon |
|supabase       |https://formulae.brew.sh/formula/supabase |
|goenv          |https://formulae.brew.sh/formula/goenv |
|rustup         |https://formulae.brew.sh/formula/rustup |
|pulumi         |https://formulae.brew.sh/formula/pulumi |
|yabai          |https://formulae.brew.sh/formula/yabai |
|skhd-zig       |https://github.com/jackielii/skhd-zig |

### Apps with user interface

|GUI Apps       |Links        |
|:--------------|:------------|
|iterm2         |https://formulae.brew.sh/cask/iterm2 |
|hazel          |https://formulae.brew.sh/cask/hazel |
|1password-cli  |https://formulae.brew.sh/cask/1password-cli |
|1password      |https://formulae.brew.sh/cask/1password |
|karabiner-elements| https://formulae.brew.sh/cask/karabiner-elements |
|alfred         |https://formulae.brew.sh/cask/alfred |
|discord        |https://formulae.brew.sh/cask/discord |
|slack          |https://formulae.brew.sh/cask/slack |
|gimp           |https://formulae.brew.sh/cask/gimp |
|telegram       |https://formulae.brew.sh/cask/telegram |
|microsoft-word |https://formulae.brew.sh/cask/microsoft-word |
|microsoft-powerpoint|https://formulae.brew.sh/cask/microsoft-powerpoint |
|microsoft-excel|https://formulae.brew.sh/cask/microsoft-excel |
|visual-studio-code|https://formulae.brew.sh/cask/visual-studio-code |
|figma          |https://formulae.brew.sh/cask/figma |
|postman        |https://formulae.brew.sh/cask/postman |
|protonvpn      |https://formulae.brew.sh/cask/protonvpn |
|transmission   |https://formulae.brew.sh/cask/transmission |
|alacritty      |https://formulae.brew.sh/cask/alacritty |
|obsidian       |https://formulae.brew.sh/cask/obsidian |
|zen            |https://formulae.brew.sh/cask/zen |
|firefox        |https://formulae.brew.sh/cask/firefox |
|darktable      |https://formulae.brew.sh/cask/darktable |
|rawtherapee    |https://formulae.brew.sh/cask/rawtherapee |
|claude-code    |https://formulae.brew.sh/cask/claude-code |
|hiddenbar      |https://formulae.brew.sh/cask/hiddenbar |
|stats          |https://formulae.brew.sh/cask/stats |
|love           |https://formulae.brew.sh/cask/love |
|subler         |https://formulae.brew.sh/cask/subler |
|google-cloud-sdk|https://formulae.brew.sh/cask/google-cloud-sdk |

### Apps from the store

|Appstore       |ID             |Links          |
|:--------------|:--------------|:--------------|
|Things 3       |904280696      |https://apps.apple.com/us/app/things-3/id904280696 |
|Magnet         |441258766      |https://apps.apple.com/us/app/magnet/id441258766 |
|1password      |1569813296     |https://apps.apple.com/us/app/1password-password-manager/id159813296 |
|Keys for Safari|1494642810     |https://apps.apple.com/us/app/keys-for-safari/id1494642810 |
|Vinegar        |1591303229     |https://apps.apple.com/sg/app/vinegar-tube-cleaner/id1591303229 |
|Baking Soda    |1601151613     |https://apps.apple.com/us/app/baking-soda-tube-cleaner/id1601151613 |
|Refined Github |1519867270     |https://apps.apple.com/us/app/refined-github/id1519867270 |
|DeArrow        |6451469297     |https://apps.apple.com/us/app/dearrow-for-youtube/id6451469297 |
|Wappalyzer     |1520333300     |https://apps.apple.com/us/app/wappalyzer/id1520333300 |
|Trello         |1278508951     |https://apps.apple.com/us/app/trello/id1278508951 |
|Dropover       |1355679052     |https://apps.apple.com/us/app/dropover-easier-drag-drop/id1355679052 |

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
- Added 9-step post-install checklist with detailed SIP disable instructions
- Migrated from koekeishiya/skhd to jackielii/skhd-zig
- Updated nvim config for neovim 0.12 (removed lsp-zero, use native LSP)
- Added global caps_lock to left_control in Karabiner
- Fixed TPM path in tmux.conf (hardcoded /opt/homebrew)
- Added brew shellenv to .zshrc
- Added `bash` to Brewfile so tokyo-night-tmux renders correctly. macOS ships
  bash 3.2 (no associative array support); the plugin's `declare -A THEME=(...)`
  fails silently and every `${THEME[*]}` collapses to the last scalar write
  (`#d29922`), turning the entire status bar one ugly orange. Homebrew bash 5+
  fixes it. Restart the tmux server (`tmux kill-server`) after install.
- Added Step 5 to post-install #1: switch dotfiles remote from HTTPS to SSH
  (`config remote set-url origin git@github.com:USER/dotfiles.git`) so
  `config push` uses the SSH key instead of failing on missing HTTPS creds.
- Added `fileicon` to Brewfile and an automated bootstrap step that applies
  the custom Alacritty icon (`~/Alacritty.tiff`) to `/Applications/Alacritty.app`
  after `brew bundle`. The `.tiff` source stays at the repo root where it has
  always lived.

### 2026-04-29
- Removed discontinued apps: Effortless, Omnivore, Duolingo, Wireless@SG
- Removed unavailable brew packages: codex, overlayed
- Added Zen browser, rawtherapee to Brewfile

### Earlier
- Initial bootstrap script with interactive prompts
- Dual SSH key support (personal + work GitHub accounts)
