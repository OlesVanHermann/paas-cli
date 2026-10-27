# Version

La version publiée porte un tag Git `vX.Y.Z`. `paas-apps --version` donne la
version installée.

## v2.62.2 — 2026-10-27

- **CLI `paas-apps` 2.62.2**, vérifiée contre l’API client **2.62.2** (437
  opérations, inchangées).
- **Documentation du `paas.xml`** à jour de la plateforme 2.62.2 (aucune option
  changée).

## v2.62.1 — 2026-10-27

- **CLI `paas-apps` 2.62.1**, vérifiée contre l’API client **2.62.1** (437
  opérations, inchangées).
- **Documentation du `paas.xml`** à jour de la plateforme 2.62.1 (aucune option
  changée).

## v2.62.0 — 2026-10-27

- **CLI `paas-apps` 2.62.0**, vérifiée contre l’API client **2.62.0** (437
  opérations, inchangées).
- Ce que la plateforme 2.62.0 apporte à votre `paas.xml` :
  - en Python (recettes simple et fermée), un service de chaque réservation,
    jusqu’à huit : PostgreSQL ; MySQL ou MariaDB ; Redis ; et, réservés comme
    en Go, Node et PHP, Meilisearch, OpenSearch, RabbitMQ, un stockage S3 et un
    annuaire LDAP ; l’app reçoit l’URL, l’utilisateur, le mot de passe ou la
    clé et l’autorité de chacun, vérifié avant son démarrage, et
    `local_endpoint` ouvre un relais sur 127.0.0.1 pour chacun d’eux ;
  - en Python toujours, MySQL 8.4 aux côtés de MariaDB 11.8, et la taille du
    volume d’un service que la plateforme décrit : `services.<nom>.storage`
    `1Gi`, `2Gi`, `5Gi`, `10Gi` ou `20Gi`.
- **Documentation du `paas.xml`** à jour de la plateforme 2.62.0.

## v2.61.2 — 2026-10-26

- **CLI `paas-apps` 2.61.2**, vérifiée contre l’API client **2.61.2** (437
  opérations, inchangées).
- Ce que la plateforme 2.61.2 apporte à votre `paas.xml` :
  - en PHP, un service de chaque réservation, jusqu’à huit : PostgreSQL ;
    MySQL ou MariaDB ; Redis ; et, réservés comme en Go et Node, Meilisearch,
    OpenSearch, RabbitMQ, un stockage S3 et un annuaire LDAP ; l’app reçoit
    l’URL, l’utilisateur, le mot de passe ou la clé et l’autorité de chacun, et
    `local_endpoint` ouvre un relais sur 127.0.0.1 pour Redis et pour chacun
    d’eux ; en Go et Node, jusqu’à neuf services ;
  - la taille du volume d’un service que la plateforme décrit (Meilisearch,
    OpenSearch, RabbitMQ, S3, LDAP) : `services.<nom>.storage` `1Gi`, `2Gi`,
    `5Gi`, `10Gi` ou `20Gi` ;
  - PHP 8.4.27 : les recettes `php-8.4.27-apache-alpine-…` du catalogue
    `2026.10.26.php.26`, aux mêmes extensions ; passez `build.runtime_version`,
    `build.recipe` et `build.catalogue` à cette version : les recettes 8.4.26
    ne passent plus la politique CVE par défaut.
- **Documentation du `paas.xml`** à jour de la plateforme 2.61.2.

## v2.60.1 — 2026-10-26

- **CLI `paas-apps` 2.60.1**, vérifiée contre l’API client **2.60.1** (437
  opérations, inchangées).
- Ce que la plateforme 2.60.1 apporte à votre `paas.xml` :
  - PostGIS 3.6 pour le PostgreSQL 16 réservé, quel que soit le langage :
    `postgis` (et `postgis_topology`) dans `services.<nom>.extensions`, avec
    les autres extensions publiées ;
  - OpenSearch 3.9, RabbitMQ 4.4, un stockage S3 et un annuaire LDAP réservés
    pour une app Go ou Node : `services.<nom>.type` `opensearch`, `rabbitmq`,
    `s3` ou `ldap`, serveur dédié en TLS vérifié ; l’app reçoit l’URL,
    l’utilisateur, le mot de passe ou la clé et l’autorité du service, et
    `local_endpoint` ouvre un relais sur 127.0.0.1.
