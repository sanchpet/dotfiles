#!/bin/sh
# Register the iximiuz Labs MCP server (labs.iximiuz.com/mcp) with BOTH Claude profiles. The
# labctl binary next to it (dot_config/mise/config.toml) drives the same platform from the
# terminal; this is the agent-facing half — catalog search, playground VMs, and coaching through
# a challenge — which otherwise lives only as hand-typed state under ~/.claude-* and is lost the
# moment a profile is rebuilt or the machine is replaced.
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# Both profiles and both machines, unlike every other registration here: the Kubernetes and Linux
# practice is the same practice whichever contour the day happens to run in, and the endpoint is
# public, so neither a corporate host nor the mesh is a precondition.
#
# A remote HTTP server, so nothing is installed and no credential passes through this repo.
# Authentication is OAuth and therefore interactive, per profile, once — the same split as
# mcp-tg, where the registration converges and the login does not. The access-token alternative
# is for headless environments; here it would only add a secret to hold and a yearly expiry to
# forget.
set -eu

ENDPOINT="https://labs.iximiuz.com/mcp"

command -v claude >/dev/null 2>&1 || { echo "ixlabs: claude not on PATH — skipping registration"; exit 0; }

pending=""
for config_dir in "$HOME/.claude-personal" "$HOME/.claude-work"; do
  profile=$(basename "$config_dir" | sed 's/^\.claude-//')

  # `mcp get` rather than `mcp list`: it reads the config without a health check, so an
  # unauthenticated remote server cannot stall the apply.
  if CLAUDE_CONFIG_DIR="$config_dir" claude mcp get ixlabs 2>/dev/null | grep -q "$ENDPOINT"; then
    echo "ixlabs: already registered in the $profile profile"
    continue
  fi

  CLAUDE_CONFIG_DIR="$config_dir" claude mcp add ixlabs --scope user --transport http "$ENDPOINT"
  pending="$pending $profile"
done

[ -n "$pending" ] || exit 0

echo "ixlabs: registered in:$pending. Each profile authenticates separately and interactively —"
echo "        run '/mcp' in a Claude Code session there and pick Authenticate."
echo "        On the consent screen, grant account:read, learning:* and playground:*;"
echo "        author:* is Pro-only and only needed for drafting Labs content."
