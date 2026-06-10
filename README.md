# Lab DevSecOps — Sécuriser une image Docker

> **Durée estimée : 1h00**  
> **Stack : Node.js + Docker**  
> **Outil principal : Trivy**

---

## Objectifs pédagogiques

À la fin de ce TP, vous serez capable de :

- Identifier les vulnérabilités d'une image Docker avec un scanner automatique.
- Comprendre l'impact concret d'un conteneur mal configuré via une simulation d'attaque.
- Corriger un Dockerfile pour réduire la surface d'attaque.
- Intégrer Trivy dans une pipeline CI pour bloquer automatiquement les images non conformes.

---

## Prérequis

| Outil | Vérification |
|-------|-------------|
| Git | `git --version` |
| Docker | `docker --version` |
| Compte GitHub | accès à l'onglet Actions |

> `setup.sh` vérifie que les outils sont présents. Si Trivy est absent, il vous indique comment l'installer.

---

## Contexte

Vous êtes développeur dans une équipe qui vient de containeriser son API Node.js. L'image fonctionne, les tests passent, le déploiement est imminent.

L'équipe DevSecOps demande à passer l'image au scanner avant la mise en production. Un script de simulation d'attaque est lancé en parallèle pour mesurer l'impact réel. Les résultats sont préoccupants.

Votre mission : comprendre ce qui ne va pas, corriger l'image, et faire passer la CI au vert.

---

## Structure du projet

```
Lab2/
├── app.js                        ← API Node.js
├── package.json
├── Dockerfile                    ← Image vulnérable (point de départ)
├── .env                          ← Fichier de configuration sensible
├── .trivyignore                  ← CVE acceptées (base de données npm pas encore à jour)
├── attack-simulation.sh          ← Script de simulation d'attaque
├── solution/
│   ├── Dockerfile                ← Image corrigée (à ouvrir APRÈS avoir essayé)
│   └── .dockerignore
└── .github/
    └── workflows/
        └── security.yml          ← Pipeline CI avec Trivy
```

---

## Étape 0 — Mise en place

Installez les outils nécessaires :

```bash
./setup.sh
```

Construisez et démarrez l'API :

```bash
docker build -t vulnerable-api .
docker run -d -p 3000:3000 --name vulnerable-api vulnerable-api
```

Vérifiez que l'API répond :

```bash
curl http://localhost:3000/health
```

---

## Étape 1 — Simulation d'attaque

Lancez le script de simulation :

```bash
bash attack-simulation.sh
```

Le script simule ce qu'un attaquant ferait après avoir obtenu une exécution de code dans ce conteneur. Il ne vous dit pas quoi corriger — c'est votre job.

Questions :
- Sous quel utilisateur tourne le processus ? Quel est l'UID affiché ?
- La tentative d'écriture dans `/etc/passwd` a-t-elle réussi ? Qu'est-ce que cela implique ?
- Quels fichiers sont présents dans `/app` ? Y a-t-il des fichiers qui ne devraient pas s'y trouver ?
- Combien de paquets sont installés ? Pourquoi est-ce un problème ?

---

## Étape 2 — Scanner avec Trivy

Lancez Trivy contre l'image :

```bash
trivy image vulnerable-api
```

Pour filtrer sur les sévérités les plus critiques :

```bash
trivy image --severity HIGH,CRITICAL vulnerable-api
```

Questions :
- Combien de CVE HIGH et CRITICAL sont détectées ?
- D'où viennent la majorité des CVE — de l'application ou de l'image de base ?
- Quel est le package avec le plus de vulnérabilités ?

💡 La majorité des CVE ne viennent pas du code que vous avez écrit. Elles viennent de ce que vous avez *embarqué* sans le choisir en utilisant `FROM node:18`.

---

## Étape 3 — Corriger l'image

Corrigez le `Dockerfile` **et** les dépendances pour éliminer toutes les CVE HIGH et CRITICAL.

Les CVE viennent de deux sources distinctes — vous devrez corriger les deux :
- le `Dockerfile` (image de base, configuration)
- les dépendances npm (utilisez `npm audit` pour identifier ce qui est à corriger)

Après chaque correction, reconstruisez et relancez les checks :

```bash
npm audit fix --force  # met à jour les dépendances vulnérables
docker build -t vulnerable-api .
./attack-simulation.sh
trivy image --severity HIGH,CRITICAL vulnerable-api
```

Objectif : `trivy image` ne remonte plus aucun HIGH ou CRITICAL, et le script d'attaque affiche `BLOQUÉ` sur la tentative d'écriture système.

Indice si vous êtes bloqué : regardez `solution/Dockerfile` — mais essayez d'abord.

---

## Étape 4 — Intégrer dans la pipeline CI

Le fichier `.github/workflows/security.yml` contient un squelette à compléter.

Votre mission : écrire les steps manquants pour que le workflow GitHub Actions :

1. Récupère le code source (checkout)
2. Construise l'image Docker
3. Installe Trivy sur le runner
4. Lance Trivy contre l'image et **bloque le job** si des CVE HIGH ou CRITICAL sont détectées

Une fois la pipeline écrite, committez et poussez :

```bash
git add Dockerfile .github/workflows/security.yml
git commit -m "feat: pipeline CI avec Trivy"
git push
```

Rendez-vous sur l'onglet **Actions** de votre dépôt GitHub. Le job `Scan d'image conteneur (Trivy)` doit passer au vert uniquement si votre image est propre.

Questions :
- Qu'est-ce qui déclenche le workflow ? Sur quelle(s) branche(s) ?
- Que se passe-t-il si vous poussez l'image vulnérable d'origine ? Pourquoi est-ce utile dans un workflow réel ?

---

## Étape 5 — Ce qu'il faut retenir

| Problème | Impact | Correction |
|----------|--------|------------|
| `FROM node:18` (image complète, EOL) | Des centaines de CVE embarquées | Utiliser `node:22-alpine` (LTS supporté) |
| Pas de `USER` — tourne en root | Un attaquant peut modifier les fichiers système | Ajouter `USER node` |
| `COPY . .` sans `.dockerignore` | Le fichier `.env` est copié dans l'image | Ajouter un `.dockerignore` |
| `npm install` — dépendances de dev | Plus de packages = plus de surface d'attaque | Utiliser `npm ci --only=production` |
| `express@4.18.2` (et dépendances transitives) | 7 CVE dont 3 HIGH | `npm audit fix --force` → express@4.22.2 |

> Une image Docker n'est pas juste votre code. C'est votre code + l'OS + le runtime + tout ce que vous avez oublié de ne pas embarquer.

---

## Livrables attendus

- La sortie de `bash attack-simulation.sh` sur l'image d'origine (avec les résultats préoccupants).
- La sortie de `trivy image --severity HIGH,CRITICAL vulnerable-api` avant correction.
- La sortie de `trivy image --severity HIGH,CRITICAL vulnerable-api` après correction (propre).
- Votre `Dockerfile` corrigé.
- Le pipeline CI au vert sur GitHub Actions.

---

## Pour aller plus loin (optionnel)

- Tester `trivy fs .` pour scanner les dépendances Node.js sans builder l'image.
- Pousser l'image vers un registry (Docker Hub / GHCR) et scanner directement depuis le registry : `trivy image ghcr.io/yourname/secure-api:latest`.
- Explorer `trivy image --format cyclonedx` pour générer un SBOM (Software Bill of Materials) de l'image.
