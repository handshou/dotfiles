#!/usr/bin/env bash
### ------------ bootstrap.sh - set up development environment ------------ ###
# https://github.com/MikeMcQuaid/strap, https://github.com/Homebrew/install

set -e

OS=$(uname -s)
case $OS in
Darwin)
  export LINUX=0 MACOS=1 UNIX=1
  if [[ $(uname -m) == "arm64" ]]; then
    DEFAULT_HOMEBREW_PREFIX="/opt/homebrew"
  else
    DEFAULT_HOMEBREW_PREFIX="/usr/local"
  fi
  ;;
Linux)
  export LINUX=1 MACOS=0 UNIX=1
  if [[ -d $HOME/.linuxbrew ]]; then
    DEFAULT_HOMEBREW_PREFIX="$HOME/.linuxbrew"
  else
    DEFAULT_HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  fi
  [[ $(id -un) == "codespace" ]] && export CODESPACE=1
  ;;
*) echo "Unsupported operating system $OS" && exit 1 ;;
esac
[[ -z $HOMEBREW_PREFIX ]] && HOMEBREW_PREFIX="$DEFAULT_HOMEBREW_PREFIX"

STRAP_CI=${STRAP_CI:=0}
STRAP_DEBUG=${STRAP_DEBUG:-0}
[[ $1 = "--debug" || -o xtrace ]] && STRAP_DEBUG=1
STRAP_INTERACTIVE=${STRAP_INTERACTIVE:-0}
STDIN_FILE_DESCRIPTOR=0
[ -t "$STDIN_FILE_DESCRIPTOR" ] && STRAP_INTERACTIVE=1
# Pre-populate from existing git config and SSH keys (for re-runs)
[ -z "$STRAP_GIT_NAME" ] && STRAP_GIT_NAME="$(git config --global user.name 2>/dev/null)"
[ -z "$STRAP_GIT_EMAIL" ] && STRAP_GIT_EMAIL="$(git config --global user.email 2>/dev/null)"
[ -z "$STRAP_GITHUB_USER" ] && STRAP_GITHUB_USER="$(git config --global github.user 2>/dev/null)"
# Extract work info from SSH key comment if it exists (format: id+username@users.noreply.github.com)
if [ -f ~/.ssh/id_ed25519_work.pub ]; then
  work_email_from_key="$(awk '{print $3}' ~/.ssh/id_ed25519_work.pub 2>/dev/null)"
  [ -z "$STRAP_GIT_EMAIL_WORK" ] && STRAP_GIT_EMAIL_WORK="$work_email_from_key"
  # Extract GitHub username from noreply email formats (POSIX-compatible):
  #   - username@users.noreply.github.com -> username
  #   - 12345+username@users.noreply.github.com -> username
  if [ -z "$STRAP_GITHUB_USER_WORK" ]; then
    case "$work_email_from_key" in
      *@users.noreply.github.com)
        local_part="${work_email_from_key%@users.noreply.github.com}"
        case "$local_part" in
          *+*) STRAP_GITHUB_USER_WORK="${local_part##*+}" ;;
          *) STRAP_GITHUB_USER_WORK="$local_part" ;;
        esac
        ;;
    esac
  fi
  # Default work name to work GitHub username if not set
  [ -z "$STRAP_GIT_NAME_WORK" ] && STRAP_GIT_NAME_WORK="$STRAP_GITHUB_USER_WORK"
fi

# Interactive prompts for required variables (works on fresh macOS without gum)
prompt_if_missing() {
  local var_name="$1" prompt_text="$2" default_val="$3"
  local current_val="${!var_name}"
  if [ -z "$current_val" ]; then
    if [ "$STRAP_INTERACTIVE" -gt 0 ] 2>/dev/null || [ -t 0 ]; then
      if [ -n "$default_val" ]; then
        read -rp "--> $prompt_text [$default_val]: " input
        eval "$var_name=\"\${input:-$default_val}\""
      else
        read -rp "--> $prompt_text: " input
        eval "$var_name=\"\$input\""
      fi
    fi
  fi
}

