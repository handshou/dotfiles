# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

source ~/.bashrc

# prune git branches
function prune-local () {
  git fetch -p;
  git branch -vv | grep ': gone]' | grep -v '*' | awk '{ print $1; }' > /tmp/branch-to-delete;
  ${EDITOR:-vi} /tmp/branch-to-delete;
  xargs git branch -D < /tmp/branch-to-delete;
  rm /tmp/branch-to-delete;
}

# Keep project skills explicitly user-invoked only.
function sklock () {
  python3 - <<'PY'
from pathlib import Path

override = Path("AGENTS.override.md")
override.touch(exist_ok=True)

roots = [path for path in (Path("agents/skills"), Path(".agents/skills")) if path.exists()]
files = sorted({path.resolve() for root in roots for path in root.glob("**/SKILL.md")})

if not files:
    raise SystemExit("sklock: no skills found under agents/skills or .agents/skills")

changed = 0
for path in files:
    text = path.read_text()
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        print(f"sklock: skipped {path} (no YAML frontmatter)")
        continue

    end = next((i for i, line in enumerate(lines[1:], 1) if line.strip() == "---"), None)
    if end is None:
        print(f"sklock: skipped {path} (unclosed YAML frontmatter)")
        continue

    field_indexes = [i for i in range(1, end) if lines[i].startswith("disable-model-invocation:")]
    desired = "disable-model-invocation: true\n"
    if field_indexes:
        first = field_indexes[0]
        updated = lines[:first] + [desired] + [
            line for i, line in enumerate(lines[first + 1:], first + 1)
            if i not in field_indexes[1:]
        ]
    else:
        name_index = next((i for i in range(1, end) if lines[i].startswith("name:")), 0)
        updated = lines[:name_index + 1] + [desired] + lines[name_index + 1:]

    new_text = "".join(updated)
    if new_text != text:
        path.write_text(new_text)
        changed += 1

print(f"sklock: {changed} changed, {len(files) - changed} already locked; AGENTS.override.md present")
PY
}

# poetry in python3
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Darktable
export PATH="/Applications/darktable.app/Contents/MacOS:$PATH"

source <(fzf --zsh)

# Add tmux-sessionizer script to PATH
export PATH="$HOME/scripts/tmux-sessionizer:$PATH"

# Alias for tmux-sessionizer
alias tmux-sessionizer="tmux-sessionizer"

# Add ssh keys for git
if [ "$SSH_AUTH_SOCK" = "" -a -x /usr/bin/ssh-agent ]; then
    eval `/usr/bin/ssh-agent`
    # eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519_work
    ssh-add ~/.ssh/id_ed25519
fi

# Format ONLY the Python files you've changed (working tree + staged) on the
# current branch — never the whole tree. Mirrors the lefthook pre-commit hook
# (`ruff format {staged_files}`) so manual runs stop reformatting dormant files
# owned by other teams. ruff discovers each file's nearest pyproject.toml, so
# per-service config (quote-style etc.) still applies.
function ruff-mine () {
  local files
  files=$( { git diff --name-only --diff-filter=d HEAD -- '*.py'; \
             git diff --cached --name-only --diff-filter=d -- '*.py'; } \
           | sort -u | grep . )
  if [ -z "$files" ]; then
    echo "ruff-mine: no changed .py files"
    return 0
  fi
  echo "$files" | tr '\n' ' ' | xargs ruff format
  echo "$files" | tr '\n' ' ' | xargs ruff check --fix
}

# direnv: per-directory env vars (.envrc)
eval "$(direnv hook zsh)"