- **Documentation du `paas.xml`** à jour de la plateforme 2.60.1.

## v2.58.1 — 2026-10-25

- **CLI `paas-apps` 2.58.1**, vérifiée contre l’API client **2.58.1** (437
  opérations, inchangées).
- Ce que la plateforme 2.58.1 apporte à votre `paas.xml` :
  - Meilisearch 1.46, réservé pour une app Go ou Node (npm, pnpm) :
    `services.<nom>.type` `meilisearch`, serveur dédié en TLS vérifié ; l’app
    reçoit `MEILI_URL`, `MEILI_MASTER_KEY` et `MEILI_SSL_CA`, et
    `local_endpoint` ouvre un relais HTTP sur 127.0.0.1.
- **Documentation du `paas.xml`** à jour de la plateforme 2.58.1.

## v2.57.1 — 2026-10-25

- **CLI `paas-apps` 2.57.1**, vérifiée contre l’API client **2.57.1** (437
  opérations, inchangées).
- Ce que la plateforme 2.57.1 apporte à votre `paas.xml` :
  - une app dont les seuls processus sont des crons (Node ; Go avec les
    catalogues `2026.10.25.go.11` et `2026.10.25.go126.3`) est servie : sa
    release se lit `scheduled` dans `paas-apps releases list`, et
    `paas-apps run` lance son image ;
  - une exécution de cron en cours ne bloque plus la mise en service d’une app
    qui a aussi un web.
- **Documentation du `paas.xml`** à jour de la plateforme 2.57.1.

## v2.57.0 — 2026-10-25

- **CLI `paas-apps` 2.57.0**, vérifiée contre l’API client **2.57.0** (437
  opérations, inchangées).
- Ce que la plateforme 2.57.0 apporte à votre `paas.xml` :
  - en Go, une app sans processus web : un worker seul, sans port ni route,
    sondé par sa commande (`healthcheck` de type `exec`) ou par un port local
    (`tcp`), avec les catalogues `2026.10.25.go.11` et `2026.10.25.go126.3` ;
  - les recettes Go 1.27.3 (`go-1.27.3-*`) et Go 1.26.10 (`go-1.26.10-*`), dans
    ces mêmes catalogues ;
  - Ruby 3.4.11 dans les deux recettes Ruby (catalogues `2026.10.25.ruby.7`,
    `2026.10.25.ruby.8` et `2026.10.25.ruby.9`) : avec eux,
    `build.runtime_version` vaut `3.4.11` ;
  - un `paas.xml` qui nomme un catalogue Go ou Ruby antérieur garde sa
    recette, mais son image ne passe plus la politique CVE par défaut : passez
    aux catalogues du 25 octobre.
- **Documentation du `paas.xml`** à jour de la plateforme 2.57.0.

## v2.56.0 — 2026-10-25

- **CLI `paas-apps` 2.56.0**, vérifiée contre l’API client **2.56.0** (437
  opérations ; les processus d’une app décrivent désormais leur commande
  exacte, leurs réglages de cron et leur délai d’arrêt). Elle publie aussi la
  2.52.2, jamais publiée seule.
