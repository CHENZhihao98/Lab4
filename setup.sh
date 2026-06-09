#!/usr/bin/env bash
set -euo pipefail

# Install Trivy if not already present
if ! command -v trivy &>/dev/null; then
    echo "==> Installation de Trivy..."
    mkdir -p "$HOME/.local/bin"
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" \
        || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "Trivy $(trivy --version)"
echo "Prêt."
