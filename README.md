# baegagopa.github.io

Public GitHub Pages repository for CrossPromo publish artifacts only.

## Public URLs

- Config: `https://baegagopa.github.io/config/crosspromo.json`
- Asset example: `https://baegagopa.github.io/assets/sample-utility-icon.svg`

## Recommended Folder Split

Use a single top-level workspace, but split responsibility by folder:

- Git-managed public publish output
  - `config/`
  - `assets/`
  - `.nojekyll`
  - `README.md`
  - `.gitignore`
  - `.p4ignore`
- P4-managed private tooling
  - `CrossPromoTools/`

## What belongs in Git

Keep only public publish artifacts in this repository.

- `config/crosspromo.json`
- `assets/`
- `.nojekyll`
- lightweight public documentation like this `README.md`
- ignore/config files needed to keep the repo clean

## What belongs in P4

Keep all private operations tooling under `CrossPromoTools/`.

Recommended examples:

- GUI management tool source
- batch or PowerShell publish helpers
- local validation helpers
- staging folders and temp export files
- internal notes, drafts, and source design files

## Suggested CrossPromoTools Layout

```text
CrossPromoTools/
  App/
  Scripts/
  Incoming/
  Exports/
  Docs/
  Temp/
```

A simple long-term flow is:

1. Manage CrossPromo content with the private tool under `CrossPromoTools/`.
2. Export final `crosspromo.json` and final assets into the Git-managed root.
3. Commit and push only the public publish result.

## Current Live Layout

- `config/crosspromo.json`: live public config
- `assets/`: live public images

## Notes

- This repository is public, so anything pushed here can be read by others.
- If a file should not be publicly visible, keep it under `CrossPromoTools/` and manage it with P4 instead of Git.
- Prefer keeping this repository small and publish-focused.
