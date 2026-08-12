#!/bin/sh
# Register Serena (LSP-backed symbolic code navigation, declared in dot_config/mise/config.toml)
# with the WORK Claude profile. This is the other half of the mise declaration — the registration
# itself, which otherwise lives only as hand-typed state in ~/.claude-work and is lost the moment
# that profile is rebuilt or the machine is replaced.
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# Work profile ONLY, for now. The tool is recommended by the employer and is on trial in the work
# contour; whether it also belongs in the personal one is a separate decision, deliberately not
# pre-empted here. `--scope user` writes into whichever profile CLAUDE_CONFIG_DIR names, so the
# variable is set explicitly rather than inherited from whatever shell runs `chezmoi apply`.
#
# The launch command uses the mise shim's absolute path for the same reason the rtk hook does:
# mise puts tools on PATH at shell activation, and an agent that was not started from an activated
# interactive shell would fail to resolve a bare `serena`.
#
# `--project-from-cwd` lets one registration serve every repository — Serena activates whichever
# project the agent is working in, rather than being pinned to one at registration time.
set -eu

CONFIG_DIR="$HOME/.claude-work"
SERENA="$HOME/.local/share/mise/shims/serena"

command -v claude >/dev/null 2>&1 || { echo "serena: claude not on PATH — skipping registration"; exit 0; }
[ -x "$SERENA" ] || { echo "serena: binary not installed (mise not applied yet?) — skipping"; exit 0; }

# Idempotent: already registered is the steady state, not an error.
if CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp list 2>/dev/null | grep -q '^serena'; then
  echo "serena: already registered in the work profile"
  exit 0
fi

CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp add serena \
  --scope user \
  -- "$SERENA" start-mcp-server --context=claude-code --project-from-cwd

echo "serena: registered in the work profile. Restart Claude Code to pick it up."
