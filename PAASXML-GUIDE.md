# Guide : écrire, vérifier et pousser un paas.xml

État au 2026-10-18, plateforme v2.48.1, CLI 2.48.1. Chaque commande et chaque code d'erreur cités ici ont été
mesurés.

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
  Pendant l'attente, le déploiement est `pending` (v2.48.1).
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
- Les mots de passe des comptes passent par l'entrée standard des commandes natives, jamais en argument.

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

4. L'app répond sur `apps-<8hex>.<domaine des apps>`. Le nom court `<8hex>.<domaine des apps>` y redirige,
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
| `ENV_COMPONENTS_REQUIRE_SEPARATE_QUALIFICATION` | `http_endpoints` hors de la recette npm stable, ou sur un autre port que celui du process web | Viser le port du process web, ou retirer la clé |
| `N0_RESOURCES_LARGER_THAN_NODES` | Un pod demande plus que n'alloue le plus grand nœud (push, `paas builds rebuild`, déploiement forcé) | Réduire `resources` : le message donne ce qu'alloue ce nœud et une demande qui tient |
| `N0_CLUSTER_CAPACITY` | Aucun nœud n'a la marge demandée en ce moment | Pousser la demande réduite que donne le message, ou attendre ; `[Paas]` |
| `ENV_STORAGE_RESERVED_VOLUME_CHANGED` | Volume réservé redéclaré autrement (point de montage, taille, classe, accès) ; refusé au gel du plan, au push | Garder la déclaration de la réservation, nommée par le message |
| `ENV_PNPM_LOCK_OVERRIDES_MISMATCH` | `overrides` du verrou pnpm autres que ceux que lit le pnpm épinglé (`pnpm-workspace.yaml` seul, ni `resolutions` ni le champ `pnpm` de package.json) | Le message donne les deux listes ; le verrou amont tel quel ne s'installe pas avec ce pnpm |
| `ENV_AUTO_NPM_OFFICIAL_REGISTRY_ONLY: node_modules/<paquet> : résolu hors du registre officiel (https://<hôte>)` (v2.43.1) | Le verrou npm résout une dépendance sur un autre hôte que registry.npmjs.org | Déclarer l'archive dans `build.node.remote_archives` : l'adresse exacte du verrou (`resolved`) et sa SHA-256 ; une archive du dépôt (`file:`) se déclare dans `build.node.embedded_archives` |
| `ENV_AUTO_ACQUISITION_SIZE_OR_TIME_LIMIT:blob=…` (préparation npm) | Une archive du verrou dépasse 64 Mio, ou l'ensemble 512 Mio | Déclarer `build.node.archive_profile` `large-browser-assets-v1` (256 Mio par archive, 1 Gio au total) |
| `ENV_SOURCE_DOCKERFILE_UNDECLARED` (v2.43.1) | Le dépôt amont garde un Dockerfile que le paas.xml ne déclare pas | Déclarer sa SHA-256 dans `build.source_dockerfile` : il reste dans l'arbre, la recette publiée construit |
| `ENV_STATIC_HEADER_UNSUPPORTED` sur X-Frame-Options, Referrer-Policy ou Permissions-Policy (v2.43.1) | La bordure de la plateforme impose ces en-têtes à toutes les apps | Les retirer de `web.headers` : la valeur servie est celle que le message indique |
| `ENV_GO_TOOLCHAIN_CONFLICT: "vendor" : un vendor/ livré dans le module se déclare` (v2.44.0) | Le module livre son vendor/ | Déclarer `build.go.vendor` : `verify` (il est comparé à l'acquisition vérifiée) ou `rebuild` (elle le reconstitue) |
| `ENV_GO_VENDOR_MISMATCH: "vendor/<fichier>" : module <m> <v> : …` (préparation, v2.44.0) | `verify` : le vendor/ livré diffère de ce que go.mod et go.sum donnent | Déclarer `rebuild`, ou livrer un vendor/ à jour (`go mod vendor`) |
| `ENV_GO_PARAMETERS_INVALID: Go 1.27, <combinaison> : aucune variante publiée ; variantes proches : …` (v2.44.0) | Aucune recette Go ne réunit ce frontend, git et cgo | Choisir l'une des variantes nommées |
| `ENV_GO_STEP_UNRESOLVED: build.steps[<i>] ("<nom>") : <commande> : <règle>` (v2.44.0) | L'étape n'est ni un générateur à la version de go.mod, ni un paquet du module, ni un outil de go.mod, ni cp ou mkdir | Écrire la commande sous l'une de ces formes (`go run <module>/<paquet>@<version de go.mod>`, `go run ./<paquet>`, `go tool <nom>`) |
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