prompt_if_missing STRAP_GIT_NAME "Enter your PERSONAL full name for git commits"
prompt_if_missing STRAP_GIT_EMAIL "Enter your PERSONAL email for git commits"
prompt_if_missing STRAP_GITHUB_USER "Enter your PERSONAL GitHub username" "handshou"
prompt_if_missing STRAP_GIT_EMAIL_WORK "Enter your WORK email (leave blank to skip work setup)"
if [ -n "$STRAP_GIT_EMAIL_WORK" ]; then
  prompt_if_missing STRAP_GIT_NAME_WORK "Enter your WORK full name for git commits"
  prompt_if_missing STRAP_GITHUB_USER_WORK "Enter your WORK GitHub username"
fi

STRAP_GIT_NAME=${STRAP_GIT_NAME:?Variable not set}
STRAP_GIT_EMAIL=${STRAP_GIT_EMAIL:?Variable not set}
STRAP_GITHUB_USER=${STRAP_GITHUB_USER:?Variable not set}
DEFAULT_DOTFILES_URL="https://github.com/$STRAP_GITHUB_USER/dotfiles"
STRAP_DOTFILES_URL=${STRAP_DOTFILES_URL:="$DEFAULT_DOTFILES_URL"}
STRAP_DOTFILES_BRANCH=${STRAP_DOTFILES_BRANCH:="main"}
STRAP_SUCCESS=""

sudo_askpass() {
  if [ -n "$SUDO_ASKPASS" ]; then
    sudo --askpass "$@"
  else
    sudo "$@"
  fi
}

cleanup() {
  set +e
  sudo_askpass rm -rf "$CLT_PLACEHOLDER" "$SUDO_ASKPASS" "$SUDO_ASKPASS_DIR"
  sudo --reset-timestamp
  if [ -z "$STRAP_SUCCESS" ]; then
    if [ -n "$STRAP_STEP" ]; then
      echo "!!! $STRAP_STEP FAILED" >&2
    else
      echo "!!! FAILED" >&2
    fi
    if [ "$STRAP_DEBUG" -eq 0 ]; then
      echo "!!! Run '$0 --debug' for debugging output." >&2
    fi
  fi
}
trap "cleanup" EXIT

if [ "$STRAP_DEBUG" -gt 0 ]; then
  set -x
else
  STRAP_QUIET_FLAG="-q"
  Q="$STRAP_QUIET_FLAG"
fi

# Prompt for sudo password and initialize (or reinitialize) sudo
sudo --reset-timestamp

clear_debug() {
  set +x
}
reset_debug() {
  if [ "$STRAP_DEBUG" -gt 0 ]; then
    set -x
  fi
}

sudo_init() {
  if [ "$STRAP_INTERACTIVE" -eq 0 ]; then return; fi
  # If TouchID for sudo is setup: use that instead.
  if grep -q pam_tid /etc/pam.d/sudo; then return; fi
  local SUDO_PASSWORD SUDO_PASSWORD_SCRIPT
  if ! sudo --validate --non-interactive &>/dev/null; then
    while true; do
      read -rsp "--> Enter your password (for sudo access):" SUDO_PASSWORD
      echo
      if sudo --validate --stdin 2>/dev/null <<<"$SUDO_PASSWORD"; then
        break
      fi
      unset SUDO_PASSWORD
      echo "!!! Wrong password!" >&2
    done
    clear_debug
    SUDO_PASSWORD_SCRIPT="$(
      cat <<-BASH
				#!/usr/bin/env bash
				echo "$SUDO_PASSWORD"
				BASH
    )"
    unset SUDO_PASSWORD
    SUDO_ASKPASS_DIR="$(mktemp -d)"
    SUDO_ASKPASS="$(mktemp "$SUDO_ASKPASS_DIR"/strap-askpass-XXXXXXXX)"
    chmod 700 "$SUDO_ASKPASS_DIR" "$SUDO_ASKPASS"
    bash -c "cat > '$SUDO_ASKPASS'" <<<"$SUDO_PASSWORD_SCRIPT"
    unset SUDO_PASSWORD_SCRIPT
    reset_debug
    export SUDO_ASKPASS
  fi
}

sudo_refresh() {
  clear_debug
  if [ -n "$SUDO_ASKPASS" ]; then
    sudo --askpass --validate
  else
    sudo_init
  fi
  reset_debug
}

