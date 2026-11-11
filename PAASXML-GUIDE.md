# Guide : écrire, vérifier et pousser un paas.xml

État au 2026-11-11, plateforme v2.81.54, CLI 2.81.54. Chaque commande et chaque code d'erreur cités ici ont été
mesurés, à la version qu'ils nomment.

## 1. Partir d'un exemple ou d'un squelette

- **Une app de la bibliothèque** : copier son répertoire (`exemples/<app>/paas.xml` et son `README.md`), lire le
  README, puis suivre ses étapes. Chaque exemple est planifié sans erreur sur l'arbre amont qu'il indique.
- **Une autre app** : partir d'un squelette vérifié, `squelettes/node.paas.xml` ou `squelettes/php.paas.xml`,
  puis ajouter les options de [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md), dans la colonne de sa recette. Le squelette Node attend `index.js`,
  `package.json` et `package-lock.json` ; le squelette PHP attend `public/index.php`.

Un `paas.xml` ne remplace pas le logiciel : il s'ajoute à son arbre amont, inchangé. Ce qui manque à la
plateforme pour une app devient une option générique de la plateforme, que le `paas.xml` déclare. On ne
modifie pas le code de l'app pour l'adapter.

## 2. Écrire le fichier

- Un seul fichier de configuration par dépôt : `paas.xml` ou `paas.toml`, pas les deux
  (`V2_CONFIGURATION_AMBIGUOUS`).
- Obligatoire : `paas_spec_version` (`v2.46.2` ; toute version publiée de v2.1.0 à v2.46.2 est acceptée ; la section `security` demande une plateforme v2.28.0 ou plus, quelle que soit la version déclarée), `app`,
  `build.recipe`, `build.catalogue`, `build.runtime`, `build.test.command`, un processus `web` avec son port
  (≥ 1024) et `healthcheck`.
- Une section est un élément ; une liste contient des `<item>` ; une table prend le nom choisi comme
  élément (`<env><NOM>valeur</NOM></env>`) ou `<entry key="…">` quand ce nom n'est pas un nom XML.
- Les nombres et booléens suivent le schéma ; `type="integer"`, `type="number"` ou `type="boolean"` choisit un
  type quand l'option en accepte plusieurs. CDATA et entités XML pour les gabarits qui contiennent `<` ou `&`.
- Interdits : noms ou attributs inconnus, doublons, espaces de noms, DTD, instructions de traitement, `--`
  dans un commentaire. Limites : 262 144 octets, profondeur 64, 16 384 nœuds.
- Gabarits : `{{secrets.NOM}}`, `{{services.<nom>.url}}` (et `host`, `port`, `user`, `database`,
  `password`…), `{{app.public_url}}`, `{{app.version}}`… Voir `env` et `files` dans [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md).

## 3. Secrets et variables

| Besoin | Déclaration |
|---|---|
| Valeur aléatoire | `<NOM><generate>hex</generate><bytes>32</bytes></NOM>` (ou `base64`) |
| Valeur choisie | `paas secrets seal --name NOM --value-file <fichier hors du dépôt>`, puis `<NOM><sealed>…</sealed></NOM>` |
| Variable ordinaire | `<env><NOM>valeur</NOM></env>` |
| Valeur que vous fournissez après le push (v2.48.0) | `<NOM><provide>tenant</provide></NOM>` ; puis `paas secrets provided --app <app>` et `paas secrets provide NOM --app <app> --value-file <fichier hors du dépôt>` (ou l'entrée standard) |

- **Valeurs fournies** : la release, construite, testée, scannée et signée, attend chaque valeur manquante
  (`awaiting_secrets`, erreur `secrets_not_provided` qui les nomme) et repart seule, sans nouveau push, quand la
  dernière est fournie ; la valeur passe dans le corps de la requête, jamais en argument ni dans le dépôt.
  Pendant l'attente, le déploiement est `pending` (v2.48.1). Une valeur fournie quand une release est déjà servie
  l'atteint (v2.81.35) : ses variables et ses fichiers sont rendus de nouveau et ses processus redémarrent ; un cron la
  lit à sa prochaine exécution. La réponse dit où elle est allée (`reached`).
- Nom : `[A-Za-z_][A-Za-z0-9_]*`, 128 caractères au plus, jamais le préfixe `PAAS_` (réservé à la
  plateforme). Un secret est injecté sous son propre nom ; une variable `env` ne peut pas porter ce nom
  (`V2_DUPLICATE_NAME`).
- **Noms sensibles** : un nom de variable qui contient `password`, `passwd`, `pass`, `secret`, `token`,
  `credential`, `apikey`, `privatekey`, `signingkey`, `encryptionkey`, `accesskey`, `salt`, `dsn` ou `auth`
  n'accepte qu'une référence (`{{secrets.…}}`), `true`, `false`, ou un chemin absolu si le nom finit par
  `_FILE`. Quelques noms de configuration sont publics : `authurl`, `authendpoint`, `authmethod`, `authmode`,
  `authtype`, `authrequired`, `authenabled`, `authenticationmethod`, `requireauthentication`,
  `requireauthorization`, `oauthredirecturl`, `oauthissuerurl`, `secretname`, `secretref`, `tokenurl`,
  `tokenendpoint`. La comparaison ignore la casse et les séparateurs. Pour une valeur non secrète sous un nom
  sensible, scellez-la (exemple nightscout : `AUTH_DEFAULT_ROLES=denied`).
- Les mots de passe des comptes passent par l'entrée standard des commandes natives (`stdin_template`), jamais en argument. Seule exception (v2.75.5) : un programme qui ne prend le secret qu'en option (`--password`), servi par paas-entry (Go, Node) : la commande le déclare (`secret_arguments` à `true` sur `lifecycle.install`, `prepare`, `upgrade` ou sur le compte) ; paas-entry rend le secret au lancement, ne le journalise jamais et le masque dans la sortie rapportée.

## 4. Vérifier hors ligne avant de pousser

Depuis la racine du dépôt, une fois `paas.xml` commité :

```
paas environments:catalogue-store > ../catalogue-store.json
paas config plan --catalogue ../catalogue-store.json
```

- Le plan applique la même admission, la même projection et la même validation technique que la
  plateforme. Il porte sur l'arbre du commit HEAD : commitez d'abord. Il ne lit que la liste des fichiers du
  commit, aucune extraction n'est nécessaire.
- Sans `-f`, la CLI prend le seul `paas.xml` ou `paas.toml` du répertoire courant (pas celui de `--repo`).
- Sans `--catalogue`, le plan échoue (`ENV_CATALOGUE_UNAVAILABLE`) : les catalogues sont des données de la
  plateforme, pas du binaire.
- Code de sortie 0 : planifié, avec ses empreintes (`plan_sha256`) ; 1 : refusé, avec les diagnostics ;
  2 : erreur d’usage, de lecture ou de dépôt.
- `paas config validate` ne contrôle que la structure : il accepte par exemple `storage.tmpfs` ou `scaling`,
  que la plateforme refuse encore. Seul `plan` fait foi.
- Le plan donne aussi les budgets de temps de chaque étape du build (v2.38.0) et, pour chaque diagnostic, qui
  doit agir : `[Cust]` (corriger le `paas.xml` ou le dépôt) ou `[Paas]` (la plateforme ne sait pas encore le faire).

## 5. Pousser et suivre

1. `paas git credentials configure <app>` configure un identifiant HTTPS du dépôt de l'app (écriture du
   dépôt seulement). Les clés SSH ne suffisent pas encore dans tous les cas : utilisez HTTPS.
2. `git push` lance la chaîne : clone, préparation hors réseau, build, tests (`build.test`), scan de l'image,
   SBOM, signature, admission, déploiement. Compter quelques minutes : 1 min 53 s pour le build de Nightscout.
