# dotfiles

Personal dotfiles repository.

## Workflow

- This repo is not versioned and does not have ci/cd. Thus create commits directly in main branch (small, focused commits with --signoff)
- When making any change to this repository, make sure `README.md` stays up to date.
- This repo and code are maintained in English
- **Check CI at the start of work, not by blocking after every push.** The `smoke` workflow has two jobs: a fast `templates` job (ubuntu, ~8s, renders the chezmoi templates) and a slow `bare-machine` job (macOS, full bootstrap + package install, 8+ min). When you first touch this repo in a session, check the latest run on `main` (`gh run list --workflow=smoke.yml --branch main --limit 1`; `gh` is a mise tool). If it failed, fix it before starting new work — a red `main` is a defect, not something to ignore (another machine's `chezmoi update` would apply broken config). Inspect failures with `gh run view <id> --log-failed`.
- After pushing, a quick glance at the fast `templates` job is worth it, but **do not block waiting on the slow `bare-machine` job** — its result is picked up by the start-of-work check above.
- Doc-only changes (`**.md`, e.g. this file or `README.md`) do not trigger `smoke` (see `paths-ignore` in `smoke.yml`), so they need no CI check at all.

## Installing tools

If a CLI tool can be installed via [mise](https://mise.jdx.dev), use mise (mise-first). Anything mise can't manage (e.g. GUI casks) is installed via [Homebrew](https://brew.sh).

**Backend preference, in order** — this mirrors mise's own registry acceptance tiers, so a bare tool name usually lands on the right one already. State a backend explicitly only when the tool is absent from the mise registry, or when the registry's first choice is wrong for us (and then say why, in a comment):

1. `aqua:owner/repo` — default. Most features and security, no plugin to execute. Also the right pick over `github:` when the aqua-registry entry does something the raw release does not: renaming the binary (`kubectl-view-secret`), or verifying checksums.
2. `github:owner/repo` (or `gitlab:`) — when there is no aqua package. Verifies GitHub artifact attestations and SLSA provenance.
3. `http:` — vendor-distributed binaries with no Git host at all. Pin the version and the sha256 (`http:yc`), since nothing else vouches for the artifact.
4. `pipx:` / `npm:` / `gem:` / `cargo:` — only for tools native to that ecosystem, where the language's package manager is the honest home.

**Never `ubi:`** — deprecated, gone in mise 2027.1.0; `github:` is its successor. mise is configured to refuse it (`settings.disable_backends`) and CI rejects both a `ubi:` declaration and the removal of that ban.

**Never introduce a new `vfox:` or `asdf:` tool** — mise stopped accepting them for supply-chain reasons, because a plugin is arbitrary code executed at install time. Three pre-existing tools still resolve to vfox because nothing else can install them; the README records why. Don't add a fourth, and don't "fix" those three without reading that section.

When adding a tool that keeps a cache or writes outside its own install dir (a package manager, language toolchain, etc.), check whether `~/.local/bin/cleanup` should learn it — a Tier 1 cache-clean or a Tier 2 orphan entry. External backend caches like rustup's `~/.rustup` or cargo's `~/.cargo` are exactly what the script otherwise misses.

## chezmoi templates (`*.tmpl`)

- chezmoi parses `{{ ... }}` **everywhere in a `.tmpl` file, including inside `#` comments**. A literal `{{` or `}}` in a comment breaks `chezmoi apply` with `missing value for command`. To mention the delimiters in a comment, write them as words ("template directives") or escape: `{{ "{{" }}`.
- Edit templated files at the **source** (`chezmoi edit` / the repo) then `chezmoi apply`. **Never `chezmoi add` a template** — it overwrites the source with rendered content and destroys the `{{ ... }}` directives (incl. secrets). `chezmoi add` is only for non-templated targets.
