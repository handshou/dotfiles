# Pi dotfiles: two-machine coordination

## Read this before changing either machine

This note is a coordination handoff, **not a completed migration**. It was written on the machine where the user requested the `agent` → `base` cleanup (Machine A). The other machine is Machine B.

Repository: `git@github.com:handshou/dotfiles.git`, branch `main`.

The `config` shell alias is:

```sh
/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME"
```

Use `config`, not plain `git` from `~/.config`. This is a bare dotfiles repository with `$HOME` as its worktree. Uncommitted changes on one machine are not transferred by Git.

**Only this handoff document is being committed and pushed now.** The cleanup described below remains uncommitted on Machine A. Do not interpret this document appearing on GitHub as the migration having shipped.

## Machine A: actual local state

- `~/.pi/agent` was deleted after auditing its dependencies.
- Still-used resources were moved to `~/.pi/base` (initially named `shared`, then renamed at the user's request).
- Twelve profile symlinks were repointed to `base`.
- Old session files were merged into `personal/sessions`, checking for conflicting filenames first. They remain private and untracked.
- Obsolete default-profile package trees and generated state were deleted; roughly 221 MB was freed. No archive was created.
- The old default `auth.json` was empty. Active personal/work auth files were left alone.
- `~/.zshrc` now defaults `PI_CODING_AGENT_DIR` to `~/.pi/personal` only if it is unset or empty. Explicit work selection is preserved.
- No directory-based work/personal switching was added. Profile selection is by environment/launcher, not by current directory.
- Personal Plannotator was verified at 0.28.23 during this work. The initially reported older extension belonged to the inactive default profile, not the active personal profile.

### Intended local layout

```text
~/.pi/
  base/       # Shared authored resources, not an active agent profile
  personal/   # Personal profile, own settings/auth/packages/sessions
  work/       # Work profile, own settings/auth/packages/sessions
```

`base` is our organizational choice, not a special Pi feature. Pi loads these resources through profile symlinks.

Both profiles link to these `base` resources:

- `extensions/`
- `themes/`
- `keybindings.json`
- `cloak.json`

Additional links:

- `personal/skills/herdr` → `../../base/skills/herdr`
- `work/skills` → `../base/skills`
- `work/mcp.json` → `../base/mcp.json`
- `work/pi-transcribe.json` → `../base/pi-transcribe.json`

Personal retains its own `skills/` directory and `mcp.json`. Other profile-owned state stays separate. Some base skills are themselves links to `~/.agents/skills`; preserve valid targets rather than replacing them with duplicate copies.

### Shell changes

The local default is:

```sh
export PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/personal}"
```

The existing `pi` function runs `command pi update --all` before ordinary launches. Its management-command cases bypass that startup update. New interactive zsh shells load the default above; Pi's built-in default was not changed. Launches outside that shell setup need an explicit agent directory or equivalent environment setup.

`herdr-personal` selects personal and `herdr-work` selects work. There is no automatic profile switch when changing directories, and an already-running Pi session should not be assumed to change profiles.

## Changes already pulled from Machine B

Machine A fetched and fast-forwarded through `a5ad75d`:

- `54c19ed` — MCP SQL access, model keybinding, Supabase token prompt
- `02fe73d` — opt-in Supabase shell authentication
- `413bcd0` — scope Supabase token to `herdr-work`
- `a5ad75d` — Slack secret loading and portable Claude command

Incoming changes to the old `agent` paths were reconciled into the local `base` paths:

- `base/keybindings.json` includes `app.models.save: alt+s`.
- `base/extensions/mcp-read-only/index.ts` includes Supabase `execute_sql` in the allowlist.
- `~/.zshrc` includes the subshell-scoped `herdr-work`, missing-token prompts for Supabase/Slack, `claude` lookup through PATH, and removal of the inherited Claude config-directory override. The local personal-profile default was reapplied afterward.

**Security check still needed:** allowing `execute_sql` in the client gate does not itself make SQL read-only. Confirm the server/credential policy enforces the intended access. This was an incoming change, not an independently verified security guarantee.

## What remains uncommitted on Machine A

- `agent` → `base` resource moves and deletion of obsolete `agent/settings.json`.
- Profile symlink changes.
- Personal-default export in `.zshrc`.
- `.pi/AGENTS.md` and `.pi/native-mcp.md` updates.
- `.pi/.gitignore` addition for `/base/mcp.json`.
- An unrelated `.agents/.skill-lock.json` modification exists; do not silently bundle it into this migration.

`base/mcp.json` is private and ignored locally. Profile auth, OAuth state, sessions, npm/git installs, model stores, and backups must not be committed. Remaining untracked profile files include `.extmgr-cache`, voice migration markers, `models.json`, and `trust.json`; review/tighten ignore rules before staging. Review model configuration for private identifiers rather than assuming it is safe to publish.

Do not use a broad `config add -A` across the home directory.

## Machine B: morning checklist

1. Inspect local state **before pulling or moving anything**:

   ```sh
   config status --short --untracked-files=all
   config log -5 --oneline
   printf '%s\n' "${PI_CODING_AGENT_DIR:-<unset>}"
   ls -ld ~/.pi/agent ~/.pi/base ~/.pi/shared ~/.pi/personal ~/.pi/work 2>/dev/null
   ```

2. Identify whether Machine B already has an uncommitted equivalent migration. Inspect profile symlink targets and check for references to `agent`, `shared`, or `base`. Do not delete a directory just because its name looks obsolete: active profiles may link into it.
3. Compare Machine B's `.zshrc`, profile settings, and authored resources against this note and Machine A's pending diff. Report unique changes before choosing one final migration commit.
4. Keep Machine B's credentials, sessions, trust decisions, caches, and machine-specific runtime state local. Check unique data before deleting obsolete installations. Never copy work credentials into personal just to make files match.
5. If a pull would overwrite local edits or untracked files, stop and reconcile them explicitly. Do not use `reset --hard`, `clean -fd`, or blanket deletion to force the pull.
6. Prefer one reviewed migration commit, followed by both machines adopting it, rather than independently committing equivalent renames. If B already has a migration commit, compare its contents before cherry-picking or merging.
7. If renames conflict with new edits at old paths, merge the edits into `base` rather than discarding them or recreating a third installation.

## Validation before the final migration commit

- Verify every profile symlink resolves, including nested skill links.
- Verify new zsh shells default to personal and preserve an explicitly selected work profile.
- Verify required launchers outside interactive zsh set the intended profile.
- Run `zsh -n ~/.zshrc` and relevant extension checks. Machine A has passed shell syntax and basic JSON/link checks; full extension tests and interactive authentication flows have **not** been verified.
- Test Supabase/Slack prompts and ensure their secrets remain scoped to the work launcher.
- Verify both profiles still load their extensions, themes, keybindings, MCP configuration, and their own credentials.
- Audit staged paths and content for secrets and generated state. Stage the old tracked paths and corresponding new authored resources together so Git can recognize renames.
- Finish review and update the documentation: `.pi/AGENTS.md` currently has an updated profile preface but still contains a legacy `agent/` resource map below it.

A Plannotator review was opened on Machine A using a temporary snapshot under `/var/folders/.../pi-config-review-.../repo` because the dotfiles repository is bare. That directory is only a review copy, not the live Pi configuration. No approval has been received in this conversation. Do not edit the snapshot as if it were the source.

## Coordination protocol

Before committing the migration, report:

- Machine B's current layout and uncommitted/committed unique changes.
- Which machine will author the final migration commit.
- Any private/local files that must be retained or ignored.
- Checks performed and remaining failures.

After committing and pushing the migration, update this note with the migration commit hash and each machine's adoption status. Until then, GitHub's resource layout remains `agent`; the `base` layout exists locally on Machine A and may independently exist on Machine B.
