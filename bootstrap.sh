#!/usr/bin/env bash
#
# bootstrap.sh — один command → настроенная машина.
#
#   Использование (на голой машине):
#     git clone https://github.com/sanchpet/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
#
#   В терминале chezmoi init спросит профиль машины (work/personal).
#   Headless/CI (не-TTY) — задать заранее, иначе init упадёт на промпте:
#     DOTFILES_PROFILE=personal ~/dotfiles/bootstrap.sh
#
# Идемпотентно: безопасно запускать повторно. Целевой порядок (mise-first):
#   1. mise           — базовый тул-менеджер (curl) + chezmoi через mise
#   2. chezmoi init    — создаёт source из репозитория
#   3. apply mise-cfg  — раскладывает ~/.config/mise/config.toml (разрыв «курица-яйцо»)
#   4. mise install    — ставит инструменты (bw, uv, …) из конфига
#   5. bw unlock       — если есть bitwarden-шаблоны (интерактив)
#   6. Oh My Zsh       — фреймворк zsh (curl; не управляется mise)
#   7. chezmoi apply   — полная раскладка конфигов
#   8. brew bundle     — рендер Brewfile.tmpl (per-machine profile) → GUI-casks
#                        (Homebrew ставится лениво, только под них)
#
# Секреты в репозиторий НЕ попадают (см. README, Decision Record по секретам).

set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/sanchpet/dotfiles.git}"

# --- вывод ---
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. mise (базовый тул-менеджер) ---
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  log "mise не найден — устанавливаю (https://mise.run)"
  curl -fsSL https://mise.run | sh
fi
# mise + его shims в PATH текущей (не-интерактивной) сессии
export PATH="$HOME/.local/bin:${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
command -v mise >/dev/null 2>&1 || die "mise не найден в PATH после установки."
log "mise готов ($(mise --version 2>/dev/null | head -1))"

# chezmoi нужен уже для init — ставим его через mise (идемпотентно).
if ! command -v chezmoi >/dev/null 2>&1; then
  log "chezmoi не найден — ставлю через mise"
  mise use -g chezmoi@latest
  hash -r 2>/dev/null || true
fi
command -v chezmoi >/dev/null 2>&1 || die "chezmoi не найден в PATH после установки через mise."

# --- 2. chezmoi init (создаёт source) ---
chezmoi_src="$(chezmoi source-path 2>/dev/null || true)"
if [ -n "$chezmoi_src" ] && [ -d "$chezmoi_src" ]; then
  log "chezmoi source уже инициализирован ($chezmoi_src)"
else
  log "chezmoi init — клонирую source из $REPO"
  chezmoi init "$REPO"
  chezmoi_src="$(chezmoi source-path)"
fi

# Клон делаем по HTTPS (read-доступ к public-репо есть всегда, ключ не нужен — переносимо
# и работает в CI/на голой машине). Если у машины есть рабочий SSH-ключ к GitHub —
# переключаем origin на SSH, чтобы рабочий клон владельца был push-ready. Идемпотентно.
if git -C "$chezmoi_src" remote get-url origin 2>/dev/null | grep -q '^https://github.com/'; then
  if ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
    ssh_url="$(git -C "$chezmoi_src" remote get-url origin | sed -E 's#https://github.com/#git@github.com:#')"
    log "SSH-ключ к GitHub найден — переключаю origin на SSH ($ssh_url)"
    git -C "$chezmoi_src" remote set-url origin "$ssh_url"
  fi
fi

# --- 3. Разрыв «курица-яйцо»: разложить ТОЛЬКО mise-конфиг до mise install ---
if [ -f "$chezmoi_src/dot_config/mise/config.toml" ]; then
  log "chezmoi apply — раскладываю mise-конфиг (до mise install)"
  chezmoi apply --force "$HOME/.config/mise/config.toml"
fi

# --- 4. mise install (инструменты из конфига: bw, uv, …) ---
if [ -f "$HOME/.config/mise/config.toml" ]; then
  log "mise install — установка инструментов из ~/.config/mise/config.toml"
  mise install
fi

# --- 5. Bitwarden unlock — только если в source есть bitwarden-шаблоны ---
if grep -rqls "bitwarden" "$chezmoi_src" --include='*.tmpl' 2>/dev/null; then
  if command -v bw >/dev/null 2>&1; then
    if [ -z "${BW_SESSION:-}" ]; then
      log "Обнаружены bitwarden-шаблоны — нужен unlock Bitwarden"
      bw login --check >/dev/null 2>&1 || bw login
      BW_SESSION="$(bw unlock --raw)" || die "Не удалось разблокировать Bitwarden."
      export BW_SESSION
    fi
  else
    warn "Есть bitwarden-шаблоны, но 'bw' не установлен — секреты не подставятся."
  fi
fi

# --- 6. Oh My Zsh (фреймворк zsh; ставим ДО раскладки .zshrc) ---
# --unattended → RUNZSH=no + CHSH=no; KEEP_ZSHRC=yes → не трогать .zshrc (его кладёт chezmoi).
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Oh My Zsh не найден — устанавливаю (без подмены .zshrc и смены shell)"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  log "Oh My Zsh уже установлен"
fi

# --- 7. chezmoi apply (полная раскладка) ---
log "chezmoi apply — полная раскладка конфигов"
chezmoi apply

# --- 8. brew bundle (GUI-casks; Homebrew ставится лениво) ---
# Brewfile — chezmoi-шаблон (per-machine через .profile). Рендерим его тем же
# движком, что и dotfiles, во временный файл, и только потом отдаём в brew bundle.
BREWFILE_TMPL="$chezmoi_src/Brewfile.tmpl"
BREWFILE="$(mktemp -t Brewfile)"
trap 'rm -f "$BREWFILE"' EXIT
if [ -f "$BREWFILE_TMPL" ]; then
  log "render Brewfile через chezmoi execute-template (per-machine profile)"
  chezmoi execute-template < "$BREWFILE_TMPL" > "$BREWFILE"
fi
if [ -s "$BREWFILE" ] && grep -qE '^[[:space:]]*(cask|brew)[[:space:]]' "$BREWFILE"; then
  if ! command -v brew >/dev/null 2>&1; then
    if [ "$(uname -s)" = "Darwin" ]; then
      log "Homebrew нужен для casks из Brewfile — устанавливаю"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      warn "Brewfile с casks есть, но Homebrew нет и это не macOS — пропускаю."
    fi
  fi
  if command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ]; then
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    log "brew bundle — GUI-приложения из Brewfile"
    brew bundle --file="$BREWFILE"
  fi
else
  log "Brewfile без casks/формул — brew не нужен (mise-first)."
fi

log "Готово. Машина настроена."
