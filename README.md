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

### Todo: instruct installation of submodule

### Todo: instruct adding new or updating apps, configurations, to bootstrap 

# Submodules

|Name|Repo|Location|
|:---|:---|:-------|
|Nvim Config|init.lua|.config/nvim|

## Update Submodules
```bash
config update --init --recursive
config submodule update --remote --merge
```

## Add Submodule
```bash
config submodule add <clone address> <directory>

```
# Brewfile

|CLI Apps       |
|:--------------|
|docker         |
|docker-compose |
|neovim         |
|node           |
|python@3.11    |
|pgcli          |
|ripgrep        |
|tree           |
|yabai          |
|skhd           |

|GUI Apps       |
|:--------------|
|iterm2         |
|hazel          |
|1password-cli  |
|1password      |
|karabiner-elements|
|alfred         |
|discord        |
|slack          |
|gimp           |
|telegram       |
|microsoft-word |
|microsoft-powerpoint|
|microsoft-excel|
|visual studio code|
|figma          |
|postman        |
|protonvpn      |
|transmission   |
|alacritty      |
|obsidian       |

|Appstore       |ID             |
|:--------------|:--------------|
|Things 3       |904280696      |
|Magnet         |441258766      |
|1password      |1569813296     | 
|Effortless     |1368722917     |
|Keys for Safari|1494642810     |
|Vinegar        |1591303229     |
|Baking Soda    |1601151613     |
|Omnivore       |1564031042     |
|Wireless@SG    |1449928544     | 
|Refined Github |1519867270     |

# Manuals
Yabai - https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)

Skhd - https://github.com/koekeishiya/skhd