abort() {
  STRAP_STEP=""
  echo "!!! $*" >&2
  exit 1
}
log() {
  STRAP_STEP="$*"
  sudo_refresh
  echo "--> $*"
}
logn() {
  STRAP_STEP="$*"
  sudo_refresh
  printf -- "--> %s " "$*"
}
logk() {
  STRAP_STEP=""
  echo "OK"
}
escape() {
  printf '%s' "${1//\'/\'}"
}

# Given a list of scripts in the dotfiles repo, run the first one that exists
run_dotfile_scripts() {
  if [ -d ~/.dotfiles ]; then
    (
      cd ~/.dotfiles
      for i in "$@"; do
        if [ -f "$i" ] && [ -x "$i" ]; then
          log "Running dotfiles $i:"
          if [ "$STRAP_DEBUG" -eq 0 ]; then
            "$i" 2>/dev/null
          else
            "$i"
          fi
          break
        fi
      done
    )
  fi
}

[ "$USER" = "root" ] && abort "Run bootstrap.sh as yourself, not root."

# shellcheck disable=SC2086
if [ "$MACOS" -gt 0 ]; then
  [ "$STRAP_CI" -eq 0 ] && caffeinate -s -w $$ &
  groups | grep $Q -E "\b(admin)\b" || abort "Add $USER to admin."
  logn "Configuring security settings:"
  SAFARI="com.apple.Safari"
  sudo_askpass defaults write $SAFARI \
    $SAFARI.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
  sudo_askpass defaults write $SAFARI \
    $SAFARI.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles \
    -bool false
  sudo_askpass defaults write com.apple.screensaver askForPassword -int 1
  sudo_askpass defaults write com.apple.screensaver askForPasswordDelay -int 0
  sudo_askpass defaults write \
    /Library/Preferences/com.apple.alf globalstate -int 1
  sudo_askpass launchctl load \
    /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null
  if [ -n "$STRAP_GIT_NAME" ] && [ -n "$STRAP_GIT_EMAIL" ]; then
    FOUND="Found this computer? Please contact"
    LOGIN_TEXT=$(escape "$FOUND $STRAP_GIT_NAME at $STRAP_GIT_EMAIL.")
    echo "$LOGIN_TEXT" | grep -q '[()]' && LOGIN_TEXT="'$LOGIN_TEXT'"
    sudo_askpass defaults write \
      /Library/Preferences/com.apple.loginwindow LoginwindowText "$LOGIN_TEXT"
    logk
  fi
fi

# Check for and enable full-disk encryption
logn "Checking full-disk encryption status:"
VAULT_MSG="FileVault is (On|Off, but will be enabled after the next restart)."
# shellcheck disable=SC2086
if fdesetup status | grep $Q -E "$VAULT_MSG"; then
  logk
elif [ "$MACOS" -eq 0 ] || [ "$STRAP_CI" -gt 0 ]; then
  echo
  logn "Skipping full-disk encryption."
elif [ "$STRAP_INTERACTIVE" -gt 0 ]; then
  echo
  log "Enabling full-disk encryption on next reboot:"
  sudo_askpass fdesetup enable -user "$USER" |
    tee ~/Desktop/"FileVault Recovery Key.txt"
  logk
else
  echo
  abort "Run 'sudo fdesetup enable -user \"$USER\"' for full-disk encryption."
fi

# Set up Xcode Command Line Tools
install_xcode_clt() {
  if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
    log "Installing the Xcode Command Line Tools:"
    CLT_STRING=".com.apple.dt.CommandLineTools.installondemand.in-progress"
    CLT_PLACEHOLDER="/tmp/$CLT_STRING"
    sudo_askpass touch "$CLT_PLACEHOLDER"
    CLT_PACKAGE=$(softwareupdate -l |
      grep -B 1 "Command Line Tools" |
      awk -F"*" '/^ *\*/ {print $2}' |
      sed -e 's/^ *Label: //' -e 's/^ *//' |
      sort -V |
      tail -n1)
    sudo_askpass softwareupdate -i "$CLT_PACKAGE"
    sudo_askpass rm -f "$CLT_PLACEHOLDER"
    if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
      if [ "$STRAP_INTERACTIVE" -gt 0 ]; then
        echo
        logn "Requesting user install of Xcode Command Line Tools:"
        xcode-select --install
      else
        echo
        abort "Install Xcode Command Line Tools with 'xcode-select --install'."
      fi
    fi
    logk
  fi
}

