#!/bin/sh
# Install the helm plugins that mise cannot declare. A plugin is not a tool on PATH: it lives in
# helm's own plugin directory and is registered by `helm plugin install`, so without this it exists
# only as hand-typed state that disappears with the machine — the same gap the other
# run_onchange_after_* scripts here close.
#
# revision: 2  — bump to force a re-run after editing the list below.
#
# The plugin directory is shared across helm majors (~/Library/helm/plugins on macOS), so one
# install serves both the globally declared helm and a project that pins an older major.
#
# Installed from the signed release tarball rather than the git URL. helm 4 verifies plugin
# signatures by default and cannot verify a VCS checkout at all, so the git URL upstream documents
# only works with --verify=false. Keeping verification on costs a pinned version to bump by hand,
# which is the honest price.
#
# What the signature proves and does not: the key and the plugin ship from the same project, so a
# good signature means the release asset was signed by that project's key — it defends against a
# replaced asset or a tampered download, not against the project itself. Pinning the fingerprint
# below adds the one thing that is otherwise missing: a key quietly swapped in the repository later
# will not pass.
#
# helm-unittest: render-level assertions for charts — values in, rendered manifest asserted, no
# cluster involved. It earns its place over greping `helm template` output because of
# `failedTemplate`, which turns "this misconfiguration must fail the render" into a test case
# instead of a comment.
set -eu

PLUGIN_VERSION=1.1.2
PLUGIN_URL="https://github.com/helm-unittest/helm-unittest/releases/download/v${PLUGIN_VERSION}/unittest-${PLUGIN_VERSION}.tgz"
PLUGIN_KEY_URL="https://github.com/helm-unittest/helm-unittest/raw/refs/heads/main/public-key.asc"

# Read off the key and confirmed as the signer of the 1.1.2 provenance on 2026-08-13.
PLUGIN_KEY_FPR=853008CD0B0A5A2DA04FF8A5616AD47F65B54AC7

# Helm needs a legacy keyring, and it gets one of its own: exporting the whole gpg store here would
# let any key in it vouch for a plugin.
KEYRING="$HOME/Library/helm/plugin-keyring.gpg"

HELM="$HOME/.local/share/mise/shims/helm"
[ -x "$HELM" ] || { echo "helm plugins: helm not installed (mise not applied yet?) — skipping"; exit 0; }
command -v gpg >/dev/null 2>&1 || { echo "helm plugins: gpg missing, cannot verify — skipping"; exit 0; }

# Already installed is the steady state, not an error.
if "$HELM" plugin list 2>/dev/null | awk 'NR > 1 { print $1 }' | grep -qx unittest; then
  echo "helm plugins: unittest already installed"
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
chmod 700 "${work}"

# Isolated GNUPGHOME: importing a third party's key into the real store is a side effect nobody
# asked for, and gpg is only needed here to reshape the key for helm.
curl -fsSL "${PLUGIN_KEY_URL}" -o "${work}/key.asc"
GNUPGHOME="${work}" gpg --batch --quiet --import "${work}/key.asc"

got=$(GNUPGHOME="${work}" gpg --batch --list-keys --with-colons | awk -F: '/^fpr:/ { print $10; exit }')
if [ "${got}" != "${PLUGIN_KEY_FPR}" ]; then
  echo "helm plugins: signing key is ${got}, expected ${PLUGIN_KEY_FPR} — refusing to install" >&2
  exit 1
fi

mkdir -p "$(dirname "${KEYRING}")"
GNUPGHOME="${work}" gpg --batch --export "${PLUGIN_KEY_FPR}" > "${KEYRING}"

"$HELM" plugin install "${PLUGIN_URL}" --keyring "${KEYRING}"
echo "helm plugins: unittest ${PLUGIN_VERSION} installed, signature verified against ${PLUGIN_KEY_FPR}"
