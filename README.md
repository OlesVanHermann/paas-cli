# CLI et documentation du PaaS di2amp

Tout ce qu'il faut pour utiliser le PaaS di2amp hors de la console : la CLI
`paas-apps`, prête à l'emploi, la documentation de l'API et des skills pour
les agents IA (Claude Code…).

| Fichier | Contenu |
|---|---|
| `paas-apps-linux-x86_64` | **CLI `paas-apps`** pour Linux x86_64 |
| `paas-apps-linux-aarch64` | **CLI `paas-apps`** pour Linux ARM64 |
| [`SHA256SUMS`](SHA256SUMS) | Sommes de contrôle des exécutables |
| [`CLI.md`](CLI.md) | Guide de la CLI : commandes, options, variables d'environnement, codes de sortie |
| [`API.md`](API.md) | Guide de l'API : authentification, enveloppes, erreurs, pagination |
| [`API-REFERENCE.md`](API-REFERENCE.md) | **Référence de l'API** : les 428 opérations, par domaine, avec leurs paramètres, leurs types et leur appel CLI |
| [`openapi.yaml`](openapi.yaml) | **Contrat de l'API** (OpenAPI 3.0.3), qui fait foi. Il permet aussi de générer un client dans votre langage |
| [`SKILL-paas-cli.md`](SKILL-paas-cli.md) | Skill pour agents IA : utiliser la CLI |
| [`SKILL-paas-api.md`](SKILL-paas-api.md) | Skill pour agents IA : appeler l'API en HTTP (curl) |
| [`exemples/`](exemples/README.md) | **Dix apps à installer en une commande** (WordPress, Drupal…) : un `paas.xml` par app ; `push.sh` installe, `clean.up` retire. Les dix fonctionnent ; FileBrowser montre une liste d'exceptions CVE, listmonk un contrôle CVE désactivé |
| [`CHANGELOG.md`](CHANGELOG.md) | Contenu de la version publiée |
| [`LICENSE`](LICENSE) | Licence MIT |

**État** : CLI **0.3.3**, vérifiée contre l'API **2.30.0**.
- `paas-apps api` donne accès à **toutes les opérations** de l'API, sauf les
  flux continus (journaux et terminal en direct).
- Les commandes métier couvrent la session, la lecture des applications, des
  builds et des releases, et le **diagnostic complet d'un échec** : étape,
  cause, détails (failles CVE bloquantes, diagnostics du `paas.xml`, commande
  de test, état du conteneur…), marche à suivre et fin du journal.
- La CLI s'appelle `paas-apps` et s'installe à côté de la CLI `paas`, sans la
  remplacer.

## Installer la CLI

Linux x86_64 ou ARM64, avec la glibc 2.34 ou plus récente (Ubuntu 22.04,
Debian 12, RHEL 9 et suivantes) :

```bash
arch=$(uname -m)                                   # x86_64 ou aarch64
base=https://github.com/OlesVanHermann/paas-cli/raw/main
curl -fsSL -O "$base/paas-apps-linux-$arch" -O "$base/SHA256SUMS"
sha256sum --check --ignore-missing SHA256SUMS
install -D -m 0755 "paas-apps-linux-$arch" ~/.local/bin/paas-apps
paas-apps --version
```

Vérifiez que `~/.local/bin` est dans votre `PATH`. Il n'y a pas encore
d'exécutable pour macOS ni pour Windows.

## Se connecter

```bash
paas-apps login --web     # ouvre la page de connexion du PaaS dans le navigateur
paas-apps whoami          # e-mail, rôle et tenant de la session
```

- Vous vous connectez dans votre navigateur (mot de passe, MFA ou SSO). La CLI
  reçoit la session et l'écrit dans `~/.paas/credentials.json` (droits 0600).
- Un agent IA lancé ensuite sur la même machine utilise cette session sans
  jamais voir de mot de passe.
- Machine distante : fixez le port avec
  `PAAS_LOGIN_CALLBACK_PORT=8765 paas-apps login --web`, puis ouvrez
  `ssh -L 8765:localhost:8765 <serveur>` depuis votre poste.

Sans navigateur, `paas-apps login --email vous@exemple.fr` demande le mot de
passe sans l'afficher. Ne le confiez jamais à un agent IA ni à une
conversation.

En intégration continue, passez le mot de passe par une variable, jamais en
argument, ou fournissez un jeton dans `PAAS_TOKEN` :

```bash
printf '%s' "$PAAS_PASSWORD" | paas-apps login --email "$PAAS_EMAIL" --password-stdin
```

## Utiliser la CLI

```bash
paas-apps apps list
paas-apps --app mon-app builds list --limit 5

# Toutes les opérations de l'API
paas-apps api list --tag addons
paas-apps api show create_addon_generic
paas-apps --app mon-app api call list_app_addons
paas-apps api call create_addon_generic mon-app -d '{"type":"postgres","plan":"standard"}' --yes
```

