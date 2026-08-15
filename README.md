# dotfiles

[![smoke](https://github.com/sanchpet/dotfiles/actions/workflows/smoke.yml/badge.svg)](https://github.com/sanchpet/dotfiles/actions/workflows/smoke.yml)

Personal macOS development environment, managed declaratively with [chezmoi](https://www.chezmoi.io) (dotfiles), [mise](https://mise.jdx.dev) (CLI tools), and [Homebrew](https://brew.sh) (GUI apps). One command on a bare machine → a fully configured setup. **Secrets never touch the repo.**

## Quick start (bare machine)

```sh
git clone https://github.com/sanchpet/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` is idempotent and runs, in order (mise-first):

1. **mise** — install the base tool manager (`curl https://mise.run`), then `chezmoi` via mise
2. **chezmoi source** — point chezmoi at **this clone** as its source (`chezmoi init --source`), so edits apply with no commit/push/re-clone round-trip and no duplicate clone in `~/.local/share/chezmoi`. Also generate a per-machine `ed25519` SSH key if missing (no passphrase; disk is encrypted) — it must exist **before** step 7 so the rendered git config turns commit signing on
3. **apply mise config** — lay down `~/.config/mise/config.toml` *before* installing tools (breaks the chicken-and-egg: the mise config is itself a managed dotfile)
4. **mise install** — install CLI tools from the config (bitwarden-cli, uv, …)
5. **Bitwarden** — point the `bw` CLI at `.bitwarden.server` (self-hosted, blank = cloud), then login + unlock; interactive, skipped without a TTY (CI)
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
| rtk | CLI proxy that compresses command output before an agent reads it — wired as a `PreToolUse` hook, see below | [docs](https://www.rtk-ai.app) · [github](https://github.com/rtk-ai/rtk) |
| Serena | MCP server giving the agent LSP-backed symbolic navigation and editing (`serena-agent` on PyPI, binary `serena`) — registered in the work profile, see below | [docs](https://oraios.github.io/serena/) · [github](https://github.com/oraios/serena) |
| sweb | CLI for the SpaceWeb (sweb.ru) hosting API — my own tool (github backend) | [github](https://github.com/sanchpet/sweb) |
| aqua | Declarative CLI version manager — used to author/test aqua-registry packages | [docs](https://aquaproj.github.io) · [github](https://github.com/aquaproj/aqua) |
| GitHub CLI (`gh`) | GitHub from the terminal | [docs](https://cli.github.com) |
| GitLab CLI (`glab`) | GitLab from the terminal — **work profile only** (`conf.d/work.toml`); personal work is on GitHub | [docs](https://gitlab.com/gitlab-org/cli) |
| 1Password CLI (`op`) | Secret retrieval on work machines — **work profile only**; personal machines use `bw` | [docs](https://developer.1password.com/docs/cli/) |
| kubectl | Kubernetes cluster CLI | [docs](https://kubernetes.io/docs/reference/kubectl/) |
| kubectx | Switch kubectl context / namespace (aliased `kctx`) | [github](https://github.com/ahmetb/kubectx) |
| kubelogin | kubectl credential plugin for OIDC clusters — no local context uses it yet, kept for the LDAP-login lab stands | [github](https://github.com/int128/kubelogin) |
| node | Node.js runtime | [docs](https://nodejs.org) |
| Starship | Cross-shell prompt (zsh prompt; `starship init` in `.zshrc`) | [docs](https://starship.rs) |
| zoxide | Frecency `cd` — replaces `cd` (`--cmd cd`); `cdi` = interactive | [github](https://github.com/ajeetdsouza/zoxide) |
| fzf | Fuzzy finder (`fzf --zsh` in `.zshrc`) | [github](https://github.com/junegunn/fzf) |
| ripgrep (`rg`) | Fast recursive search | [github](https://github.com/BurntSushi/ripgrep) |
| bat | `cat` with syntax highlighting & paging (aliased to `cat`) | [github](https://github.com/sharkdp/bat) |
| delta | Syntax-highlighting pager for git diffs (wired as git `core.pager`) | [github](https://github.com/dandavison/delta) |
| dust | Intuitive `du` — disk-usage tree (aliased to `du`) | [github](https://github.com/bootandy/dust) |
| duf | Better `df` — disk free, tabular (aliased to `df`) | [github](https://github.com/muesli/duf) |
| dua (`dua i`) | Interactive disk-usage explorer — find & delete big dirs | [github](https://github.com/Byron/dua-cli) |
| fd | Fast, user-friendly `find` | [github](https://github.com/sharkdp/fd) |
| hyperfine | Command-line benchmarking tool | [github](https://github.com/sharkdp/hyperfine) |
| python | Python runtime | [docs](https://www.python.org) |
| helm | Kubernetes package manager | [docs](https://helm.sh) |
| terragrunt | Terraform/OpenTofu wrapper (aliased `tg`) | [docs](https://terragrunt.gruntwork.io) |
| awscli (`aws`) | AWS CLI | [docs](https://aws.amazon.com/cli/) |
| go | Go toolchain | [docs](https://go.dev) |
| terraform | Infrastructure as code | [docs](https://developer.hashicorp.com/terraform) |
| vault | Secrets management CLI | [docs](https://developer.hashicorp.com/vault) |
| flux2 (`flux`) | GitOps continuous delivery for Kubernetes | [docs](https://fluxcd.io) |
| cilium-cli (`cilium`) | Cilium CNI — install, status, connectivity tests | [docs](https://docs.cilium.io) |
| terraform-docs | Generate module documentation from Terraform sources | [docs](https://terraform-docs.io) |
| teleport-community (`tsh`, `tctl`, `teleport`) | Access plane for infrastructure — client, admin CLI, and the node agent this Mac runs (see [Remote access](#remote-access-teleport)) | [docs](https://goteleport.com/docs/) |
| wstunnel | Tunnel traffic over websocket/HTTP2 — client side; ansible installs its own pinned Linux build on the homelab hub | [github](https://github.com/erebe/wstunnel) |
| typst | Markup-based typesetting (LaTeX alternative) | [github](https://github.com/typst/typst) |
| ansible (`ansible-core`) | IT automation engine — installed via uv (`pipx:` backend) | [docs](https://docs.ansible.com) |
| ansible-lint | Ansible playbook linter (via uv) | [github](https://github.com/ansible/ansible-lint) |
| yamllint | YAML linter (via uv) | [github](https://github.com/adrienverge/yamllint) |
| regctl | The OCI registry client — manifests, indexes, artifacts, copy/retag and `image mod` without a daemon. Deliberately the only one: see [Design decisions](#design-decisions-decision-record) | [github](https://github.com/regclient/regclient) |
| hadolint | Dockerfile linter — a native binary, so no container pull stands between an edit and its findings | [github](https://github.com/hadolint/hadolint) |
| mcp-tg | Telegram MCP server — lets an agent read chats over MTProto. **Version-pinned, not `latest`**: it holds a session that authorises the whole account. See [Agent access](#agent-access-mcp). | [github](https://github.com/lexfrei/mcp-tg) |
| wolt (`wolt`, `wolt-mcp`) | Unofficial Wolt CLI + MCP server — venue search, menus, cart, checkout preview. One archive, both binaries. **Version-pinned** for the same reason as mcp-tg: it holds a session tied to payment methods. Ordering still happens in the app; the tool has no order placement. | [github](https://github.com/mekedron/wolt-cli) |

### Quality / dev workflow

| Tool | Purpose | Link |
|------|---------|------|
| pre-commit | Git pre-commit hook framework | <https://pre-commit.com> · [github](https://github.com/pre-commit/pre-commit) |
| shellcheck | Static analysis for shell scripts. Declared twice on purpose: the pre-commit hook brings its own copy (`shellcheck-py`), the mise one is for running it by hand | [shellcheck](https://github.com/koalaman/shellcheck) · [hook](https://github.com/shellcheck-py/shellcheck-py) |
| pre-commit-hooks | Standard hygiene hooks (whitespace, EOF, YAML, …) | [github](https://github.com/pre-commit/pre-commit-hooks) |
| actionlint | GitHub Actions workflow linter — catches a broken workflow before a push burns a CI run | [github](https://github.com/rhysd/actionlint) |

### GUI (Homebrew cask)

| Tool | Purpose | Profile | Link |
|------|---------|---------|------|
| Visual Studio Code | Primary code editor (self-updating; adopted into brew) | all | [docs](https://code.visualstudio.com) |
| Bitwarden | Password manager — also serves the SSH agent that signs commits and authenticates git. Cask rather than the App Store build, which cannot be reinstalled without a signed-in Store | all | [site](https://bitwarden.com) |
| AmneziaVPN | VPN client — the desktop side of the VPN fleet | all | [github](https://github.com/amnezia-vpn/amnezia-client) |
| Obsidian | Markdown knowledge base / vault editor (hypomnemata exocortex; self-updating cask) | all | [site](https://obsidian.md) |
| Freelens | Kubernetes IDE (open-source Lens fork) | all | [github](https://github.com/freelensapp/freelens) |
| cmux | Ghostty-based terminal with vertical tabs + notifications for AI coding agents | all | [site](https://www.cmux.dev/) |
| WakaTime | Menu-bar time tracker — whole-system activity beyond editor plugins | all | [docs](https://wakatime.com/mac) |
| Pearcleaner | App uninstaller + orphaned-file finder (open-source CleanMyMac alt) | all | [github](https://github.com/alienator88/Pearcleaner) |
| OrbStack | Docker-compatible container & Linux VM runtime, replaces Docker Desktop (launch once to start the engine) | all | [docs](https://docs.orbstack.dev/) |
| Yandex Music | Desktop music player (self-updating cask) | all | [site](https://music.yandex.ru) |
| Slack | Team chat client (self-updating cask) | all | [site](https://slack.com) |
| Super Productivity | To-do list + Pomodoro + time tracking (MIT, local-first) — the time-accounting instrument; see [Agent access](#agent-access-mcp) | all | [github](https://github.com/super-productivity/super-productivity) |
| .NET SDK | .NET toolchain | `work` only | [docs](https://dotnet.microsoft.com/download) |
| Windows App | Microsoft's official RDP client (succeeds the discontinued Microsoft Remote Desktop) | `work` only | [docs](https://learn.microsoft.com/windows-app/) |

### Mac App Store (mas)

Installed via the `mas` CLI. A one-time App Store sign-in is the only step that can't live in code; the entries are skipped in CI (the runner isn't signed in).

| App | Purpose | Profile | Link |
|------|---------|---------|------|
| one sec | Delay distracting apps — digital-hygiene gate (a mindful pause before Telegram/feeds) | all | [site](https://one-sec.app/mac/) |
| Focus To-Do | Superseded by Super Productivity; kept only until its history is migrated out ([#3](https://github.com/sanchpet/dotfiles/issues/3)) | all | [site](https://www.focustodo.cn) |
| WireGuard | WireGuard VPN client | all | [site](https://www.wireguard.com) |
| v2RayTun | V2Ray / proxy client | all | [site](https://v2raytun.com) |
| MKPlayer | Media player | all | — |
| GLKVM | GL.iNet KVM-over-IP client — remote console/BIOS access to homelab nodes | all | [site](https://www.gl-inet.com/products/glkvm/) |

### Homebrew formulae (CLI mise can't provide)

| Tool | Purpose | Profile | Link |
|------|---------|---------|------|
| sshpass | Non-interactive ssh password auth — ansible needs it for the `-k` root-password bootstrap play; not in the mise registry | all | [docs](https://sourceforge.net/projects/sshpass/) |
| libpq | PostgreSQL client (`psql`, `pg_dump`, …) without the server — mise's `postgres` builds the full server; keg-only, so `.zshrc` adds its `bin` to `PATH` | all | [docs](https://formulae.brew.sh/formula/libpq) |
| qrencode | QR encoder — not in the mise registry, and upstream ships source only | all | [site](https://fukuchi.org/works/qrencode/) |
| eza | Modern `ls` — git-aware, colors (aliased to `ls`/`ll`/`la`/`tree`); eza ships no macOS binary upstream so mise can't provide it cleanly (asdf 404s, cargo needs Rust) — brew has a bottle | all | [github](https://github.com/eza-community/eza) |
| mas | Mac App Store CLI — installs/declares the App Store apps above | all | [github](https://github.com/mas-cli/mas) |
| ffmpeg | Video/audio transcoding — mise offers only `conda:` (a conda backend with its own cache) or an asdf plugin that builds from source; brew's bottle ships the encoders needed (svt-av1, libvpx, x264, opus) | all | [site](https://ffmpeg.org) |
| gnu-sed | GNU sed as `gsed` — Darwin-aware build scripts call it for in-place edits BSD sed can't do (external-secrets' `make reviewable`); not in the mise registry | all | [docs](https://www.gnu.org/software/sed/) |
| gnupg | `gpg` — verifies the signed helm plugin tarballs (`run_onchange_after_install-helm-plugins.sh`); declared explicitly because it was present only as a transitive dep of skopeo, so dropping skopeo would have silently taken plugin verification with it | all | [site](https://gnupg.org) |

## Zsh shell (Oh My Zsh)

The prompt is [Starship](https://starship.rs) (`dot_config/starship.toml` — the `kubernetes`, `aws` and `terraform` modules are on, so the active cluster / profile / workspace is always visible). Oh My Zsh loads **plugins only** (theme off — Starship draws the prompt). Built-in plugins ship with Oh My Zsh; external ones are cloned into `$ZSH_CUSTOM/plugins` by `bootstrap.sh`.

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

> **Load order matters.** `zsh-autocomplete` owns the completion/history UI, so it loads last, and plugins that fight over the same keys — `fzf-tab`, `zsh-history-substring-search` — are deliberately **not** used. Beyond the plugins, `dot_zshrc.tmpl` adds custom aliases (`kg`, `kgy`, `kctx`; modern-CLI swaps `cat`→`bat`, `ls`→`eza`, `du`→`dust`, `df`→`duf`) and the `miseg`/`miserm`/`miseup` helpers (add / remove a global mise tool and re-import the config; `miseup` upgrades with a fresh version list — clears mise's cached release list first so a just-published release is picked up). `brewdiff` reports drift between installed Homebrew packages and the rendered `Brewfile.tmpl` (brew has no `miseg`-style auto-sync — the manifest is a curated template, so new packages are ported in by hand). `updates` reports available mise + Homebrew package updates (cached; the first interactive shell of the day refreshes it in the background and prints the summary — never blocks the prompt; `updates -r` rechecks now, upgrades stay manual via `brew upgrade` / `mise upgrade` / `mise self-update`). `tg` aliases `terragrunt` (the omz `terraform` plugin covers `tf*`, but terragrunt has no plugin); terragrunt ships no completion script, so its built-in `COMP_LINE` completion is wired via `bashcompinit` + `complete -C` and shared with the `tg` alias through `compdef`.

## Agent bash output (rtk)

`rtk` is a `PreToolUse` hook on the `Bash` tool: it rewrites a command to its `rtk` equivalent (`git status` → `rtk git status`) so the agent reads a compressed rendering instead of raw output. It applies to `Bash` calls only — Claude Code's built-in `Read`, `Grep` and `Glob` bypass hooks entirely.

Three things about this deployment are choices rather than defaults:

- **The hook command is the mise shim's absolute path, not a bare `rtk`.** mise puts tools on `PATH` at shell activation, so a bare name resolves only under an already-activated interactive shell. The shim resolves without one, the same reason the `statusLine` entry is absolute. Note this only hardens the hook itself: the command it *emits* is a bare `rtk …`, which still needs `rtk` on the agent's `PATH`. An agent started before rtk was installed keeps the old `PATH` and fails every rewritten command with `command not found` — restart it after installing.
- **Never run `rtk init -g` on this machine.** It patches `~/.claude*/settings.json`, writes `RTK.md`, and appends the `@RTK.md` import — all in `$HOME`, i.e. chezmoi targets. Those edits survive until the next `chezmoi apply` silently reverts them. The hook, `RTK.md` and the import live in the source here; run `init` only against a throwaway `CLAUDE_CONFIG_DIR` to see what a new version would write, then port it.
- **Output is lossy by design.** Where a command's exact output is the evidence (a checksum, a full log, a diff being quoted verbatim), reach for `rtk proxy <cmd>` to bypass the filter, or add the command to `exclude_commands` in `~/Library/Application Support/rtk/config.toml` if it should never be rewritten.

## Agent access (MCP)

Five MCP servers give Claude Code a browser, a Telegram reader, the time-accounting instrument, that instrument's UI, and symbolic navigation over source. Each hands an agent something with real reach, so what bounds that reach is written down here rather than left implicit.

### Code intelligence — `serena`

An MCP server that puts a language server between the agent and the code: find a symbol, find what references it, replace a symbol's body — instead of reading whole files and editing by text match. On trial in the **work profile only**, against declared criteria and a review date; whether it belongs in the personal contour is a later decision.

**The registration is reproducible** (`run_onchange_after_register-serena.sh`), idempotent, and pins the profile for the same reason the others do. `--project-from-cwd` means one registration serves every repository — Serena activates whichever project the agent is working in.

**Its global memories are a symlink into the vault** (`~/.serena/memories/global` → `~/tv/adversaria/70-memory`). Serena's own path for these is hardcoded (`serena_config.py`, no setting for it), and leaving them in `~/.serena` would put durable knowledge outside version control. The symlink survives Serena's `mkdir(exist_ok=True)` on startup. Note the ordering trap: any `serena` invocation, `--version` included, creates that directory, so the symlink has to be in place before the first run or it lands *inside* the directory instead of replacing it.

**Project memories are a different matter and are not adopted yet.** Not because of where they land — `project_serena_folder_location` relocates the whole `.serena` folder anywhere, `$projectDir` and `$projectFolderName` included — but because of what Serena calls a project. It identifies one by directory path, with no git awareness, so under a one-worktree-per-branch workflow every branch is a separate project and neither placeholder can express "the repository". The one arrangement where the memories follow the code is committing them, which is what upstream expects (their own `.serena/.gitignore` excludes only `cache` and `project.local.yml`) — and that is a team decision, not a personal one. Global memories only until it is asked.

### Browser — `chrome-devtools-mcp`

Registered at user scope in the **personal profile** pointing at `http://127.0.0.1:9222`, i.e. it attaches to a browser that is **already running** rather than launching its own. `cometdbg` in `dot_zshrc.tmpl` starts that browser: Comet is Chromium, so it speaks the DevTools protocol unchanged (verified — it reports `Chrome/150`, protocol 1.3).

**The registration is reproducible** (`run_onchange_after_register-chrome-devtools.sh`), for the same reason mcp-tg's is: `--scope user` writes into whichever profile `CLAUDE_CONFIG_DIR` names, so a hand-typed registration silently belongs to one contour and is missing from the other. That is not hypothetical — this server sat in the default profile alone until a session under the personal one reported having no browser at all. The script pins the profile and is idempotent.

**It runs a dedicated profile (`~/.cache/comet-debug`), not the everyday one.** Whoever holds a CDP endpoint can read every open tab and its cookies, and act as you on any site you are signed into. The separate profile keeps that to one window. This is the whole reason `cometdbg` exists instead of a note saying "pass `--remote-debugging-port`".

### Time accounting — `super-productivity-mcp`

Super Productivity is the instrument for tracking physical time by task, replacing Focus To-Do. The choice was driven by reachability rather than features: Focus To-Do publishes no API at all, so every adapter for it is built on reverse-engineered endpoints and authenticates with the account password in plain environment variables. Super Productivity keeps its data in a local directory and publishes a plugin API first-party, so an adapter over it is an ordinary client — when it breaks, that is a bug report rather than a second round of reverse engineering.

**The registration is reproducible** (`run_onchange_after_register-super-productivity-mcp.sh.tmpl`), idempotent, and gated to the **personal machine** — a stronger condition than the personal profile the other two settle for. The app is declared for every machine, because work time is tracked on the work machine too, but that instance stays agentless on purpose: its task titles belong to an employer, and the cheapest way to keep them away from an agent is to never register a reader for them. Only weekly per-bucket totals cross that boundary, carried by hand.

**Unpinned `@latest`, unlike mcp-tg and wolt-cli.** Those hold live sessions — one authorises a whole Telegram account, the other is tied to payment methods — so a surprise release there reaches further than this machine. This server holds no session: there are no credentials in its design and the data is a local folder. The looser rule is a deliberate exception, accepted knowingly.

**Two steps stay manual, and no amount of declaration removes them:** the plugin is uploaded through the app's own Settings UI, and SP ≥ 18.13.0 then raises a one-time Node execution consent dialog. The script prints both when it registers.

**Point the app's sync at a folder inside the vault.** The accounting history is the evidence base for a practice measured in months; keeping it in a vendor's cloud makes it unrecoverable from a clean clone, which is exactly the defect this move was meant to fix.

**Task text is data, not instructions.** The agent may edit the tasks it reads, so anything that arrives through a task title or note is treated as content — the same rule that governs venue and menu text in the Wolt contour.

### Time accounting, the UI — `sp-devtools`

A second `chrome-devtools-mcp` instance on `http://127.0.0.1:9223`, so an agent can click through the app's own interface instead of asking the owner to. Electron is Chromium, so the browser server attaches unchanged; what the second registration buys is a second endpoint, since `chrome-devtools` is fixed to `:9222`. `spdbg` (`dot_zshrc.tmpl`) opens the port on demand — the app runs without a debugging port until someone asks for one, and **that is the isolation**: unlike the browser there is no separate profile to sandbox into, because there is one app and one data store.

The reach is narrower than the browser endpoint's — one application rather than every signed-in site — but it is read/write over the instrument that holds the time accounting.

**The Node-execution consent dialog stays with the owner.** It is a security prompt whose entire purpose is a human answer, and consent an agent gives on the owner's behalf is not consent. Native dialogs generally are out of reach anyway: they live outside the renderer, where CDP cannot follow.

### Telegram — `mcp-tg`

MTProto with a **user session**, because a bot cannot read a conversation between two people. `mcp-tg login` takes the phone, code and 2FA on a TTY — the credentials never pass through an agent's transcript — and stores the session in the login keychain rather than a file on disk.

**The registration itself is reproducible** (`run_onchange_after_register-mcp-tg.sh.tmpl`): mise pins the binary, and that script registers the server in the personal profile, reading the API credentials from Vault (`homelab/telegram/mcp-tg`) at apply time so they stay out of git. It is idempotent, personal-profile-only, and skips with a message when Vault is off the mesh — a bootstrap must not fail on reachability. The account login stays manual and interactive by design: that is the one step that should never be automated.

**All 78 tools are enabled, deliberately.** The server has no read-only mode, and an earlier `permissions.deny` listing every write tool was removed at the owner's decision: the agent is a working instrument on a machine the owner controls, and a tool that cannot act is worth less than the risk it avoids here.

What that means concretely, so it is never a surprise: an agent can send, edit and delete messages as the account holder, forward, react, join and leave chats, block users, and change the profile. Messages it sends are indistinguishable from the owner's to whoever receives them — this is the only capability that reaches **other people**, and the one worth thinking about before granting a session to any agent.

Two properties of the mechanism, unchanged by the above:

- **The session authorises the entire account.** It is a bearer credential that has already passed 2FA. Keychain storage protects it at rest; nothing protects it from a process that can ask the keychain.
- **No Telegram MCP server can be scoped to a single conversation.** Access is per-account, never per-chat. Upstream tracks per-chat allowlists as an open request.

To reinstate a restriction later, `permissions.deny` in `~/.claude/settings.json` takes tool names as `mcp__mcp-tg__<tool>`. The current surface:

```sh
gh api repos/lexfrei/mcp-tg/contents/docs/tools.md --jq .content | base64 -d
```

## Remote access (Teleport)

This Mac is a **Teleport SSH node**: the agent dials out to the cluster proxy on `:443` and holds a reverse tunnel, so there is no inbound port, no port forwarding on the router, and no dependence on the network it sits behind — home, office or a cafe are the same to it.

Two properties are worth stating because they are choices, not accidents:

- **It runs as a login agent, not a system daemon.** A non-root Teleport node can only serve sessions as the user it runs as, so the blast radius is that one account even if cluster RBAC were wrong. The cost is that the machine is reachable only while that user is logged in: after a cold boot FileVault holds the disk and nothing starts. No remote-access scheme fixes that — plan around it rather than expect it to be solved.
- **Only a personal machine becomes a node.** `.chezmoiignore` withholds the config and the agent on any other profile: reaching a node and being one are different things, and a corporate machine should only ever do the former.

**Joining** is a one-time out-of-band step, like every other bootstrap credential — the token never lives in this repo:

```sh
tctl tokens add --type=node --ttl=15m --format=text > ~/.config/teleport/join-token
chezmoi apply ~/.config/teleport/teleport.yaml   # then the agent picks it up
```

The node writes its own certificates into `~/.local/share/teleport` on first start and never reads the token again. Diagnostics: `~/Library/Logs/teleport-node.log`.

**Reaching the desktop** from another Mac — `home-desktop` forwards the port and opens Apple's own Screen Sharing client (Mac-to-Mac negotiates a far better path than a generic VNC viewer):

```sh
home-desktop            # tunnel + viewer; closing the shell closes both
tsh ssh sanchpet@macbook-air   # terminal only
```

Screen Sharing itself is a macOS service, enabled once per machine outside chezmoi (it needs root). The reliable path is System Settings → General → Sharing → Screen Sharing; the `launchctl` equivalent (`enable` then `kickstart -k system/com.apple.screensharing`) is fussy about ordering and silently unhelpful when the service is still disabled. Sleep is separate and matters as much:

```sh
sudo pmset -c sleep 0    # a sleeping laptop answers nothing
```

**The tunnel is the access path, not a shield.** macOS binds Screen Sharing on `0.0.0.0:5900`, so the port answers on every network the machine joins — authenticated, but answering. Reaching it *through* Teleport is what gives the audited, certificate-gated path; if the machine sits on networks you do not trust, turn on the application firewall (currently off on this Mac) or narrow the allowed users in the same Sharing pane.

Note that a closed lid still sleeps an Apple Silicon laptop without an external display, so a machine meant to be reachable stays open.

## Repository layout

| Path | Role |
|------|------|
| `dot_*` | Dotfiles rendered into `$HOME` by chezmoi (e.g. `dot_gitconfig` → `~/.gitconfig`) |
| `dot_config/mise/config.toml` | Global mise config → `~/.config/mise/config.toml` (user CLI tools) |
| `dot_config/mise/conf.d/work.toml` | Work-only CLI tools; mise merges every `conf.d/*.toml`, and `.chezmoiignore` withholds this one from personal machines |
| `.chezmoitemplates/claude-settings.json` | Single source for Claude Code's `settings.json` (model, theme, claudeline statusline, `screencapture` sandbox exclusion, rtk `PreToolUse` hook), included by every account profile below |
| `private_dot_claude/private_settings.json.tmpl` | `~/.claude/settings.json` (0600) — default profile. Secrets/permissions stay in `settings.local.json` (untracked) |
| `private_dot_claude/RTK.md` | `~/.claude/RTK.md` — rtk's agent-facing reference, pulled into `CLAUDE.md` by an `@RTK.md` import. Vendored from `rtk init`; refresh it from a new `rtk init` rather than editing by hand |
| `private_dot_claude-personal/`, `private_dot_claude-work/` | `~/.claude-personal`, `~/.claude-work` (0700) — separate accounts selected by `CLAUDE_CONFIG_DIR` (`claude-personal` / `claude-work` functions in `.zshrc`). Same settings as the default profile; `CLAUDE.md` and `RTK.md` are symlinks to the canonical copies under `~/.claude/` |
| `dot_config/starship.toml` | Starship prompt config → `~/.config/starship.toml` (kubernetes/aws/terraform modules) |
| `dot_zshrc.tmpl` | `~/.zshrc` — Oh My Zsh (plugins only) + Starship prompt + zoxide + mise + aliases (kubectl, modern CLI); secrets pending |
| `dot_local/bin/` | Executable scripts symlinked to `~/.local/bin/` by chezmoi |
| `dot_local/bin/executable_cleanup` | `~/.local/bin/cleanup` — disk-reclaim tool (reports by default; `--apply` deletes Tier 1 caches + orphan caches of removed tools, `--deep` adds Go modcache) |
| `dot_local/bin/executable_updates` | `~/.local/bin/updates` — reports available mise + Homebrew package updates |
| `dot_local/bin/executable_statusline` | `~/.local/bin/statusline` — Claude Code statusline: prefixes a marker for the active account profile (`🏢` work, `🏠` personal, read from `CLAUDE_CONFIG_DIR`), then execs `claudeline` with every segment intact |
| `dot_local/bin/executable_git-agent-sign.tmpl` | `~/.local/bin/git-agent-sign` — signing shim: forces this machine's vault agent socket, then execs `ssh-keygen`, so non-login shells sign too |
| `private_dot_ssh/private_config.tmpl` | `~/.ssh/config` (0600) — `IdentityAgent` pointed at the machine's vault agent, plus OrbStack's include |
| `dot_local/bin/executable_login-agents` | `~/.local/bin/login-agents` — bootout/bootstrap cycle for the login agents below; run by the `run_onchange` hook and by bootstrap step 10 |
| `Library/LaunchAgents/*.plist` | `~/Library/LaunchAgents/` — launchd agents started at login, one file per app (`dev.sanchpet.orbstack` starts the OrbStack engine so the Docker socket is up without opening the app). Add an app = add a plist |
| `run_onchange_after_login-agents.sh.tmpl` | Reloads the login agents on `chezmoi apply` whenever a plist changes (keyed on their hashes) |
| `run_onchange_after_install-helm-plugins.sh` | Installs `helm-unittest` from its signed release tarball into helm's own plugin directory — a plugin is not a tool on `PATH`, so mise cannot declare it. Verifies the signature against a pinned key fingerprint in an isolated keyring; skips (not fails) when helm or gpg is absent |
| `run_onchange_after_sudo-touch-id.sh` | Installs `/etc/pam.d/sudo_local` (Touch ID for `sudo`) + `/etc/sudoers.d/timestamp` (no credential cache). Idempotent, macOS-only, skips rather than prompts without a terminal |
| `dot_config/teleport/teleport.yaml.tmpl` | `~/.config/teleport/teleport.yaml` — SSH node config: reverse tunnel to the personal cluster's proxy, SSH service only. **Personal profile only** (`.chezmoiignore`) |
| `Library/LaunchAgents/dev.sanchpet.teleport-node.plist` | Runs the node as a login agent, so it serves sessions only as the logged-in user. **Personal profile only** |
| `dot_local/bin/executable_home-desktop` | `~/.local/bin/home-desktop` — forwards a local port to a node's Screen Sharing over Teleport and opens the viewer; the shell it drops you in is the tunnel's lifetime |
| `dot_local/bin/add-podkop-subnet` | `~/.local/bin/add-podkop-subnet` — route a domain through Podkop (VLESS) on Cudy router, then `podkop reload`. Default: resolve domain → subnet → `user_subnets` (for FortiClient VPN, where FakeIP routing fails). `--domain`: add the name verbatim → `user_domains` (FakeIP), e.g. for a domain whose anycast IPs are partially blackholed on the RU path |
| `dot_local/bin/executable_age-archive` | `~/.local/bin/age-archive` — encrypt a directory to your `age` key with a verify gate (`-s DIR [-o FILE] [-d DEST]… [--rclone REMOTE]… [-R age1…]…`), or restore one (`--restore ARCHIVE TARGET`). The secret key comes from `--identity-cmd` (default `$AGE_IDENTITY_CMD`, e.g. `bw get item <item>`) or stdin; the self-recipient is derived from it, so no `age1…` on the CLI. Plaintext and the secret key never hit disk; distribution is gated behind a passing round-trip decrypt; pass `-R` recipients to widen access (e.g. add a YubiKey key). `--help` for the full interface |
| `.chezmoi.toml.tmpl` | Generates per-machine chezmoi config at `init` (prompts `profile`); never deployed |
| `bootstrap.sh` | Bare-machine bootstrap (operational, not deployed) |
| `Brewfile.tmpl` | GUI casks + Mac App Store apps for `brew bundle`, templated per `profile` (operational; rendered at bootstrap) |
| `mise.toml` | Repo-local dev tooling (pre-commit) |
| `.pre-commit-config.yaml` | Lint hooks (shellcheck + hygiene) |
| `.chezmoiignore` | Keeps operational files in the repo but out of `$HOME` |

## Design decisions (Decision Record)

- **Touch ID for `sudo`, never a `NOPASSWD` rule.** An agent working in this shell cannot type a password — its commands run without a controlling terminal. The tempting fix, a `NOPASSWD` line in `sudoers.d`, hands those rights not to one agent but to *every* process running as this user (a package `postinstall`, any script that gets executed), and no honestly narrow allowlist exists: `launchctl` as root is a loaded arbitrary daemon, i.e. full root anyway. `auth sufficient pam_tid.so` in `/etc/pam.d/sudo_local` inverts that — the module short-circuits before the password prompt, so the missing terminal never matters, and the prompt is a system dialog raised inside `sudo` itself. Verified: a `sudo` issued from a non-TTY agent process does raise it, because the process inherits the GUI session's bootstrap namespace. Paired with `Defaults timestamp_timeout=0` (`/etc/sudoers.d/timestamp`) it means every single root action costs one live fingerprint — an agent can *ask* for root and never *hold* it. Consequences worth remembering: inside `tmux` this needs `pam_reattach`; over a remote session (Teleport, SSH) it cannot work at all, since there is no finger at that end — remote `sudo` falls back to a password, which a non-TTY caller cannot supply. Both files live outside `$HOME` and need root, so chezmoi cannot own them as targets; `run_onchange_after_sudo-touch-id.sh` installs them instead. It costs one password on a fresh machine and nothing ever after — it exits early when both files are already right, and refuses to prompt when there is no terminal, so a headless bootstrap prints what is left to do rather than hanging on a prompt nobody can answer. The sudoers drop-in is validated with `visudo -c` before it is installed, because a malformed one locks the account out of root entirely.
- **chezmoi over GNU Stow / bare-git.** Needed templating (per-machine values), first-class secret handling, and a source tree where dotfiles stay *visible* (`dot_` prefix) instead of hidden. Stow only symlinks; bare-git has no templating or secrets.
- **mise-first for CLI tools.** All CLI tooling is declared in mise (`config.toml`), versioned and cross-machine. Homebrew is reserved for what mise can't provide — GUI casks, plus the rare CLI with heavy native deps or no upstream release (e.g. `sshpass`). This keeps the toolchain reproducible and the Brewfile minimal.
- **Per-profile mise tools live in `conf.d/`, not in a template.** The Brewfile gates its work-only block with `{{ if eq .profile "work" }}`, and the obvious move is to do the same in `config.toml` — but `miseg`/`miserm` (`.zshrc`) run `chezmoi add ~/.config/mise/config.toml` after every change, and `chezmoi add` on a template overwrites the source with rendered content, silently destroying the directives. So `config.toml` stays a plain file and work-only tools go in `dot_config/mise/conf.d/work.toml`, which mise merges automatically and `.chezmoiignore` withholds from personal machines. The residue: `miseg` on a work machine still writes into the shared `config.toml`, so a work-only addition has to be moved into `conf.d/` by hand.
- **One OCI registry client, not four.** `crane`, `oras` and `skopeo` were dropped in favour of `regctl` at the 2026-08-15 inventory, which found a year of shell history with zero invocations of any of them — the surest sign that choosing between overlapping tools costs more than the tools save. Their unique parts serve ecosystems absent here (podman transports, Apptainer, signing outside cosign), while `regctl`'s — manifest indexes and OCI artifacts — are exactly the GHCR chart-publishing case.
- **Bitwarden for secrets.** Secrets are pulled from Bitwarden at `chezmoi apply` via `{{ bitwarden ... }}` templates — nothing secret (encrypted or otherwise) lives in this public repo. Trade-off: bootstrap needs an interactive `bw unlock` before applying secret-bearing files (vs. `age`/`secrets.env`, which keep apply offline but place material in/near the repo).
- **pre-commit + shellcheck.** Every commit lints shell scripts and runs hygiene checks, so `bootstrap.sh` and friends stay correct. pre-commit itself is installed via mise (`postinstall` wires the git hooks automatically).
- **Bootstrap ordering.** The mise config is itself a managed dotfile, so it is applied *before* `mise install` to break the chicken-and-egg; Homebrew is installed lazily, only when GUI casks are present.
- **mise hooks enabled (`settings.experimental`).** Turned on globally so a project's `mise.toml` can self-activate its git hooks with `[hooks] enter = "git config core.hooksPath .githooks"`, instead of a manual `git config` on every clone/machine. Kept at the machine level (not duplicated per repo) so individual projects only declare the `[hooks]` they need.
- **Backend preference: aqua first, then github, then http, and a language manager last.** mise's registry has acceptance tiers, and the ladder here mirrors them: `aqua` (most features and security, and no plugin code runs at install), then `github`/`gitlab` for what aqua lacks (attestation + SLSA verification), then `http` for vendor binaries with no Git host — pinned by version and sha256, because nothing else vouches for them — and `pipx`/`npm`/`gem`/`cargo` only where the tool is native to that ecosystem. A bare tool name is left alone unless the registry's own first choice is wrong here; an explicit backend always carries a comment saying why. `aqua` also wins over `github` when the aqua-registry entry does something the raw release does not: `kubectl-view-secret` (no longer declared here) ships its binary dash-named, and only aqua's `files:` rename to `kubectl-view_secret` makes kubectl discover it as a plugin.
- **Two tools stay on `vfox`, deliberately.** mise no longer accepts vfox/asdf tools, since a plugin is arbitrary code run at install time. `1password-cli` (work profile only) and `teleport-community` are grandfathered because neither can move, and the reasons are worth recording so nobody re-litigates them. `redis` was the third until the 2026-08-15 inventory dropped it as unused — it published **no prebuilt binaries at all**, which is a model mismatch with aqua rather than a missing package, so the exception it needed was the most expensive of the three. The `op` CLI is closed-source with **no public GitHub repository**, so although an aqua package exists it is a bare `type: http` against the AgileBits CDN with no `repo_owner`/`repo_name`; aqua resolves version lists only from GitHub releases or tags, so `latest` cannot work and the tool would have to be hand-pinned and hand-bumped. For a credential CLI, falling behind on updates is the worse trade. `teleport-community` looks like the easier of the two to move — an aqua package exists, resolves `latest`, and halves the install — but on macOS it ships only the client tools (`tsh`, `tctl`). The personal profile also runs the `teleport` **node daemon** out of that same install dir (see [Remote access](#remote-access-teleport)), and the launch agent execs it by absolute path with an `[ -x ] || exit 0` guard — so dropping the server binary would not fail loudly, it would leave the node silently serving nothing. Both plugins come from mise's own orgs (`mise-plugins`, `jdx`), so they share a trust root with mise itself — which is what makes the exception tolerable. New vfox/asdf tools are still refused.
- **The `ubi:` backend is banned (`settings.disable_backends`).** mise deprecated it in favour of `github:`, which resolves the same GitHub releases and additionally verifies artifact attestations and SLSA provenance; it disappears in mise 2027.1.0. Rather than let a `ubi:` tool be added and quietly rot until that release, mise is told to refuse the backend outright. The mise registry itself no longer routes any tool through ubi, so the ban costs nothing — only a hand-written `ubi:` line can hit it. Because a setting binds one machine at install time, CI carries the matching repo-level guard, which rejects both a `ubi:` declaration and the removal of the ban itself.
- **Per-machine via `profile`, not per-machine directories.** One source tree; machine-specific variation is driven by a single `profile` value (`work`/`personal`), prompted once at `chezmoi init` (override in CI/headless with `DOTFILES_PROFILE`) and stored in the machine-local chezmoi config (never in this repo). Templates branch on it — `Brewfile.tmpl` installs the .NET SDK only when `profile == "work"`. Git identity, by contrast, is **directory**-based and kept out of this public repo: `dot_gitconfig.tmpl` defaults to the personal identity (`sanchpet`) with SSH commit signing everywhere. A machine that also does corporate work sets its work identity (`work.name` / `work.email`) and the dir its repos live under (`work.gitdir`) in the machine-local chezmoi data — never in this repo. When **both** are set, an `includeIf "gitdir:…"` pulls in `dot_config/git/work.inc` to switch to that identity under the work dir; a machine with no corporate identity gets neither the `includeIf` nor `work.inc`. Setting `work.email` while leaving `work.gitdir` blank is refused at render time — git reads an empty `gitdir:` pattern as matching *every* repository, which would make the corporate identity the global default. Corporate commits are signed by a key declared for work (`work.signingKey`, machine-local like the rest), trusted in `allowed_signers` under the work email as its own principal; registering that key with the corporate host is what makes them verify there. Declare no work key and signing is switched **off** under the work dir rather than inheriting the personal key — a host that has never seen that key cannot verify it, so such a signature only discloses which personal key made the commit, and unlike an unsigned commit it does not look like one. Personal signing is separately gated on its key existing, so a machine without it still commits. This keeps a single declarative source of truth, keeps the employer identity out of the public repo, and avoids the duplication/drift of per-machine dirs.
- **SSH keys live in a vault agent — never on disk.** Each machine keeps its own `auth@…` and `signing@…` keys in its password manager and serves them over that app's SSH agent, unlocked by Touch ID: personal machines use Bitwarden, work machines 1Password. The choice is one value in the machine-local chezmoi data (`agent.kind`), alongside that machine's signing **public** key (`agent.signingKey`), which `dot_gitconfig.tmpl` renders as a `key::` literal for `user.signingKey`. Onboarding a machine means creating the keys in the vault, not running `ssh-keygen` — `bootstrap.sh` generates nothing and reads the public halves from the agent when registering them on GitHub. `~/.ssh/config` sets `IdentityAgent` to the machine's socket for all hosts. Because that only covers `ssh`, git additionally points `gpg.ssh.program` at a shim (`~/.local/bin/git-agent-sign`) forcing the same socket for signing, so non-login shells (Claude Code, background agents, scripts) sign too. Verification is declarative: every machine's signing public key is listed in `allowed_signers`, which is how commits made elsewhere verify locally. Corporate repos sign as well — only the identity differs there, not the key. Under the same flag, Teleport's `tsh` is told not to load its short-lived cert into this sign-only agent (`TELEPORT_USE_LOCAL_SSH_AGENT=false`) — the add would fail and abort the login; `tsh` keeps its certs in `~/.tsh` regardless.
- **Bitwarden server — self-hosted, per machine.** `bootstrap.sh` points the `bw` CLI at `.bitwarden.server` (asked once at `chezmoi init`, override `DOTFILES_BW_SERVER`) before login, so a self-hosted Vaultwarden works out of the box; blank keeps the `bitwarden.com` default. The URL is live infra, so it is never defaulted in this public repo — it lives only in the machine-local chezmoi config. Login is TTY-gated: a non-TTY run (CI/headless) skips it instead of hanging.

## Syncing changes (chezmoi)

chezmoi has two locations: the **source** (this repo, `chezmoi source-path`) and the **live** files in `$HOME`. Always edit the source, then push it to live — never edit the live file directly.

| Scenario | Command |
|----------|---------|
| Changed a dotfile (e.g. `.zshrc`) | edit the source (`dot_zshrc.tmpl`), then `chezmoi apply ~/.zshrc` (alias `cza`) |
| Pull latest on another machine | `chezmoi update` (= `git pull` + `apply`) (alias `czu`) |
| Check source ↔ live drift | `chezmoi diff` (alias `czd`) |
| A tool wrote to a **non-templated** target (e.g. `mise use -g` → `~/.config/mise/config.toml`) | re-import: `chezmoi add <target>` (see the `miseg` helper) |

> **Never run `chezmoi add ~/.zshrc`.** It is a **template** (`dot_zshrc.tmpl`) — `add` would overwrite it with the rendered content and destroy the `{{ ... }}` directives (incl. future secrets). Templated files are source-edited only; `chezmoi add` is for non-templated targets.

## Secrets

Secrets are **never committed**. They are resolved at apply time from [Bitwarden](https://bitwarden.com) via chezmoi templates. On a fresh machine, `bootstrap.sh` prompts for `bw unlock` only when the source actually contains secret templates.

For interactive use, `bwu` (defined in `.zshrc`) logs in once per machine and unlocks per session, exporting `BW_SESSION`. `~/.local/bin/age-archive` then reads its key via `AGE_IDENTITY_CMD` (a `bw get item …`), so the age secret is fetched from the vault at run time — never pasted, never on disk.

The zsh config (`dot_zshrc.tmpl`) is kept as a `.tmpl` so a `{{ bitwarden ... }}` secret line can be added later without a rename — see [Zsh shell](#zsh-shell-oh-my-zsh) for the plugin set and prompt.

> **Pending:** the `OBSIDIAN_API_KEY` secret reference (via Bitwarden) is not wired yet — `.zshrc` is kept as a `.tmpl` so the `{{ bitwarden ... }}` line can be added without a rename.
