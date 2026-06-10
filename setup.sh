#!/usr/bin/env bash
set -euo pipefail

PASS="[OK]"
FAIL="[MISSING]"
errors=0

check() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" &>/dev/null; then
        echo "$PASS $name : $($cmd --version 2>&1 | head -n1)"
    else
        echo "$FAIL $name : not found"
        errors=$((errors + 1))
    fi
}

echo "==> Vérification des prérequis..."
echo ""
check "Git"    git
check "Docker" docker
check "Trivy"  trivy
echo ""

if [ "$errors" -gt 0 ]; then
    echo "Des outils manquants ont été détectés."
    echo ""
    echo "Installez Trivy manuellement :"
    echo "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    echo ""
    echo "Exemple (Linux/macOS) :"
    echo "  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \\"
    echo "    | sh -s -- -b /usr/local/bin"
    exit 1
fi

echo "Tout est en place. Vous pouvez démarrer le TP."
