# dotfiles

[![smoke](https://github.com/sanchpet/dotfiles/actions/workflows/smoke.yml/badge.svg)](https://github.com/sanchpet/dotfiles/actions/workflows/smoke.yml)

Personal macOS development environment, managed declaratively with
[chezmoi](https://www.chezmoi.io) (dotfiles), [mise](https://mise.jdx.dev) (CLI tools),
and [Homebrew](https://brew.sh) (GUI apps).
One command on a bare machine → a fully configured setup. **Secrets never touch the repo.**

## Quick start (bare machine)

```sh
git clone https://github.com/sanchpet/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` is idempotent and runs, in order (mise-first):

1. **mise** — install the base tool manager (`curl https://mise.run`), then `chezmoi` via mise
2. **chezmoi init** — clone this repo into chezmoi's source
3. **apply mise config** — lay down `~/.config/mise/config.toml` *before* installing tools (breaks the chicken-and-egg: the mise config is itself a managed dotfile)
4. **mise install** — install CLI tools from the config (bitwarden-cli, uv, …)
5. **Bitwarden unlock** — only if the source contains `*.tmpl` secrets (interactive)
6. **Oh My Zsh** — install the zsh framework (without touching `.zshrc` or changing the shell)
7. **chezmoi apply** — render and place all dotfiles
8. **brew bundle** — GUI casks (Homebrew is installed lazily, only if the Brewfile needs it)

## Tools

### Foundation

| Tool | Purpose | Link |
|------|---------|------|
| mise | Polyglot tool & runtime manager — single declarative source for CLI tooling | <https://mise.jdx.dev> · [github](https://github.com/jdx/mise) |
| chezmoi | Dotfiles manager — templating, per-machine, secrets | <https://www.chezmoi.io> · [github](https://github.com/twpayne/chezmoi) |
| Oh My Zsh | Zsh configuration framework | <https://ohmyz.sh> · [github](https://github.com/ohmyzsh/ohmyzsh) |
| Homebrew | macOS package manager — used only for GUI casks | <https://brew.sh> |

### CLI tools (managed via mise)

| Tool | Purpose | Link |
|------|---------|------|
| Bitwarden CLI (`bw`) | Secret retrieval at `chezmoi apply` | <https://bitwarden.com/help/cli/> · [github](https://github.com/bitwarden/clients) |
| uv | Fast Python package & project manager | [docs](https://docs.astral.sh/uv/) · [github](https://github.com/astral-sh/uv) |
| Yandex Cloud CLI (`yc`) | Manage Yandex Cloud resources (IAM, compute, k8s, …) | [docs](https://yandex.cloud/docs/cli/) |

### Quality / dev workflow

| Tool | Purpose | Link |
|------|---------|------|
| pre-commit | Git pre-commit hook framework | <https://pre-commit.com> · [github](https://github.com/pre-commit/pre-commit) |
| shellcheck | Static analysis for shell scripts (via `shellcheck-py`) | [shellcheck](https://github.com/koalaman/shellcheck) · [hook](https://github.com/shellcheck-py/shellcheck-py) |
| pre-commit-hooks | Standard hygiene hooks (whitespace, EOF, YAML, …) | [github](https://github.com/pre-commit/pre-commit-hooks) |

### GUI (Homebrew cask)

| Tool | Purpose | Profile | Link |
|------|---------|---------|------|
| Freelens | Kubernetes IDE (open-source Lens fork) | all | [github](https://github.com/freelensapp/freelens) |
| .NET SDK | .NET toolchain | `work` only | [docs](https://dotnet.microsoft.com/download) |

## Repository layout

| Path | Role |
|------|------|
| `dot_*` | Dotfiles rendered into `$HOME` by chezmoi (e.g. `dot_gitconfig` → `~/.gitconfig`) |
| `dot_config/mise/config.toml` | Global mise config → `~/.config/mise/config.toml` (user CLI tools) |
| `.chezmoi.toml.tmpl` | Generates per-machine chezmoi config at `init` (prompts `profile`); never deployed |
| `bootstrap.sh` | Bare-machine bootstrap (operational, not deployed) |
| `Brewfile.tmpl` | GUI casks for `brew bundle`, templated per `profile` (operational; rendered at bootstrap) |
| `mise.toml` | Repo-local dev tooling (pre-commit) |
| `.pre-commit-config.yaml` | Lint hooks (shellcheck + hygiene) |
| `.chezmoiignore` | Keeps operational files in the repo but out of `$HOME` |

## Design decisions (Decision Record)

- **chezmoi over GNU Stow / bare-git.** Needed templating (per-machine values), first-class
  secret handling, and a source tree where dotfiles stay *visible* (`dot_` prefix) instead of
  hidden. Stow only symlinks; bare-git has no templating or secrets.
- **mise-first for CLI tools.** All CLI tooling is declared in mise (`config.toml`), versioned and
  cross-machine. Homebrew is reserved for what mise can't provide — GUI casks. This keeps the
  toolchain reproducible and the Brewfile minimal.
- **Bitwarden for secrets.** Secrets are pulled from Bitwarden at `chezmoi apply` via
  `{{ bitwarden ... }}` templates — nothing secret (encrypted or otherwise) lives in this public
  repo. Trade-off: bootstrap needs an interactive `bw unlock` before applying secret-bearing files
  (vs. `age`/`secrets.env`, which keep apply offline but place material in/near the repo).
- **pre-commit + shellcheck.** Every commit lints shell scripts and runs hygiene checks, so
  `bootstrap.sh` and friends stay correct. pre-commit itself is installed via mise (`postinstall`
  wires the git hooks automatically).
- **Bootstrap ordering.** The mise config is itself a managed dotfile, so it is applied *before*
  `mise install` to break the chicken-and-egg; Homebrew is installed lazily, only when GUI casks
  are present.
- **Per-machine via `profile`, not per-machine directories.** One source tree; machine-specific
  variation is driven by a single `profile` value (`work`/`personal`), prompted once at
  `chezmoi init` (override in CI/headless with `DOTFILES_PROFILE`) and stored in the machine-local
  chezmoi config (never in this repo). Templates branch on it — `Brewfile.tmpl` installs the .NET
  SDK only when `profile == "work"`, and `dot_gitconfig.tmpl` selects the work vs personal git
  identity. This keeps a single declarative source of truth and avoids the duplication/drift of
  per-machine dirs.

## Secrets

Secrets are **never committed**. They are resolved at apply time from
[Bitwarden](https://bitwarden.com) via chezmoi templates. On a fresh machine, `bootstrap.sh`
prompts for `bw unlock` only when the source actually contains secret templates.

> The zsh configuration (`.zshrc` + its secret references) is being set up separately and will
> land here once finalized.
