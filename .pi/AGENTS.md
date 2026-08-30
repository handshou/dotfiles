# PI AGENT HOME

Global Pi configuration and local extensions. TypeScript extensions are ESM-only. This directory is a live user home, not an npm workspace or Git checkout.

## Structure

```text
.pi/
├── AGENTS.md
└── agent/
    ├── settings.json       # Provider, model, theme, and installed packages
    ├── keybindings.json    # User keybinding overrides
    ├── cloak.json          # Secret-masking rules
    ├── trust.json          # Project trust decisions
    ├── extensions/         # Global local extensions
    │   ├── *.ts            # Single-file extensions
    │   └── */index.ts      # Multi-file or package-local extensions
    ├── skills/             # Global skills; one directory per skill
    ├── themes/             # Global theme JSON files
    ├── npm/                # Pi-managed npm package installation
    ├── git/                # Pi-managed git package checkouts
    └── sessions/           # Runtime session data
```

`auth.json`, model stores, timestamped backups, sessions, and installed-package trees are runtime or generated state.

## Where to look

| Task | Location |
| --- | --- |
| Change provider, model, theme, or package list | `agent/settings.json` |
| Install or update extension system commands | `~/Brewfile`; run `brew bundle --file ~/Brewfile` |
| Change keybindings | `agent/keybindings.json` |
| Change secret masking | `agent/cloak.json` |
| Create a single-file extension | `agent/extensions/<name>.ts` |
| Create a multi-file extension | `agent/extensions/<name>/index.ts` |
| Create a skill | `agent/skills/<name>/SKILL.md` |
| Add a theme | `agent/themes/<name>.json` |
| Change project trust decisions | `agent/trust.json` |

## Conventions

- Pi auto-discovers global extensions at `agent/extensions/*.ts` and `agent/extensions/*/index.ts`.
- Give a substantial extension its own directory. Add `package.json`, `tsconfig.json`, tests, and dependencies there when needed.
- Keep extension-specific dependencies in that extension's package; run installs and scripts from its directory.
- Use ESM (`"type": "module"`) and strict TypeScript for packaged extensions.
- A skill starts at `agent/skills/<name>/SKILL.md`; keep optional scripts, references, and assets beside it.
- Installed npm and git packages are declared in `agent/settings.json`; let Pi manage `agent/npm/` and `agent/git/`.
- System commands required by Pi extensions are declared in `~/Brewfile`; reconcile and upgrade them with `brew bundle --file ~/Brewfile`.
- Run the nearest package's checks after changes: `npm run check` when present, otherwise its `typecheck` and `test` scripts.

## Design changes

For a nontrivial feature, refactor, or new abstraction, present a contract map before implementation. At each affected boundary (for example API, service, class, and function), show **current → proposed** for:

- input types and validation
- output types and guarantees
- errors and failure behavior
- externally observable side effects

Make the proposal concrete enough to resemble pseudocode or signatures rather than a high-level product description. Prefer small, local abstractions that fit the existing design. Introduce broader architecture only when the contract map demonstrates the need, and get approval before implementing it.

## Guardrails

- Treat `agent/auth.json`, session files, model stores, backups, and package-manager internals as private runtime state. Avoid reading or editing them unless the task explicitly targets that state.
- Keep credentials and private model catalog IDs out of source, tests, fixtures, documentation, examples, comments, and other shareable files. Use public models or generic placeholders.
- Put secret-output patterns in `agent/cloak.json`; never encode actual secret values in masking rules.
- Edit `agent/settings.json` rather than manually changing Pi-managed package contents under `agent/npm/` or `agent/git/`.
- Keep generated dependencies such as `node_modules/` out of authored changes.