3. Suivre :

   | Commande | Pour |
   |---|---|
   | `paas builds list --app <app>` | les builds et leur état |
   | `paas builds logs <build>` | le journal du build |
   | `paas builds test <build>` | la commande de test, son code de sortie et son journal |
   | `paas builds cve <build>` | le rapport de scan ; les CRITICAL ne sont jamais tronquées |
   | `paas builds rebuild --app <app>` (CLI 2.30.0, comme `paas deploy --app <app> --force`) | reconstruire le dernier commit poussé, sans commit vide ; sortie lisible même redirigée, erreur complète et code de sortie non nul en cas d'échec |
   | `paas apps info <app>`, `paas status --app <app>` | l'état de l'app et l'erreur complète de son dernier déploiement |
   | `paas releases list --app <app>` | les releases ; ce qu'attend une release `awaiting_secrets` ou `scaled-zero` (v2.48.0) |
   | `paas ps --app <app>` | les processus et les pods de la release courante, redémarrages compris (v2.48.0) |
   | `paas logs --app <app> --since 30m` | les lignes les plus récentes de la fenêtre, avec leur processus (v2.48.0) |

   **Mise à zéro et push** (comportement depuis v2.48.0, écrit en v2.75.1) : `paas scale web 0 --app <app>` arrête
   l'app, et un push suivant ne la relance pas. Sa release est appliquée à 0 réplique et publiée dormante
   (`scaled-zero` dans `paas releases list`), sans échec. `paas scale web 1 --app <app>` sert alors cette release,
   la dernière appliquée, jamais l'ancienne image. Sans nouveau push, la même commande remet en service la release
   arrêtée. Un refus de `paas scale` affiche son code et son message.

   **Rejouer l'installation sur un état neuf** (v2.75.1) : `paas apps reset-state <app> --confirm <app>` (CLI
   publique : `paas-apps apps reset-state <app> --confirm <app>`) arrête l'app, copie chaque base que la plateforme
   lui réserve dans son propre volume (copie vérifiée, gardée sous `paas-reset-<id>`), met de côté son journal
   d'installation (`<lifecycle.state_directory>/state.json.reset-<id>`), vide chaque base, puis redémarre l'app :
   son installation se rejoue en entier. Les autres fichiers de ses volumes restent, sauf avec `--volumes` (v2.75.2) :
   le contenu de chaque volume est alors mis de côté dans `.paas-reset-<id>`, illisible par l'app, pour un
   installateur qui refuse un second passage à cause d'un fichier qu'il a écrit dans un volume. Sans `--confirm`,
   rien ne se passe. Un échec avant le vidage remet tout en place ; une remise à zéro interrompue pendant le vidage
   garde l'app arrêtée et la même commande la reprend. `--status` montre les remises à zéro de l'app. Services
   vidés : PostgreSQL, MySQL, MariaDB, MongoDB, Redis (copie par l'outil du moteur) ; depuis v2.75.2, LDAP,
   Meilisearch, OpenSearch, RabbitMQ et S3 (leurs données mises de côté dans `/data/paas-reset-<id>`, le service
   repart vide). `paas apps info` dit pourquoi une app dont la remise à zéro s'est interrompue est arrêtée.

4. L'app répond sur `apps-<8hex>.runtime.${PAAS_DOMAIN}`. Le nom court `<8hex>.runtime.${PAAS_DOMAIN}` y redirige,
   tous ses chemins compris (`/login`, `/signup` et `/auth/` partaient vers la console avant v2.38.1).
5. « pending » dans la console : aucune image n'est encore servie. Le build est en cours, ou il a échoué :
   l'erreur complète s'affiche alors sous l'en-tête de l'app (même contenu que `paas apps info`).

## 6. Diagnostics fréquents

| Code ou message | Cause | Que faire |
|---|---|---|
| `V2_PROJECTION_UNSUPPORTED_KEY` | Clé du schéma pas encore raccordée | Retirer la clé ; statut dans [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md) |
| `V2_REQUIRED_MISSING@build.recipe` | Aucune recette nommée | Choisir une recette de [PAASXML-FEATURES.md](PAASXML-FEATURES.md) |
| `V2_VALUE_INVALID` sur un nom | Préfixe `PAAS_` | Renommer |
| `V2_SECRET_VALUE_REFUSED` | Valeur littérale sous un nom sensible, ou secret sans exactement une origine (`generate`, `provide`, `external`, `sealed`) | Sceller la valeur, ou la référencer par `{{secrets.NOM}}` (seule ou avec du texte autour, v2.56.0) |
| `V2_DUPLICATE_NAME` | Même nom en `env` et en `secrets` | Garder le secret, retirer la variable |
| `ENV_CATALOGUE_UNAVAILABLE` | `plan` sans instantané du catalogue | Ajouter `--catalogue` |
| `ENV_TECHNICAL_INIT_SOURCE_REQUIRED` | Script de `lifecycle.init` absent du commit | Commiter le script |
| `ENV_TECHNICAL_INIT_ARGV_INVALID` | `init` ne commence pas par l'interpréteur et un chemin relatif | `<item>node</item><item>scripts/init.js</item>` |
| `ENV_TECHNICAL_FALLBACK_INVALID` | `web.fallback` sans `front_controller` ou hors `static_paths` | Voir `web` dans [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md) |
| `N2_LEGACY_POSTGRES_ADOPTION_SHAPE_UNSUPPORTED` | Base PostgreSQL héritée à plusieurs instances (plans business, enterprise) | Manque publié de la plateforme (la reprise telle quelle n’en couvre qu’une) : l’app garde sa base tant que son `paas.xml` ne déclare pas PostgreSQL |
| `N2_LEGACY_MYSQL_REQUIRES_EXPLICIT_ADOPTION` (et Redis, MongoDB) | Service hérité vivant, créé par `paas addons` | La plateforme ne le reprend pas encore : manque publié, à elle |
| `ENV_TECHNICAL_LIFECYCLE_POLICY` | Cycle de vie PHP sans `lock=true` ni `interrupted` | Les ajouter |
| `ENV_TECHNICAL_ACCOUNT_COMMAND_INVALID` | Compte PHP sans commande native ni `stdin_template` | Voir `account` |
| `ENV_TECHNICAL_SERVICE_OPTION_UNSUPPORTED` | Option de service non raccordée (`backup`, `plan`…), ou service refusé pour ce runtime | Voir [PAASXML-FEATURES.md](PAASXML-FEATURES.md), section 3 |
| `ENV_TECHNICAL_MYSQL_PROFILE_UNSUPPORTED`, `…_PYTHON_SERVICE_UNSUPPORTED`, `…_RUBY_SERVICE_UNSUPPORTED` | Service non disponible pour ce runtime | Idem |
| `ENV_TECHNICAL_POSTGRES_PROFILE_UNSUPPORTED` | Extensions PostgreSQL hors variante publiée | Liste exacte d'une variante |
| `ENV_TECHNICAL_EXTENDED_PHP_REQUIRED` | Services, comptes ou cycle de vie qu'aucune entrée ne lit : recette Python simple, ou compte d'une app Node npm sans service (le code nomme PHP à tort) | Recette `python314-node24-closure-v1` avec `build.python` ; en Node npm, le service déclaré fait lire comptes et cycle de vie au moteur de `paas-entry` |
| `ENV_TECHNICAL_ACCOUNT_CHECK_REQUIRED` | Compte PHP sans contrôle qui le lit | Un `lifecycle.checks` de phase `ready` dont les paramètres portent `{{account.email}}` |
| `ENV_TECHNICAL_NODE_OPTIONS_UNSUPPORTED` | Option que l'app Node servie par `paas-entry` (pnpm, ou npm avec un service) ne prend pas encore en charge ; le détail les nomme | La retirer ; `[Paas]` |
| `ENV_COMPONENTS_REQUIRE_SEPARATE_QUALIFICATION` | `sidecars` déclarés, ou `http_endpoints` d'une app sans processus web (jusqu'en v2.78.3 : hors de la recette npm, ou sur un autre port que celui du web) | Retirer la clé ; depuis v2.78.4 une origine nommée vise tout port du conteneur web, 1024 ou plus |
| `N0_GPU_UNAVAILABLE` (v2.79.1) | Aucun nœud du cluster ne donne les GPU de `resources.gpu` (la plateforme n'a pas encore de GPU) | Attendre le nœud de cette classe et redéployer, ou servir l'app sans GPU (retirer `resources.gpu` et `pytorch-cuda`) ; `[Paas]` |
| `ENV_ASSET_DEST_IN_TREE` (v2.79.2) | Un fichier déclaré (`assets[].dest`) tomberait sur un chemin de l'arbre, ou sous lui | Choisir une destination que l'arbre n'a pas |
| `ENV_ASSET_DEST_INVALID` (v2.79.2) | Destination hors de l'arbre, sous `.venv`, `.git` ou `.paas`, déclarée deux fois, ou répertoire d'un autre fichier | Un chemin relatif propre à chaque fichier |
| `COMPONENT_BUILD_FAILED` (v2.79.3) | Le build de l'image propre d'un processus (`processes[].build`) a échoué : la release attend toutes les images du push | Lire le build nommé (`paas builds logs`), corriger, pousser |
| `COMPONENTS_SOURCE_REQUIRED` (v2.79.3) | Une requête sans le dépôt de l'app ne construit pas les images des processus | Pousser, ou reconstruire la branche |
| `admission_component_unknown` (v2.79.3) | Le commit ne fait plus tourner ce processus dans son image propre | Pousser la configuration qui la déclare, ou retirer l'image |
| `N0_RESOURCES_LARGER_THAN_NODES` | Un pod demande plus que n'alloue le plus grand nœud (push, `paas builds rebuild`, déploiement forcé) | Réduire `resources` : le message donne ce qu'alloue ce nœud et une demande qui tient |
| `N0_CLUSTER_CAPACITY` | Aucun nœud n'a la marge demandée en ce moment | Pousser la demande réduite que donne le message, ou attendre ; `[Paas]` |
| `ENV_STORAGE_RESERVED_VOLUME_CHANGED` | Volume réservé redéclaré autrement (point de montage, taille, classe, accès) ; refusé au gel du plan, au push | Garder la déclaration de la réservation, nommée par le message |
| `ENV_PNPM_LOCK_OVERRIDES_MISMATCH` | `overrides` du verrou pnpm autres que ceux que lit le pnpm épinglé (`pnpm-workspace.yaml` seul, ni `resolutions` ni le champ `pnpm` de package.json) | Le message donne les deux listes ; le verrou amont tel quel ne s'installe pas avec ce pnpm |
| `ENV_AUTO_NPM_OFFICIAL_REGISTRY_ONLY: node_modules/<paquet> : résolu hors du registre officiel (https://<hôte>)` (v2.43.1) | Le verrou npm résout une dépendance sur un autre hôte que registry.npmjs.org | Déclarer l'archive dans `build.node.remote_archives` : l'adresse exacte du verrou (`resolved`) et sa SHA-256 ; une archive du dépôt (`file:`) se déclare dans `build.node.embedded_archives` |
| `ENV_AUTO_ACQUISITION_SIZE_OR_TIME_LIMIT:blob=…` (préparation npm) | Une archive du verrou dépasse 64 Mio, ou l'ensemble 512 Mio | Déclarer `build.node.archive_profile` `large-browser-assets-v1` (256 Mio par archive, 1 Gio au total) |
| `ENV_PYTHON_ACQUISITION_SIZE_LIMIT: torch-<version>-…-manylinux_…_x86_64.whl` (préparation Python) | La liste (uv.lock, poetry.lock) prend torch sur PyPI : sa construction CUDA dépasse 512 Mio, avec ses dépendances `nvidia-*`, `cuda-*` et `triton` au-delà de 2 Gio | Déclarer `build.python.wheel_profile` `pytorch-cpu` (v2.75.3) : torch, torchvision et torchaudio sont pris construits pour le processeur sur l'index officiel de PyTorch, à la version de la liste, sans leurs dépendances CUDA ; la liste reste celle de l'arbre |
| `ENV_SOURCE_DOCKERFILE_UNDECLARED` (v2.43.1) | Le dépôt amont garde un Dockerfile que le paas.xml ne déclare pas | Déclarer sa SHA-256 dans `build.source_dockerfile` : il reste dans l'arbre, la recette publiée construit |
| `ENV_STATIC_HEADER_UNSUPPORTED` sur X-Frame-Options, Referrer-Policy ou Permissions-Policy (v2.43.1) | La bordure de la plateforme impose ces en-têtes à toutes les apps | Les retirer de `web.headers` : la valeur servie est celle que le message indique |
| `ENV_GO_TOOLCHAIN_CONFLICT: "vendor" : un vendor/ livré dans le module se déclare` (v2.44.0) | Le module livre son vendor/ | Déclarer `build.go.vendor` : `verify` (il est comparé à l'acquisition vérifiée) ou `rebuild` (elle le reconstitue) |
| `ENV_GO_VENDOR_MISMATCH: "vendor/<fichier>" : module <m> <v> : …` (préparation, v2.44.0) | `verify` : le vendor/ livré diffère de ce que go.mod et go.sum donnent | Déclarer `rebuild`, ou livrer un vendor/ à jour (`go mod vendor`) |
| `ENV_GO_PARAMETERS_INVALID: Go 1.27, <combinaison> : aucune variante publiée ; variantes proches : …` (v2.44.0) | Aucune recette Go ne réunit ce frontend, git et cgo | Choisir l'une des variantes nommées |
| `ENV_GO_STEP_UNRESOLVED: build.steps[<i>] ("<nom>") : <commande> : <règle>` (v2.44.0) | L'étape n'est ni un générateur à la version de go.mod, ni un paquet du module, ni un outil de go.mod, ni cp ou mkdir | Écrire la commande sous l'une de ces formes (`go run <module>/<paquet>@<version de go.mod>`, `go run ./<paquet>`, `go tool <nom>`) |
| `ENV_GO_STEP_UNRESOLVED` sur `nx`, `pnpm`, `npm` ou `node` (v2.75.4) | Une commande Node déclarée en étape Go | La déclarer dans `build.node.build_exec` : ses sorties (`build.node.outputs`) sont copiées dans l'arbre avant les étapes Go |
| Un outil de génération lancé par son nom (`protoc-gen-go`, `buf`, `statik`) (v2.75.4) | L'outil n'est pas installé | Une étape `go install <module>/<paquet>@<version exacte>` l'installe (à la version de go.mod si go.mod le requiert) ; les étapes suivantes le lancent par son nom |
| `buf generate` avec un `buf.lock` qui nomme des modules du registre Buf (v2.75.7) | La préparation les acquiert au commit du verrou, vérifie leur condensé B5 et les sert à buf comme répertoires de l'espace de travail de la copie du build | Rien à déclarer ; l'arbre reste inchangé |
| `ENV_GO_BUF_REGISTRY_REMOTE_UNSUPPORTED` ou `ENV_GO_BUF_LOCK_DIGEST_UNSUPPORTED` (v2.75.7) | Un module d'un autre registre que buf.build, ou un verrou v1 à condensé B4 (`shake256:`) | Manque de la plateforme ; `[Paas]` |
| `ENV_NODE_PRISMA_OPENSSL_1_1` (v2.75.7) | Un paquet Prisma d'avant 3.13 attend OpenSSL 1.1, qu'aucune image servie ne porte | Monter Prisma à 3.13 ou plus ; `[Cust]` |
| `ENV_RUST_GIT_SOURCE_UNPINNED` (v2.75.7) | Une source Git du `Cargo.lock` sans commit | Épingler la dépendance à un commit (`rev`) et régénérer le verrou ; `[Cust]` |
| Plusieurs services TLS, une seule autorité lue (`services.single_authority`, v2.75.7) | L'app ne lit que l'autorité d'un service | Donner `{{services.ca_bundle}}` (toutes les autorités) à la variable que lit l'app, par exemple `NODE_EXTRA_CA_CERTS` |
| `V2_VALUE_INVALID build.steps[<i>].argv : lit <fichier>, que la plateforme rend au build` (v2.75.7) | Une étape lit un fichier des `files` rendus au build, écrits après les étapes | Rendre le fichier au démarrage (`render` start), ou passer ses réglages en arguments |
| `ENV_JAVA_PLUGIN_UNACQUIRED` (v2.75.7) | Un greffon de build que déclare un POM manque à la liste Maven produite (liste d'avant v2.75.7) | Demander la liste de nouveau (`paas dependencies produce`) ; `[Paas]` |
| `ENV_NPM_COMPOSER_FOLDER_DEPENDENCY` (v2.75.7) | Le `package.json` d'un frontal PHP dépend d'un dossier que Composer installe (`file:vendor/…`), et le frontal se construit avant Composer | Déclarer `build.frontend.after_composer` : la liste npm se produit alors depuis le verrou Composer ; `[Cust]` |
| `ENV_NPM_COMPOSER_FOLDER_UNINSTALLED` (v2.75.7) | Ce dossier appartient à un paquet que la build n'installe pas (absent de `composer.lock`, ou paquet de développement) | Corriger `composer.lock` ; `[Cust]` |
| `ENV_DEPENDENCY_LIST_TO_PRODUCE` sur `pnpm-lock.yaml` au format 5.4 ou 6.0 (v2.75.7) | Un verrou écrit par pnpm 7 ou 8, qu'aucun pnpm publié ne lit | Rien à faire : la plateforme le convertit par pnpm lui-même, chaque paquet gardé à sa version, et le lit à la place du verrou de l'arbre |
| Un outil Python de PyPI lancé par une app d'un autre langage (Woob, yt-dlp, v2.75.7) | `runtime.packages` sert la distribution, pas PyPI | Déclarer `runtime.python_packages` (chaque distribution de la fermeture, `nom==version --hash=sha256:…`) avec `python3` dans `runtime.packages` : installés dans `/opt/paas-python`, sur le PATH |
| `ENV_GO_CGO_HEADER_MISSING` ou `ENV_GO_LIBRARY_UNPUBLISHED` (v2.76.9) | Un paquet cgo inclut l'en-tête d'une bibliothèque C que la recette ne sert qu'à la demande | Déclarer `build.go.cgo` et `build.go.libraries` (`libolm`, `libtensorflow`, `onnxruntime`, `libvips`… : les noms que la recette publie, refusés au plan avec la liste sinon). Les bibliothèques hors de la distribution signée viennent de leur archive épinglée et sont déclarées dans le SBOM de l'image ; `[Paas]` tant que la recette ne la publie pas |
| `ENV_NATIVE_LIBRARY_UNPUBLISHED` sur `poco` (v2.76.9) | POCO n'est dans aucun index signé | `build.native.libraries` le nomme comme une bibliothèque signée quand la liste C le publie (statique, construite par la plateforme avec les options de Collabora Online) |
| `ENV_NODE_PRISMA_OPENSSL_1_1` (v2.76.9) | Prisma avant 3.13.0 ne publie ses moteurs que pour OpenSSL 1.1 | Monter Prisma à 3.13.0 ou plus ; sinon déclarer `build.node.runtime_libraries = ["openssl-1.1"]` (OpenSSL 1.1.1w, sans support public depuis le 2023-09-11), les moteurs `debian-openssl-1.1.x` de la version dans `build.resources` et `@prisma/engines` dans `build.node.install_scripts` ; `[Cust]` |
| `PLAN_CAPABILITY_NOT_GRANTED: runtime.security.capabilities_add : <NOM>` (v2.76.9) | Le paas.xml ajoute à ses conteneurs une capacité Linux (`NET_ADMIN`, `SYS_TIME`…) que l'opérateur n'a pas accordée à cette app : le fichier seul n'accorde rien | Demander l'accord à l'opérateur, une capacité à la fois, avec sa raison ; accordée, les conteneurs de l'app la portent à la release suivante ; retirée, le plan suivant est refusé. Les noms sont ceux de capabilities(7), sans le préfixe `CAP_` ; toute autre clé de `runtime.security` reste refusée ; `[Cust]` |
| `ENV_RUNTIME_PYTHON_WHEEL_UNSERVED` (v2.75.7) | Aucune empreinte déclarée n'est celle d'une roue qui s'installe sur l'image (sa version de Python, glibc ou musl, x86_64) | Déclarer l'empreinte de la roue de cette plateforme ; `[Cust]` |
| `ENV_NODE_TS_PATHS_UNRESOLVED` (v2.75.4) | `node <module>.ts` alors que le `tsconfig.json` du projet déclare des alias `paths`, que Node ne lit pas | Lancer la sortie compilée, ou un tsx livré dans `node_modules` |
| Une faille npm dont la version corrigée est publiée (v2.76.10) | Le verrou de l'arbre tient une version vulnérable d'un paquet | Déclarer `build.node.dependency_updates` (`<item>proxy-addr@2.0.8</item>`, 64 au plus) : la plateforme révise le verrou depuis le registre officiel (liste produite, `paas/dependencies/`), les builds l'installent à sa place ; le refus d'un scan propose l'élément exact |
| Une faille pnpm, Yarn ou Bun dont la version corrigée est publiée (v2.77.0) | Le `pnpm-lock.yaml`, le `yarn.lock` (classique ou berry) ou le `bun.lock` de l'arbre tient une version vulnérable | Déclarer `build.node.dependency_updates` (pnpm, Yarn) ou `build.bun.dependency_updates` (Bun), même forme : le gestionnaire de la recette monte chaque instance à la version la plus récente que ses dépendants acceptent, au moins la version déclarée (`pnpm update`, `yarn up -R`, Bun sur les entrées mises de côté) ; la plateforme vérifie que rien d'autre ne change, l'arbre reste tel quel |
| Une faille d'un paquet Composer dont la version corrigée est publiée (v2.77.0) | Le `composer.lock` de l'arbre tient une version vulnérable | Déclarer `build.php.composer_updates` (`<item>guzzlehttp/guzzle@7.9.3</item>`, 64 au plus) : Composer révise le verrou (`update <paquets> --with <paquet>:<version>`, rien d'autre ne bouge), la build l'installe à sa place ; une exigence qui retient le paquet est nommée (`ENV_COMPOSER_DEPENDENCY_UPDATE_RANGE`) : déclarer aussi la montée de ce qui le demande ; pas avec un correctif publié ni un vendor commité |
| Une faille d'un paquet Python dont la version corrigée est publiée (v2.77.0) | La liste exacte de l'arbre (`poetry.lock`, `uv.lock`, `Pipfile.lock`, `requirements.txt` à versions exactes) tient une version vulnérable | Déclarer `build.python.dependency_updates` (`<item>requests@2.32.4</item>`, 64 au plus) : pip résout la liste de l'arbre, chaque paquet à sa version mais ceux-ci montés, pour l'interpréteur de la recette (liste produite avec ses empreintes), la build l'installe à sa place ; un conflit que pip nomme est à lever en déclarant aussi la montée de ce qui le cause ; pas avec `build.python.additional_packages` |
| Une app Lua (v2.77.1) | Ni rockspec ni verrou, des rocks listés dans un `DEPENDS` ou un Dockerfile | `build.runtime` lua, recette `lua-5.4.9-v1` ou `lua-5.3.6-v1`, `build.lua.rocks` ; la plateforme produit `paas/dependencies/luarocks.lock.json` au premier plan ; `./configure` et `make` en `build.steps` ; le processus lance `lua` et ses mots |
| Le web d'une app Flutter (v2.77.1) | Un `pubspec.lock`, `flutter build web` | `build.runtime` dart, recette `dart-flutter-3.47.9-v1`, `build.dart.root` (le projet), `build.static.publish_root` `<root>/build/web` ; le serveur HTTP de la plateforme sert le site, le processus web ne déclare que son port |
| La préparation web d'un amont télécharge une archive ou clone un dépôt (v2.77.1) | Un `prepare-web.sh` qui `curl` un zip publié ou `git clone` un dépôt | `build.dart.archives` (URL https, SHA-256, `dest`, `root`) et `build.dart.sources` (dépôt https, commit, `dest`), acquis par la préparation dans la copie de build ; ses commandes deviennent des `build.steps` (`flutter`, `dart`, `cp`, `mv`, `mkdir`, `touch`, `sed -i`) |
| Une app Erlang/OTP (v2.77.2) | Un `rebar.lock`, ou une archive source qui porte ses dépendances (CouchDB : `src/`, `bin/rebar3`) | `build.runtime` erlang, recette `erlang-otp-28.5.0.8-v1`, `build.erlang.root` au besoin ; `build.steps` (`rebar3 as prod release`, ou `./configure` et `make release`) ; avec un `rebar.lock`, chaque paquet hex (vérifié par sa somme externe) et chaque dépendance Git placés sous `_checkouts/` ; le processus lance `erl` ou le programme de la release (`./rel/couchdb/bin/couchdb`) |
| Une app Crystal (v2.77.2) | Un `shard.yml` et un `shard.lock` | `build.runtime` crystal, recette `crystal-1.22.2-v1` ; un verrou qui nomme des tags est épinglé par commits (`paas/dependencies/shard.lock`) au premier plan ; les shards placés dans `lib/` comme `shards install` les laisse ; `crystal build … -o app` en `build.steps` ; les fichiers qu'un build télécharge en `build.crystal.archives` ; le processus lance `./app` |
| Une app Haskell (v2.77.3) | Un `cabal.project` (et ses `source-repository-package` par commit), sans `stack.yaml` ni gel | `build.runtime` haskell, recette `haskell-ghc-9.6.7-v1`, `build.haskell.targets` (`exe:<nom>`) ; la plateforme gèle le projet (`paas/dependencies/hackage.lock.json`) au premier plan ; le processus lance `./bin/<nom>` |
| Une app Racket (v2.77.3) | Un `info.rkt` qui liste ses paquets sans version | `build.runtime` racket, recette `racket-9.3-v1` ; la plateforme produit `paas/dependencies/racket-pkgs.lock.json` depuis l'`info.rkt` au premier plan ; `raco make <programme>.rkt` en `build.steps` ; le processus lance `racket` et ses mots |
| Un site Go compilé en WebAssembly (v2.77.4) | Un `GOOS=js GOARCH=wasm go build` que lit un frontend npm ou pnpm (un `Makefile` qui copie `wasm_exec.js`) | `build.go.binaries` : `goos` js, `goarch` wasm, `output` (le chemin où le frontend lit le module), `wasm_exec` (où copier `wasm_exec.js`) ; `build.go.frontend` et `build.static.publish_root` ; le processus web ne déclare que son port |
| Le module web Rust d'une app Flutter (v2.77.4) | `flutter_rust_bridge build-web` sur une crate d'un dépôt Git, ses fichiers servis par l'app | `build.dart.rust_web` (`crate` dans une source déclarée, `out_dir`, `name`) avec le catalogue `2026.11.08.dart.2` ; le module se construit sans réseau par la nightly du catalogue, ses crates venant de son `Cargo.lock` |
| Un site construit par emscripten (v2.77.4) | Un `emmake make` ou `emcc` (un émulateur et son cœur libretro) dont le dossier de sortie est servi | `build.runtime` emscripten, recette `emscripten-7.0.0-v1` ; `build.steps` (`emmake`, `emcc`, `make`, `cp`…), `build.emscripten.sources` et `archives` pour ce que le build lirait sur le réseau, `build.static.publish_root` ; le port zlib est servi, un autre port ne l'est pas |
| Une app Objective-C sur GNUstep (v2.77.4) | Un `./configure` et un `GNUmakefile` de gnustep-make (SOGo et son framework SOPE) | `build.runtime` objc, recette `objc-gnustep-1.31.1-v1` ; le framework en `build.objc.archives` (archive de release par son SHA-256) ou `build.objc.sources` ; `./configure`, `make`, `make install` en `build.steps` ; `make install` remplit `/app/.gnustep/Local` ; le processus lance `./.gnustep/Local/Tools/Admin/<outil>` |
| Une app qui envoie du courrier réel (v2.78.1) | Le mode `capture` garde les messages, il n'en remet aucun | `services.<nom>` : `type` smtp, `provider` shared, `mode` relay ; nommer `{{services.<nom>.host}}`, `port`, `user`, `password` et `from` dans `services.<nom>.env` ; l'expéditeur est imposé (`from`, à l'enveloppe et au `From`) ; servi aux apps que paas-entry lance, pas en PHP, Python ni Ruby ; `mail_relay_unavailable` : l'installation n'a pas de relais, `[Paas]` |
| Un serveur de courrier sur le port 25 (v2.78.1) | Le serveur lit l'adresse de son client (SPF) ; ses DNS désignent son adresse | Déclarer le port 25 en `tcp_ports` et demander à l'opérateur une adresse propre (`--dedicated`) : l'app lit alors l'adresse de son client, son processus est placé sur le nœud qui annonce l'adresse ; `paas apps info` donne les enregistrements à poser (A, MX, SPF ; le PTR chez le fournisseur de l'adresse) |
| Une boîte IMAP pour l'app (v2.78.2) | Un webmail, un lecteur de rapports ou une boîte de rebonds lit ou range des messages en IMAP | `services.<nom>` : `type` imap, `version` 2.4.5, `provider` dedicated, `tls` required, `ca_file` ; liés : `url` (`imaps://…:31993`), `host`, `port`, `user` (`app`), `password` ; elle ne reçoit rien d'Internet : une boîte existante chez un fournisseur se lit par son adresse et ses identifiants en `secrets.*` |
| Une base PostgreSQL 17 (v2.79.4) | L'app exige PostgreSQL 17, ou une extension à sa version de 17 | `services.<nom>` : `type` postgresql, `version` 17 (et `extensions` : celles de 16, à leurs versions de 17) ; PostGIS est servi sur 16 seulement ; une base réservée garde sa version : passer de 16 à 17 se fait par une nouvelle base et la migration de ses données |
| Savoir si sa base est sauvegardée (v2.79.4) | Une base d'un plan payant doit pouvoir revenir en arrière | `paas addons info` : `backup.tier` (`none`, `daily`, `pitr`) et la dernière sauvegarde terminée ; le plan `starter` n'est pas sauvegardé |
| Un modèle de langue pour l'app (v2.79.5) | L'app converse, résume ou calcule des embeddings avec un modèle à elle, sans service extérieur | `services.<nom>` : `type` inference, `version` 0.40.15, `provider` dedicated, `tls` required, `storage`, `ca_file`, `model` (le nom d'un asset qui donne l'adresse https et le SHA-256 d'un GGUF), et son relais `local_endpoint` ; l'app prend INFERENCE_URL (l'API OpenAI), INFERENCE_API_KEY et INFERENCE_MODEL |
| Un cache memcached pour l'app (v2.79.4) | Des sessions, des pages ou des résultats gardés dans memcached (un webmail, un CMS, une API) | `services.<nom>` : `type` memcached, `version` 1.6.45, `provider` dedicated, `tls` required, `ca_file`, et son relais `local_endpoint` (`port`) ; l'app joint `127.0.0.1:{{services.<nom>.local_port}}` en clair, sans identifiants : le relais s'authentifie (compte `app`) en TLS ; le protocole texte seulement ; un cache, perdu à un redémarrage |
| Un serveur DNS sur le port 53 (v2.78.2) | `tcp_ports` refusait 53 (au-dessous de 1024, hors de la liste) | Déclarer 53 en `tcp` et en `udp` ; l'opérateur l'approuve, sur une adresse propre (`--dedicated`) si une autre app tient déjà 53 ; un serveur qui ne peut écouter sur 53 dans son conteneur déclare un `target_port` au-dessus de 1024 |
| Deux apps qui servent IMAPS (ou SMTPS, LDAPS, MQTT sur TLS) sur le même port (v2.78.3) | Un port public ne sert qu'une app sur l'adresse partagée | Déclarer `<route>sni</route>` sur le port (TCP, inférieur à 10000) : le routeur TLS mène chaque connexion à l'app qui tient le nom demandé (son hôte `apps-<sous-domaine>.<domaine>`, ses domaines vérifiés) ; l'app garde son certificat |
| Un port qu'Internet doit joindre (v2.78.3) | `paas apps info` dit `(private)` : le port s'ouvre par défaut sur l'adresse privée de l'installation | Demander à l'opérateur l'ouverture publique (`--public`, ou `--dedicated` pour une adresse propre) |
| Une WebSocket servie par un second processus (v2.78.4) | Le processus web ne la sert pas, son port n'est pas publié | Déclarer le processus en worker `mode = in-process` avec son `port`, et `web.front` : `listen`, une route `<path>/ws/</path><upstream>…</upstream><websocket>true</websocket>` |
| Plusieurs ports HTTP d'un même processus (v2.78.4) | Seul le port du web est servi | Par un nom : `http_endpoints` (`target_port`) ; par un chemin : une route de `web.front` avec `port` |
| Un SPA qui appelle `/api` et `/ws` de sa propre origine (v2.78.4, v2.81.34) | Un site publié n'a pas de processus | Depuis v2.81.34, le frontal sert le site construit lui-même : une route `<path>/</path><root>/app/dist</root><fallback>index.html</fallback>` (un dossier de l'image sous `/app`, la page de repli d'une navigation), et des routes qui mènent `/api` et `/ws` au processus de l'API (`upstream`, `websocket`). Avant v2.81.34 : le SPA servi par le processus web |
| Des fichiers que l'app écrit dans un volume, servis tels quels (v2.81.34) | Des médias téléversés, une image de marque, que le processus ne sert pas | Une route de `web.front` dont `root` est un dossier d'un volume déclaré : servi en bac à sable (`Content-Security-Policy: sandbox`), GET et HEAD, sans liste de dossier ni fichier caché |
| `FRONT_FALLBACK_MISSING` (v2.81.34) | La page de repli (`fallback`) d'une route `root` n'est pas dans son dossier au démarrage : le frontal ne démarre pas | Produire la page dans ce dossier (une sortie du build), ou corriger `fallback` |
| `V2_VALUE_INVALID@web.front.routes[…].root` (v2.81.34) | Le dossier n'est ni sous `/app` hors des volumes, ni dans un volume déclaré ; ou la route a aussi un `port` ou `websocket` ; ou le dossier recoupe un fichier rendu au démarrage (`lifecycle.start_files`), le dossier d'état du cycle de vie ou l'autorité d'un service (`ca_file`) | Viser le dossier construit, ou un dossier du volume ; une route sert un dossier ou un processus (`upstream`), pas les deux |
| Arrêter un cron sans supprimer l'app (v2.81.32) | Une app faite de crons ne s'arrêtait qu'en la supprimant | `paas scale <cron> 0 --app <app>` le suspend ; `paas scale <cron> 1` le reprend, et une exécution manquée depuis moins de 10 minutes part aussitôt ; `paas ps` dit son planning et son état |
| Une app Python faite d'un worker ou d'un cron (v2.81.27) | `ENV_PROFILE_UNKNOWN` : la recette Python simple ne servait qu'un processus web | Déclarer le worker ou le cron en premier processus, sans port ; le cron monte les volumes de l'app (v2.81.28) |
| Un outil de courrier qui vise `127.0.0.1:143` (v2.81.30) | Le relais local d'un service n'écoutait qu'au-dessus de 1024 | `services.<nom>.local_endpoint.port` à 143 pour une boîte IMAP ; un autre port sous 1025 reste refusé |
| `ENV_DART_HOOKS_DECLARED`, `ENV_DART_HOOK_DEFINE_INVALID` (v2.81.16) | Un hook de build d'un paquet du verrou télécharge quand une étape lance `dart` (sqlite3) | `build.dart.hook_defines` : `<item><package>sqlite3</package><key>source</key><value>system</value></item>` ; le `pubspec.yaml` racine ne déclare pas en même temps `hooks:` |
| Les macros d'une app Crystal lisent son dépôt Git (v2.81.13) | « not a git repository » au build : le build n'a pas de `.git` | `build.crystal.git_branch` : la branche ; le build reçoit le dépôt du commit seul, retiré de l'image servie |
| `ENV_NODE_STEP_PHP` (v2.81.36) | Une étape lance `php` hors de l'étape Node qu'une recette PHP joue après Composer, avec du code en ligne (`-r`) ou un script hors de l'arbre | `build.frontend.after_composer` et une étape `php [-d NOM=VALEUR]… <script de l'arbre> [arguments]` (`php -d memory_limit=512M bin/console mautic:assets:generate`) |
| `V2_VALUE_INVALID` à `processes` : « un processus de l'image du web dans son propre pod » | L'app déclare un cycle de vie et un worker, cron ou job de l'image du web dans son propre pod : il n'aurait ni les fichiers de démarrage ni les relais du cycle de vie | Lui donner son image propre (`processes[].build`, v2.81.47), ou le faire tourner dans le conteneur du web (`mode` in-process) |
| `V2_VALUE_INVALID` à `security.cve_exceptions[i].id` pour un identifiant du rapport | Avant v2.81.50, seuls CVE et GHSA étaient admis | Depuis v2.81.50 : NSWG-ECO, RUSTSEC, GO, PYSEC et TEMP le sont aussi, tels que le rapport les donne |
| `ENV_JAVA_IVY_SETTINGS_UNSUPPORTED` | L'arbre d'un build Ant porte ses propres réglages d'Ivy (`ivysettings.xml`) : ils nommeraient d'autres dépôts que la liste produite | Pas encore servi (v2.81.45) : un build dont les dépendances sont sur Maven Central s'en passe ; sinon, c'est à la plateforme d'évoluer (`Paas`) |
| `ENV_DEPENDENCY_LIST_STALE` après un changement de `build.jvm.properties` | La liste a été produite pour d'autres options ; les propriétés en font partie, Maven et Ivy les lisent | `paas dependencies produce --app <app>` la refait depuis la tête de la branche ; le build repart ensuite seul |
| `ENV_PHP_EXTENSION_UNAVAILABLE` pour `brotli` | Le `composer.json` exige `ext-brotli` et aucune recette déclarée ne la porte | `build.recipe` à `php-8.4.27-apache-alpine-full-brotli-v15` et `build.catalogue` à `2026.11.10.php.29` (v2.81.44), avec les 33 extensions de la recette, dans l'ordre du catalogue |
| `security_scan_blocked` sur libxslt 1.1.43-r3 (2026-11-10) | Deux failles HIGH dans l'image d'une recette PHP full du catalogue php.27 | `build.catalogue` à `2026.11.10.php.28` (v2.81.42) : la même recette, corrigée |
| `admission_served_observation_mismatch` sur la release d'une app dont un processus a son image propre ; compte initial illisible (409 « initial application credentials are not available ») | Avant v2.81.52, la release ne retrouvait pas les images de ces processus | Depuis v2.81.52 : redéployer (`paas deploy --force`) ; l'app à 0 réplique, la release s'applique à 0 et est promue |
| `admission_runtime_serving_identity_mismatch` sur `paas scale`, un redémarrage ou `paas run` d'une telle app | Avant v2.81.53, le pod du processus à image propre n'était pas reconnu | Depuis v2.81.53 : admis |
| Le client PostgreSQL de l'app ne fait confiance qu'aux autorités publiques (« error performing TLS handshake », « UnknownIssuer ») | Le certificat du service est signé par l'autorité de la plateforme, que ce client ne lit pas (le pool de Lemmy) | Depuis v2.81.51, dans les recettes que sert paas-entry : `services.<nom>.local_endpoint` (`<port>15432</port>`), et l'URL de l'app à `{{services.<nom>.local_url}}`, sans `sslmode` |
| Une app PHP qui joint MariaDB sans ouvrir TLS (v2.81.41) | MariaDB refuse le transport en clair | `services.<nom>.local_endpoint` (`<port>13306</port>`), et l'app vise `127.0.0.1` à ce port (`{{services.<nom>.local_port}}`) |
| Un installateur qui se croit configuré dès que son fichier existe (Mautic) | Un lien de fichier avec `create` crée le fichier vide ; l'installateur exige aussi son dossier inscriptible | Lier le dossier entier au volume (`<create>directory</create>`) : le fichier est absent avant l'installation, l'installateur l'y écrit |
| L'installateur web reste public tant que l'app n'est pas installée | N'importe qui pourrait le terminer | Installer sans navigateur : `account` (mot de passe généré), `lifecycle.start_files` en `absent-only` pour le fichier que lit l'installateur en ligne de commande, `lifecycle.install`, un contrôle `ready` sur le compte (v2.81.43). Le client lit le compte par `paas-apps api call --yes submit_installation_credentials <app_id>` |
| `ENV_TECHNICAL_ACCOUNT_COMMAND_INVALID` (PHP) | Le mot de passe du compte initial n'arrive à l'installateur ni par son entrée standard ni par un fichier de démarrage | `lifecycle.install.stdin_template` avec `{{account.password}}`, ou (v2.81.43) un fichier de `lifecycle.start_files` qui le contient |
| Recevoir le courrier de ses domaines sans adresse propre (v2.78.5) | Le port 25 de l'adresse partagée ne sert qu'une app | Déclarer `<route>mx</route>` sur le port 25 ; vérifier le domaine dans l'app ; poser `<domaine> MX 10 <hôte entrant>` (`paas apps info`) ; l'opérateur ouvre `--public` |
| Servir IMAP ou POP à ses utilisateurs sur l'adresse partagée (v2.78.5) | 143 et 110 ne servent qu'une app | Déclarer `<route>login</route>` ; les identifiants sont `compte@domaine`, un domaine vérifié de l'app ; le serveur accepte un login en clair du réseau du cluster |
| Une faille d'une gem, d'un artefact Maven ou d'un paquet NuGet dont la version corrigée est publiée (v2.77.0) | Le `Gemfile.lock`, le BOM ou une dépendance transitive tient une version vulnérable | Ruby : `build.ruby.dependency_updates` (`<item>rack@3.1.12</item>`) : Bundler révise le verrou (`bundle lock --update <gems> --conservative`) ; Maven : `build.jvm.dependency_updates` (`<item>com.google.guava:guava@33.4.0-jre</item>`) : le POM racine de la copie de build gère l'artefact à cette version, au-dessus d'un BOM importé ; NuGet : `build.dotnet.dependency_updates` (`<item>System.Text.Json@8.0.5</item>`) : un Directory.Build.targets de la copie de build référence le paquet ; l'arbre reste tel quel |
| Une gem que l'app installe sans jamais la lancer porte des failles dans ses exécutables (v2.77.0) | Un proxy que le Gemfile nomme et qu'aucun processus ne démarre | `build.ruby.unused_gem_executables` (`<item>thruster</item>`) : l'image servie garde ses fichiers Ruby (Bundler la trouve), pas ses exécutables ; ne déclarer qu'une gem qu'aucun processus ni script ne lance |
| `ENV_PNPM_DEPENDENCY_UPDATE_RANGE`, `ENV_YARN_DEPENDENCY_UPDATE_RANGE`, `ENV_BUN_DEPENDENCY_UPDATE_RANGE` (v2.77.0) | Le projet, un motif du verrou ou un paquet qui demande le paquet n'accepte pas la version déclarée ; après la révision, une instance reste en dessous | Choisir une version corrigée dans la plage nommée, ou déclarer aussi la montée de ce qui la demande ; un paquet que les `resolutions` de package.json fixent se change par cette résolution (`ENV_YARN_DEPENDENCY_UPDATE_COMBINED`) |
| `ENV_NPM_DEPENDENCY_UPDATE_RANGE: <paquet>@<v> : <dépendant> demande <plage>` (v2.76.10) | Un paquet du verrou n'accepte pas la version déclarée | Choisir une version corrigée dans cette plage, ou déclarer aussi la montée du dépendant ; `ENV_NPM_DEPENDENCY_UPDATE_DEPENDENCY` nomme une dépendance de la nouvelle version à monter aussi |
| `ENV_GO_MODULE_UPDATE_TOOLCHAIN: go <version> : … (<Go de la recette>)` (v2.76.10) | Une mise à jour de `build.go.module_updates` demande un Go plus récent que celui de la recette | Jusqu'au Go de la recette, les directives `go` et `toolchain` de la copie de build montent avec la mise à jour (`golang.org/x/net` v0.62.0 demande `go 1.26.0`) ; au-delà, choisir une version de module plus ancienne ou attendre la recette du Go suivant ; l'arbre du dépôt n'est jamais modifié |
| `ENV_GO_MODULE_UPDATE_LIMIT` (v2.76.10) | Plus de 64 mises à jour déclarées | Garder les modules qui portent une faille ou que la montée exige ; 64 au plus (32 avant v2.76.10) |
| Un `replace M => M vX` du go.mod garde une version vulnérable (v2.76.10) | Le replace fige le module quelle que soit son exigence | Déclarer `M@<version corrigée>` dans `build.go.module_updates` : la mise à jour relève aussi le replace du module vers lui-même, sur la copie de build ; un module nouveau qu'importe une version montée reçoit ses lignes de go.sum, vérifiées par la base de sommes de Go |
| `ENV_GO_MODULE_OVERRIDE_REFUSED: "go.mod" : replace <directive> : …` (v2.44.0) | Un replace vise un répertoire | Remplacer par un module à une version publiée |
| `ENV_COMPOSER_ARCHIVE_TYPE: "<paquet>" : "<entrée>" : lien vers …, hors du paquet` (v2.45.1) | Une archive du verrou contient un lien qui sort de son paquet, ou un fichier spécial ; un lien interne au paquet est admis | Changer de version du paquet, ou signaler l'archive à son auteur |
| `V2_VALUE_INVALID build.node.package_manager_version: Yarn berry (2 et suivants) n'a pas encore de recette publiée` (v2.46.0) | Le paas.xml déclare Yarn 3 ou 4 ; la recette publiée sert Yarn classique 1.22.22 | Côté plateforme (`[Paas]`) : Yarn berry est prévu (FEATURES, section 6) |
| `ENV_TECHNICAL_YARN_VERSION: Yarn 1.22.19 déclaré ; la recette … publie Yarn 1.22.22` (v2.46.0) | Une autre version de Yarn classique que celle de la recette | Déclarer celle de la recette (`build.node.package_manager_version`) |
| `V2_VALUE_INVALID accounts[0].http.steps[0].json: account.* : aucun compte initial déclaré (account)` (v2.46.2) | Une étape d'un compte supplémentaire lit `account.*` sans compte initial | Lire `user.*` dans ses étapes, ou déclarer le compte initial (`account`) |
| `ENV_PHP_EXTENSION_UNKNOWN: build.php.extensions : imagickk` (v2.45.0) | Le nom déclaré n'est pas une extension de PHP 8.4 ni de PECL | Corriger le nom (`imagick`) |
| `ENV_PHP_RECIPE_EXTENSIONS_MISMATCH: build.php.extensions : sqlite3 en plus des extensions de la recette …` (v2.45.0) | Les extensions déclarées sont celles d'une autre recette, ou dans un autre ordre | Déclarer la recette que le détail nomme, avec sa liste dans l'ordre du catalogue |
| `ENV_PHP_EXTENSION_UNDECLARED: composer.lock : ext-sqlite3 (composer.json) ; la recette … les porte` (v2.45.0) | Le verrou Composer exige une extension que l'image de la recette déclarée ne charge pas ; Composer refuserait l'installation au build | Déclarer la recette nommée et ses extensions |
| `ENV_PHP_COMPOSER_REFERENCE: <vendor>/composer/installed.json : <paquet> … aucun fichier livré sous …` (v2.45.0) | Un paquet de l'inventaire n'a pas de commit (une branche) et l'arbre ne livre pas ses fichiers : il faudrait le télécharger sans commit | Livrer le paquet dans l'arbre, ou un verrou qui l'épingle par commit |
| `installation_blocked (N3_REPAIR_V2_SUSPENDED)` après un premier push refusé (v2.44.1) | Le premier push de l'app a été refusé ; la plateforme ne répare pas un paas.xml et garde ce commit bloqué, `paas deploy --force` compris | Corriger, puis pousser un nouveau commit (l'arbre peut être le même) |
| `ENV_STATIC_INDEX_REQUIRED: dist/index.html : le build ne l'a pas produit` (v2.43.0) | Le dossier `build.static.publish_root` d'un build Node n'est pas celui que le build écrit | Lire la sortie du bundler (Vite : `dist`, Angular : `dist/<projet>`) et la déclarer |
| `build_policy.unresolved_plan` (… `unknown_command (script build: command tsx)`, v2.42.0) | Le script de build lance un programme que la plateforme ne sait pas classer : ni outil du système ou du langage, ni exécutable d'une dépendance que le verrou épingle | Déclarer la dépendance qui fournit le programme (dans `package.json` et le verrou), ou lancer le build par un script qui n'appelle que des programmes connus ; le message nomme le script et le programme |
| `ENV_NODE_BASE_PARAMETERS_INVALID` sur le module lancé (v2.41.0) | Le module de `node <module>` n'est ni un fichier du dépôt, ni produit sous une sortie déclarée, ni le binaire d'une dépendance de production ; le détail nomme le module et la raison | Corriger `argv`, ou déclarer `build.node.outputs` ; `[Cust]` |
| `ENV_NODE_LAUNCHER_INVALID` (v2.41.0, au build) | Le binaire lancé n'est pas dans le `bin` du paquet installé, ou un lanceur sans suffixe ne commence pas par un shebang node | Lancer le chemin que nomme le `bin` du paquet ; `[Cust]` |
| `ENV_PNPM_WORKSPACE_SETTING_UNSUPPORTED` (v2.40.3) | Réglage de `pnpm-workspace.yaml` qui peut changer ce qui est téléchargé ou exécuté (autre registre, `useNodeVersion`, `ignoreScripts: false`…) ; le message le nomme | Le retirer ; les réglages inertes (`publicHoistPattern`, `nodeLinker`…) sont admis ; `[Cust]` |
| `ENV_GO_FRONTEND_PNPM_UNAVAILABLE` (v2.40.2) | Le pnpm du frontend d'un build Go manque à l'image de préparation du catalogue nommé (catalogue antérieur à sa publication) | Nommer le catalogue courant que donne le message ; `[Cust]` |
| `ENV_COMPOSER_SOURCE_NOT_SERVED` (v2.38.2) | La forge ne sert plus l'archive d'un paquet du verrou (dépôt bloqué, supprimé, privé, commit absent) ; le message cite la forge | Remplacer le paquet ou sa source dans `composer.json` et `composer.lock` ; `[Cust]` |
| `ENV_COMPOSER_DOWNLOAD_FAILED` | Archive d'un paquet non téléchargée après trois essais pour une réponse passagère | Relancer le build (`paas builds rebuild`) ; `[Paas]` présumé |
| `admission_serving_release_missing` | Mise à l'échelle, redémarrage, `paas run` ou promotion sans release en service ; le message nomme la dernière release, son état et sa raison | Corriger cette cause puis pousser, ou relancer son build si elle était passagère |
| `N0_LEGACY_REPLICA_EXPANSION_REQUIRED` | Plus d'une réplique | `replicas=1` (N0.SCALE prévu) |
| `N0_GPU_FUTURE_NOT_SUPPORTED` | GPU demandé | Aucun GPU disponible |
| `security_scan_blocked` (ancien `admission_security_evidence_invalid`) | Image refusée par le scan : failles CRITICAL ou HIGH non acceptées | Lire chaque faille de l'erreur ; monter le paquet, ou coller l'extrait `security.cve_exceptions` (mode A) ou `security.block_on` (mode B) proposé ; [PAASXML-SECURITE.md](PAASXML-SECURITE.md) |
| `V2_VALUE_INVALID@security.block_on` | `medium` ou `low` | `high`, `critical` ou `none` |
| `V2_DUPLICATE_NAME@security.cve_exceptions[N]` | Deux entrées pour la même faille dans le même paquet | En garder une |
| `rollout_failed` | La release est construite et admise mais ne reste pas prête, ou sa commande de release échoue | Lire `details.reason` et la fin du journal : `oom_killed` → `resources.memory` ; `probe_failed` → `healthcheck` et port d'écoute ; `process_exited` → commande, variables, secrets ; `container_config` → secret manquant ; `not_ready` → sonde de démarrage |
| `admission_build_required`, « source must start with forgejo:// » | Image ou dépôt Git externe | Pousser l'arbre sur le dépôt de l'app |
| `build_policy.base_not_admitted`, `build_policy.vendor_application_image` | Build par le `Dockerfile` du dépôt sur une base qui n'est ni l'outillage ni une image de recette publiée, ou sur une image d'application | Partir d'une base listée par `paas builds bases`, ou écrire un `paas.xml` avec une recette ; le Dockerfile amont reste alors une source inerte |
| `Permission denied (publickey)` | Clé SSH sans effet | Pousser en HTTPS (étape 5.1) |

## 7. Sans paas.xml reconnu

- **Un `Dockerfile` à la racine**, hors des recettes connues (v2.33.0) : le push prend la voie native, sans
  découverte. Le Dockerfile est construit sous la politique de build : chaque `FROM` part de l'outillage ou d'une
  image de recette publiée (`paas builds bases`), sinon `build_policy.base_not_admitted` nomme la base refusée.
  Une commande de test versionnée est exigée (`admission_versioned_tests_missing` dit où la déclarer :
  `[build] test_command` d'un `paas.toml`). Depuis un `paas.xml`, `build.runtime` `dockerfile` fait de même avec les
  tests, le processus web, la sonde, les ressources et la politique CVE du même fichier (v2.34.0).
- **Sinon**, la plateforme lance sa propre découverte. Si elle ne reconnaît pas le logiciel
  (`SOURCE_UNRECOGNIZED`, côté client), la sortie est d'écrire un `paas.xml` avec une recette, en partant d'un
  exemple ou d'un squelette.
