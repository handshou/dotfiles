# Engineering rules

- Do not use React `useEffect`; prefer derived state, event handlers, framework APIs, or external-store subscriptions.
- Do not add code comments; communicate intent through names, types, structure, and tests.
- Keep each change atomic. Exclude unrelated cleanup and refactoring.
- Benchmark performance-sensitive changes against the merge base.
- Treat a failed performance budget as a hard failure. Never weaken or replace the baseline without approval.
- Run all relevant lint, typecheck, test, build, and performance checks before completion.
