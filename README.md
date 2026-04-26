# baegagopa.github.io

Public GitHub Pages repository for CrossPromo publish artifacts only.

## Public URLs

- Config: `https://baegagopa.github.io/config/crosspromo.json`
- Asset example: `https://baegagopa.github.io/assets/sample-utility-icon.svg`

## What belongs in Git

Keep only public publish artifacts in this repository.

- `config/crosspromo.json`
- `assets/`
- `.nojekyll`
- lightweight public documentation like this `README.md`

## What should stay out of Git

Do not keep private operations tooling in this public repository.

Recommended to manage these in Perforce (P4) or another private workspace:

- GUI management tools
- batch or PowerShell publish helpers
- local validation helpers
- staging folders like `incoming/`
- internal notes, drafts, or source design files

## Recommended Split

- Git: final public files that must be served by GitHub Pages
- P4: internal tool source, GUI app, local automation, and working files

A good long-term flow is:

1. Manage CrossPromo content with a private tool in P4.
2. Export final `crosspromo.json` and final assets into this repository.
3. Commit and push only the publish result.

## Current Live Layout

- `config/crosspromo.json`: live public config
- `assets/`: live public images

## Notes

- This repository is public, so anything pushed here can be read by others.
- If a file should not be publicly visible, keep it in P4 instead of Git.
- Prefer keeping this repository small and publish-focused.
