#!/usr/bin/env bash
#
# bootstrap.sh — one command → a configured machine.
#
#   Usage: clone the repo (HTTPS) and run this script from it —
#     git clone https://github.com/sanchpet/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
#   chezmoi uses that clone as its source; step 8 flips its origin to SSH once the key is set.
#
#   `chezmoi init` prompts for the machine profile (work/personal). Headless/CI (non-TTY): set
#   it beforehand, otherwise init blocks on the prompt:
#     DOTFILES_PROFILE=personal ~/dotfiles/bootstrap.sh
#
# Idempotent: safe to re-run. Order (mise-first):
#   1. mise           — base tool manager (curl) + chezmoi via mise
#   2. chezmoi source  — use THIS clone as chezmoi's source; generate ed25519 SSH key
#   3. apply mise cfg  — lay down ~/.config/mise/config.toml (break the chicken-and-egg)
#   4. mise install    — install tools (bw, uv, …) from the config
#   5. bw unlock       — only if bitwarden templates exist (interactive)
#   6. Oh My Zsh       — zsh framework (curl; not managed by mise)
#   7. chezmoi apply   — full dotfiles apply
#   8. github ssh keys — register on GitHub (gh login + auth+signing) + switch origin→SSH (interactive on TTY)
#   9. brew bundle     — render Brewfile.tmpl (per-machine profile) → GUI casks
#                        (Homebrew installed lazily, only when needed)
#
# Secrets never land in the repository (see README, secrets Decision Record).

set -euo pipefail

# Absolute dir this script lives in — the dotfiles clone you ran bootstrap from. chezmoi uses it
# directly as its source (step 2), and step 8 flips its origin to SSH once the key is registered.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

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

# --- 2. chezmoi source + per-machine config ---
# bootstrap is always run from a clone of the dotfiles (git clone … && ./bootstrap.sh), so use
# THAT clone as chezmoi's source directly (chezmoi init --source): no second copy in
# ~/.local/share/chezmoi, and edits apply with no commit/push/re-clone. .chezmoi.toml.tmpl pins
# sourceDir to wherever init ran with --source. The per-machine config (chezmoi.toml) must exist,
# else every `chezmoi apply` re-evaluates the config template and re-prompts (promptStringOnce),
# which hangs on a TTY — so (re)generate it whenever it's missing or points elsewhere.
[ -f "$SCRIPT_DIR/.chezmoi.toml.tmpl" ] || die "run bootstrap.sh from a dotfiles clone (no .chezmoi.toml.tmpl beside it)."
chezmoi_config="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
chezmoi_src="$SCRIPT_DIR"
if [ "$(chezmoi source-path 2>/dev/null || true)" != "$chezmoi_src" ] || [ ! -f "$chezmoi_config" ]; then
  log "chezmoi init — using this clone as source ($chezmoi_src)"
  chezmoi init --source="$chezmoi_src"
else
  log "chezmoi source already points at this clone ($chezmoi_src)"
fi

# Ensure a per-machine SSH key exists *before* chezmoi apply (step 7). dot_gitconfig.tmpl only
# enables commit signing when ~/.ssh/id_ed25519.pub is present at render time — generate it now
# or apply would write a gitconfig with signing off. ed25519 (SOTA for user keys), no passphrase
# (protected by full-disk encryption). Idempotent: never overwrites. GitHub registration is
# step 8 (it needs gh, installed at step 4).
ssh_key="$HOME/.ssh/id_ed25519"
if [ ! -f "$ssh_key" ]; then
  log "no SSH key — generating ed25519 (machine: $(hostname -s))"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname -s)" -f "$ssh_key" -N ""
fi
# The source was cloned over HTTPS above (portable — works in CI / on a bare machine, no key
# needed). Switching origin to SSH waits until the key is registered on GitHub (end of step 8).

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