- Ce que la plateforme 2.56.0 apporte à votre `paas.xml` :
  - en Node, PHP et Go, des workers et des crons dans leurs propres pods, et un
    processus `release` joué avant chaque déploiement ; une app Node sans
    processus web ; des workers et des crons par intervalle dans le conteneur
    du web, pour toutes les recettes ;
  - un mot de passe demandé avant toute requête vers l’app
    (`edge.access.basic_auth_secret`) ;
  - les sous-modules Git déclarés (`source.gitlinks`), les dossiers laissés de
    côté (`source.ignore_directories`) et des arbres jusqu’à 100 000 fichiers ;
  - PHP : inventaires Composer 1, archives et correctifs Composer déclarés,
    chemins inscriptibles (`storage.writable`), adresses sans extension
    (`web.extensionless`) ;
  - PHP et Ruby : le frontal npm construit par la plateforme ; Ruby : les gems
    du `Gemfile.lock` installées hors réseau ;
  - l’installation par formulaires lit la cible et des valeurs de la page
    (jeton anti-CSRF) ; les comptes Ruby se créent par formulaire ;
  - un Dockerfile hors de la racine du dépôt, avec son contexte et son étape ;
    l’index d’un site statique (`build.static.index`) ;
  - les liens vers un volume (`storage.links`) en Node et Go.
- **Documentation du `paas.xml`** à jour de la plateforme 2.56.0.

## v2.52.2 — 2026-10-23

- **CLI `paas-apps` 2.52.2**, vérifiée contre l’API client **2.52.2** (437
  opérations ; contrat inchangé depuis la 2.51.2). Elle publie aussi la 2.51.3,
  jamais publiée seule.
- Ce que la plateforme 2.52 apporte à votre `paas.xml` :
  - jusqu’à trois services privés par app en PHP, Node et Go, un de chaque
    réservation : PostgreSQL 16 ; MySQL 8.4 ou MariaDB 11.8 ; Redis 7.4 ;
  - Redis et MariaDB pour les apps Node et Go ; PostgreSQL, MariaDB et Redis
    pour les apps PHP ;
  - toute liste des extensions de l’image PostgreSQL publiée, chacune à sa
    version ;
  - des bases MySQL et MariaDB nommées (`databases`) et le droit de créer des
    bases `app_*` (`privileges` : `CREATE_DATABASE`) ;
  - le réglage `log_bin_trust_function_creators` des bases MySQL et MariaDB ;
  - un service ajouté à une app déjà installée : l’app garde son installation.
- **Documentation du `paas.xml`** à jour de la plateforme 2.52.2.

## v2.51.3 — 2026-10-21

- **CLI `paas-apps` 2.51.3**, vérifiée contre l’API client **2.51.3** (437
  opérations ; contrat inchangé depuis la 2.51.2). Elle publie aussi la 2.51.2,
  jamais publiée seule.
- Ce que la plateforme 2.51.3 corrige pour vous, sans rien changer à votre
  `paas.xml` : la liste de vos applications ne lit plus les SBOM ni les
  journaux de tests de leurs builds, et la liste de vos applications supprimées
  est servie par pages : la réponse reste rapide quel que soit leur nombre.
- **Documentation du `paas.xml`** à jour de la plateforme 2.51.3.

## v2.51.2 — 2026-10-21

- **CLI `paas-apps` 2.51.2**, vérifiée contre l’API client **2.51.2** (437
  opérations).
- Ce que la plateforme 2.51.2 corrige pour vous, sans rien changer à votre
  `paas.xml` :
  - quand le scan refuse une image pour des paquets de sa recette, la révision
    corrigée qu’il propose est publiée après le catalogue de votre plan et sans
    faille CRITICAL ni HIGH au dernier rescan quotidien de son image : une
    révision devenue vulnérable n’est plus proposée ; de même pour les mises à
    jour de sécurité ;
  - l’acceptation d’une liste de dépendances
    (`POST /v1/apps/{app}/dependency-lists/{id}/accept`) accepte le nom de
    l’application, comme les autres routes des listes ;
  - en mode `manual`, un push ou une reconstruction d’un commit dont la liste
    est proposée rejoint cette proposition, sans seconde production ;
  - paquets Python construits depuis leur source : l’inventaire des
    bibliothèques intégrées nomme le paquet source de chacune, que le scan
    rapproche des avis de sécurité.
- **Documentation du `paas.xml`** à jour de la plateforme 2.51.2.

## v2.51.1 — 2026-10-20

