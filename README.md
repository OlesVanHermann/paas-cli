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
| [`API-REFERENCE.md`](API-REFERENCE.md) | **Référence de l'API** : les 437 opérations de l'API client, par domaine, avec leurs paramètres, leurs types et leur appel CLI |
| [`openapi.yaml`](openapi.yaml) | **Contrat de l'API** (OpenAPI 3.0.3), qui fait foi. Il permet aussi de générer un client dans votre langage |
| [`SKILL-paas-cli.md`](SKILL-paas-cli.md) | Skill pour agents IA : utiliser la CLI |
| [`SKILL-paas-api.md`](SKILL-paas-api.md) | Skill pour agents IA : appeler l'API en HTTP (curl) |
| [`PAASXML-REFERENCE.md`](PAASXML-REFERENCE.md) | **Référence du `paas.xml`** : toutes ses sections et toutes ses clés, avec leur statut mesuré recette par recette, et l'index des codes de refus (qui doit agir, règle) |
| [`PAASXML-GUIDE.md`](PAASXML-GUIDE.md) | Guide du `paas.xml` : écrire, vérifier hors ligne et pousser une app, diagnostics fréquents |
| [`PAASXML-FEATURES.md`](PAASXML-FEATURES.md) | Fonctionnalités du `paas.xml` : disponibles, par version, et prévues |
| [`PAASXML-SECURITE.md`](PAASXML-SECURITE.md) | Sécurité : ce que la plateforme impose, ce que le `paas.xml` déclare (failles, secrets, réseau) |
| [`exemples/`](exemples/README.md) | **Treize apps à installer en une commande**, en PHP, Go, Node, Ruby et Python (WordPress, Discourse, ERPNext…) : un `paas.xml` par app ; `push.sh` installe, `clean.up` retire. Les dix fonctionnent ; FileBrowser montre une liste d'exceptions CVE, listmonk un contrôle CVE désactivé |
| [`CHANGELOG.md`](CHANGELOG.md) | Contenu de la version publiée |
| [`LICENSE`](LICENSE) | Licence MIT |

**État** : CLI **2.69.0**, vérifiée contre l'API **2.69.0** : les 437 opérations
du contrat répondent sur le serveur en service. La version de la CLI est celle
de la plateforme qu'elle sert.
- `paas-apps api` donne accès à **toutes les opérations** de l'API, sauf les
  flux continus (journaux et terminal en direct).
- Les commandes métier couvrent la session, la lecture des applications, des
  builds et des releases, les mises à jour de sécurité d'une application
  (`apps security-updates` : une alerte, ou une mise à jour faite par la
  plateforme, quand elle publie une révision corrigée de la base de son
  image), les bases admises d'un Dockerfile avec le dernier rescan de chaque
  image publiée (`builds bases`), et le **diagnostic complet d'un échec** :
  étape, cause, **qui doit agir** (`Cust` : le `paas.xml` ou le dépôt se
  corrige ; `Paas` : la plateforme ne sait pas encore le faire, et nomme ce
  qui lui manque, ou un incident passager, que la reconstruction du même
  commit suffit à passer), détails (failles CVE bloquantes et révision
  corrigée de la base quand elle est publiée, diagnostics du `paas.xml`,
  commande de test, état du conteneur…), marche à suivre et fin du journal.
  `apps list` montre `Cust` ou `Paas` pour chaque application en échec.
- Depuis la 2.48.0 : les processus et les pods de la release courante
  (`ps`), les valeurs que vous fournissez à une application et que sa
  release attend (`secrets provided`, `secrets provide`, jamais en
  argument), l'imputation du verdict et sa reclassification (`now`).
- Depuis la 2.51.0 : les **listes de dépendances que la plateforme produit**
  (`dependencies list`, `show`, `produce`, `accept`, `mode`) pour une
  application dont la liste n'est pas exacte : résolues une fois depuis le
  registre officiel, avec les empreintes, écrites dans son dépôt Git, figées.
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
Les quatre documents `PAASXML-…` décrivent le fichier `paas.xml` qu'une app ajoute à son dépôt. Les commandes
qu'ils citent sont celles de la CLI `paas` de la plateforme (installée par `get.di2amp.com`) ; `paas-apps` lit et
diagnostique les mêmes applications par l'API.

[`exemples/`](exemples/README.md) contient treize logiciels en cinq langages
(WordPress, Drupal, DokuWiki, BookStack, Kanboard, FreshRSS, Piwigo, OpenCart en
PHP ; FileBrowser, listmonk en Go ; Etherpad en Node ; Discourse en Ruby ; ERPNext
en Python), chacun avec son `paas.xml`. Une commande les installe, avec la CLI
`paas` 2.30 ou plus récente :
```bash
cd exemples && ./push.sh wordpress mon-blog
./clean.up mon-blog      # la retire (réversible)
```

**Ce que la plateforme construit.** Elle ne devine pas le langage d'un dépôt :
- le cas général est un `paas.xml` à la racine du dépôt. Il nomme le runtime, la
  recette technique du catalogue (`paas environments:catalogue-store`), les
  processus et la commande de test. `paas config plan` le vérifie en local,
  avant le push ;
- sans `paas.xml` ni `paas.toml`, seuls les logiciels que la plateforme
  reconnaît dans son catalogue s'installent ;
- un `Dockerfile` à la racine est construit tel quel quand le fichier de
  configuration le déclare : `<runtime>dockerfile</runtime>` dans un
  `paas.xml` (plateforme 2.34 ou plus récente), avec la commande de test et
  l'image, épinglée par empreinte, où elle tourne
  (`<test><command>…</command><image>IMAGE@sha256:…</image></test>`), le
  processus `web` et son port. Un `paas.toml` qui déclare `test_command` et
  `test_image` dans `[build]` reste accepté. Le build vérifie trois
  conditions :
  - chaque `FROM` est une image épinglée par empreinte (`@sha256:…`) que la
    plateforme admet : son outillage et les images des recettes publiées du
    catalogue. `paas-apps builds bases` les liste, avec leur rôle (`build`,
    `test`, `run`), leur recette et le dernier rescan de chaque image
    publiée ;
  - le build ne télécharge que ce que le dépôt fixe : les dépendances sont
    dans le dépôt ou, pour Python, installées par
    `pip install --require-hashes --only-binary=:all: -r <verrou>`, chaque
    ligne du verrou en `==` avec l'empreinte de ses fichiers ;
  - l'image produite ne porte aucune faille CRITICAL ni HIGH, hors exceptions
    déclarées.

L'application écoute sur `0.0.0.0:$PORT`.

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