# --- 8. GitHub SSH keys — register this machine's key on GitHub (push + Verified) ---
# The key was generated in step 2 (before apply, so commit signing turned on). git signs commits
# with it (dot_gitconfig.tmpl) and pushes over SSH; both need it on the GitHub account — as an
# authentication key (push) and a signing key (Verified badge). Register both (idempotent).
# Interactive on a TTY: runs `gh auth login` if unauthenticated and refreshes the token scope
# when needed (both open a browser). On a non-TTY run (CI / headless) it prints the key and
# skips. Finally, now that the key is on GitHub, switch the dotfiles clone's origin to SSH so
# it's push-ready — same run, no second bootstrap needed (idempotent; stays HTTPS when SSH auth
# isn't working: CI, or registration was declined/failed).
ssh_key="$HOME/.ssh/id_ed25519"
gh_scopes="admin:public_key,admin:ssh_signing_key"
if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  if [ -t 0 ]; then
    log "gh not authenticated — launching interactive login"
    gh auth login --hostname github.com --git-protocol ssh --scopes "$gh_scopes" || true
  else
    warn "gh not authenticated (non-TTY) — register this key on GitHub manually (auth + signing):"
    warn "  $(cat "$ssh_key.pub")"
  fi
fi
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  key_blob="$(awk '{print $2}' "$ssh_key.pub")"
  for type in authentication signing; do
    title="$type-$(hostname -s)"
    if gh ssh-key list 2>/dev/null | awk -F'\t' -v t="$type" '$5 == t { print $2 }' | grep -qF "$key_blob"; then
      log "GitHub $type key already registered"
    elif out="$(gh ssh-key add "$ssh_key.pub" --type "$type" --title "$title" 2>&1)"; then
      log "registered this machine's SSH key as a GitHub $type key"
    elif printf '%s' "$out" | grep -qiE 'already|duplicate'; then
      log "GitHub $type key already present"
    elif [ -t 0 ]; then
      # add failed — most likely a missing token scope (e.g. admin:public_key for an auth key).
      # Refresh interactively: this opens a browser/device prompt, so keep its output VISIBLE —
      # suppressing it turns the wait into a silent hang. One-time; the scope is cached after.
      log "GitHub needs more scope for the $type key — running 'gh auth refresh', follow the prompt…"
      if gh auth refresh --hostname github.com --scopes "$gh_scopes" \
         && gh ssh-key add "$ssh_key.pub" --type "$type" --title "$title"; then
        log "registered this machine's SSH key as a GitHub $type key (after scope refresh)"
      else
        warn "couldn't add $type key — add it manually: gh ssh-key add $ssh_key.pub --type $type"
      fi
    else
      warn "couldn't add $type key: $out"
      warn "  fix scope then re-run: gh auth refresh -s $gh_scopes"
    fi
  done
  # Key is now on GitHub — switch the dotfiles clone from HTTPS to SSH so it's push-ready.
  if git -C "$chezmoi_src" remote get-url origin 2>/dev/null | grep -q '^https://github.com/'; then
    if ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
      ssh_url="$(git -C "$chezmoi_src" remote get-url origin | sed -E 's#https://github.com/#git@github.com:#')"
      log "GitHub SSH auth works — switching origin to SSH ($ssh_url)"
      git -C "$chezmoi_src" remote set-url origin "$ssh_url"
    fi
  fi
fi

# --- 9. brew bundle (GUI casks; Homebrew installed lazily) ---
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
    # App Store sign-in gate: `mas` entries need the App Store signed in. Apple blocks
    # CLI sign-in (mas 7 dropped `signin`/`account`), so this can only be a TTY prompt.
    # CI renders no mas entries (Brewfile guards them behind `not (env "CI")`) → skipped.
    if grep -qE '^[[:space:]]*mas[[:space:]]' "$BREWFILE"; then
      if [ -t 0 ]; then
        log "Brewfile lists Mac App Store apps — opening the App Store to sign in"
        open -a "App Store" 2>/dev/null || true
        printf '\033[1;34m==>\033[0m Sign in to the App Store, then press Enter to continue… '
        read -r _
      else
        warn "Brewfile lists mas apps but no TTY to prompt for App Store sign-in — those installs may fail; sign in and re-run."
      fi
    fi
    log "brew bundle — GUI apps from Brewfile"
    brew bundle --file="$BREWFILE"
  fi
else
  log "Brewfile has no casks/formulae — brew not needed (mise-first)."
fi

log "Done. Machine configured."