- **CLI `paas-apps` 2.51.1**, vérifiée contre l’API client **2.51.1** (437
  opérations, chacune présente sur le serveur en service). Elle publie aussi
  ce que la plateforme 2.51.0 apporte.
- **Nouvelles commandes** `dependencies list`, `show`, `produce`, `accept` et
  `mode` (API 2.51.0) : les listes de dépendances que la plateforme produit
  pour une application dont la liste n’est pas exacte.
- Ce que la plateforme 2.51.0 change pour vous, dans le `paas.xml` :
  - **listes de dépendances produites par la plateforme** : npm sans
    `package-lock.json`, Python à plages ou sans empreintes (`requirements.txt`,
    `pyproject.toml`, `setup.cfg`), Composer sans `composer.lock` : au push, la
    plateforme résout la liste une fois, depuis le registre officiel, avec les
    empreintes, et l’écrit dans le Git de l’application (`paas/dependencies/`,
    provenance `paas/dependencies.json`) ; chaque build l’installe hors réseau ;
    elle ne change que sur votre demande (`dependencies produce`) ;
  - un `yarn.lock` (frontend Yarn 1 d’un build Go) dont des entrées sont hors
    de leur plage est réparé de même, une fois ; votre `yarn.lock` n’est pas
    modifié ;
  - **recette Python simple** raccordée au `paas.xml` : `build.python`,
    `build.env`, `build.steps`, cycle de vie, comptes, PostgreSQL 16 et
    Redis 7.4, paquets sans roue construits depuis leur source
    (`build.python.source_builds`), montages persistants ;
  - `build.node.manifest` : un `package.json` gardé sous la racine.
- Ce que la plateforme 2.51.1 corrige : les listes npm et Yarn sont produites
  en service ; les constructions Python depuis la source passent le build ;
  une reconstruction d’un commit dont la liste est à produire la fait produire.
- **CLI** : un build en échec à sa préparation se lit « failed » (il se lisait
  « succeeded »).
- **Documentation du `paas.xml`** à jour de la plateforme 2.51.1.

## v2.50.1 — 2026-10-19

- **CLI `paas-apps` 2.50.1**, vérifiée contre l’API client **2.50.1** (433
  opérations ; contrat inchangé depuis la 2.49.4). Elle publie aussi la 2.50.0
  et les versions qu’elle portait, jamais publiées seules.
- Ce que la plateforme 2.50.1 corrige pour vous, sans rien changer à votre
  `paas.xml` :
  - une réponse passagère d’un registre, d’une forge ou du proxy des modules Go
    (429, 500, 502, 503, 504) ou une coupure ne fait plus échouer un build : la
    préparation retente depuis zéro, trois essais au plus, après 2 puis 4
    secondes (paquets npm, Yarn classique et berry, archives Git, archive d’un
    site, PyPI, modules Go, pnpm) ; toute autre réponse est refusée au premier
    essai, et le refus nomme la cause et le nombre d’essais ;
  - une indisponibilité qui dure n’est plus imputée à votre déclaration :
    `ENV_STATIC_ARCHIVE_UNAVAILABLE`, `ENV_GO_GENERATOR_ACQUISITION_UNAVAILABLE`.
- **Documentation du `paas.xml`** à jour de la plateforme 2.50.1 (règles des
  codes de refus).

## v2.50.0 — 2026-10-19

- **CLI `paas-apps` 2.50.0**, vérifiée contre l’API client **2.50.0** (433
  opérations, chacune présente sur le serveur en service ; contrat inchangé
  depuis la 2.49.4). Elle publie aussi la 2.49.7, la 2.49.5, la 2.49.4 et la
  2.48.1, jamais publiées seules.
