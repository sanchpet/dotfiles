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
2. **chezmoi source** — point chezmoi at **this clone** as its source (`chezmoi init --source`), so edits apply with no commit/push/re-clone round-trip and no duplicate clone in `~/.local/share/chezmoi`. Also generate a per-machine `ed25519` SSH key if missing (no passphrase; disk is encrypted) — it must exist **before** step 7 so the rendered git config turns commit signing on
3. **apply mise config** — lay down `~/.config/mise/config.toml` *before* installing tools (breaks the chicken-and-egg: the mise config is itself a managed dotfile)
4. **mise install** — install CLI tools from the config (bitwarden-cli, uv, …)
5. **Bitwarden unlock** — only if the source contains `*.tmpl` secrets (interactive)
6. **Oh My Zsh** — install the zsh framework (without touching `.zshrc` or changing the shell)
7. **chezmoi apply** — render and place all dotfiles
8. **GitHub SSH keys** — register this machine's key (generated in step 2) on GitHub as both an *authentication* key (push) and a *signing* key (Verified badge), then switch the dotfiles clone's origin from HTTPS to SSH so it's push-ready. Interactive on a TTY: runs `gh auth login` if unauthenticated and refreshes the token scope when needed. Idempotent; on CI / headless it prints the key and skips
9. **brew bundle** — GUI casks (Homebrew is installed lazily, only if the Brewfile needs it)

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
| uv | Fast Python package & project manager — also backs mise's `pipx:` tools (`settings.pipx.uvx`) | [docs](https://docs.astral.sh/uv/) · [github](https://github.com/astral-sh/uv) |
| Yandex Cloud CLI (`yc`) | Manage Yandex Cloud resources (IAM, compute, k8s, …) | [docs](https://yandex.cloud/docs/cli/) |
| Claude Code (`claude`) | Anthropic agentic CLI — self-update off (`DISABLE_AUTOUPDATER`), update via `mise up claude` | [docs](https://docs.claude.com/en/docs/claude-code) |
| claudeline | Real-time Claude Code statusline (quota / context / model) — wired via `~/.claude/settings.json` `statusLine` | [github](https://github.com/lexfrei/claudeline) |
| aqua | Declarative CLI version manager — used to author/test aqua-registry packages | [docs](https://aquaproj.github.io) · [github](https://github.com/aquaproj/aqua) |
| GitHub CLI (`gh`) | GitHub from the terminal | [docs](https://cli.github.com) |
| GitLab CLI (`glab`) | GitLab from the terminal | [docs](https://gitlab.com/gitlab-org/cli) |
| kubectl | Kubernetes cluster CLI | [docs](https://kubernetes.io/docs/reference/kubectl/) |
| kubectx | Switch kubectl context / namespace | [github](https://github.com/ahmetb/kubectx) |
| node | Node.js runtime | [docs](https://nodejs.org) |
| Starship | Cross-shell prompt (zsh prompt; `starship init` in `.zshrc`) | [docs](https://starship.rs) |
| zoxide | Frecency `cd` — replaces `cd` (`--cmd cd`); `cdi` = interactive | [github](https://github.com/ajeetdsouza/zoxide) |
| fzf | Fuzzy finder (`fzf --zsh` in `.zshrc`) | [github](https://github.com/junegunn/fzf) |
| ripgrep (`rg`) | Fast recursive search | [github](https://github.com/BurntSushi/ripgrep) |
| bat | `cat` with syntax highlighting & paging (aliased to `cat`) | [github](https://github.com/sharkdp/bat) |
| eza | Modern `ls` — git-aware, colors (aliased to `ls`/`ll`/`la`/`tree`) | [github](https://github.com/eza-community/eza) |
| delta | Syntax-highlighting pager for git diffs (wired as git `core.pager`) | [github](https://github.com/dandavison/delta) |
| dust | Intuitive `du` — disk-usage tree (aliased to `du`) | [github](https://github.com/bootandy/dust) |
| duf | Better `df` — disk free, tabular (aliased to `df`) | [github](https://github.com/muesli/duf) |
| dua (`dua i`) | Interactive disk-usage explorer — find & delete big dirs | [github](https://github.com/Byron/dua-cli) |
| fd | Fast, user-friendly `find` | [github](https://github.com/sharkdp/fd) |
| hyperfine | Command-line benchmarking tool | [github](https://github.com/sharkdp/hyperfine) |
| opencode | Terminal-based AI coding agent | [docs](https://opencode.ai) · [github](https://github.com/sst/opencode) |
| python | Python runtime | [docs](https://www.python.org) |
| helm | Kubernetes package manager | [docs](https://helm.sh) |
| terragrunt | Terraform/OpenTofu wrapper | [docs](https://terragrunt.gruntwork.io) |
| yq | YAML/JSON processor | [github](https://github.com/mikefarah/yq) |
| awscli (`aws`) | AWS CLI | [docs](https://aws.amazon.com/cli/) |
| go | Go toolchain | [docs](https://go.dev) |
| terraform | Infrastructure as code | [docs](https://developer.hashicorp.com/terraform) |
| vault | Secrets management CLI | [docs](https://developer.hashicorp.com/vault) |
| flux2 (`flux`) | GitOps continuous delivery for Kubernetes | [docs](https://fluxcd.io) |
| cfssl | Cloudflare PKI/TLS toolkit | [github](https://github.com/cloudflare/cfssl) |
| typst | Markup-based typesetting (LaTeX alternative) | [github](https://github.com/typst/typst) |
| ansible (`ansible-core`) | IT automation engine — installed via uv (`pipx:` backend) | [docs](https://docs.ansible.com) |
| ansible-lint | Ansible playbook linter (via uv) | [github](https://github.com/ansible/ansible-lint) |
| yamllint | YAML linter (via uv) | [github](https://github.com/adrienverge/yamllint) |

### Quality / dev workflow

| Tool | Purpose | Link |
|------|---------|------|
| pre-commit | Git pre-commit hook framework | <https://pre-commit.com> · [github](https://github.com/pre-commit/pre-commit) |
| shellcheck | Static analysis for shell scripts (via `shellcheck-py`) | [shellcheck](https://github.com/koalaman/shellcheck) · [hook](https://github.com/shellcheck-py/shellcheck-py) |
| pre-commit-hooks | Standard hygiene hooks (whitespace, EOF, YAML, …) | [github](https://github.com/pre-commit/pre-commit-hooks) |

### GUI (Homebrew cask)

| Tool | Purpose | Profile | Link |
|------|---------|---------|------|
| Visual Studio Code | Primary code editor (self-updating; adopted into brew) | all | [docs](https://code.visualstudio.com) |
| Freelens | Kubernetes IDE (open-source Lens fork) | all | [github](https://github.com/freelensapp/freelens) |
| cmux | Ghostty-based terminal with vertical tabs + notifications for AI coding agents | all | [site](https://www.cmux.dev/) |
| WakaTime | Menu-bar time tracker — whole-system activity beyond editor plugins | all | [docs](https://wakatime.com/mac) |
| Pearcleaner | App uninstaller + orphaned-file finder (open-source CleanMyMac alt) | all | [github](https://github.com/alienator88/Pearcleaner) |
| Docker Desktop | Container engine + CLI + VM (launch once to start the daemon) | all | [docs](https://docs.docker.com/desktop/setup/install/mac-install/) |
| Yandex Music | Desktop music player (self-updating cask) | all | [site](https://music.yandex.ru) |
| .NET SDK | .NET toolchain | `work` only | [docs](https://dotnet.microsoft.com/download) |

### Homebrew formulae (CLI mise can't provide)

| Tool | Purpose | Profile | Link |
|------|---------|---------|------|
| sshpass | Non-interactive ssh password auth (used by ansible) — not in the mise registry | all | [docs](https://sourceforge.net/projects/sshpass/) |
| libpq | PostgreSQL client (`psql`, `pg_dump`, …) without the server — mise's `postgres` builds the full server; keg-only, so `.zshrc` adds its `bin` to `PATH` | all | [docs](https://formulae.brew.sh/formula/libpq) |

## Zsh shell (Oh My Zsh)

The prompt is [Starship](https://starship.rs) (`dot_config/starship.toml` — the `kubernetes`, `aws`
and `terraform` modules are on, so the active cluster / profile / workspace is always visible). Oh
My Zsh loads **plugins only** (theme off — Starship draws the prompt). Built-in plugins ship with
Oh My Zsh; external ones are cloned into `$ZSH_CUSTOM/plugins` by `bootstrap.sh`.

| Plugin | Source | Purpose |
|--------|--------|---------|
| git | built-in | Git aliases (`gst`, `gco`, `gp`, …) |
| kubectl | built-in | `k*` aliases + completion (`kgp`, `kgaa`, `kdp`, …) |
| helm | built-in | Helm completion |
| terraform | built-in | `tf*` aliases + completion + workspace |
| aws | built-in | `asp`/`acp` profile switch + completion |
| ansible | built-in | Ansible aliases + completion |
| gh | built-in | GitHub CLI completion |
| colored-man-pages | built-in | Colored man pages |
| extract | built-in | `x <archive>` — extract any archive |
| sudo | built-in | Double-`Esc` prepends `sudo` |
| copypath / copybuffer | built-in | Copy `$PWD` / the current command line to the clipboard |
| dirhistory | built-in | `Alt`+`←/→` directory history, `Alt`+`↑` parent dir |
| forgit | external | fzf-powered git (`ga`, `glo`, `gd`) |
| zsh-completions | external | Extra completion definitions |
| zsh-autosuggestions | external | Fish-style suggestions from history |
| zsh-you-should-use | external | Reminds you when a typed command already has an alias |
| zsh-syntax-highlighting | external | Command-line syntax highlighting |
| zsh-autocomplete | external | Live menu completion (loaded **last** so its keybindings win) |

> **Load order matters.** `zsh-autocomplete` owns the completion/history UI, so it loads last, and
> plugins that fight over the same keys — `fzf-tab`, `zsh-history-substring-search` — are
> deliberately **not** used. Beyond the plugins, `dot_zshrc.tmpl` adds custom aliases (`kg`, `kgy`,
> `kctx`; modern-CLI swaps `cat`→`bat`, `ls`→`eza`, `du`→`dust`, `df`→`duf`) and the `miseg`/`miserm`
helpers (add / remove a global mise tool and re-import the config). `tg` aliases `terragrunt`
(the omz `terraform` plugin covers `tf*`, but terragrunt has no plugin); terragrunt ships no
completion script, so its built-in `COMP_LINE` completion is wired via `bashcompinit` +
`complete -C` and shared with the `tg` alias through `compdef`.

## Repository layout

| Path | Role |
|------|------|
| `dot_*` | Dotfiles rendered into `$HOME` by chezmoi (e.g. `dot_gitconfig` → `~/.gitconfig`) |
| `dot_config/mise/config.toml` | Global mise config → `~/.config/mise/config.toml` (user CLI tools) |
| `private_dot_claude/private_settings.json` | `~/.claude/settings.json` (0600) — Claude Code config: theme + claudeline statusline. Secrets/permissions stay in `settings.local.json` (untracked) |
| `dot_config/starship.toml` | Starship prompt config → `~/.config/starship.toml` (kubernetes/aws/terraform modules) |
| `dot_zshrc.tmpl` | `~/.zshrc` — Oh My Zsh (plugins only) + Starship prompt + zoxide + mise + aliases (kubectl, modern CLI); secrets pending |
| `dot_local/bin/executable_cleanup` | `~/.local/bin/cleanup` — disk-reclaim tool (reports by default; `--apply` deletes Tier 1 caches + orphan caches of removed tools, `--deep` adds Go modcache) |
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
  cross-machine. Homebrew is reserved for what mise can't provide — GUI casks, plus the rare CLI
  with heavy native deps or no upstream release (e.g. `sshpass`). This keeps the toolchain
  reproducible and the Brewfile minimal.
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
- **mise hooks enabled (`settings.experimental`).** Turned on globally so a project's
  `mise.toml` can self-activate its git hooks with `[hooks] enter = "git config core.hooksPath
  .githooks"`, instead of a manual `git config` on every clone/machine. Kept at the machine level
  (not duplicated per repo) so individual projects only declare the `[hooks]` they need.
- **Per-machine via `profile`, not per-machine directories.** One source tree; machine-specific
  variation is driven by a single `profile` value (`work`/`personal`), prompted once at
  `chezmoi init` (override in CI/headless with `DOTFILES_PROFILE`) and stored in the machine-local
  chezmoi config (never in this repo). Templates branch on it — `Brewfile.tmpl` installs the .NET
  SDK only when `profile == "work"`. Git identity, by contrast, is **directory**-based:
  `dot_gitconfig.tmpl` defaults to the personal identity (`sanchpet`) with SSH commit signing
  everywhere, and an `includeIf "gitdir:~/IWE/magnit/"` pulls in `dot_config/git/work.inc` to
  switch to the work identity (signing off) for the corporate repos under `~/IWE/magnit/`.
  Defaulting to personal keeps the corporate email opt-in — it can only ever appear under
  `~/IWE/magnit/` — and signing is gated on the key existing so a machine without it still
  commits. This keeps a single declarative source of truth and avoids the duplication/drift of
  per-machine dirs.

## Syncing changes (chezmoi)

chezmoi has two locations: the **source** (this repo, `chezmoi source-path`) and the **live** files
in `$HOME`. Always edit the source, then push it to live — never edit the live file directly.

| Scenario | Command |
|----------|---------|
| Changed a dotfile (e.g. `.zshrc`) | edit the source (`dot_zshrc.tmpl`), then `chezmoi apply ~/.zshrc` (alias `cza`) |
| Pull latest on another machine | `chezmoi update` (= `git pull` + `apply`) (alias `czu`) |
| Check source ↔ live drift | `chezmoi diff` (alias `czd`) |
| A tool wrote to a **non-templated** target (e.g. `mise use -g` → `~/.config/mise/config.toml`) | re-import: `chezmoi add <target>` (see the `miseg` helper) |

> **Never run `chezmoi add ~/.zshrc`.** It is a **template** (`dot_zshrc.tmpl`) — `add` would
> overwrite it with the rendered content and destroy the `{{ ... }}` directives (incl. future
> secrets). Templated files are source-edited only; `chezmoi add` is for non-templated targets.

## Secrets

Secrets are **never committed**. They are resolved at apply time from
[Bitwarden](https://bitwarden.com) via chezmoi templates. On a fresh machine, `bootstrap.sh`
prompts for `bw unlock` only when the source actually contains secret templates.

The zsh config (`dot_zshrc.tmpl`) is kept as a `.tmpl` so a `{{ bitwarden ... }}` secret line can
be added later without a rename — see [Zsh shell](#zsh-shell-oh-my-zsh) for the plugin set and
prompt.

> **Pending:** the `OBSIDIAN_API_KEY` secret reference (via Bitwarden) is not wired yet — `.zshrc`
> is kept as a `.tmpl` so the `{{ bitwarden ... }}` line can be added without a rename.
