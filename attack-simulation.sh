#!/usr/bin/env bash
# Simule ce qu'un attaquant ferait après avoir obtenu une exécution de code
# dans ce conteneur. Ne vous dit PAS quoi corriger.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

IMAGE="vulnerable-api"
SEP="=================================================="

echo -e "${BOLD}${CYAN}$SEP${RESET}"
echo -e "${BOLD}${CYAN}  SIMULATION D'ATTAQUE — image : $IMAGE${RESET}"
echo -e "${BOLD}${CYAN}$SEP${RESET}"
echo ""

if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo -e "${YELLOW}[*] Image introuvable — construction en cours...${RESET}"
    docker build -t "$IMAGE" . -q
    echo -e "${YELLOW}[*] Image construite.${RESET}"
    echo ""
fi

# ------------------------------------------------------------------
echo -e "${BOLD}[1/5] PRIVILEGE CHECK — Sous quel utilisateur tourne l'application ?${RESET}"
echo      "      Un attaquant vérifie s'il dispose des droits root (UID 0)."
echo ""
ID_OUTPUT=$(docker run --rm "$IMAGE" id)
if echo "$ID_OUTPUT" | grep -q "uid=0"; then
    echo -e "  ${RED}$ID_OUTPUT${RESET}"
    echo -e "  ${RED}⚠  DANGER — le processus tourne en root${RESET}"
else
    echo -e "  ${GREEN}$ID_OUTPUT${RESET}"
    echo -e "  ${GREEN}✓  OK — processus non-root${RESET}"
fi
echo ""

# ------------------------------------------------------------------
echo -e "${BOLD}[2/5] PRIVILEGE ESCALATION — Modification d'un fichier système${RESET}"
echo      "      Un attaquant tente d'ajouter un compte root dans /etc/passwd."
echo ""
RESULT=$(docker run --rm "$IMAGE" sh -c \
    "echo 'attacker:x:0:0::/root:/bin/sh' >> /etc/passwd 2>&1 \
     && echo 'SUCCESS' \
     || echo 'BLOCKED'")
if [[ "$RESULT" == "SUCCESS" ]]; then
    echo -e "  ${RED}⚠  DANGER — /etc/passwd a été modifié${RESET}"
else
    echo -e "  ${GREEN}✓  BLOQUÉ — permission refusée${RESET}"
fi
echo ""

# ------------------------------------------------------------------
echo -e "${BOLD}[3/5] SECRETS EXPOSURE — Fichiers copiés dans l'image${RESET}"
echo      "      Un attaquant liste le contenu du répertoire applicatif."
echo      "      Cherche : fichiers .env, clés, tokens, configurations sensibles."
echo ""
LS_OUTPUT=$(docker run --rm "$IMAGE" ls -la /app)
echo "$LS_OUTPUT"
echo ""
if echo "$LS_OUTPUT" | grep -q "\.env"; then
    echo -e "  ${RED}⚠  DANGER — fichier .env présent dans l'image${RESET}"
else
    echo -e "  ${GREEN}✓  OK — aucun fichier .env trouvé${RESET}"
fi
echo ""

# ------------------------------------------------------------------
echo -e "${BOLD}[4/5] ATTACK SURFACE — Paquets installés dans l'image${RESET}"
echo      "      Plus il y a de paquets, plus il y a de CVE potentielles."
echo ""
PKG_COUNT=$(docker run --rm "$IMAGE" sh -c \
    "dpkg -l 2>/dev/null | grep -c '^ii' || apk list --installed 2>/dev/null | wc -l || echo '0'")
if [[ "$PKG_COUNT" -gt 100 ]]; then
    echo -e "  ${RED}⚠  $PKG_COUNT paquets installés dans cette image${RESET}"
else
    echo -e "  ${GREEN}✓  $PKG_COUNT paquets installés dans cette image${RESET}"
fi
echo ""

# ------------------------------------------------------------------
echo -e "${BOLD}[5/5] SECRETS LEAKAGE — Fichiers de configuration sensibles${RESET}"
echo      "      Un attaquant tente de lire le fichier .env embarqué dans l'image."
echo ""
SECRETS=$(docker run --rm "$IMAGE" sh -c "cat /app/.env 2>/dev/null || echo '__NOTFOUND__'")
if [[ "$SECRETS" == "__NOTFOUND__" ]]; then
    echo -e "  ${GREEN}✓  Aucun fichier .env trouvé${RESET}"
else
    echo -e "${RED}$SECRETS${RESET}"
    echo ""
    echo -e "  ${RED}⚠  DANGER — credentials lisibles depuis l'image${RESET}"

fi
echo ""

# ------------------------------------------------------------------
echo -e "${BOLD}${CYAN}$SEP${RESET}"
echo -e "${BOLD}${CYAN}  FIN DE LA SIMULATION${RESET}"
echo -e "${BOLD}${CYAN}$SEP${RESET}"
echo ""
echo -e "  Prochaine étape — scanner l'image avec Trivy :"
echo -e "  ${BOLD}trivy image --severity HIGH,CRITICAL $IMAGE${RESET}"
echo ""
