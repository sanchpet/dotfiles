#!/usr/bin/env bash
#
# bootstrap.sh — one command → a configured machine.
#
#   Usage (bare machine):
#     git clone https://github.com/sanchpet/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
#
#   In a terminal, `chezmoi init` prompts for the machine profile (work/personal).
#   Headless/CI (non-TTY): set it beforehand, otherwise init fails on the prompt:
#     DOTFILES_PROFILE=personal ~/dotfiles/bootstrap.sh
#
# Idempotent: safe to re-run. Order (mise-first):
#   1. mise           — base tool manager (curl) + chezmoi via mise
#   2. chezmoi init    — create the source from the repository
#   3. apply mise cfg  — lay down ~/.config/mise/config.toml (break the chicken-and-egg)
#   4. mise install    — install tools (bw, uv, …) from the config
#   5. bw unlock       — only if bitwarden templates exist (interactive)
#   6. Oh My Zsh       — zsh framework (curl; not managed by mise)
#   7. chezmoi apply   — full dotfiles apply
#   8. brew bundle     — render Brewfile.tmpl (per-machine profile) → GUI casks
#                        (Homebrew installed lazily, only when needed)
#
# Secrets never land in the repository (see README, secrets Decision Record).

set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/sanchpet/dotfiles.git}"

# --- output ---
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. mise (base tool manager) ---
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  log "mise not found — installing (https://mise.run)"
  curl -fsSL https://mise.run | sh
fi
# mise + its shims on PATH for the current (non-interactive) session
export PATH="$HOME/.local/bin:${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
command -v mise >/dev/null 2>&1 || die "mise not on PATH after install."
log "mise ready ($(mise --version 2>/dev/null | head -1))"

# chezmoi is needed for init — install it via mise (idempotent).
if ! command -v chezmoi >/dev/null 2>&1; then
  log "chezmoi not found — installing via mise"
  mise use -g chezmoi@latest
  hash -r 2>/dev/null || true
fi
command -v chezmoi >/dev/null 2>&1 || die "chezmoi not on PATH after installing via mise."

# --- 2. chezmoi init (creates the source) ---
chezmoi_src="$(chezmoi source-path 2>/dev/null || true)"
if [ -n "$chezmoi_src" ] && [ -d "$chezmoi_src" ]; then
  log "chezmoi source already initialized ($chezmoi_src)"
else
  log "chezmoi init — cloning source from $REPO"
  chezmoi init "$REPO"
  chezmoi_src="$(chezmoi source-path)"
fi

# Clone over HTTPS (read access to a public repo always works, no key needed — portable
# and works in CI / on a bare machine). If the machine has a working GitHub SSH key,
# switch origin to SSH so the owner's working clone is push-ready. Idempotent.
if git -C "$chezmoi_src" remote get-url origin 2>/dev/null | grep -q '^https://github.com/'; then
  if ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
    ssh_url="$(git -C "$chezmoi_src" remote get-url origin | sed -E 's#https://github.com/#git@github.com:#')"
    log "GitHub SSH key found — switching origin to SSH ($ssh_url)"
    git -C "$chezmoi_src" remote set-url origin "$ssh_url"
  fi
fi

# --- 3. Break the chicken-and-egg: apply ONLY the mise config before mise install ---
if [ -f "$chezmoi_src/dot_config/mise/config.toml" ]; then
  log "chezmoi apply — laying down the mise config (before mise install)"
  chezmoi apply --force "$HOME/.config/mise/config.toml"
fi

# --- 4. mise install (tools from the config: bw, uv, …) ---
if [ -f "$HOME/.config/mise/config.toml" ]; then
  log "mise install — installing tools from ~/.config/mise/config.toml"
  mise install
fi

# --- 5. Bitwarden unlock — only if the source has bitwarden templates ---
if grep -rqls "bitwarden" "$chezmoi_src" --include='*.tmpl' 2>/dev/null; then
  if command -v bw >/dev/null 2>&1; then
    if [ -z "${BW_SESSION:-}" ]; then
      log "Bitwarden templates detected — Bitwarden unlock required"
      bw login --check >/dev/null 2>&1 || bw login
      BW_SESSION="$(bw unlock --raw)" || die "Failed to unlock Bitwarden."
      export BW_SESSION
    fi
  else
    warn "Bitwarden templates present but 'bw' is not installed — secrets won't be resolved."
  fi
fi

# --- 6. Oh My Zsh (zsh framework; install BEFORE laying down .zshrc) ---
# --unattended → RUNZSH=no + CHSH=no; KEEP_ZSHRC=yes → don't touch .zshrc (chezmoi lays it down).
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Oh My Zsh not found — installing (without replacing .zshrc or changing the shell)"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  log "Oh My Zsh already installed"
fi

# External omz plugins (not bundled with omz) — clone into $ZSH_CUSTOM/plugins.
# starship/zoxide come via mise (see step 4); only zsh plugins here.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in \
  "zsh-users/zsh-autosuggestions" \
  "zsh-users/zsh-syntax-highlighting" \
  "zsh-users/zsh-completions" \
  "MichaelAquilina/zsh-you-should-use" \
  "wfxr/forgit" \
  "marlonrichert/zsh-autocomplete"; do
  dest="$ZSH_CUSTOM/plugins/${plugin##*/}"
  if [ ! -d "$dest" ]; then
    log "omz plugin: cloning ${plugin##*/}"
    git clone --depth=1 "https://github.com/${plugin}.git" "$dest"
  fi
done

# --- 7. chezmoi apply (full apply) ---
log "chezmoi apply — full dotfiles apply"
chezmoi apply

# --- 8. brew bundle (GUI casks; Homebrew installed lazily) ---
# Brewfile is a chezmoi template (per-machine via .profile). Render it with the same
# engine as the dotfiles into a temp file, then hand it to brew bundle.
BREWFILE_TMPL="$chezmoi_src/Brewfile.tmpl"
BREWFILE="$(mktemp -t Brewfile)"
trap 'rm -f "$BREWFILE"' EXIT
if [ -f "$BREWFILE_TMPL" ]; then
  log "render Brewfile via chezmoi execute-template (per-machine profile)"
  chezmoi execute-template < "$BREWFILE_TMPL" > "$BREWFILE"
fi
if [ -s "$BREWFILE" ] && grep -qE '^[[:space:]]*(cask|brew)[[:space:]]' "$BREWFILE"; then
  if ! command -v brew >/dev/null 2>&1; then
    if [ "$(uname -s)" = "Darwin" ]; then
      log "Homebrew needed for casks from Brewfile — installing"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      warn "Brewfile has casks but Homebrew is missing and this is not macOS — skipping."
    fi
  fi
  if command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ]; then
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    log "brew bundle — GUI apps from Brewfile"
    brew bundle --file="$BREWFILE"
  fi
else
  log "Brewfile has no casks/formulae — brew not needed (mise-first)."
fi

log "Done. Machine configured."