# shellcheck disable=SC2086
check_xcode_license() {
  if /usr/bin/xcrun clang 2>&1 | grep $Q license; then
    if [ "$STRAP_INTERACTIVE" -gt 0 ]; then
      logn "Asking for Xcode license confirmation:"
      sudo_askpass xcodebuild -license
      logk
    else
      abort "Run 'sudo xcodebuild -license' to agree to the Xcode license."
    fi
  fi
}

if [ "$MACOS" -gt 0 ]; then
  install_xcode_clt
  check_xcode_license
else
  log "Not macOS. Xcode CLT install and license check skipped."
fi

# Generate SSH keys early (needed for git operations)
# https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
if [ ! -f ~/.ssh/config ]; then
  log "Setting up SSH keys and config"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Generate personal key
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    log "Generating personal SSH key"
    yes "y" | ssh-keygen -t ed25519 -C "$STRAP_GIT_EMAIL" -f ~/.ssh/id_ed25519 -N ""
    ssh-add ~/.ssh/id_ed25519
  fi

  # Generate work key if work email provided
  if [ -n "$STRAP_GIT_EMAIL_WORK" ] && [ ! -f ~/.ssh/id_ed25519_work ]; then
    log "Generating work SSH key"
    yes "y" | ssh-keygen -t ed25519 -C "$STRAP_GIT_EMAIL_WORK" -f ~/.ssh/id_ed25519_work -N ""
    ssh-add ~/.ssh/id_ed25519_work
  fi

  # Create SSH config with IdentitiesOnly to prevent key confusion
  log "Creating SSH config"
  cat > ~/.ssh/config << 'EOF'
# Personal GitHub
Host github.com
    HostName github.com
    User git
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# Work GitHub (use: git clone git@work.github.com:org/repo.git)
Host work.github.com
    HostName github.com
    User git
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
EOF
  chmod 600 ~/.ssh/config
fi

configure_git() {
  logn "Configuring Git:"
  if [ "$STRAP_CI" -gt 0 ]; then
    git config --global commit.gpgsign false
    git config --global gpg.format openpgp
  fi
  if [ -n "$STRAP_GIT_NAME" ] && ! git config user.name >/dev/null; then
    git config --global user.name "$STRAP_GIT_NAME"
  fi
  if [ -n "$STRAP_GIT_EMAIL" ] && ! git config user.email >/dev/null; then
    git config --global user.email "$STRAP_GIT_EMAIL"
  fi
  if [ -n "$STRAP_GITHUB_USER" ] &&
    [ "$(git config github.user)" != "$STRAP_GITHUB_USER" ]; then
    git config --global github.user "$STRAP_GITHUB_USER"
  fi
  # Set up GitHub HTTPS credentials
  # shellcheck disable=SC2086
  if git credential-osxkeychain 2>&1 | grep $Q "git.credential-osxkeychain"; then
    # Execute credential in case it's a wrapper script for credential-osxkeychain
    if git "credential-$(git config --global credential.helper 2>/dev/null)" 2>&1 |
      grep -v $Q "git.credential-osxkeychain"; then
      git config --global credential.helper osxkeychain
    fi
    if [ -n "$STRAP_GITHUB_USER" ] && [ -n "$STRAP_GITHUB_TOKEN" ]; then
      PROTOCOL="protocol=https\\nhost=github.com"
      printf "%s\\n" "$PROTOCOL" | git credential reject
      printf "%s\\nusername=%s\\npassword=%s\\n" \
        "$PROTOCOL" "$STRAP_GITHUB_USER" "$STRAP_GITHUB_TOKEN" |
        git credential approve
    else
      log "Skipping Git credential setup."
    fi
    logk
  fi
}

configure_git

# Check for and install any remaining software updates
logn "Checking for software updates:"
# shellcheck disable=SC2086
if softwareupdate -l 2>&1 | grep $Q "No new software available."; then
  logk