- Ce que la plateforme 2.50.0 change pour vous, dans le `paas.xml`, sans
  nouvelle commande :
  - **Yarn berry** (3 et 4) : une app Node servie par Yarn berry (recette
    `node-24.20.0-yarn-berry-v1`) et le frontend Yarn berry d’un build Go,
    installés hors ligne par le Yarn que publie la plateforme ;
  - **distribution Node installée** : `build.node.dependency_mode` =
    `installed-git-v1` sert tel quel un arbre qui livre son `node_modules` de
    production, vérifié contre son inventaire, sans installation ni build ;
  - **build Node** : `build.resources.node_heap_mb`, `build.env`,
    `build.steps`, `build.node.projects`, site produit par un build Yarn,
    `build.node.runtime_dependencies` (dépendances de développement chargées
    au lancement) ;
  - **verrous** : `package-lock.json` version 1, archives Git de GitLab et
    Codeberg, dépendances `file:` et `devEngines.runtime` en pnpm ; Go 1.26.9
    pour les modules qui refusent Go 1.27 ;
  - **corrections** : boîte IMAP privée (image du moteur reconstruite),
    modules natifs Node (bibliothèques de l’image d’exécution), refus de plan
    qui nomment le fichier en cause.
- **Documentation du `paas.xml`** à jour de la plateforme 2.50.0 (colonne
  Yarn berry).

## v2.49.7 — 2026-10-19

- **CLI `paas-apps` 2.49.7**, vérifiée contre l’API client **2.49.7** (433
  opérations, chacune présente sur le serveur en service ; contrat inchangé
  depuis la 2.49.4). Elle publie aussi la 2.49.5 et la 2.49.4, jamais
  publiées seules :
  - `paas-apps builds list` et `builds info` : un build en cours se lit
    `running (<étape>)`, ou `running (before <étape>)` pendant la préparation
    de la recette, au lieu de `pending (…)` ;
  - ce que la plateforme 2.49.6 et 2.49.7 change pour vous, sans nouvelle
    commande :
    - une application supprimée est effacée jusqu’à ses builds, avant les
      lignes de leurs tâches ; une étape de l’effacement déjà faite est
      rejouée s’il reste quelque chose de son périmètre ;
    - une base PostgreSQL reprise telle quelle garde seule l’exception de son
      volume : celui d’une base réservée sans sa réservation est refusé.
- **Exemples** : trois logiciels de plus, dans trois autres langages, chacun
  avec sa recette (N1), ses processus et volumes (N0) et ses services (N2) :
  [etherpad](exemples/etherpad/) (Node, PostgreSQL), [discourse](exemples/discourse/)
  (Ruby, PostgreSQL, Redis, SMTP), [erpnext](exemples/erpnext/) (Python, MariaDB,
  Redis).
- **Documentation du `paas.xml`** à jour de la plateforme 2.49.7.

## v2.49.5 — 2026-10-18

- **CLI `paas-apps` 2.49.5**, vérifiée contre l’API client **2.49.5** (433
  opérations, chacune présente sur le serveur en service ; contrat inchangé
  depuis la 2.49.4). Elle publie aussi la 2.49.4, jamais publiée seule. Ce que
  la plateforme 2.49.5 change pour vous, sans nouvelle commande :
  - une base PostgreSQL créée par l’API des addons, reprise telle quelle
    quand le `paas.xml` déclare PostgreSQL, est admise au déploiement avec son
    volume de données ; la 2.49.4 la refusait
    (`N0_POSTGRES_CLAIM_FOREIGN_OWNER`, imputé à la plateforme). Un nouveau
    push de l’application la déploie, sur la même base et les mêmes données.
- **Documentation du `paas.xml`** à jour de la plateforme 2.49.5.

## v2.49.4 — 2026-10-18