Toute écriture demande confirmation, sauf avec `--yes`. La référence complète
est dans [CLI.md](CLI.md).

## Comprendre un échec

Un build ou un déploiement qui échoue porte son **erreur complète** (objet
`paas.error.v1` de l'API) : l'étape, la cause en une phrase, les détails
propres au cas, la marche à suivre (commande, extrait de `paas.xml` prêt à
coller, documentation) et la fin du journal.

```bash
paas-apps --app mon-app releases list            # colonne FAILURE : le code de chaque échec
paas-apps --app mon-app releases info <release>  # l'erreur complète et la marche à suivre
paas-apps apps info mon-app                      # pourquoi l'app ne sert rien de neuf
paas-apps --app mon-app builds info <build>      # l'échec d'un build
paas-apps --app mon-app builds cve <build>       # le rapport CVE : ce qui bloque, ce qui est accepté
paas-apps --app mon-app builds test <build>      # les tests : commande, code de sortie, journal
```

Les codes et le contenu de l'objet sont décrits dans
[API.md](API.md#échec-dun-build-ou-dun-déploiement--paaserrorv1).

## Déployer une application

1. Créez l'application ; son dépôt Git est créé avec elle. Votre tenant est
   affiché par `paas-apps whoami`.
   ```bash
   paas-apps api call create_app -d '{"name":"mon-app","tenant_id":"<tenant>"}' --yes
   ```
2. Demandez un accès Git temporaire, valable de 5 à 60 minutes. La réponse
   donne `remote`, `username` et `secret` :
   ```bash
   paas-apps api call mint_git_credential mon-app -d '{"ttl_seconds":3600}' --yes
   ```
3. Poussez votre code. Git demande l'identifiant (`username`), puis le mot de
   passe (`secret`). Le dépôt d'une app neuve contient déjà un premier commit
   (un `README.md`) : posez votre arbre au-dessus de lui, sinon le push est
   refusé. Le push lance le build, puis le déploiement.
   ```bash
   git fetch <remote> main
   git push <remote> "$(git commit-tree 'HEAD^{tree}' -p FETCH_HEAD -m 'Mon app')":refs/heads/main
   ```
   Pour garder votre historique, fusionnez plutôt ce premier commit
   (`git merge --allow-unrelated-histories FETCH_HEAD`), puis
   `git push <remote> HEAD:main`.

**Le plus simple pour un logiciel connu : partir d'un exemple.** Le dossier
[`exemples/`](exemples/README.md) contient dix logiciels (WordPress, Drupal,
DokuWiki, BookStack, Kanboard, FreshRSS, Piwigo, OpenCart, FileBrowser,
listmonk), chacun avec son `paas.xml`. Une commande les installe, avec la CLI
`paas` 2.30 ou plus récente :
```bash
cd exemples && ./push.sh wordpress mon-blog
./clean.up mon-blog      # la retire (réversible)
```

L'application se construit à partir d'un `Dockerfile` à la racine. À défaut,
la plateforme détecte le langage (`package.json`, `requirements.txt`,
`go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`…). Elle doit
écouter sur `0.0.0.0:$PORT`.

## Installer les skills (Claude Code)

Claude Code lit chaque skill dans un dossier à son nom, sous le nom
`SKILL.md`. La skill `paas-api` lit aussi `API-REFERENCE.md`, placé à côté :

```bash
mkdir -p ~/.claude/skills/paas-cli ~/.claude/skills/paas-api
cp SKILL-paas-cli.md ~/.claude/skills/paas-cli/SKILL.md
cp SKILL-paas-api.md ~/.claude/skills/paas-api/SKILL.md
cp API-REFERENCE.md ~/.claude/skills/paas-api/
```

Pour un seul projet, remplacez `~/.claude/skills` par
`<projet>/.claude/skills`. L'agent charge une skill quand la tâche correspond
à sa `description` :
- `paas-cli` pour utiliser la CLI ;
- `paas-api` pour appeler l'API en HTTP (curl).

## Sécurité

- Connexion dans le navigateur (`--web`) : aucun mot de passe dans le terminal. Le mot de passe et les
  jetons ne passent **jamais** en argument de commande (saisie masquée ou `--password-stdin`).
- Le fichier de session `~/.paas/credentials.json` est écrit en 0600, de façon
  atomique. Il ne doit jamais être versionné.
- Les erreurs complètes de la plateforme (`paas.error.v1`) s'affichent
  entières : elles ne citent jamais la valeur d'un secret. Une ligne qui porte
  un marqueur d'identifiant (jeton, clé privée…) est tout de même masquée. Les
  autres messages du serveur qui ressemblent à un secret sont masqués.
- Une écriture n'est jamais rejouée automatiquement, sauf si le serveur honore
  la clé `Idempotency-Key` fournie.
- `paas-apps logout` révoque aussi les accès Git actifs du compte, sur toutes
  ses sessions.

## Licence

MIT : voir [LICENSE](LICENSE).