else
  if [ "$MACOS" -gt 0 ] && [ "$STRAP_CI" -eq 0 ]; then
    echo
    log "Installing software updates:"
    sudo_askpass softwareupdate --install --all
    check_xcode_license
  else
    log "Skipping software updates."
  fi
  logk
fi

# shellcheck disable=SC2086
install_homebrew() {
  logn "Installing Homebrew:"
  HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  [ -n "$HOMEBREW_PREFIX" ] || HOMEBREW_PREFIX="$DEFAULT_HOMEBREW_PREFIX"
  [ -d "$HOMEBREW_PREFIX" ] || sudo_askpass mkdir -p "$HOMEBREW_PREFIX"
  if [ "$MACOS" -gt 0 ]; then
    sudo_askpass chown "root:wheel" "$HOMEBREW_PREFIX" 2>/dev/null || true
  else
    sudo_askpass chown "root:root" "$HOMEBREW_PREFIX" 2>/dev/null || true
  fi
  (
    cd "$HOMEBREW_PREFIX"
    sudo_askpass mkdir -p \
      Cellar Caskroom Frameworks bin etc include lib opt sbin share var
    if [ "$MACOS" -gt 0 ]; then
      sudo_askpass chown "$USER:admin" \
        Cellar Caskroom Frameworks bin etc include lib opt sbin share var
    else
      sudo_askpass chown "$USER:$USER" \
        Cellar Caskroom Frameworks bin etc include lib opt sbin share var
    fi
  )
  HOMEBREW_REPOSITORY="$(brew --repository 2>/dev/null || true)"
  [ -n "$HOMEBREW_REPOSITORY" ] || HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
  [ -d "$HOMEBREW_REPOSITORY" ] || sudo_askpass mkdir -p "$HOMEBREW_REPOSITORY"
  if [ "$MACOS" -gt 0 ]; then
    sudo_askpass chown -R "$USER:admin" "$HOMEBREW_REPOSITORY"
  else
    sudo_askpass chown -R "$USER:$USER" "$HOMEBREW_REPOSITORY"
  fi
  if [ "$HOMEBREW_PREFIX" != "$HOMEBREW_REPOSITORY" ]; then
    ln -sf "$HOMEBREW_REPOSITORY/bin/brew" "$HOMEBREW_PREFIX/bin/brew"
  fi
  export GIT_DIR="$HOMEBREW_REPOSITORY/.git" GIT_WORK_TREE="$HOMEBREW_REPOSITORY"
  git init $Q
  git config remote.origin.url "https://github.com/Homebrew/brew"
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch $Q --tags --force
  git reset $Q --hard origin/HEAD
  unset GIT_DIR GIT_WORK_TREE
  logk
  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
  logn "Updating Homebrew:"
  brew update
  logk
}

set_up_brew_skips() {
  local brewfile_path casks ci_skips mas_ids mas_prefix
  log "Setting up Homebrew Bundle formula installs to skip."
  ci_skips="awscli black jupyterlab mkvtoolnix zsh-completions"
  [ "$STRAP_CI" -gt 0 ] && HOMEBREW_BUNDLE_BREW_SKIP="$ci_skips"
  if [ -f "$HOME/.Brewfile" ]; then
    brewfile_path="$HOME/.Brewfile"
  elif [ -f "Brewfile" ]; then
    brewfile_path="Brewfile"
  else
    abort "No Brewfile found"
  fi
  log "Setting up Homebrew Bundle cask installs to skip."
  if [ "$MACOS" -gt 0 ] && [ "$brewfile_path" == "$HOME/.Brewfile" ]; then
    casks="$(brew bundle list --global --cask --quiet | tr '\n' ' ')"
  elif [ "$MACOS" -gt 0 ] && [ "$brewfile_path" == "Brewfile" ]; then
    casks="$(brew bundle list --cask --quiet | tr '\n' ' ')"
  else
    log "Cask commands are only supported on macOS."
  fi
  HOMEBREW_BUNDLE_CASK_SKIP="${casks%% }"
  log "Setting up Homebrew Bundle Mac App Store (mas) installs to skip."
  mas_ids=""
  mas_prefix='*mas*, id: '
  while read -r brewfile_line; do
    # shellcheck disable=SC2295
    [[ $brewfile_line == *$mas_prefix* ]] && mas_ids+="${brewfile_line##$mas_prefix} "
  done <"$brewfile_path"
  HOMEBREW_BUNDLE_MAS_SKIP="${mas_ids%% }"
  log "HOMEBREW_BUNDLE_BREW_SKIP='$HOMEBREW_BUNDLE_BREW_SKIP'"
  log "HOMEBREW_BUNDLE_CASK_SKIP='$HOMEBREW_BUNDLE_CASK_SKIP'"
  log "HOMEBREW_BUNDLE_MAS_SKIP='$HOMEBREW_BUNDLE_MAS_SKIP'"
  export HOMEBREW_BUNDLE_BREW_SKIP="$HOMEBREW_BUNDLE_BREW_SKIP"
  export HOMEBREW_BUNDLE_CASK_SKIP="$HOMEBREW_BUNDLE_CASK_SKIP"
  export HOMEBREW_BUNDLE_MAS_SKIP="$HOMEBREW_BUNDLE_MAS_SKIP"
}

