# Install
```bash
STRAP_GIT_EMAIL="handshou@users.noreply.github.com" \
STRAP_GIT_NAME="hansel" STRAP_GITHUB_USER="handshou" \
/usr/bin/env bash -c \
"$(curl -fsSL https://raw.githubusercontent.com/handshou/dotfiles/HEAD/bootstrap.sh)"
```

# Submodules
|Name|Repo|Location|
|:---|:---|:-------|
|Packer|packer.nvim|.local/share/nvim/site/pack/packer/start/packer.nvim|
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
|giflib         |
|little-cms     |
|jpeg-xl        |
|cairo          |
|docker         |
|docker-compose |
|ghostscript    |
|jpeg           |
|pango          |
|librsvg        |
|neovim         |
|node           |
|python@3.11    |
|pgcli          |
|pkg-config     |
|ripgrep        |
|tree           |
|cockroachdb    |
|cockroachdb-sql|
|gh             |
|yabai          |
|skhd           |

|GUI Apps       |
|:--------------|
|iterm2         |
|hazel          |
|1password-cli  |
|1password      |
|karabiner-elements|
|font-back-nerd-font|
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
|notion         |
|protonvpn      |
|transmission   |

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
