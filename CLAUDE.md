# dotfiles

Personal dotfiles repository.

## Workflow

- This repo is not versioned and does not have ci/cd. Thus create commits directly in main branch (small, focused commits with --signoff)
- When making any change to this repository, make sure `README.md` stays up to date.
- This repo and code are maintained in English
- **Check CI at the start of work, not by blocking after every push.** The `smoke`
  workflow has two jobs: a fast `templates` job (ubuntu, ~8s, renders the chezmoi
  templates) and a slow `bare-machine` job (macOS, full bootstrap + package install,
  8+ min). When you first touch this repo in a session, check the latest run on `main`
  (`gh run list --workflow=smoke.yml --branch main --limit 1`; `gh` is a mise tool).
  If it failed, fix it before starting new work — a red `main` is a defect, not
  something to ignore (another machine's `chezmoi update` would apply broken config).
  Inspect failures with `gh run view <id> --log-failed`.
- After pushing, a quick glance at the fast `templates` job is worth it, but **do not
  block waiting on the slow `bare-machine` job** — its result is picked up by the
  start-of-work check above.
- Doc-only changes (`**.md`, e.g. this file or `README.md`) do not trigger `smoke`
  (see `paths-ignore` in `smoke.yml`), so they need no CI check at all.

## Installing tools

If a CLI tool can be installed via [mise](https://mise.jdx.dev), use mise (mise-first).
Anything mise can't manage (e.g. GUI casks) is installed via [Homebrew](https://brew.sh).

When adding a tool that keeps a cache or writes outside its own install dir (a package
manager, language toolchain, etc.), check whether `~/.local/bin/cleanup` should learn it —
a Tier 1 cache-clean or a Tier 2 orphan entry. External backend caches like rustup's
`~/.rustup` or cargo's `~/.cargo` are exactly what the script otherwise misses.

## chezmoi templates (`*.tmpl`)

- chezmoi parses `{{ ... }}` **everywhere in a `.tmpl` file, including inside `#` comments**.
  A literal `{{` or `}}` in a comment breaks `chezmoi apply` with `missing value for command`.
  To mention the delimiters in a comment, write them as words ("template directives") or escape:
  `{{ "{{" }}`.
- Edit templated files at the **source** (`chezmoi edit` / the repo) then `chezmoi apply`.
  **Never `chezmoi add` a template** — it overwrites the source with rendered content and destroys
  the `{{ ... }}` directives (incl. secrets). `chezmoi add` is only for non-templated targets.