run_brew_installs() {
  local brewfile_domain brewfile_path brewfile_url git_branch github_user
  if ! command -v brew &>/dev/null; then
    log "brew command not in shell environment. Attempting to load."
    eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"
    command -v brew &>/dev/null && logk || return 1
  fi
  # Disable Homebrew Google Analytics: https://docs.brew.sh/Analytics
  brew analytics off
  [ "$STRAP_CI" -gt 0 ] || [ "$LINUX" -gt 0 ] && set_up_brew_skips
  [ "$LINUX" -gt 0 ] && brew install gcc # "We recommend that you install GCC"
  log "Running Homebrew installs."
  if [ -f "$HOME/.Brewfile" ]; then
    log "Installing from $HOME/.Brewfile with Brew Bundle."
    brew bundle check --global || brew bundle --global
    logk
  elif [ -f "Brewfile" ]; then
    log "Installing from local Brewfile with Brew Bundle."
    brew bundle check || brew bundle
    logk
  else
    [ -z "$STRAP_DOTFILES_BRANCH" ] && STRAP_DOTFILES_BRANCH=HEAD
    git_branch="${STRAP_DOTFILES_BRANCH##*/}"
    github_user="${STRAP_GITHUB_USER:?Variable not set}"
    brewfile_domain="https://raw.githubusercontent.com"
    brewfile_path="$github_user/dotfiles/$git_branch/Brewfile"
    brewfile_url="$brewfile_domain/$brewfile_path"
    log "Installing from $brewfile_url with Brew Bundle."
    curl -fsSL "$brewfile_url" | brew bundle --file=-
    logk
  fi
  # Tap a custom Homebrew tap
  if [ -n "$CUSTOM_HOMEBREW_TAP" ]; then
    read -ra CUSTOM_HOMEBREW_TAP <<<"$CUSTOM_HOMEBREW_TAP"
    log "Running 'brew tap ${CUSTOM_HOMEBREW_TAP[*]}':"
    brew tap "${CUSTOM_HOMEBREW_TAP[@]}"
    logk
  fi
  # Run a custom Brew command
  if [ -n "$CUSTOM_BREW_COMMAND" ]; then
    log "Executing 'brew $CUSTOM_BREW_COMMAND':"
    # shellcheck disable=SC2086
    brew $CUSTOM_BREW_COMMAND
    logk
  fi
}

# Install Homebrew early (needed for gum TUI and other tools)
# https://docs.brew.sh/Installation
script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
NONINTERACTIVE=$STRAP_CI \
  /usr/bin/env bash -c "$(curl -fsSL $script_url)" || install_homebrew

# Set up Homebrew on Linux: https://docs.brew.sh/Homebrew-on-Linux
# [ "$LINUX" -gt 0 ] && run_dotfile_scripts scripts/linuxbrew.sh

run_brew_installs || abort "Homebrew installs were not successful."

