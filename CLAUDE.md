# dotfiles

Personal dotfiles repository.

## Workflow

- When making any change to this repository, make sure `README.md` stays up to date.
- This repo and code are maintained in English
- After pushing a change, check the `smoke` CI workflow and investigate any failure it
  surfaces — a red smoke run is a defect to fix, not to ignore. List runs with
  `gh run list --workflow=smoke.yml` (`gh` is a mise tool) and inspect a failure with
  `gh run view <id> --log-failed`.

## Installing tools

If a CLI tool can be installed via [mise](https://mise.jdx.dev), use mise (mise-first).
Anything mise can't manage (e.g. GUI casks) is installed via [Homebrew](https://brew.sh).

## chezmoi templates (`*.tmpl`)

- chezmoi parses `{{ ... }}` **everywhere in a `.tmpl` file, including inside `#` comments**.
  A literal `{{` or `}}` in a comment breaks `chezmoi apply` with `missing value for command`.
  To mention the delimiters in a comment, write them as words ("template directives") or escape:
  `{{ "{{" }}`.
- Edit templated files at the **source** (`chezmoi edit` / the repo) then `chezmoi apply`.
  **Never `chezmoi add` a template** — it overwrites the source with rendered content and destroys
  the `{{ ... }}` directives (incl. secrets). `chezmoi add` is only for non-templated targets.
