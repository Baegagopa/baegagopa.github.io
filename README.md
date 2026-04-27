# baegagopa.github.io

Public GitHub Pages repository for published CrossPromo output only.

## Public URLs

- Config: `https://baegagopa.github.io/config/crosspromo.json`
- Asset example: `https://baegagopa.github.io/assets/sample-utility-icon.svg`

## What This Repo Should Contain

Keep only public publish artifacts here:

- `config/crosspromo.json`
- `assets/`
- `.nojekyll`
- lightweight public-facing documentation such as this `README.md`
- ignore files needed to keep the public repo clean

## What Must Stay Out Of GitHub

Do not commit private tooling or operator material into this public repository.

Examples that must stay outside GitHub:

- GUI or automation tool source
- PowerShell helper scripts used for internal publish work
- staging folders, temp exports, and drafts
- internal notes, runbooks, and operator-only screenshots
- anything under `CrossPromoTools/`

`CrossPromoTools/` should stay local or in P4 only, and should not be tracked by Git in this public repo.

## Public vs Private Rule Of Thumb

Publish to GitHub only if the file is safe for any anonymous visitor to read directly in the browser.

- `public`: final config, final assets, minimal public docs
- `private`: tooling, source materials, previews, exports, internal instructions, credentials, or anything that reveals internal workflow

If you would hesitate to paste the file into a public issue, it does not belong in this repository.

## Maintainer Safety

This repo includes sample local hooks under `.githooks/` and a GitHub Actions workflow under `.github/workflows/guard-private-tooling.yml` to block tracked files under `CrossPromoTools/`.

- local hooks help stop accidental staging or pushing before the change leaves your machine
- `.githooks/` is only a sample location; nothing runs automatically until you copy or symlink these hooks into `.git/hooks/` or configure `core.hooksPath`
- the GitHub Actions check helps stop accidental publication even if a local hook was skipped
