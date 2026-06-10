#!/usr/bin/env bash
set -euo pipefail

install_node() {
    echo "==> Installation de Node.js (LTS)..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
}

install_trivy() {
    echo "==> Installation de Trivy..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin
}

echo "==> Vérification des prérequis..."
echo ""

# Git
if command -v git &>/dev/null; then
    echo "[OK] Git : $(git --version)"
else
    echo "[MISSING] Git : installez Git avant de continuer."
    exit 1
fi

# Docker
if command -v docker &>/dev/null; then
    echo "[OK] Docker : $(docker --version)"
else
    echo "[MISSING] Docker : installez Docker avant de continuer."
    exit 1
fi

# Node.js / npm
if command -v node &>/dev/null && command -v npm &>/dev/null; then
    echo "[OK] Node.js : $(node --version)"
    echo "[OK] npm : $(npm --version)"
else
    install_node
    echo "[OK] Node.js : $(node --version)"
    echo "[OK] npm : $(npm --version)"
fi

# Trivy
if command -v trivy &>/dev/null; then
    echo "[OK] Trivy : $(trivy --version | head -n1)"
else
    install_trivy
    echo "[OK] Trivy : $(trivy --version | head -n1)"
fi

echo ""
echo "Tout est en place. Vous pouvez démarrer le TP."
