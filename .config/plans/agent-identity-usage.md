# Native Pi and identity commands

Reload existing zsh terminals after the change:

```sh
source ~/.zshrc
rehash
```

## Daily use

```sh
herdr-personal
herdr-work
```

Inside the selected session:

```sh
pi
pi --continue
command pi update --extensions
```

There is one Pi launch alias, not separate personal/work launch implementations. It reads `PI_CODING_AGENT_DIR` from the selected environment; personal is the fallback. For a plain terminal outside Herdr, deliberately select the directory first with `export PI_CODING_AGENT_DIR="$HOME/.pi/work"` or the personal equivalent. This selects Pi only—not every other tool's credentials.

The alias supplies `-nc -na -ns`, `--skill "$HOME/.agents/skills"`, the selected profile's skill directory, and an explicit per-project session directory. Machine skills retain `disable-model-invocation: true`: available through `/skill:name`, not in the automatic skill catalog. Future updates must retain this metadata. Extensions/packages and MCP are configured in the native profile files; no `profiles.json` or Python launcher is involved.

No `pi-update` or `pi-manual` convenience command remains. Native maintenance commands bypass the launch alias:

```sh
command pi update --extensions -na   # Packages only
command pi update -na                # Pi itself
command pi update --all -na          # Both
command pi list
```

The launch alias does not dispatch management subcommands; use the forms above rather than `pi update`. Piping into ordinary `pi` preserves Pi's stdin behavior. Noninteractive scripts must pass the intended flags/environment themselves because zsh aliases are not standalone executables.

## Git and GitHub

Native Git configuration selects work under `~/Code/work/`, personal elsewhere. Existing local overrides and projects under Developer remain untouched. Work/personal keys and signing are distinct; `config` remains the dotfiles Git alias.

Run ordinary `gh` in either session. There are no `gh`, `gh-personal`, or `gh-work` aliases/functions. Native `GH_CONFIG_DIR` selects `~/.config/gh-personal` (handshou) or `~/.config/gh-work` (hanselse); credentials remain in the existing macOS Keychain. The new YAML files contain only public account selectors/preferences, not tokens. Herdr entry aliases set the selected directory; re-sourcing `.zshrc` inside an existing named session selects the matching directory and clears old token overrides. Fresh terminals outside Herdr default to personal.

```sh
source ~/.zshrc
gh api user --jq .login
```

Expect handshou in personal, hanselse in work. Agents already running retain their inherited environment; start new agent processes after reloading the shell. Git HTTPS helpers explicitly select the matching native gh directory, independent of terminal selection. Git API identity no longer automatically changes when you cd: choose the work or personal terminal. Existing native `~/.config/gh` was preserved. Avoid `gh auth switch`/logout as an isolation mechanism: the directories select accounts but still share the Keychain service. The installed gh 2.102.0 source and concurrent real account checks confirmed username-specific lookup.

## Retired implementation and tests

`~/.config/agent-profiles` no longer exists. Its custom executable shims were removed from `~/.local/bin`. Old code and rollback snapshots are archived at:

`~/.local/state/pi-profile-migration-20261024/`

The four task-created test files and captured help output were **deleted at the user's request**. Native alias checks and actual Pi help startups passed before cleanup. Existing upstream skill/worktree tests remain untouched.

Native migration rollback: the archive's `rollback/` holds pre-task snapshots; `rollback/pre-simplification/` holds the intermediate setup before removing Python. Preserve later unrelated edits rather than blindly restoring whole files. No auth/session stores, keys, or repositories were moved or deleted.

Work Claude and both Codex homes still need deliberate user authentication; work Supabase/Vercel need work authorization. Computer MCP shares the host desktop. Existing Herdr processes were not restarted.