# Set up dotfiles, uncomment with ## for old config, ignore uncommenting # comments
# shellcheck disable=SC2086
if [ ! -f "$HOME/.bashrc" ]; then
  if [ -z "$STRAP_DOTFILES_URL" ]; then #|| [ -z "$STRAP_DOTFILES_BRANCH" ]; then
    abort "Please set STRAP_DOTFILES_URL." # and STRAP_DOTFILES_BRANCH."
  fi
  log "Cloning $STRAP_DOTFILES_URL to ~/tmp."
  git clone $Q "$STRAP_DOTFILES_URL" ~/tmp
  cp -a ~/tmp/. ~/
  rm -rf ~/tmp
  rm -rf ~/.git
fi
## strap_dotfiles_branch_name="${STRAP_DOTFILES_BRANCH##*/}"
## log "Checking out $strap_dotfiles_branch_name in ~/.dotfiles."
# shellcheck disable=SC2086
##(
##  cd ~/.dotfiles
##  git stash
##  git fetch $Q
##  git checkout "$strap_dotfiles_branch_name"
##  git pull $Q --rebase --autostash
##)

# Check if the font is installed in the specified directory
FONT_NAME="JetBrainsMonoNerdFont-Regular"
FONT_DIR="$HOME/Library/Fonts"
FONT_FILE="$HOME/JetBrainsMonoNerdFont-Regular.ttf"
if ls "$FONT_DIR" 2>/dev/null | grep -i "$FONT_NAME" | grep -i ".ttf\|.otf" >/dev/null; then
    log "Font '$FONT_NAME' is already installed."
elif command -v brew &>/dev/null; then
    log "Installing font via Homebrew..."
    brew install --cask font-jetbrains-mono-nerd-font
elif [ -f "$FONT_FILE" ]; then
    log "Installing font '$FONT_NAME' by copying to ~/Library/Fonts..."
    mkdir -p "$FONT_DIR"
    cp "$FONT_FILE" "$FONT_DIR/"
else
    log "Font '$FONT_NAME' not found. Please install manually."
fi

# run_dotfile_scripts scripts/macos-setup.sh
logk

if [ ! -d "$HOME/.cfg" ]; then
  if [ -z "$STRAP_DOTFILES_URL" ] || [ -z "$STRAP_DOTFILES_BRANCH" ]; then
    abort "Please set STRAP_DOTFILES_URL and STRAP_DOTFILES_BRANCH."
  fi
  log "Cloning $STRAP_DOTFILES_URL bare to ~/.cfg."
  git clone $Q --bare "$STRAP_DOTFILES_URL" $HOME/.cfg
  function config {
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"
  }
  mkdir -p .config-backup
  if config checkout 2>/dev/null; then
    log "Checked out config."
  else
    log "Backing up pre-existing files."
    # Extract filenames from git error output (lines starting with whitespace, containing paths)
    config checkout 2>&1 | grep -E "^\s+" | grep -v "^error:" | grep -v "Please move" | grep -v "Aborting" | awk '{$1=$1};1' | while read -r f; do
      if [ -n "$f" ] && [ -e "$f" ]; then
        mkdir -p ".config-backup/$(dirname "$f")"
        mv "$f" ".config-backup/$f" 2>/dev/null || true
      fi
    done
    config checkout
  fi
  config config --local status.showUntrackedFiles no
  # Initialize submodules (e.g., nvim config)
  log "Initializing git submodules"
  config submodule update --init --recursive
fi

# configure_git already called after SSH setup above

# Install neovim plugins (lazy.nvim)
if command -v nvim &>/dev/null; then
  log "Installing neovim plugins via lazy.nvim"
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || log "Neovim plugin install skipped (will install on first launch)"
fi

# Install nvm: https://github.com/nvm-sh/nvm
log "Installing node version manager (nvm)"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash

STRAP_SUCCESS=1
log "Your system is now bootstrapped!"

