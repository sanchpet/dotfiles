#!/bin/sh
# Enable Touch ID for sudo on this machine, and make every root action cost a fresh one.
# Rationale (why this and not a NOPASSWD rule) is in README § Design decisions.
#
# Two system files, neither of which chezmoi can own — they live outside $HOME and need root:
#   /etc/pam.d/sudo_local     `auth sufficient pam_tid.so`, from Apple's own template
#   /etc/sudoers.d/timestamp  Defaults timestamp_timeout=0 — no credential cache
#
# Safe to run anywhere, which is the whole trick: it is idempotent (an already-configured
# machine exits before asking for anything) and it REFUSES to prompt without a terminal. A
# headless bootstrap — CI, a remote apply — would otherwise hang forever on a password prompt
# nobody can answer, so there it prints what is left to do and gets out of the way.
#
# On a corporate machine, note that MDM may own /etc/pam.d and revert this.
set -eu

[ "$(uname -s)" = "Darwin" ] || exit 0

pam_target=/etc/pam.d/sudo_local
pam_template=/etc/pam.d/sudo_local.template
sudoers_target=/etc/sudoers.d/timestamp

# macOS < 14 has no update-surviving include file; do not touch /etc/pam.d/sudo itself.
[ -f "$pam_template" ] || exit 0

pam_done=false
sudoers_done=false
grep -qs '^auth[[:space:]]*sufficient[[:space:]]*pam_tid\.so' "$pam_target" && pam_done=true
[ -f "$sudoers_target" ] && sudoers_done=true

if $pam_done && $sudoers_done; then
  exit 0
fi

if [ ! -t 0 ]; then
  echo "sudo-touch-id: no terminal to authenticate on — skipping."
  echo "sudo-touch-id: run 'chezmoi apply' from an interactive shell to finish the setup."
  exit 0
fi

echo "sudo-touch-id: configuring Touch ID for sudo (one password, once per machine)…"

sudo sh -s <<'ROOT'
set -eu

if ! grep -qs '^auth[[:space:]]*sufficient[[:space:]]*pam_tid\.so' /etc/pam.d/sudo_local; then
  # Apple ships the line commented out in the template; uncommenting it is the whole change.
  sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template > /etc/pam.d/sudo_local
  chmod 444 /etc/pam.d/sudo_local
fi

# A malformed sudoers file locks the account out of root entirely, so it is validated before it
# is ever installed — never write into /etc/sudoers.d directly.
tmp="$(mktemp)"
printf 'Defaults timestamp_timeout=0\n' > "$tmp"
if visudo -cf "$tmp" >/dev/null 2>&1; then
  install -m 440 -o root -g wheel "$tmp" /etc/sudoers.d/timestamp
else
  echo "sudo-touch-id: refusing to install an invalid sudoers file" >&2
fi
rm -f "$tmp"
ROOT

echo "sudo-touch-id: done — sudo now asks for a fingerprint, and asks again every time."
