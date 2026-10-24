# GitHub CLI authentication without token injection

Research-only handoff from Herdr agent `gh-auth-research`, 2026-10-24. The research pane is closed. No login, account switching, or new GitHub configuration was performed as part of this research.

Installed CLI observed by parent: **gh 2.102.0** (2026-09-30). Research source comparisons covered v2.90.0/current trunk and v2.65.0, not an exact installed-version source audit.

## Findings

- `gh auth switch` is the simplest native option for sequential use. It changes the persistent active identity shared by terminals using the same configuration. Closing a terminal does not restore the previous account. Switch/run/switch-back sequences can race with other terminals.
- Separate `GH_CONFIG_DIR` directories selected once per terminal/Herdr environment are the promising token-free approach for simultaneous personal `handshou` and work `hanselse` sessions. Both can use existing macOS Keychain credentials when the CLI resolves the configured active username's entry first.
- This is version-sensitive. The researcher found username-first Keychain lookup in v2.90.0/current trunk, versus shared username-empty active-slot lookup in v2.65.0. Verify the installed 2.102.0 implementation or perform an isolated read-only account-resolution check before migration.
- `GH_CONFIG_DIR` does **not** namespace Keychain. The service remains `gh:github.com`, with entries keyed by username plus a shared fallback slot. Separate configuration directories select accounts; they are not separate security tenants. Login, refresh, or logout can affect shared credentials.
- There is no universal per-command `--account`/`--user` option for all `gh` commands. Some authentication subcommands have account-specific options; that does not make ordinary API/PR commands account-selectable by flag.
- `gh auth git-credential` gets the active token and then rejects a mismatched requested Git username. Git's credential username is a filter, not an account selector. Git conditional includes alone therefore cannot select the `gh` API account.
- GitHub API identity, SSH transport identity, and commit author/signing are independent layers.

## Applied after user approval

The user subsequently approved separate `GH_CONFIG_DIR` environments and requested removal of the account-specific command aliases. Exact v2.102.0 source inspection confirmed username-first Keychain lookup. Concurrent real checks using config-only selectors returned handshou and hanselse without token environment variables; the original configuration/account remained unchanged. The Herdr environments and native Git HTTPS helpers now select these directories. No login, auth switch, logout, token-file write, or new credential copy was performed. Existing token-injecting gh aliases were removed. This is account selection, not separate Keychain tenancy.

Exact installed-version source: https://github.com/cli/cli/blob/v2.102.0/internal/config/config.go

## Recommendation

Prefer separately selected `GH_CONFIG_DIR` environments for concurrent work/personal terminals if installed-version validation succeeds. Preserve existing Keychain credentials, use configuration-only selectors, and verify each environment's `gh api user --jq .login` before removing the current token-based aliases. No custom Python launcher is required. Existing long-lived Herdr servers will not adopt environment changes merely by reattaching.

Use native `gh auth switch` only if one active account at a time is acceptable. Do not promise concurrent safety or automatic restoration when closing a terminal.

## Sources

- https://cli.github.com/manual/gh_auth_switch
- https://cli.github.com/manual/gh_help_environment
- https://cli.github.com/manual/gh_auth_login
- https://github.com/cli/cli/blob/v2.90.0/internal/config/config.go
- https://github.com/cli/cli/blob/v2.65.0/internal/config/config.go
- https://github.com/cli/cli/blob/trunk/pkg/cmd/auth/gitcredential/helper.go