- **CLI `paas-apps` 2.49.4**, vérifiée contre l’API client **2.49.4** (433
  opérations, chacune présente sur le serveur en service). Elle publie aussi la
  2.49.0 à la 2.49.3 de la plateforme, jamais publiées seules :
  - `paas-apps apps security-updates <app> --method commit|branch` : en mode
    automatique, comment la révision corrigée arrive dans l’application
    (`commit`, par défaut : intégrée à sa branche ; `branch` : servie depuis la
    branche de la plateforme, la sienne intacte). Une méthode seule garde le
    mode. La commande affiche les options que la plateforme offre à
    l’application (chaque mode et méthode, sa valeur par défaut, s’il lui est
    ouvert, ce qu’il fait) ; le contrat gagne `method` dans le corps du `PUT` ;
  - ce que la plateforme 2.49 change pour vous, sans nouvelle commande :
    - une application supprimée reste restaurable pendant le délai de la
      corbeille, que la suppression annonce et inscrit (`retention_until`) ;
      ce délai passé, la plateforme efface tout ce qu’elle laisse (processus,
      routage, services, volumes, images, dépôt Git, fiche), et en garde les
      traces (audit, journal de la purge, usage facturé) ;
    - une application qui a une base PostgreSQL créée par l’API des addons et
      qui déclare PostgreSQL dans son `paas.xml` la garde, reprise telle
      quelle avec ses données (`N2_LEGACY_POSTGRES_ADOPTION_SHAPE_UNSUPPORTED`
      pour une base à plusieurs instances) ;
    - une release réhabilitée (prête et stable après un premier verdict
      `crashloop`) ne montre plus son échec ;
    - une suppression et une restauration nomment qui les a demandées.
- **Documentation du `paas.xml`** à jour de la plateforme 2.49.4.

## v2.48.1 — 2026-10-18

- **CLI `paas-apps` 2.48.1**, vérifiée contre l'API client **2.48.1** (433
  opérations, chacune présente sur le serveur en service ; contrat inchangé
  depuis la 2.48.0). Ce que la plateforme 2.48.1 change pour vous, sans
  nouvelle commande :
  - un nom d'application refusé à la création : le message porte le nom
    proposé (`nom proposé : « … »`), que `paas-apps` affiche ;
  - une release qui attend vos valeurs (`awaiting_secrets`) a un
    `rollout_status` `pending` (`progressing` en 2.48.0) ; reprise après la
    dernière valeur fournie, elle ne garde plus l'erreur
    `secrets_not_provided` ;
  - des refus de plan qui disent quoi changer : la recette à déclarer telle
    que le catalogue la publie, chaque écart d'une variante Go, ce qu'un
    contrôle d'installation déclaré a obtenu ; un refus causé par un manque
    publié de la plateforme est imputé à la plateforme.
- **Documentation du `paas.xml`** publiée avec la CLI : `PAASXML-REFERENCE.md` (toutes les clés, leur statut
  mesuré recette par recette, l'index des codes de refus), `PAASXML-GUIDE.md`, `PAASXML-FEATURES.md` et
  `PAASXML-SECURITE.md`, à jour de la plateforme 2.48.1.

## v2.48.0 — 2026-10-18

- **CLI `paas-apps` 2.48.0**, vérifiée contre l'API client **2.48.0** (433
  opérations, chacune présente sur le serveur en service). Elle publie aussi
  tout le contenu de la 2.47.0 ci-dessous, jamais publiée seule :
  - `secrets provided` et `secrets provide NOM` : les valeurs que vous
    fournissez à une application (`secrets.<NOM>.provide` dans son
    `paas.xml`). Sa release, construite, testée, scannée et signée, les
    attend toutes (état `awaiting_secrets`) ; `secrets provide` lit la valeur
    dans un fichier (`--value-file`) ou sur l'entrée standard (saisie sans
    écho au clavier), jamais en argument, l'envoie dans le corps de la
    requête, et la release repart sans nouveau push ;
  - `ps` : les processus d'une application et les pods de sa release
    courante ; un pod d'une release remplacée encore vivant est marqué
    `(superseded)` ; les redémarrages comptés sont ceux de la release
    courante ; l'état suit les répliques prêtes (`scaled-zero`, `running`,
    `degraded`, `not-ready`) ;
  - qui doit agir : l'imputation affichée est celle du verdict, enregistrée
    avec lui et la version de ses règles ; quand les règles du jour décident
    autrement, une ligne `now` le dit à côté, et la marche à suivre suit
    cette lecture. `apps list` et `apps info` (nouvelle ligne `failure`)
    donnent la même imputation, et sa reclassification une fois datée par la
    plateforme ;
  - releases qui attendent : une release appliquée à 0 réplique
    (`scaled-zero`) est celle de l'application, servie par
    `paas scale web 1` ; une release `awaiting_secrets` attend vos valeurs.
    `releases list` et `releases info` le disent.
