# Install
```bash
STRAP_GIT_EMAIL="handshou@users.noreply.github.com" \
STRAP_GIT_NAME="hansel" STRAP_GITHUB_USER="handshou" \
/usr/bin/env bash -c \
"$(curl -fsSL https://raw.githubusercontent.com/handshou/dotfiles/HEAD/bootstrap.sh)"
```

## Hide untracked files for `config status`
```bash
config config --local status.showUntrackedFiles no
```

Connect config with remote by ssh
```bash
config remote set-url origin git@github.com:handshou/dotfiles.git
```

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
