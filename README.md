# dotfiles

A repository to bootstrap a fresh macOS environment (todo: Linux). 
We want to include essential apps, set coding configurations, iteratively.

## Start Here

Use your git credentials, then download and run `bootstrap.sh`.

```bash
STRAP_GIT_EMAIL="handshou@users.noreply.github.com" \
STRAP_GIT_NAME="hansel" STRAP_GITHUB_USER="handshou" \
/usr/bin/env bash -c \
"$(curl -fsSL https://raw.githubusercontent.com/handshou/dotfiles/HEAD/bootstrap.sh)"
```

## Understanding the script

1. Update macOS to latest patch
1. Download macOS scripts
1. Install font
1. Install essential code tools
1. Install essentials from App Store
1. Install macOS scripts

The following commands are included in the script.

### Hide untracked files for `config status`

```bash
config config --local status.showUntrackedFiles no
```

### Connect config with remote by ssh

```bash
config remote set-url origin git@github.com:handshou/dotfiles.git
```

### Todo: granting permissions, missing apps (Cider) in macOS settings

### Todo: manual app configurations

### Todo: setup ssh

### Todo: instruct installation of submodule

### Todo: instruct adding new or updating apps, configurations, to bootstrap 

# Submodules

|Name|Repo|Location|
|:---|:---|:-------|
|Nvim Config|init.lua|.config/nvim|

## Update Submodules
```bash
config submodule update --init --recursive
config submodule update --remote --merge
```

## Add Submodule
```bash
config submodule add <clone address> <directory>

```
# Brewfile

## Apps with command line interface

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
|yabai          |https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release) |
|skhd           |https://github.com/koekeishiya/skhd |

## Apps with user interface

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
|visual studio code|https://formulae.brew.sh/cask/visual-studio-code |
|figma          |https://formulae.brew.sh/cask/figma |
|postman        |https://formulae.brew.sh/cask/postman |
|protonvpn      |https://formulae.brew.sh/cask/protonvpn |
|transmission   |https://formulae.brew.sh/cask/transmission |
|alacritty      |https://formulae.brew.sh/cask/alacritty |
|obsidian       |https://formulae.brew.sh/cask/obsidian |

## Apps from the store

|Appstore       |ID             |Links          |
|:--------------|:--------------|:--------------|
|Things 3       |904280696      |https://apps.apple.com/us/app/things-3/id904280696 |
|Magnet         |441258766      |https://apps.apple.com/us/app/magnet/id441258766 |
|1password      |1569813296     |https://apps.apple.com/us/app/1password-password-manager/id159813296 |
|Effortless     |1368722917     |https://apps.apple.com/us/app/effortless/id1368722917 |
|Keys for Safari|1494642810     |https://apps.apple.com/us/app/keys-for-safari/id1494642810 |
|Vinegar        |1591303229     |https://apps.apple.com/sg/app/vinegar-tube-cleaner/id1591303229 |
|Baking Soda    |1601151613     |https://apps.apple.com/us/app/baking-soda-tube-cleaner/id1601151613 |
|Omnivore       |1564031042     |https://apps.apple.com/us/app/omnivore-read-it-later/id1564031042 |
|Wireless@SG    |1449928544     |https://apps.apple.com/us/app/wireless-sgx/id1449928544 |
|Refined Github |1519867270     |https://apps.apple.com/us/app/refined-github/id1519867270 |
|DeArrow        |6451469297     |https://apps.apple.com/us/app/dearrow-for-youtube/id6451469297 |
|Duolingo       |570060128      |https://apps.apple.com/us/app/duolingo-language-lessons/id570060128 |
|Wappalyzer     |1520333300     |https://apps.apple.com/us/app/wappalyzer/id1520333300 |

# Learning

Using `test` to check file conditionals. Read more with `man test`.

# Caveats

Some apps will regress.

1Password issues.