- **SDK et contrat** : `list_provided_secrets`, `provide_secret` (la valeur
  est un `Secret`, jamais affichée ni tracée) ; `App.current_release` (la
  release servie) ; `PodRef.release_id` et `current` ; `AppAddon.last_error` ;
  `Responsibility.rules` et `decided_at` ; `PaasError.reclassification` et
  `reviewed_rules` ; code `secrets_not_provided` ; raisons de rollout
  `not_created` et `not_started`, et la cause que le journal établit
  (`details.runtime_gap`).

## v2.47.0 — 2026-10-18

- **CLI `paas-apps`** pour Linux x86_64 et ARM64. Sa version est celle de la
  plateforme qu'elle sert : vérifiée contre l'API client **2.47.0** (431
  opérations, chacune présente sur le serveur en service) :
  - `paas-apps api` donne accès à toutes les opérations de l'API client ;
  - commandes métier pour la session (dont la connexion dans le navigateur),
    les applications, les builds et les releases ;
  - diagnostic complet d'un build ou d'un déploiement en échec
    (`paas.error.v1`), avec **qui doit agir** : `Cust` quand le `paas.xml` ou
    le dépôt se corrige, `Paas` quand la plateforme ne sait pas encore le
    faire (la capacité qui lui manque est nommée) ou quand un incident
    passager l'a arrêtée (la reconstruction du même commit suffit) ; la marche
    à suivre s'accorde avec qui doit agir ; rapport CVE (`builds cve`) et
    tests (`builds test`) d'un build ; quand les failles qui bloquent une
    image sont dans sa base et que la plateforme en a publié une révision
    corrigée, le diagnostic la nomme ;
  - chaque diagnostic d'un plan refusé commence par qui doit agir (colonne
    `WHO` : `Cust` ou `Paas`) ;
  - `apps list` montre, pour chaque application en échec, qui doit agir et
    le code de l'échec (colonne `FAILURE`) ;
  - `apps security-updates` : ce que fait une application quand la plateforme
    publie une révision corrigée de la base de son image, une alerte qui nomme
    les failles et la révision (`manual`) ou une mise à jour commitée dans son
    dépôt, construite et déployée par la plateforme (`automatic`), et
    l'historique de ces mises à jour ;
  - `builds bases` : les bases qu'un Dockerfile peut prendre en `FROM`, leur
    rôle et leur recette, avec le dernier rescan quotidien de chaque image
    publiée.
- **SDK et contrat** : une méthode par opération de l'API client, dont les
  mises à jour de sécurité (`get_security_updates`,
  `set_security_updates_mode`) et les bases admises (`list_build_bases`) ;
  `paas.error.v1` porte `responsibility.transient` ; le rapport CVE d'un build
  porte les secrets détectés dans l'image, sans leur valeur.
- **Documentation** : guide de la CLI, guide et référence de l'API, contrat
  OpenAPI, skills pour agents IA (`paas-cli`, `paas-api`). Le README dit ce
  que la plateforme construit : un `paas.xml`, ou un `Dockerfile` avec un
  `paas.toml` qui déclare la commande de test, à ses conditions.
- **`exemples/`** : dix logiciels à installer en une commande par leur
  `paas.xml` (`push.sh`) et à retirer (`clean.up`), avec trois politiques CVE
  en exemple : par défaut, liste d'exceptions, contrôle désactivé.
- **README** : la voie Dockerfile de la plateforme — `runtime` `dockerfile`
  dans `paas.xml`, bases admises listées par `paas-apps builds bases`
  (outillage et images des recettes publiées), `pip` à empreintes.