echo ""
echo "=============================================="
echo "  POST-INSTALL CHECKLIST"
echo "=============================================="
echo ""
echo "  1. ADD SSH KEYS TO GITHUB"
echo "  ─────────────────────────"
echo ""
echo "     PERSONAL account ($STRAP_GITHUB_USER):"
echo ""
echo "     Step 1: Copy your public key to clipboard:"
echo "       pbcopy < ~/.ssh/id_ed25519.pub"
echo ""
echo "     Step 2: Open in browser:"
echo "       https://github.com/settings/ssh/new"
echo ""
echo "     Step 3: Paste key, give it a name, click 'Add SSH key'"
echo ""
echo "     Step 4: Test connection:"
echo "       ssh -T git@github.com"
echo "       # Success: 'Hi $STRAP_GITHUB_USER! You've successfully authenticated...'"
echo ""
if [ -n "$STRAP_GIT_EMAIL_WORK" ]; then
echo "     ───────────────────────"
echo "     WORK account ($STRAP_GITHUB_USER_WORK):"
echo ""
echo "     Step 1: Copy your WORK public key:"
echo "       pbcopy < ~/.ssh/id_ed25519_work.pub"
echo ""
echo "     Step 2: Log into your WORK GitHub, then open:"
echo "       https://github.com/settings/ssh/new"
echo ""
echo "     Step 3: Paste key, give it a name, click 'Add SSH key'"
echo ""
echo "     Step 4: Test connection (uses work.github.com alias):"
echo "       ssh -T git@work.github.com"
echo "       # Success: 'Hi $STRAP_GITHUB_USER_WORK! You've successfully authenticated...'"
echo ""
echo "     Clone work repos using the alias:"
echo "       git clone git@work.github.com:org/repo.git"
echo ""
fi
echo "  2. SETUP SKHD"
echo "  ─────────────"
echo ""
echo "     Step 1: Ensure skhd is linked:"
echo "       brew unlink skhd-zig && brew link skhd-zig"
echo ""
echo "     Step 2: Verify skhd exists:"
echo "       ls -la /opt/homebrew/bin/skhd"
echo ""
echo "     Step 3: Grant Accessibility permission:"
echo "       - System Settings → Privacy & Security → Accessibility"
echo "       - Click '+', press Cmd+Shift+G"
echo "       - Paste: /opt/homebrew/bin/skhd"
echo "       - Click Open, then toggle ON"
echo ""
echo "     Step 4: Start skhd service:"
echo "       brew services start skhd-zig"
echo ""
echo "  3. SETUP YABAI"
echo "  ──────────────"
echo ""
echo "     NOTE: Full yabai features require partially disabling SIP."
echo "     See: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"
echo ""
echo "     Step 1: Start yabai service (creates plist and starts yabai):"
echo "       yabai --start-service"
echo ""
echo "     Step 2: Grant Accessibility & Screen Recording permissions:"
echo "       - System Settings → Privacy & Security → Accessibility → add yabai"
echo "       - System Settings → Privacy & Security → Screen Recording → add yabai"
echo "       Path: /opt/homebrew/bin/yabai"
echo ""
echo "     Step 3: Generate sudoers entry (copy the ENTIRE output including username):"
echo "       echo \"\$(whoami) ALL=(root) NOPASSWD: sha256:\$(shasum -a 256 \$(which yabai) | cut -d ' ' -f 1) \$(which yabai) --load-sa\""
echo ""
echo "       Example output: h ALL=(root) NOPASSWD: sha256:abc123... /opt/homebrew/bin/yabai --load-sa"
echo ""
echo "     Step 4: Edit sudoers file and paste the FULL line:"
echo "       sudo visudo -f /private/etc/sudoers.d/yabai"
echo ""
echo "     Step 5: Restart yabai and load scripting addition:"
echo "       yabai --restart-service"
echo "       sudo yabai --load-sa"
echo ""
echo "  4. INSTALL TMUX PLUGINS"
echo "  ───────────────────────"
echo ""
echo "     Step 1: Open tmux:"
echo "       tmux"
echo ""
echo "     Step 2: Press prefix + I to install plugins:"
echo "       Ctrl+a, then Shift+I"
echo ""
echo "     Step 3: Wait for 'TMUX environment reloaded' message"
echo ""
echo "  5. INSTALL NODE.JS VIA NVM"
echo "  ──────────────────────────"
echo ""
echo "     source ~/.nvm/nvm.sh && nvm install --lts"
echo ""
echo "  6. RESTART TERMINAL"
echo "  ───────────────────"
echo ""
echo "     Close and reopen Terminal, or run:"
echo "       source ~/.zshrc"
echo ""
echo "=============================================="
