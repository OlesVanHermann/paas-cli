# Fonctionnalités du paas.xml — disponibles et prévues

État au 2026-11-14 : plateforme v2.90.0, CLI 2.90.0, catalogue de production du même jour. « Disponible » veut dire
accepté par `paas config plan` ; « prouvé » veut dire en service depuis un exemple de cette bibliothèque. La
liste de toutes les clés, avec leur statut, est dans [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md) : depuis v2.38.4, chaque statut y est
mesuré recette par recette (npm, pnpm, Yarn, PHP, Python, Python fermé, Ruby, Go, Go + npm, Go + Yarn, Dockerfile) sur un exemple minimal, et un test
généré avec la référence refait chaque mesure. La marche à suivre est dans [PAASXML-GUIDE.md](PAASXML-GUIDE.md) ; les règles de sécurité dans
[PAASXML-SECURITE.md](PAASXML-SECURITE.md).

## 1. En bref

Un `paas.xml` décrit une application sans toucher à son logiciel : il s'ajoute à l'arbre amont tel quel. Il
choisit une recette technique publiée (runtime et version), réserve les services, déclare le processus web,
les volumes, les variables, les secrets et le cycle de vie natif (installation, montée de version, comptes,
contrôles).

| | Disponible | Pas encore (identifiant de la feuille de route) |
|---|---|---|
| Runtimes | PHP 8.4 ; Node 24 (npm, workspaces, pnpm, yarn), Node 22 (pnpm avec workspaces, npm, Yarn classique et berry, v2.74.53) et Node 16 (npm, Yarn classique, sans support de l'éditeur : avertissement du plan, v2.72.0) ; Go 1.26 et 1.27 ; Python 3.12 et 3.14, fermeture Python + Node ; Ruby 3.4 ; Dockerfile (`build.runtime` `dockerfile`, v2.34.0), à la racine du dépôt ou dessous avec son contexte et son étape cible (`build.dockerfile`, v2.56.0), sur l'outillage, les images des recettes publiées et les bases tierces de la liste publiée (`paas builds bases`) ; profils N3 nommés par un `paas.xml` (v2.56.0) ; statique (se planifie, jamais prouvé) | JVM (N1.JVM), Elixir (N1.ELIXIR), Rust (N1.RUST), .NET (N1.DOTNET), plusieurs conteneurs (N1.COMPOSE), autres versions majeures (N1.VERSIONS) |
| Build | Budgets de temps publiés par étape (v2.38.0) et `build.resources.timeout_seconds` ; budgets de lecture de l'arbre `source.limits`, fichiers laissés de côté `source.ignore`, fichiers inertes admis par empreinte `source.pinned` (v2.37.0) ; app rangée dans un sous-répertoire d'un monorepo, `source.root` (v2.39.0) ; dossiers laissés de côté entiers `source.ignore_directories`, sous-modules Git `source.gitlinks`, arbres jusqu'à 100 000 fichiers (v2.56.0) ; verrous npm, Yarn et pnpm lus comme leur gestionnaire ; gems Ruby et frontaux npm de PHP et Ruby installés hors réseau (v2.56.0) ; ressources que le build télécharge, déclarées (`assets`) et servies hors réseau par un miroir local en pnpm et à l'installation Composer des greffons PHP, scripts d'installation déclarés en pnpm (`build.node.install_scripts`), paquets Node au binaire posé par leur script refusés au plan sauf déclaration (`build.node.native_unused`) (v2.72.0) | `build.resources` `cpu`, `memory` et les clés de tas ou de parallélisme (refusées chacune avec sa raison) |
| Services | PostgreSQL 16 (avec PostGIS 3.6, v2.59.0) et 17 (v2.79.4), MySQL 8.4, MariaDB 11.8, Redis 7.4, MongoDB 8.0, Meilisearch 1.46 (Node et Go, v2.58.1), OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (Node et Go, v2.60.0), memcached 1.6 par son relais (v2.79.4), inférence (Ollama 0.40 sur le processeur, le modèle déclaré, v2.79.5), ces cinq-là aussi en PHP (v2.61.0) et en Python (v2.62.0), SMTP en capture ; base dédiée, TLS vérifié ; un service de chaque réservation par app, jusqu'à huit en PHP (v2.61.0) et en Python (v2.62.0), neuf en Node et Go (v2.61.0 ; trois depuis v2.52.0) ; volume de 1, 2, 5, 10 ou 20 Gi déclaré pour les services que la plateforme décrit (v2.61.0) ; extensions de l'image PostgreSQL publiée, bases MySQL et MariaDB nommées, droit de créer des bases `app_*`, réglage `log_bin_trust_function_creators` (v2.52.0) ; relais MySQL en boucle locale (`local_endpoint`) en PHP, Node et Go (v2.37.0), tunnel Redis en Node et Go (v2.52.0), tunnel Meilisearch (v2.58.1), tunnels OpenSearch, RabbitMQ, S3 et LDAP (v2.60.0), tunnels Redis, Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP en PHP (v2.61.0), tunnels Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP en Python (v2.62.0) | PostgreSQL 17 (N2.PGEXT) ; Valkey, memcached, ClickHouse, InfluxDB ; Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP en Ruby ; MySQL et MariaDB en Ruby ; envoi réel de courrier (N2.SMTP), IMAP ; réplicas, sauvegarde et PITR (N2.OPTIONS) |
| Processus | Un processus web ; en Node, PHP et Go, workers et crons dans leurs propres pods et un processus release avant chaque déploiement (v2.56.0), une app Go sans processus web (depuis v2.57.0), faite seulement de crons comprise (v2.57.1), et une app Node en npm ou pnpm (v2.73.11 ; en Yarn quand ses lignes publieront les profils `worker` et `job`) ; workers et crons par intervalle dans le conteneur du web, dans toutes les recettes (v2.56.0 ; en Python fermé et Ruby, jusqu'à 7 workers) ; une réplique ; un job (`processes`, type `job`, v2.76.1) : une commande déclarée que le client lance par son nom (`paas run --process <nom>`, `paas-apps run <nom>`), dans un Job ponctuel de l'image servie, avec ses variables, ses services et ses volumes, sa commande et son délai (30 à 3600 secondes, 3600 par défaut) ceux de la release servie ; jamais lancé par la plateforme | processus séparés avec un cycle de vie ; image propre d'un processus (N1.COMPOSE) ; plusieurs réplicas (N0.SCALE) ; stratégies de déploiement (N0.DEPLOY) |
| Stockage | Volumes rwo et rwx, liens (Node et Go depuis v2.56.0), copies initiales ; chemins inscriptibles `storage.writable` en PHP (v2.56.0) | `storage.private` (refusé par la projection, mesuré le 2026-10-15), tmpfs, stockage éphémère, rwx prouvé (N0.STORAGE) |
| Réseau | HTTPS, websockets, 100 Mo par requête ; liens déclarés entre apps `network.linked_services` (v2.30.0, effectifs quand l'isolation entre apps sera activée) ; tous les chemins du nom court, `/login` compris, vont à l'app (v2.38.1) ; mot de passe demandé par la bordure avant toute requête (`edge.access.basic_auth_secret`, v2.56.0) | Ports TCP (N0.TCP), règles de sortie et IPv6 (N0.NET), domaines (N0.DOMAINS), autres réglages d'entrée par app (N0.EDGE) |
| Sécurité | Une seule politique pour l'image servie (v2.36.0) : porte CVE, politique déclarée dans le `paas.xml` (`security.cve_exceptions` une par une, toute sévérité, ou `security.block_on` `critical` ou `none`), porte des constats de secrets avec `security.secret_exceptions` ; exceptions de l'opérateur (HIGH) ; secrets scellés | `security.sbom`, `security.require_mfa_for_console` |

## 2. Runtimes et recettes publiées (N1)

Un `paas.xml` doit nommer `build.recipe` et `build.catalogue`, et vérifier `build.runtime` : `php`, `node`,
`python`, `go`, `ruby` ou `static`. Le tableau donne les recettes de l'instantané du catalogue de production,
avec pour chacune le dernier catalogue qui la contient (instantané du 2026-10-26, v2.61.2, 112 recettes). Tout catalogue qui contient la recette convient ; un
exemple garde celui de sa preuve. Liste à jour : `paas environments:catalogue-store`.

| Famille | Recette | Version | Distribution | Profils | Dernier catalogue | Statut |
|---|---|---|---|---|---|---|
| COMPOSITION | `node-python-asgi-worker-v1` | CPython3.12.14+Node24.20.0 | debian12-glibc2.36 | web | `2026.09.07.composition.1` | publiée ; composition N3, non mesurée depuis un paas.xml |
| COMPOSITION | `node-python-asgi-worker-v2` | CPython3.12.14+Node24.20.0 | wolfi-glibc2.44 | web | `2026.09.27.composition.5` | publiée ; composition N3, non mesurée depuis un paas.xml |
| ELIXIR | `elixir119-otp27-npm-v1` | 1.19.5 | wolfi-glibc2.44 | web | `2026.09.18.elixir.1` | publiée ; `build.elixir` non raccordé (N1.ELIXIR) |
| GO | `go-1.26.8-node24-pnpm-v1` | 1.26.8 | debian12-glibc2.36 | web | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
| GO | `go-1.26.8-static-v1` | 1.26.8 | debian12-glibc2.36 | web | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
| GO | `go-1.26.9-cgo-v9` | 1.26.9 | wolfi-glibc2.44 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-git-v7` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-npm-cgo-v10` | 1.26.9 | wolfi-glibc2.44 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-npm-git-v8` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-npm-v5` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-pnpm-cgo-v11` | 1.26.9 | wolfi-glibc2.44 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-pnpm-git-v3` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-pnpm-v2` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.9-node24-yarn-v6` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9 pour les modules qui refusent Go 1.27 ; frontend Yarn classique ou berry 3 et 4) |
| GO | `go-1.26.9-static-v2` | 1.26.9 | debian12-glibc2.36 | web | `2026.10.19.go126.2` | publiée en v2.50.0 (Go 1.26.9, mêmes variantes que la ligne 1.27) |
| GO | `go-1.26.10-cgo-v9` | 1.26.10 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-git-v7` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-npm-cgo-v10` | 1.26.10 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-npm-git-v8` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-npm-v5` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-pnpm-cgo-v11` | 1.26.10 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-pnpm-git-v3` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-pnpm-v2` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-node24-yarn-v6` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.26.10-static-v2` | 1.26.10 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go126.3` | publiée en v2.57.0 (Go 1.26.10, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.1-node24-npm-native-v4` | 1.27.1 | debian12-glibc2.36 | web | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
| GO | `go-1.27.1-node24-npm-v5` | 1.27.1 | debian12-glibc2.36 | web | `2026.10.16.go.8` | prouvée : filebrowser (2026.10.06.go.5) |
| GO | `go-1.27.1-node24-pnpm-git-v3` | 1.27.1 | debian12-glibc2.36 | web | `2026.10.16.go.8` | publiée ; aucun exemple ne l’utilise encore |
| GO | `go-1.27.1-node24-pnpm-v2` | 1.27.1 | debian12-glibc2.36 | web | `2026.10.16.go.8` | prouvée : autobrr (2026.10.15.go.7, frontend pnpm 11.24.0 dans `web/`), memos (2026.10.16.go.8, frontend pnpm 11.28.2 dans `web/`) |
| GO | `go-1.27.1-node24-yarn-v6` | 1.27.1 | debian12-glibc2.36 | web | `2026.10.16.go.8` | prouvée : listmonk (2026.10.07.go.6) |
| GO | `go-1.27.1-static-v2` | 1.27.1 | debian12-glibc2.36 | web | `2026.10.16.go.8` | publiée ; aucun exemple ne l’utilise encore |
| GO | `go-1.27.2-cgo-v9` | 1.27.2 | wolfi-glibc2.44 | web | `2026.10.19.go.10` | publiée en v2.44.0 (cgo sans frontend, runtime glibc 2.44 (Wolfi)) |
| GO | `go-1.27.2-git-v7` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | prouvée : gogs 0.14.3 (git dans l'image, MySQL) (2026.10.16.go.9) |
| GO | `go-1.27.2-node24-npm-cgo-v10` | 1.27.2 | wolfi-glibc2.44 | web | `2026.10.19.go.10` | prouvée : navidrome 0.64.2 (étiquettes netgo et sqlite_fts5, Makefile laissé de côté) (2026.10.16.go.9) |
| GO | `go-1.27.2-node24-npm-git-v8` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | publiée en v2.44.0 (frontend npm, runtime Wolfi avec git) |
| GO | `go-1.27.2-node24-npm-v5` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | prouvée : plik 1.4.2 (vendor/ verify), fathom 1.3.1 (gulp, packr2), readeck 0.23.4 (templ, documentation) (2026.10.16.go.9) |
| GO | `go-1.27.2-node24-pnpm-cgo-v11` | 1.27.2 | wolfi-glibc2.44 | web | `2026.10.19.go.10` | prouvée : vikunja 2.7.0 (frontend pnpm, SQLite par cgo) (2026.10.16.go.9) |
| GO | `go-1.27.2-node24-pnpm-git-v3` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | publiée en v2.44.0 (frontend pnpm, runtime Wolfi avec git) |
| GO | `go-1.27.2-node24-pnpm-v2` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | publiée en v2.44.0 (frontend pnpm) |
| GO | `go-1.27.2-node24-yarn-v6` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | publiée en v2.44.0 (frontend Yarn classic) |
| GO | `go-1.27.2-static-v2` | 1.27.2 | debian12-glibc2.36 | web | `2026.10.19.go.10` | publiée en v2.44.0 (exécutable statique) |
| GO | `go-1.27.3-cgo-v9` | 1.27.3 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-git-v7` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-npm-cgo-v10` | 1.27.3 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-npm-git-v8` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-npm-v5` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-pnpm-cgo-v11` | 1.27.3 | wolfi-glibc2.44 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-pnpm-git-v3` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-pnpm-v2` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-node24-yarn-v6` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| GO | `go-1.27.3-static-v2` | 1.27.3 | debian12-glibc2.36 | web, worker, job | `2026.10.25.go.11` | publiée en v2.57.0 (Go 1.27.3, profils web, worker et job, images d'exécution révisées) |
| JVM | `jvm25-clojure-bun-v1` | 25.0.4+7 | ubuntu22.04-glibc2.35 | web | `2026.09.16.jvm.2` | publiée ; `build.jvm` non raccordé (N1.JVM) |
| NODE | `node-16.20.2-npm-source-v2` | 16.20.2 | debian12-glibc2.36 | web,worker,job | `2026.11.01.node-npm-16.1` | publiée en v2.72.0 (npm 11.19.0, verrou source ; Node 16 sans support de l'éditeur depuis le 11/09/2023, avertissement du plan ; npm tourne sur Node 22, les scripts du projet sur Node 16) |
| NODE | `node-16.20.2-yarn-classic-v1` | 16.20.2 | debian12-glibc2.36 | web | `2026.11.01.node-yarn-16.1` | publiée en v2.72.0 (Yarn classique 1.22.22 ; Node 16 sans support de l'éditeur, avertissement du plan) |
| NODE | `node-22.23.2-pnpm-minimal-v1` | 22.23.2 | debian12-glibc2.36 | web,worker,job | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-22.23.4-npm-source-v2` | 22.23.4 | debian12-glibc2.36 | web,worker,job | `2026.11.01.node-npm-22.1` | publiée en v2.72.0 (npm 11.19.0, verrou source) |
| NODE | `node-22.23.4-yarn-classic-v1` | 22.23.4 | debian12-glibc2.36 | web | `2026.11.01.node-yarn-22.1` | publiée en v2.72.0 (Yarn classique 1.22.22) |
| NODE | `node-24.20.0-bookworm-minimal-v5` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-bookworm-v1` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-bookworm-v2` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-bookworm-v3` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-bookworm-v4` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-npm-source-v2` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.16.node.5` | prouvée : cryptpad (2026.09.16.node.5), nightscout (2026.09.16.node.5) |
| NODE | `node-24.20.0-npm-workspace-v1` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.13.node.4` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-pnpm-workspace-v2` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.10.19.node.9` | prouvée : etherpad (2026.10.05.node.6), ghost (2026.10.07.node.7), t0400 (2026.10.15.node.8, pnpm 10.28.0 servi par 10.34.6) |
| NODE | `node-24.20.0-pnpm-workspace-v3` | 24.20.0 | debian12-glibc2.36 | web,worker,job | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
| NODE | `node-24.20.0-yarn-berry-v1` | 24.20.0 | debian12-glibc2.36 | web | `2026.10.19.node-yarn.3` | publiée en v2.50.0 (Yarn berry 3.2.1 à 4.18.1, installé hors ligne depuis un miroir ; preuves locales hedgedoc, facilmap, medusajs) |
| NODE | `node-24.20.0-yarn-classic-v1` | 24.20.0 | debian12-glibc2.36 | web | `2026.10.19.node-yarn.3` | prouvée en v2.46.1 : t0461 (application de recette, PostgreSQL en TLS, installation HTTP, comptes) ; Wiki.js 2.5.315 se construit et lance son cycle de vie, puis s'arrête sur son correctif patch-package (extract-files), que la plateforme n'applique pas encore (section 6) |
| NODE | `node24-pnpm11-python312-closure-v1` | 24.20.0 | wolfi-glibc2.44 | web | `2026.09.18.node-python.1` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-cache-v5` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-calendar-v6` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-iconv-v7` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-imagick-v8` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-pdo-v2` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-pdo-xml-v3` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-sqlite-intl-v4` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.25-apache-alpine-v1` | 8.4.25 | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-cache-v5` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée : flarum (2026.10.04.php.20), piwigo (2026.10.07.php.21) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-calendar-v6` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-full-pear-v11` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; full-v10 avec PEAR (`PEAR.php` dans le chemin d’inclusion) ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-full-v10` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-full-sqlite3-v12` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée : Wallos 5.8.3 (classe SQLite3, base créée sur le volume, connexion servie) (2026.10.16.php.24) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-full-tidy-v13` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l'utilise encore (wallabag) (2026.10.16.php.24) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-full-imap-v14` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée au build : Agorakit 1.11 (ddeboer/imap exige ext-imap ; Composer installe, extension chargée) (2026.10.16.php.24) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-iconv-v7` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée : bookstack (2026.10.04.php.20), dokuwiki (2026.10.04.php.20), drupal (2026.10.04.php.20), joomla (2026.10.04.php.20), opencart (2026.10.04.php.20), suitecrm (2026.10.07.php.21), woocommerce (2026.10.04.php.20), wordpress (2026.10.04.php.20) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-imagick-calendar-v9` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée (2026.10.07.php.21) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-imagick-v8` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée : nextcloud (2026.10.07.php.21), typo3 (2026.10.07.php.21) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-pdo-v2` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-pdo-xml-v3` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-sqlite-intl-v4` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | prouvée : freshrss (2026.10.04.php.20), kanboard (2026.10.04.php.20) ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.26-apache-alpine-v1` | 8.4.26 | alpine3.24-musl | web | `2026.10.18.php.25` | publiée ; aucun exemple ne l’utilise encore ; refusée par la porte CVE par défaut (`CVE-2026-109618`, CRITICAL, php84 8.4.26) : prendre la 8.4.27 |
| PHP | `php-8.4.27-apache-alpine-cache-v5` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-calendar-v6` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-full-pear-v11` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-full-v10` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | prouvée : services-recette 1.0.0 (sept services, un de chaque réservation, OpenSearch sur 10 Gi) (2026.10.26.php.26) ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-full-sqlite3-v12` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-full-tidy-v13` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-full-imap-v14` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-iconv-v7` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-imagick-calendar-v9` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-imagick-v8` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-pdo-v2` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-pdo-xml-v3` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-sqlite-intl-v4` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PHP | `php-8.4.27-apache-alpine-v1` | 8.4.27 | alpine3.24-musl | web | `2026.10.26.php.26` | publiée ; aucun exemple ne l’utilise encore ; révision de sécurité de la 8.4.26 (PHP 8.4.27, v2.61.2) |
| PYTHON | `python-3.12.14-bookworm-v1` | 3.12.14 | debian12-glibc2.36 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.12.14-wolfi-v1` | 3.12.14 | wolfi-glibc2.44 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.7-bookworm-v1` | 3.14.7 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.7-wolfi-v1` | 3.14.7 | wolfi-glibc2.44 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.8-wolfi-v1` | 3.14.8 | wolfi-glibc2.44 | web,worker,job | `2026.10.12.python.1` | publiée (v2.34.0) ; images composées par la plateforme, mesurées 0 CRITICAL / 0 HIGH ; aucun exemple ne l’utilise encore |
| PYTHON | `python314-node24-closure-v1` | 3.14.7 | wolfi-glibc2.44 | web | `2026.10.03.python.1` | prouvée : erpnext (2026.10.03.python.1) |
| PYTHON | `seafile13-native-closure-v1` | 3.12.14 | wolfi-glibc2.44 | web | `2026.09.22.native.1` | publiée ; recette native propre à une app (N3), hors doctrine |
| RUBY | `ruby34-bundler-offline-v2` | 3.4.11 | wolfi-glibc2.44 | web | `2026.10.25.ruby.7` | publiée ; Ruby 3.4.11 depuis v2.57.0 (3.4.10 jusqu'au catalogue 2026.09.18.ruby.2) ; aucun exemple ne l’utilise encore |
| RUBY | `ruby34-pnpm-offline-v1` | 3.4.11 | wolfi-glibc2.44 | web | `2026.10.25.ruby.9` | prouvée : discourse (2026.09.30.ruby.3, Ruby 3.4.10) ; Ruby 3.4.11 depuis v2.57.0 (pnpm 10.34.6, et 10.34.5 par 2026.10.25.ruby.8) |
| STATIC | `static-nginx-1.30.4-alpine3.24-v1` | HTML5-CSS-JavaScript-static | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; refusée par la porte CVE par défaut depuis le 2026-10-15 (`CVE-2026-103111`, HIGH, pcre2 de l'image nginx) : prendre la 1.30.6 |
| STATIC | `static-nginx-1.30.6-alpine3.24-v1` | HTML5-CSS-JavaScript-static | alpine3.24-musl | web | `2026.10.15.static.1` | prouvée (v2.39.3) : site de test construit et servi, 0 CRITICAL / 0 HIGH ; ligne de catalogue `static`, build et tests sur l'image Python Wolfi de la plateforme |

Extensions des recettes PHP 8.4.26 et de leurs révisions 8.4.27 (`php-8.4.27-apache-alpine-…`, les mêmes, catalogue `2026.10.26.php.26`) ; `build.php.extensions` doit correspondre exactement à la recette :

| Recette | Extensions |
|---|---|
| `php-8.4.26-apache-alpine-cache-v5` | apcu, ctype, gmp, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, posix, simplexml, sodium, tokenizer, xmlreader, xmlwriter |
| `php-8.4.26-apache-alpine-calendar-v6` | apcu, calendar, ctype, gmp, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, posix, simplexml, sodium, tokenizer, xmlreader, xmlwriter |
| `php-8.4.26-apache-alpine-full-pear-v11` | les extensions de full-v10, plus les classes de base PEAR (paquet système `pear`, hors `build.php.extensions`) |
| `php-8.4.26-apache-alpine-full-v10` | apcu, bcmath, bz2, calendar, ctype, exif, ftp, gettext, gmp, iconv, igbinary, imagick, intl, ldap, memcached, msgpack, opcache, pcntl, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, posix, redis, simplexml, soap, sockets, sodium, tokenizer, xmlreader, xmlwriter, xsl |
| `php-8.4.26-apache-alpine-iconv-v7` | apcu, ctype, gmp, iconv, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, posix, simplexml, sodium, tokenizer, xmlreader, xmlwriter |
| `php-8.4.26-apache-alpine-imagick-calendar-v9` | apcu, calendar, ctype, gmp, iconv, imagick, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, posix, simplexml, sodium, tokenizer, xmlreader, xmlwriter |
| `php-8.4.26-apache-alpine-imagick-v8` | apcu, ctype, gmp, iconv, imagick, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, posix, simplexml, sodium, tokenizer, xmlreader, xmlwriter |
| `php-8.4.26-apache-alpine-pdo-v2` | pdo_mysql, tokenizer |
| `php-8.4.26-apache-alpine-pdo-xml-v3` | ctype, pdo_mysql, simplexml, tokenizer |
| `php-8.4.26-apache-alpine-sqlite-intl-v4` | ctype, gmp, intl, opcache, pcntl, pdo_mysql, pdo_sqlite, simplexml, tokenizer, xmlreader |
| `php-8.4.26-apache-alpine-v1` | aucune (PHP de base) |

## 3. Services (N2)

Chaque service est une instance dédiée à l'app, réservée avant le build, sous TLS vérifié. Son adresse et
ses identifiants sont liés par la plateforme au démarrage. Depuis la v2.27.0, une base n'accepte que les pods
de son app.

| Runtime (recette) | Services acceptés | Combien |
|---|---|---|
| PHP | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, Meilisearch 1.46, OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (v2.52.0 : tous sauf MySQL ; v2.61.0 : Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP) | jusqu'à 8, un de chaque réservation : PostgreSQL ; MySQL ou MariaDB ; Redis ; Meilisearch ; OpenSearch ; RabbitMQ ; S3 ; LDAP (v2.61.0 ; 3 depuis v2.52.0) |
| Node (npm, pnpm, Yarn) | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, MongoDB 8.0, Meilisearch 1.46, OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (v2.52.0 : MariaDB et Redis ; v2.58.1 : Meilisearch ; v2.60.0 : OpenSearch, RabbitMQ, S3 et LDAP) ; SMTP en capture | jusqu'à 9, un de chaque réservation, plus la capture SMTP (v2.61.0 ; 3 depuis v2.52.0) |
| Go | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, MongoDB 8.0, Meilisearch 1.46, OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (v2.52.0 : MariaDB et Redis ; v2.58.1 : Meilisearch ; v2.60.0 : OpenSearch, RabbitMQ, S3 et LDAP) ; SMTP en capture | jusqu'à 9, un de chaque réservation, plus la capture SMTP (v2.61.0 ; 3 depuis v2.52.0) |
| Python simple | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, Meilisearch 1.46, OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (v2.62.0 : MySQL, Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP) | jusqu'à 8, un de chaque réservation : PostgreSQL ; MySQL ou MariaDB ; Redis ; Meilisearch ; OpenSearch ; RabbitMQ ; S3 ; LDAP (v2.62.0 ; 3 jusque-là) |
| Python fermé (`python314-node24-closure-v1`) | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, Meilisearch 1.46, OpenSearch 3.9, RabbitMQ 4.4, S3, annuaire LDAP (OpenLDAP 2.7) (v2.62.0 : MySQL, Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP) | jusqu'à 8, un de chaque réservation : PostgreSQL ; MySQL ou MariaDB ; Redis ; Meilisearch ; OpenSearch ; RabbitMQ ; S3 ; LDAP (v2.62.0 ; 3 jusque-là) |
| Ruby | PostgreSQL 16 avec au moins une extension (v2.52.0 : toute liste de l'image publiée, jusque-là une variante publiée), Redis 7.4 ; SMTP en capture | jusqu'à 3 |

- PostgreSQL avec extensions (v2.52.0) : toute liste des extensions que sert l'image publiée, version `16` :
  `btree_gin`, `cube`, `earthdistance` (avec `cube`), `hstore`, `ltree`, `pg_trgm`, `pgcrypto`, `unaccent`,
  `uuid-ossp`, `vector`, chacune créée à sa version publiée. Jusqu'à v2.51.3, seules deux listes exactes étaient
  admises. PostGIS (v2.59.0, tous les runtimes servis) : une liste qui nomme `postgis` ou `postgis_topology`
  (avec `postgis`) réserve l'image PostGIS de la plateforme (PostgreSQL 16.14, PostGIS 3.6.4 sans raster,
  topologie et tuiles vectorielles, pgvector 0.8.7), 512 Mi, avec les autres extensions de la liste ;
  `postgis_raster` n'est pas servi (`ENV_TECHNICAL_POSTGRES_PROFILE_UNSUPPORTED`).
- MySQL 8.4 et MariaDB 11.8 (v2.52.0 ; PHP, Python simple, Node, Go) : `databases`, sept bases nommées au plus,
  créées avec le service et liées par `MYSQL_DATABASES_JSON` ; `privileges` `CREATE_DATABASE`, l'utilisateur de l'app
  crée les bases dont le nom commence par `app_` et aucune autre ; `options` `log_bin_trust_function_creators` à
  `true`, seul réglage admis (le serveur réservé tourne sans journal binaire : fonctions, procédures et déclencheurs
  de l'app s'y créent).
- Une réservation ne change plus : un push qui retire un service, ou change ses extensions, ses bases ou son
  privilège, est refusé (`N2_EXISTING_RESERVATION_CONFLICT_RETAINED`). Un service ajouté est réservé au push suivant ;
  l'app garde son installation (PHP depuis v2.52.0 ; Node, Go, Python et Ruby depuis v2.52.2).
- Redis : `persistence` `aof` et `eviction` `noeviction` exigés ; liaison `REDIS_URL` (`rediss://`) et `REDIS_SSL_CA`.
  MariaDB se lie par `MYSQL_URL`, comme MySQL.
- Meilisearch (Node et Go, v2.58.1 ; PHP, v2.61.0 ; Python, v2.62.0) : version `1.46.0`, `provider` `dedicated`, `tls` `required`, `storage` (ci-dessous),
  `ca_file` sous un volume ; liaison `MEILI_URL` (`https://`), `MEILI_MASTER_KEY` et `MEILI_SSL_CA` ; les gabarits
  lisent `url`, `host`, `port`, `password` (la clé maîtresse), `ca_file` et `ca` (en Python, pas `ca`). Ruby
  le refuse par son code.
- OpenSearch 3.9, RabbitMQ 4.4, S3 et annuaire LDAP (Node et Go, v2.60.0 ; LDAP admis depuis v2.60.1 ; PHP,
  v2.61.0 ; Python, v2.62.0) :
  `type` `opensearch` (version `3.9.0`), `rabbitmq` (`4.4.0`), `s3` (`4.51`, SeaweedFS) ou `ldap` (`2.7.2`,
  OpenLDAP), `provider` `dedicated`, `tls` `required`, `storage` (ci-dessous), `ca_file` sous un volume.
  Liaison :
  `OPENSEARCH_URL` (`https://`), `OPENSEARCH_USERNAME`, `OPENSEARCH_PASSWORD`, `OPENSEARCH_SSL_CA` ;
  `RABBITMQ_URL` (`amqps://` avec l'utilisateur et le mot de passe, hôte virtuel `/`), `RABBITMQ_USERNAME`,
  `RABBITMQ_PASSWORD`, `RABBITMQ_SSL_CA` ; `S3_ENDPOINT` (`https://`), `S3_ACCESS_KEY_ID`,
  `S3_SECRET_ACCESS_KEY`, `S3_SSL_CA`, `S3_REGION` (`us-east-1`), `S3_FORCE_PATH_STYLE` (`true`) ; `LDAP_URL`
  (`ldaps://`), `LDAP_BIND_DN` (`cn=admin,dc=app`), `LDAP_BIND_PASSWORD`, `LDAP_SSL_CA`, `LDAP_BASE_DN`
  (`dc=app`). Les gabarits lisent `url`, `host`, `port`, `user`, `password`, `ca_file` et `ca`. Mémoire
  réservée : OpenSearch 2 Gi, RabbitMQ et S3 512 Mi, LDAP 256 Mi. Ruby les refuse par son code.
- Volume d'un service (Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP depuis v2.61.0 ; PostgreSQL, MySQL, MariaDB, Redis et MongoDB depuis v2.74.52) :
  `storage` `1Gi`, `2Gi`, `5Gi`, `10Gi` ou `20Gi`, réservé à cette taille ; une autre taille est refusée à sa clé
  (`ENV_TECHNICAL_SERVICE_POLICY`). L'agrandissement d'un volume déjà réservé n'est pas encore servi.
- En PHP (v2.61.0), l'entrée lie chaque service que la plateforme décrit comme paas-entry (mêmes variables) et
  le vérifie avant de servir ; un gabarit `services.<nom>.env` qui lit une valeur qu'elle ne fournit pas (la
  base d'un service décrit, l'utilisateur de Meilisearch) est refusé à sa clé
  (`ENV_TECHNICAL_SERVICE_ENV_UNBOUND`).
- En Python (v2.62.0, recettes simple et fermée), l'entrée lie chaque service que la plateforme décrit par
  les mêmes variables et le vérifie avant de lancer l'app, par son propre protocole et avec la seule
  bibliothèque standard : aucun pilote à déclarer pour lui. Son autorité est écrite au `ca_file` après
  celles du système, comme pour PostgreSQL, MySQL et Redis. Les gabarits lisent `url`, `host`, `port`,
  `user` (sauf Meilisearch), `password` et `ca_file` ; `ca` n'est ouvert qu'à PHP et à paas-entry, le PEM
  reste dans la variable `<TYPE>_SSL_CA`. Un gabarit `services.<nom>.env` qui lit une valeur que l'entrée
  ne fournit pas est refusé à sa clé (`ENV_TECHNICAL_SERVICE_ENV_UNBOUND`) ; il lit les valeurs de tout
  service déclaré (jusqu'à v2.61.2, des seuls services liés avant le sien). MySQL 8.4 s'y réserve aussi,
  par sa norme publiée (v2.62.0 ; MariaDB 11.8 seul jusque-là).
- `DATABASE_URL` : avec PostgreSQL et MySQL ou MariaDB, elle nomme PostgreSQL ; `MYSQL_URL` nomme MySQL ou MariaDB
  (v2.52.0 : l'ordre dépendait d'identifiants aléatoires). Le schéma de l'URL est `postgresql://` ; une app qui tire
  son pilote du schéma tel qu'il est écrit et attend `postgres` déclare `DATABASE_URL` vide dans l'env du service pour
  lire ses propres variables.
- En Node et Go, un service exige le cycle de vie du moteur (`lifecycle.state_directory`), `tls=required` et
  `ca_file`, le chemin où écrire l'autorité de certification. En PHP, l'entrée lie et vérifie chaque service avant de
  servir ; avec un cycle de vie, PostgreSQL demande une recette à `pdo_pgsql`.
- `local_endpoint` (v2.37.0) : relais MySQL en boucle locale, en clair côté app et en TLS vérifié vers le serveur,
  pour un client qui ne parle pas TLS ; tunnel Redis en Node et Go depuis v2.52.0, tunnel Meilisearch depuis
  v2.58.1 (`MEILI_URL` vise alors `http://127.0.0.1:<port>`, la clé reste dans `MEILI_MASTER_KEY`), tunnels
  OpenSearch, RabbitMQ, S3 et LDAP depuis v2.60.0 (`OPENSEARCH_URL` et `S3_ENDPOINT` en `http://`, `LDAP_URL` en
  `ldap://`, `RABBITMQ_URL` en `amqp://` avec ses identifiants, sur 127.0.0.1) ; en PHP depuis v2.61.0, tunnels
  Redis, Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP, chacun sur un port à lui ; en Python depuis v2.62.0, tunnels Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP
  (Redis depuis v2.51.0), chacun sur un port à lui, jamais celui du processus web. Les URL injectées
  (`DATABASE_URL` et `MYSQL_URL`, `REDIS_URL`, celle du service décrit) visent alors le relais (en Python,
  `REDIS_URL` garde celle du serveur, le gabarit `services.<nom>.local_url` donne celle du relais) ; sans relais ni URL propre au service, le plan
  avertit (`services.url_without_tls`). MariaDB passe par le relais de MySQL (Node et Go depuis v2.74.17, PHP depuis
  v2.81.41) ; PostgreSQL a le sien dans les recettes que sert paas-entry depuis v2.81.51 (`local_url` en
  `postgres://…` sur 127.0.0.1, sans `sslmode`).
- `services.<nom>.env` : variables par gabarit (`{{services.<nom>.host}}`…), noms en minuscules compris, que l'entrée
  PHP admet aussi depuis v2.38.1.
- SMTP : capture seulement, en Node et Go (en PHP : `ENV_TECHNICAL_SERVICE_OPTION_UNSUPPORTED`). Les messages vont à un
  puits lisible par le cycle de vie (`lifecycle.mail_sink`), utile pour une invitation ou une vérification ; aucun
  courrier ne sort.
- Un service déclaré par un push est réservé avant le build, et n'atteint le pod qu'avec la release qui le déclare :
  depuis v2.38.2, la release en service n'est plus redémarrée avec ses variables avant la nouvelle.
- Base PostgreSQL héritée (v2.49.0) : une app qui en a une (créée par `paas addons`) et déclare PostgreSQL la garde,
  reprise telle quelle avec ses données ; une base à plusieurs instances est refusée par son nom. MySQL, Redis et
  MongoDB hérités restent refusés.
- Options refusées aujourd'hui : `backup`, `plan`, `quota`.
- La matrice complète, avec la raison de chaque refus, est en annexe de [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md).

## 4. Processus, stockage, cycle de vie (N0)

| Domaine | Ce qui est disponible |
|---|---|
| Processus | Un processus `web`, port ≥ 1024, sonde HTTP (`healthcheck`), une réplique. En Node, PHP et Go (v2.56.0) : jusqu'à 8 processus, workers et crons chacun dans son propre pod avec sa commande (`argv`), même image, mêmes variables et services ; un `release` joué une fois dans son pod avant chaque déploiement (son échec l'annule, la version en service reste) ; pas encore à côté d'un cycle de vie (`ENV_PROCESS_LAUNCH_UNSUPPORTED`). Sans web (Node ; Go depuis les catalogues 2026.10.25.go.11 et 2026.10.25.go126.3, v2.57.0) : le premier worker ou cron, sans port ni route, sondé par sa commande (`exec`) ou un port local (`tcp`) ; une app faite seulement de crons (v2.57.1) a sa release prête quand ses CronJobs la portent sur son image, et se lit `scheduled`. Workers et crons par intervalle dans le conteneur du web (`mode` `in-process`), dans toutes les recettes ; en Python fermé et Ruby, un web et jusqu'à 7 workers `in-process`, supervisés ensemble ; arrêt du groupe en 120 s au plus. Un `job` n'est pas encore lancé. |
| Ressources | `resources.cpu`, `memory`, `cpu_limit`, `memory_limit`. Un pod qui demande plus que n'alloue le plus grand nœud est refusé avant le build, au push comme à `paas builds rebuild` (`N0_RESOURCES_LARGER_THAN_NODES`, v2.38.1), avec une demande qui tient. |
| Temps de build | Budgets publiés par étape : prepare 600 s, build 3 600 s, tests 2 100 s, build entier 3 600 s ; `build.resources.timeout_seconds` (60 à 21 600 s) relève prepare et build (v2.38.0) ; `paas config plan` les affiche ; un dépassement nomme l'étape, le budget et la durée. |
| Volumes | Jusqu'à 32, de 1 à 1024 Gio, `rwo` (`local-path`) ou `rwx` (`paas-cephfs`, jamais prouvé). `preserve_on_delete=true` obligatoire ; supprimer l'app garde le volume. Une réplique avec un volume rwo. Un volume réservé déplacé est refusé au gel du plan (`ENV_STORAGE_RESERVED_VOLUME_CHANGED`). |
| Liens et copies | `storage.links` (chemin de l'app vers un volume ; en Node et Go depuis v2.56.0, posé par l'étape de finition, sa cible créée au démarrage), `storage.seeds` (copie initiale `absent-only` ; v2.81.73 : `always`, la destination remplacée par celle de l'image à chaque démarrage, ou `once`, une fois par commit, qui demande `lifecycle.state_directory` ; ce que l'instance écrit dans une telle destination est remplacé, rien hors d'elle n'est touché). En PHP, `storage.writable` (v2.56.0) rend inscriptibles `/app` ou 16 chemins de l'arbre au plus, sans rendre inscriptibles les fichiers de l'image ; rien n'y persiste d'un démarrage à l'autre. `storage.private` n'est pas raccordé (refusé par la projection, mesuré le 2026-10-15) ; la variable de gabarit `{{storage.private}}` existe. |
| Variables | `env` (gabarits `{{…}}` : secrets, services, app), `env_stages`, `files` (rendus au build ou au démarrage). `http_endpoints` : recette npm stable seulement, chaque `target_port` égal au port du process web ; refusé en PHP (`ENV_COMPONENTS_REQUIRE_SEPARATE_QUALIFICATION`). |
| Comptes | `account` et `accounts` : compte d'administration créé par une commande native ou un formulaire, mot de passe par l'entrée standard. PHP : un contrôle `ready` doit lire le compte (`ENV_TECHNICAL_ACCOUNT_CHECK_REQUIRED`). Node npm : avec un service déclaré seulement (moteur de `paas-entry`), comptes supplémentaires par HTTP. |
| Cycle de vie | `install`, `prepare`, `upgrade` (commandes natives, entrée standard jusqu'à 16 Kio) ; en PHP `install_http`, `install_php`, verrou (`lock`) et reprise (`interrupted`) ; en Python fermé `install_python` ; `checks` (SQL en lecture seule), `file_checks`, `http_checks`, `mail_sink`, `start_files`, `init` (script du dépôt avant le serveur). Node npm : sans service, seule `init` est lue ; avec un service, le moteur de `paas-entry` lit `state_directory`, `install`, `upgrade`, `http_checks`, `mail_sink` et les comptes, et refuse `init` (mesuré le 2026-10-15). PHP, Python et Ruby (v2.81.74) : `http_checks` aussi, par leur entrée, à chaque démarrage avant de servir (PHP sur le serveur privé de son installation ; 60 s d'essais, v2.81.75). |
| Entrée HTTPS | Websockets acceptés, 100 Mo par requête, délais de 86 400 s, limite de débit par IP. Hôte de l'app : `apps-<8hex>.runtime.${PAAS_DOMAIN}`. Mot de passe de bordure (v2.56.0) : `edge.access.basic_auth_secret`, voir [PAASXML-SECURITE.md](PAASXML-SECURITE.md). |

## 5. Sécurité

Porte de l'image (0 CRITICAL, 0 HIGH non acceptées), politique CVE déclarée dans le `paas.xml` depuis v2.28.0
(`security.cve_exceptions` une par une, `security.block_on` `critical` ou `none`), exceptions de l'opérateur,
secrets scellés, chaîne de build et réseau : voir [PAASXML-SECURITE.md](PAASXML-SECURITE.md). Depuis v2.36.0, une seule politique
juge l'image servie (le pipeline relaie le verdict de la plateforme), et les constats du détecteur de secrets ont
leur propre porte, soumise à `block_on` : un constat HIGH ou CRITICAL bloque l'image, sauf s'il est accepté un par
un par `security.secret_exceptions` (règle, fichier, échéance, raison).

## 5 bis. Erreurs complètes (`paas.error.v1`, v2.28.0)

Un push, un build ou un déploiement qui échoue donne une erreur complète : l'étape, la cause, les détails et la
marche à suivre (commandes, extraits de `paas.xml` prêts à coller, documentation). La même erreur est servie par
l'API (`error` d'un déploiement, `failure` d'un build, `last_error` d'une app), affichée par la CLI (`paas deploy`,
`paas builds list`, `inspect`, `cve`, `paas apps info`, `paas status`) et par la console : en tête de chaque page de
l'app, dans l'encadré de la release de la page Overview (la cause à côté de « failed ») et sous chaque déploiement de
la page Deploys. Pendant un déploiement, la page se met à jour seule ; un code que la console ne connaît pas encore
est affiché avec tous ses détails, comme dans la CLI.

| Code | Étape | Ce que l'erreur donne |
|---|---|---|
| `plan_refused` | plan | Tous les diagnostics du fichier poussé (code, chemin, message). Depuis v2.29.2, un refus d'un contrôle de l'environnement de build (`ENV_…`) aussi, avec la clé du `paas.xml` qu'il lit et sa règle (section « Codes de refus de l'environnement de build » de `PAASXML-REFERENCE.md`), au lieu du seul code. |
| `build_step_failed`, `build_timed_out` | clone, prepare, build, scan, sign | La tâche et l'étape en échec, la fin du journal durable (`paas builds logs <build>`) ; depuis v2.29.2, le contrôle documenté qui a échoué dans le build, sa clé et sa règle (`details.refusal`). |
| `tests_failed` | test | La commande, son code de sortie, sa durée, l'image de test et la fin du journal (`paas builds test <build>`). |
| `security_scan_blocked` | scan | Chaque faille bloquante (paquet, versions installée et corrigée), la politique, ce qui est accepté, les extraits mode A et mode B. |
| `admission_*` | selon le code | La cause tirée de la preuve du build et la marche à suivre. |
| `rollout_failed` (v2.29.0) | rollout | La release ne reste pas prête, ou sa commande de release échoue : la cause (`oom_killed`, `probe_failed`, `process_exited`, `container_config`, `not_ready`, `unschedulable`, `volume_mount`, `image_pull`, `apply_refused`, `apply_timed_out`), l'état du conteneur, les avertissements, les sondes, la limite mémoire, la fin du journal du conteneur et la modification du `paas.xml` (mémoire doublée, sonde, secret manquant). |
| `database_not_ready` (v2.29.2) | rollout | Le build a réussi, mais une base réservée de l'app (MySQL, PostgreSQL, Redis, MongoDB, Meilisearch, OpenSearch, RabbitMQ, S3, LDAP) n'est pas prête après 120 s : rien n'est déployé. L'état du pod de la base, ses avertissements, la fin de son journal et la marche à suivre (base jamais initialisée : supprimer puis recréer l'app ; base lente : redéployer le même build). |

Depuis v2.31.0, chaque erreur dit qui doit agir : `Cust` quand le `paas.xml` ou le dépôt se corrige, `Paas` quand la
plateforme ne sait pas encore le faire, avec la capacité qui lui manque et la façon dont c'est établi (`paas config
plan` l'affiche aussi, `[Cust]` ou `[Paas]`). Les codes et leur règle sont dans la section « Codes de refus » de
[PAASXML-REFERENCE.md](PAASXML-REFERENCE.md).

## 5 ter. Disponible depuis v2.30.0 (en production le 2026-10-10)

| Sujet | Ce qui change |
|---|---|
| Placement des apps | Comportement de la plateforme, sans clé : chaque pod d'une app (web, autres processus, tâches de release, tâches ponctuelles, tâches planifiées) et chaque build `paas.xml` préfèrent les serveurs qui ne portent pas le control-plane (les nœuds de travail plutôt que le nœud du control-plane). C'est une préférence : un pod qui ne tient sur aucun autre serveur va quand même sur le nœud du control-plane. Un pod qui monte un volume `local-path` reste sur le serveur de ce volume, créé là où le premier pod de l'app a démarré : une app neuve s'installe donc hors du nœud du control-plane, une app existante à volume `local-path` reste où elle est ; une app sans volume ou à volume CephFS suit la préférence à son prochain déploiement. Les bases réservées ne changent pas encore de placement. Prouvé le 2026-10-10 : app neuve emoncms (build sur un nœud de travail, scan, volume, base et pod web sur un autre), reconstruction de ns-cve-304104 (build sur un nœud de travail, son pod web reste sur le nœud du control-plane avec son volume `local-path`). Les 55 caches de build qui retenaient des builds sur le nœud du control-plane ont été supprimés le même jour. |
| `network.linked_services` (N0.NET) | Noms des apps du même tenant que l'app appelle. Accepté par la projection (mesuré sur les dix recettes de la référence) et transmis au control-plane dans le manifeste généré. Il prend effet quand l'isolation entre apps (U1) sera activée : seuls ces liens seront alors admis. `network.ipv6`, `network.dedicated_ip` et `network.egress` restent refusés. |
| Recette npm (N1.NPMENV) | Le script de build tourne sans `NODE_ENV` (comme dans le terminal d'un développeur) après `npm ci --include=dev` : un bundler prend son mode production. L'installation de production et l'image servie gardent `NODE_ENV=production`. Toute app npm le prend à son prochain build. Prouvé sur Nightscout : bundle servi de 1,63 Mo au lieu de 9,28 Mo, aucune requête `/__webpack_hmr` au chargement (Chrome CDP). |
| `paas builds rebuild` | Reconstruit et redéploie le dernier commit poussé de la branche (`--branch`, `main` par défaut), sans commit vide : après des exceptions déclarées ou accordées, ou un correctif de la plateforme. Même requête que `paas deploy --force`. Prouvé en production sur ns-cve-304104. |

```xml
<network>
  <linked_services><item>litellm</item></linked_services>
</network>
```

## 5 quater. Disponible de v2.31.0 à v2.46.2 (en production du 2026-10-11 au 2026-10-16)

| Sujet | Ce qui change |
|---|---|
| Qui doit agir (v2.31.0) | `responsibility` de chaque erreur (`Cust` ou `Paas`, capacité manquante) ; `last_failure` de chaque app ; `paas config plan` marque chaque diagnostic `[Cust]` ou `[Paas]`. Un refus de limite dont le `paas.xml` peut déclarer le budget est côté client et nomme ce budget (v2.37.0). |
| Dockerfile (v2.33.0 à v2.35.0) | Un dépôt avec un `Dockerfile` à la racine, sans `paas.xml`, prend la voie native ; `build.runtime` `dockerfile` le construit depuis un `paas.xml` (tests, processus, sonde, ressources, politique CVE). Bases admises : outillage et images des recettes publiées (`paas builds bases`) ; `paas config plan` avertit quand l'étape finale part d'une image sans preuve de scan. |
| Arbre amont (v2.37.0) | Les verrous npm, Yarn et pnpm sont lus comme leur gestionnaire ; liens internes, `.gitattributes`, `.gitmodules` vendus et `.npmrc` sans effet sont admis ; `source.pinned` admet par empreinte un fichier inerte au nom réservé ; `source.limits` règle les budgets de lecture dans les plafonds (entrées 100 000, octets 4 Gio, manifestes et verrous 16 Mio, fichiers d'une archive 100 000) ; `source.ignore` laisse des fichiers de côté (32 au plus). Le plan joue chaque contrôle de la préparation, avec le même code et le même chemin. |
| PHP (v2.37.0 à v2.38.1) | Frontend précompilé servi tel que livré (`build.php.static_node_modules`, `build.php.development_manifests`) ; `composer.json` sans paquet sans verrou ; liens redéfinis par `storage.links` gardés dans l'export (v2.37.2) ; noms de variables de service en minuscules (v2.38.1). |
| Bases réservées (v2.36.0, v2.37.3) | Arrêtées avec leur app supprimée de façon réversible, volume conservé ; une nouvelle base MySQL va sur un nœud qui garde sa marge AIO ; une base d'un profil antérieur bloquée à l'initialisation reçoit le profil actuel au déploiement suivant. |
| Placement (v2.36.0, v2.38.1) | Un push dont les pods ne tiennent sur aucun nœud est refusé avant le build (`N0_CLUSTER_CAPACITY`) ; un pod plus grand que tout nœud aussi, au push comme à `paas builds rebuild` (`N0_RESOURCES_LARGER_THAN_NODES`). Une release jamais placée n'empêche plus la suivante. |
| Diagnostic (v2.37.4 à v2.38.4) | Une étape HTTP d'installation en échec publie sa requête, le statut, l'attente et le début de la réponse ; une compilation en échec cite les dernières lignes du compilateur ; une étape prepare illisible est rejouée une fois ; la SBOM refusée nomme le composant ; l'acquisition Composer nomme le paquet, l'adresse, le statut et ce que dit la forge, et une source que la forge ne sert plus est côté client (`ENV_COMPOSER_SOURCE_NOT_SERVED`, v2.38.2). La CLI affiche le code et le message de chaque refus de l'API, et une liste qui ne peut pas être lue est une erreur, jamais une liste vide ; les commandes que citent les messages de la plateforme sont vérifiées contre la CLI (v2.38.3), comme celles de cette bibliothèque (v2.38.4). Le frontend Node d'un build Go qui omet `build.node.version` ou `build.node.entrypoint` nomme la clé manquante au lieu d'une erreur interne (v2.38.4). |
| États cohérents (v2.38.1 à v2.38.4) | Un build refusé à l'admission ou avant son pipeline est clos (plus de « pending ») ; refusé avant son pipeline, il est `failed` dans `paas builds list` avec son refus, et ses tests sont `not_run` (v2.38.3), comme ceux d'un build en échec avant ses tests, au clone, à la préparation ou au build (v2.38.4) ; en pnpm et en Go, des copies `storage.seeds` sans `lifecycle.state_directory` sont refusées, au lieu d'être acceptées puis ignorées (v2.38.4) ; une release dont la fenêtre de stabilité est coupée par un redémarrage de la plateforme est jugée là où elle tourne, sans second déploiement ; la mise à l'échelle d'une app sans release en service nomme la dernière release, son état et sa raison. |
| Exécution ponctuelle (v2.38.0) | `paas run`, la mise à l'échelle et le redémarrage sont admis pendant la fenêtre de stabilité d'une release servie. |
| Index des codes de refus (v2.38.6, complété en v2.39.2 et v2.39.3) | Chaque code `ENV_…` que la plateforme peut rendre a sa ligne : clé ou fichier lu, règle, qui agit (`Cust` ou `Paas` et la capacité manquante, présumée quand le contrôle ne peut pas trancher) ; 1 413 lignes, exigées par un test généré qui lit aussi les scripts écrits dans les Tasks (v2.39.3). Chaque code `admission_…` a son texte. Quatre contrôles qui mêlaient un manque de la plateforme et une faute du dépôt ont chacun deux codes : `ENV_HEALTHCHECK_UNSUPPORTED`, `ENV_TECHNICAL_LIFECYCLE_BACKUP_UNSUPPORTED`, `ENV_TECHNICAL_HTTP_INSTALL_STEP`, `ENV_TECHNICAL_RUNTIME_OPTIONS_UNSUPPORTED`. La table complète est en annexe de [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md). |
| Monorepo (v2.39.0, lu au push depuis v2.39.1) | `source.root` nomme le sous-répertoire de l'app : seul ce sous-arbre est lu, compté et exporté, ses chemins relatifs à lui, comme chaque chemin du paas.xml ; la configuration reste à la racine du dépôt et le commit est inchangé. Un répertoire réservé, sans fichier ou avec sa propre configuration est refusé en le nommant (`ENV_SOURCE_ROOT_INVALID`, `ENV_SOURCE_ROOT_MISSING`, `ENV_SOURCE_ROOT_CONFIGURATION`). Mesuré : une app Node poussée sous `apps/web/` sert son seul sous-arbre. Voie Dockerfile : non raccordée. |
| Node : membres, fichiers, pnpm (v2.39.0) | npm : `build.node.production_members` n'installe pour la production que les membres déclarés du workspace (`.` : le projet racine), mesuré avec npm 11.19.0. pnpm : `build.node.required_runtime_files` est vérifié après l'installation de production, et `build.node.package_manager_version` choisit un pnpm publié par la recette, le même que celui qu'épingle le `packageManager` du package.json s'il en épingle un (`ENV_PNPM_MANAGER_VERSION_CONFLICT`, `ENV_PNPM_MANAGER_VERSION_UNPUBLISHED`). |
| Préparation par défaut (v2.39.2) | Site statique, Python avec ses roues dans Git, Node préconstruit : `source.ignore`, `source.pinned` et `source.limits` y sont appliqués comme pour les autres recettes (un `.env` épinglé est copié comme donnée, jamais servi ; un fichier laissé de côté n'est ni compté ni exporté ; les budgets déclarés remplacent 10 000 entrées et 256 Mio). Le plan et le push jouent ses contrôles : un lien symbolique, un nom réservé ou un budget dépassé est refusé dès `paas config plan`, avec le code et le chemin. Mesuré : un site statique poussé avec un `.env` épinglé et une page laissée de côté se construit et sert, la page répond 404. |
| Sites statiques sur leur ligne (v2.39.3) | La recette `static-nginx-1.30.6-alpine3.24-v1`, catalogue `2026.10.15.static.1` (ligne `static`) : nginx 1.30.6, pcre2 corrigé ; la 1.30.4 de toutes les autres lignes est refusée par la porte CVE par défaut depuis le 2026-10-15. Mesuré : un site poussé sur cette ligne se construit sans exception de sécurité et sert ses pages. |
| pnpm comme données (v2.40.0 à v2.40.3) | La ligne Node 24 pnpm publie, comme données de son catalogue (`2026.10.15.node.8`), pnpm 10.34.6, 11.10.0, 11.20.0, 11.21.0, 11.24.0, 11.27.1, 11.28.2, 12.3.4, 12.4.2, 12.5.1, 12.6.0, 12.8.2, 12.9.1 et 12.11.2. L'épingle `packageManager` est servie par sa version, ou par la dernière version publiée de sa majeure (10.15.1, 10.27.0, 10.28.0 et 11.9.0 par 10.34.6 et 11.28.2 : leurs versions ont trois HIGH sur le verrou installé) ; sans épingle, par le pnpm que la ligne sert pour le format du verrou (9.0 : 10.34.6), qui doit satisfaire `engines.pnpm` ; `build.node.package_manager_version` l'emporte. La preuve du build note l'épingle et la version servie. pnpm 10 lit les overrides de package.json ; avec lui, un `.npmrc` qui fixe `use-node-version` est refusé. Un catalogue antérieur garde ses versions. Un override écrit `catalog:` ou `catalog:<nom>` vaut la version que le catalogue de l'espace de travail donne au paquet, comme pour pnpm (v2.40.2). `pnpm-workspace.yaml` admet, au plan comme à la préparation, les réglages sans effet sur ce qui est téléchargé, dont ceux du `.npmrc` inerte écrits comme pnpm 10 et suivants les écrivent (`publicHoistPattern`, `shamefullyHoist`, `nodeLinker`, `linkWorkspacePackages`…) ; tout autre réglage est refusé au plan, nommé (`ENV_PNPM_WORKSPACE_SETTING_UNSUPPORTED`, v2.40.3). |
| Frontend pnpm d'un build Go dans un sous-dossier (v2.40.0, v2.40.2) | `build.node.root` (`web`) : le projet pnpm y est lu (verrou, espace de travail, `.npmrc`), installé et construit avec le pnpm de son épingle ; les sorties (`build.node.outputs`, `web/dist`) restent relatives à la racine ; catalogue `2026.10.15.go.7` ou suivant. Le pnpm du frontend est l'un de ceux que porte l'image de préparation de la recette Go du catalogue nommé : un catalogue antérieur à sa publication est refusé au plan, et le message nomme le catalogue courant (`ENV_GO_FRONTEND_PNPM_UNAVAILABLE`, `2026.10.16.go.8`, v2.40.2). Un dossier sans verrou est refusé en nommant le verrou attendu. Le module d'entrée de ce frontend peut être `.tsx` ou `.jsx`. |
| Module Node lancé (v2.41.0) | En npm comme en pnpm, `argv` lance `node <module> [arguments]` (16 arguments au plus) où le module est : un fichier du dépôt (module `.js`, `.mjs`, `.cjs`, `.ts`, `.mts`, ou lanceur sans suffixe nommé par le `bin` de son package.json ou ouvert par un shebang node, `packages/cli/bin/n8n`) ; un module produit par le build sous une sortie déclarée (`build.node.outputs`, `dist/server/main.js`), que le build exige (`ENV_NODE_LAYOUT_REQUIRED_MISSING`) ; le binaire déclaré d'une dépendance de production (`node_modules/next/dist/bin/next`), confirmé par le verrou puis par le `bin` installé (`ENV_NODE_LAUNCHER_INVALID`). Prouvé : t0410 (les cinq formes, dont l'échec attendu), portkey sans greffe de `build/`. `pnpm-workspace.yaml` admet aussi les réglages relevés dans les arbres et mesurés sans effet sur l'installation figée (hoist, symlink, pmOnFail sauf download, toute valeur de verifyDepsBeforeRun…) ; autoInstallPeers et injectWorkspacePackages valent ceux du verrou. |
| Scripts de build amont (v2.42.0, v2.42.1) | Le script de build est lu comme son gestionnaire le lance : `npm run S --ws` ou `-w <projet>`, `pnpm -r` ou `--filter <projet>` (nom, nom sans portée, ou `./dossier`), `turbo run S --filter` (tous les projets si la tâche dépend de `^S`) lancent le script des projets sélectionnés, avec ses crochets `pre` et `post` ; l'exécutable d'une dépendance que le verrou épingle pour le projet ou pour la racine (`tsx`, `turbo`, `nest`, `ng`), `npx`, `pnpm exec`, et une substitution `$(…)` simple sont lus. Une commande non résolue nomme son script et son programme. En npm, `build.node.build_exec` se déclare seul (`npm exec`, hors réseau). Prouvé : sync-in, construit par `npm run build --ws` (Nest et Angular). |
| Site construit par npm ou pnpm (v2.43.0) | `build.static.publish_root` dans une recette npm ou pnpm : le build (`build.node.build_script` ou `build_exec`, installation hors réseau depuis le verrou) produit le dossier, que seul le serveur HTTP de la plateforme sert (nginx de la ligne statique, racine en lecture seule) ; aucun processus Node, aucune autre sortie, ni service, ni volume, ni secret. La fin du build vérifie l'index.html du dossier. Prouvé : digitranscode, litechat, bentopdf (npm, Vite), t0430 (pnpm). |
| Archive de release publiée (v2.43.0) | Runtime static : `build.static.archive` (url d'un fichier de release GitHub, sha256, root facultatif) remplace un dossier de l'arbre ; la préparation l'acquiert (une redirection, vers l'hôte des archives de GitHub), vérifie la SHA-256 et chaque entrée, puis publie le dossier. Prouvé : phanpy. |
| En-têtes de réponse d'un site (v2.43.0, v2.43.1) | `web.headers` (site publié seulement) : Cross-Origin-Opener-Policy, Cross-Origin-Embedder-Policy, Cross-Origin-Resource-Policy, Content-Security-Policy (et Report-Only), une fois chacun. X-Frame-Options, Referrer-Policy, Permissions-Policy, X-Content-Type-Options, HSTS et X-XSS-Protection sont imposés par la bordure à toutes les apps et refusés. Prouvé : COOP et COEP de digitranscode, en-têtes de bentopdf. |
| Archives npm hors registre (v2.43.1, v2.43.2) | `build.node.embedded_archives` : une archive .tgz du dépôt où qu'elle soit ; `build.node.remote_archives` : une archive https d'un autre hôte, par l'adresse exacte du verrou et sa SHA-256, acquise comme celles du registre (agent HTTP nommé). Gros paquets : `build.node.archive_profile` large-browser-assets-v1. Prouvé : bentopdf (xlsx de cdn.sheetjs.com, deux archives de vendor/). |
| Go 1.27.2 et variantes (v2.44.0) | Catalogue `2026.10.16.go.9` : chaque recette Go sur Go 1.27.2 (la stdlib de 1.27.1 porte trois HIGH) et l'outillage Wolfi v8 ; nouvelles variantes : git sans frontend (`runtime.packages` git), git avec un frontend npm, cgo (`build.go.cgo`) sans frontend, avec un frontend npm ou pnpm, servies par un runtime glibc 2.44 Wolfi. Une combinaison sans variante est refusée en nommant les variantes proches. `build.go.binaries[].tags` passe ses étiquettes à `go build -tags`. Prouvé : gogs (git), navidrome (cgo + npm, étiquettes), vikunja (cgo + pnpm). |
| vendor/ livré et replace en bloc (v2.44.0) | `build.go.vendor` : `verify` compare le vendor/ livré, fichier par fichier, à celui que l'acquisition vérifiée reconstitue depuis go.mod et go.sum, et nomme le premier module qui diffère ; `rebuild` le reconstitue. Le vendor/ livré n'entre jamais dans le build (ni son .env, ni son .gitmodules). `replace ( … )` en bloc admis, un répertoire refusé ; go.work reste refusé. Prouvé : plik (verify : 3 794 fichiers identiques ; v2.44.1 : le push ne lit plus rien sous le vendor/ déclaré). |
| Étapes de l'étage Go (v2.44.0) | `build.steps` d'un build Go (hors frontend Yarn) : un générateur à la version que go.mod requiert (`go run <module>/<paquet>@<version>`, ses modules acquis par la préparation et servis hors réseau), un paquet du module (`go run ./…`), un outil de go.mod (`go tool`), `cp` et `mkdir` ; dans l'ordre, avant `go build`, et rejouées avant les tests. go generate et tout shell sont refusés en nommant l'étape. Prouvé : readeck (templ generate, documentation), fathom (packr2 embarque le tableau de bord). |
| Verrou npm ancien (v2.44.0) | Les archives du registre officiel qu'un npm ancien enregistre en http sont acquises en https, vérifiées par l'intégrité du verrou ; un nom publié avant les minuscules obligatoires (JSONStream) est admis. |
| Extensions PHP (v2.45.0) | Catalogue `2026.10.16.php.24` : sqlite3, tidy et imap, chacune servie par sa recette (full-v10 et l'extension : `full-sqlite3-v12`, `full-tidy-v13`, `full-imap-v14`), choisie par `build.recipe` et ses 33 extensions dans l'ordre du catalogue. Le plan nomme une extension inconnue (`ENV_PHP_EXTENSION_UNKNOWN`), une extension qu'aucune recette ne porte (`ENV_PHP_EXTENSION_UNAVAILABLE`), la recette qui porte la liste déclarée (`ENV_PHP_RECIPE_EXTENSIONS_MISMATCH`), et, en `composer-install-lock-v1`, l'extension que le verrou exige et que l'image ne charge pas (`ENV_PHP_EXTENSION_UNDECLARED`). Prouvé : Wallos (sqlite3), Agorakit (imap, nommée au plan avec sa recette sur full-v10). |
| Sources Composer (v2.45.0) | Archives des instances GitLab publiques gitlab.com et framagit.org (l'archive de l'API au commit du verrou), comme api.github.com et codeberg.org. Dans un inventaire livré (`composer-layout-git-v4`), un paquet sans commit (branche, ou sans source) dont l'arbre livre les fichiers est admis, identifié par leur empreinte au reçu de préparation ; les refus nomment le fichier lu, le paquet et sa source. Prouvé : Agorakit (balping/json-raw-encoder depuis gitlab.com, au reçu de l'image) ; OJS planifié en inventaire livré sur l'archive exacte (citation-style-language/locales, branche master, 72 fichiers) ; v2.45.1 : une archive qui contient un lien interne au paquet est acquise (suin/php-rss-writer). |
| Greffons Composer (v2.45.0) | Ce qu'un greffon autorisé (`composer_plugins`) installe hors de `vendor/` (le thème d'Omeka S dans `themes/default`, les modules de `composer/installers`) entre dans l'image, avec son reçu `/opt/paas-dependencies/composer.install-paths.json`. `build.outputs` reste non raccordé en PHP. Prouvé : Omeka S sans greffe (thème au reçu, 25 fichiers ; /themes/default/asset/css/style.css servi). |
| Node servi par Yarn classique (v2.46.0 à v2.46.2) | Recette `node-24.20.0-yarn-classic-v1` (catalogue `2026.10.07.node-yarn.1`) : le projet racine, verrouillé par son yarn.lock (Yarn 1.22.22), est installé hors réseau depuis le miroir du verrou, sans script de dépendance ; construit par `build.node.build_script` ou `build_exec` ; ses `outputs` sont gardées après l'installation de production, `required_runtime_files` vérifiés, `runtime_exclude_paths` laissés hors de l'image ; lancé par `node <module>` (fichier de l'arbre, sortie du build, ou binaire déclaré d'une dépendance de production verrouillée). Services, cycle de vie (fichiers de démarrage, installation HTTP, comptes) et `lifecycle.init` comme en npm (paas-entry). La version de Yarn déclarée est lue avec le paas.xml : une autre Yarn classique est refusée (`ENV_TECHNICAL_YARN_VERSION`), Yarn berry (2 et suivants) est nommé comme recette non publiée. Prouvé : t0461 (PostgreSQL en TLS, installation HTTP, compte initial et compte supplémentaire), stable sans redémarrage. |
| Étapes d'un frontend Yarn (v2.46.0) | `build.steps` d'un frontend Yarn de build Go : une étape lance l'exécutable d'une dépendance que le package.json déclare et que le yarn.lock épingle (`node_modules/.bin`, hors réseau). Prouvé dans le pipeline : gotosocial 0.22.1 (`ts-patch install`) ; son build Go s'arrête ensuite, ses dépendances (go-xunsafe) exigeant Go < 1.27 (section 6). |
| vendor/ Go et .gitignore (v2.46.1) | `build.go.vendor` `verify` n'exige plus du vendor/ livré un fichier que `go mod vendor` écrit et que le .gitignore de l'arbre écarte de Git ; le reçu de préparation le nomme (gotosocial : trois `.envrc`). |
| Comptes et variables (v2.46.2) | Une étape qui lit `account.*` sans compte initial déclaré (`account`) est refusée au plan, qui nomme l'étape ; les étapes d'un compte supplémentaire lisent `user.*`. |

## 5 quinquies. Disponible de v2.47.0 à v2.48.1 (en production du 2026-10-17 au 2026-10-18)

| Sujet | Ce qui change |
|---|---|
| Images publiées tenues à jour (v2.47.0) | Chaque image que la plateforme publie (recettes, outillage, bases admises des Dockerfile) est rescannée chaque jour, et la révision corrigée qu'elle doit est suivie (`paas builds bases`). Un build refusé pour des failles de son image de base nomme la révision corrigée publiée. `paas apps security-updates <app> --mode manual|automatic` : en manuel (défaut), une alerte ; en automatique, la plateforme pousse un commit qui ne change que le `paas.xml`, le construit et le sert. |
| Routes refusées en PHP (v2.47.0) | `web.deny_routes` (32 au plus) : un chemin quelle que soit sa casse, son extension ou un `-` ou `_` en tête, et un paramètre de la chaîne de requête par nom et valeur, refusés (403) avant les règles de l'app. |
| npm, Yarn, pnpm (v2.47.0) | npm : `build.node.peer_dependencies` (`legacy`) ou le `.npmrc` ; le plan rend le verdict de `npm ci` sur les pairs du verrou. Étapes de build : le programme est l'exécutable que publie l'archive verrouillée. Yarn : npm dans l'image de compilation (catalogue `2026.10.17.node-yarn.2`). pnpm 10 garde le Node de la recette. |
| Valeurs que vous fournissez (v2.48.0) | `secrets.<NOM>.provide` (`tenant`) : la release, construite, testée, scannée et signée, les attend toutes (`awaiting_secrets`, erreur `secrets_not_provided`) ; `paas secrets provide NOM` (entrée standard ou fichier, jamais en argument) en fournit une, et la release repart sans nouveau push ; `paas secrets provided` dit leur état. |
| Releases et suivi (v2.48.0) | Release appliquée à 0 réplique (`paas scale web 0`) : publiée dormante (`scaled-zero`) ; `paas scale web 1` la sert. Fenêtre de stabilité à trois horloges (placement et tirage, démarrage, observation). `paas ps` : pods de la release courante ; `paas logs --since` ; `paas logs --process <nom>` : les lignes d'un processus par le nom que lui donne paas.xml, les exécutions d'un cron comprises (v2.73.12) ; journal de la release et audit de l'app. |
| Installation (v2.48.0) | Comptes initiaux créés après les contrôles HTTP, chaque étape réussie consignée ; une installation inachevée reprend, recommence ou s'arrête selon `lifecycle.interrupted`. Sortie des commandes install, prepare et init en échec publiée (secrets masqués). |
| Qui doit agir (v2.48.0, v2.48.1) | L'imputation est figée avec le verdict, avec ses règles et sa date ; la lecture des règles du jour s'affiche à côté (`now`). v2.48.1 : un refus causé par un manque publié de la plateforme (paquets de production d'un `vendor/` livré, frontal Node d'une app PHP) lui est imputé ; un contrôle déclaré (`lifecycle.checks`, `lifecycle.file_checks`) en échec publie la valeur obtenue et l'attendue, piste côté locataire. |
| Plans plus exacts (v2.48.0, v2.48.1) | Erreur de syntaxe XML nommée (ligne, colonne, balise), clé fautive gardée à la projection, fichier absent nommé. v2.48.1 : la recette à déclarer telle que le catalogue la publie (verrou d'un autre gestionnaire), chaque écart d'une variante Go nommé, chaque chemin de `build.frontend.paths` nommé avec ce qui le casse ; un plan PHP accepté en 2.47.1 que la croissance de l'entrée de 2.48.0 refusait se planifie de nouveau. |

## 5 sexies. Disponible de v2.49.0 à v2.49.7 (en production du 2026-10-18 au 2026-10-19)

| Sujet | Ce qui change |
|---|---|
| Base PostgreSQL héritée (v2.49.0) | Une app vivante qui a une base PostgreSQL créée par l’API des addons (`paas addons`) et qui déclare PostgreSQL dans son `paas.xml` la garde : la plateforme la reprend telle quelle (même cluster, mêmes données ; image, instances, stockage et rôles inchangés) au lieu de refuser le plan ; `DATABASE_URL` vient alors de la base réservée, sous TLS vérifié. Une base à plusieurs instances (plans business, enterprise) est refusée par son nom (`N2_LEGACY_POSTGRES_ADOPTION_SHAPE_UNSUPPORTED`) ; MySQL, Redis et MongoDB hérités restent refusés. |
| Mises à jour de sécurité : la méthode (v2.49.0) | En mode automatique, vous choisissez comment la révision corrigée arrive : `commit` (par défaut) l’intègre à la branche de l’app ; `branch` la sert depuis la branche de la plateforme et laisse la vôtre intacte (votre prochain push reconstruit avec la révision qu’il épingle). `paas apps security-updates <app> --method commit\|branch`, la page Sécurité de la console, ou `PUT /v1/apps/{app}/security-updates` (`{mode, method}`) ; `GET` rend les options offertes à l’app, chacune décrite. Une app construite depuis son Dockerfile garde l’alerte seule ; une app dont la plateforme pilote la configuration (N3) n’est servie que depuis sa branche de livraison. |
| Suppression d’une app (v2.49.0) | Une app supprimée reste restaurable pendant le délai de la corbeille (5 minutes aujourd’hui), puis tout ce qu’elle laisse est effacé, étape par étape, chacune revérifiée : processus, routage, services (réservés et hérités), volumes, images, dépôt Git, enregistrements. Ce qu’une app vivante utilise (dépôt, nom DNS) n’est jamais effacé. |
| Corrections (v2.49.0) | Une release réhabilitée (prête et stable après un premier verdict `crashloop`) ne montre plus son échec : une app servie n’a pas de dernière erreur. |

## 5 septies. Disponible depuis v2.50.0 et v2.50.1 (en production depuis le 2026-10-19)

| Sujet | Ce qui change |
|---|---|
| Yarn berry (v2.50.0) | Recette `node-24.20.0-yarn-berry-v1` (catalogue `2026.10.19.node-yarn.3`) : une app Node servie par Yarn 3 ou 4, et le frontend Yarn berry d’un build Go (lignes Go 1.26 et 1.27), installés hors ligne par le Yarn publié (3.2.1, 3.6.3, 3.8.7, 4.11.0, 4.13.0, 4.17.1, 4.18.1) depuis un miroir que la préparation remplit et vérifie. `enableScripts: false` et `nodeLinker: node-modules` imposés ; un `yarnPath` commité est admis s’il est la release publiée (son empreinte) ; correctifs `patch:` appliqués hors réseau. Yarn exécute les scripts `preinstall`, `install` et `postinstall` du projet : le plan les lit comme des commandes du build. |
| Distribution Node installée (v2.50.0) | `build.node.dependency_mode` = `installed-git-v1` (avec `build.node.root` pour un projet sous la racine, `backend`) : un arbre qui livre son `node_modules` de production (paquet npm avec ses dépendances embarquées, sortie de `pnpm deploy`) est servi tel quel par la recette npm, sans téléchargement, installation ni build. Le plan vérifie l’arbre contre l’inventaire que le gestionnaire a laissé (pnpm : `.modules.yaml` et `.pnpm/lock.yaml` ; npm : `.package-lock.json` ; sinon les `package.json` installés), le build chaque manifeste installé (résolution de Node ; plages du semver de npm, `overrides` et `resolutions` appliqués, sans inventaire). Gestionnaire, verrou, archives et build sont refusés avec ce mode (`ENV_NODE_INSTALLED_OPTIONS`). |
| Build Node (v2.50.0) | `build.resources.node_heap_mb` (256 à 8192 Mo) fixe le tas du build en npm, pnpm et Yarn ; `build.env` et `build.steps` (commandes du build, chacune dans son dossier) en npm, pnpm, Yarn et frontends Go ; `build.node.projects` : autres projets npm que le build installe ; site produit par un build Yarn (`build.static.publish_root`) ; `build.node.runtime_dependencies` : devDependencies que le module servi charge au lancement, installées avec la production (npm). |
| Verrous et archives (v2.50.0) | `package-lock.json` version 1 (sha1) lu comme npm 7 et plus le lit ; archives Git npm d’une instance GitLab publique (`forge` = `gitlab`) ou de Codeberg ; dépendances `file:` de l’arbre et `devEngines.runtime` en pnpm ; réglages neutres de `pnpm-workspace.yaml` ; 128 fichiers lus par l’admission. Go 1.26.9 (catalogue `2026.10.19.go126.2`) pour les modules qui refusent Go 1.27. |
| Corrections (v2.50.0) | Moteur IMAP privé : image reconstruite et réépinglée (l’ancienne avait disparu du registre). Image d’exécution Node minimale : librt, libutil et libanl (modules natifs). pnpm : `engines.pnpm` choisit le pnpm publié ; verrou lu jusqu’à 16 Mio ; paquet d’archive Git ou distante refusé au plan, nommé. `ENV_AUTO_INPUT_INCOMPLETE` nomme le fichier en cause. |
| Corrections (v2.50.1) | Une réponse passagère d’un registre, d’une forge ou du proxy des modules Go (429, 500, 502, 503, 504) ou une coupure, à l’ouverture ou en cours de téléchargement, est retentée depuis zéro après 2 puis 4 s, trois essais au plus dans le temps de l’acquisition : paquets npm, Yarn classique et berry, archives Git, archive d’un site, PyPI, modules Go, pnpm. Toute autre réponse est refusée au premier essai ; le refus nomme la cause et les essais. Une indisponibilité qui dure n’est plus imputée à votre déclaration (`ENV_STATIC_ARCHIVE_UNAVAILABLE`, `ENV_GO_GENERATOR_ACQUISITION_UNAVAILABLE`). |

## 5 octies. Disponible depuis v2.51.0 à v2.51.3 (en production depuis le 2026-10-20)

| Sujet | Ce qui change |
|---|---|
| Paquets ajoutés, extras et groupes (v2.74.57) | `build.python.additional_packages` : des paquets du registre officiel, chacun à sa version exacte (`gunicorn==23.0.0`), 16 au plus, ajoutés à la liste que la plateforme produit : un serveur que le projet laisse à son déploiement ; à côté d'une liste exacte de l'arbre, ils sont refusés (`ENV_PYTHON_ADDITIONAL_PACKAGE_UNUSED`). `build.python.extras` et `build.python.dependency_groups` : ce que le projet déclare à côté de ses dépendances de production, lu dans `uv.lock`, `poetry.lock` ou la liste produite. Une liste produite avec d'autres valeurs est périmée (`ENV_DEPENDENCY_LIST_STALE`). |
| Recette Python simple (v2.51.0) | La recette Python simple lit le `paas.xml` : `build.python`, `build.env`, `build.steps`, cycle de vie (`lifecycle.*`), comptes, processus internes ; PostgreSQL 16 en TLS vérifié (par le pilote de l’app : psycopg 3 ou psycopg2) et Redis 7.4. Listes figées lues depuis `poetry.lock`, `uv.lock`, `Pipfile.lock` ou un `requirements.txt` épinglé avec ses empreintes. Un paquet sans roue pour l’interpréteur se déclare dans `build.python.source_builds` : il est construit depuis le sdist épinglé, hors réseau, et les bibliothèques que la réparation intègre à la roue sont analysées par le scan. Montages persistants ; Dockerfile amont déclarable (`build.source_dockerfile`). |
| Listes de dépendances produites par la plateforme (v2.51.0, EX-23) | Un arbre sans liste exacte (npm sans `package-lock.json`, Python à plages ou sans empreintes dans `requirements.txt`, `pyproject.toml` ou `setup.cfg`, Composer sans `composer.lock`) n’a rien à ajouter : au push, la plateforme résout la liste une fois, depuis le registre officiel, avec les empreintes, et l’écrit dans le Git de l’app (`paas/dependencies/`, provenance `paas/dependencies.json`) sur la branche `paas/dependency-list/<id>`. Mode `automatic` (par défaut) : intégrée à votre branche par avance rapide ; `manual` : proposée, acceptée par `paas dependencies accept`. La liste est figée : chaque build l’installe hors réseau, le reçu dit qu’elle vient de la plateforme ; elle ne change que sur demande (`paas dependencies produce`). Liste modifiée, périmée ou d’une autre app : refusée par son nom. CLI `paas dependencies list\|show\|produce\|accept\|mode`, page Sécurité de la console, API `/v1/apps/{app}/dependency-lists`. |
| Verrou Yarn réparé (v2.51.0, R-0090.3) | Frontend Yarn 1 d’un build Go dont le `yarn.lock` a des entrées hors de leur plage : la plateforme les répare une fois de la même façon (registre, empreintes, plan, reçu). Votre `yarn.lock` n’est pas modifié ; les builds suivants installent la liste réparée hors réseau. |
| Manifeste npm hors racine (v2.51.0) | `build.node.manifest` nomme le `package.json` qu’un arbre garde sous la racine (`install/package.json`), pour un projet npm à la racine sans `package.json` : la préparation le place à la racine de la copie de build, le reçu le nomme. |
| Corrections (v2.51.0) | Composer : un métapaquet est admis dans un verrou, sans archive à acquérir. |
| Corrections (v2.51.1) | Listes npm et Yarn produites : les résolveurs s’exécutent en service (ils sortaient sans résultat). Constructions Python depuis la source : l’inventaire des bibliothèques intégrées est exporté là où la build écrit (la build échouait). `paas builds rebuild` d’un commit dont la liste est à produire la fait produire, comme un push ; un refus restant nomme `paas dependencies produce`. CLI : un build en échec à sa préparation se lit « failed ». |
| Corrections (v2.51.2) | Porte CVE : le refus du scan et les mises à jour de sécurité ne proposent une révision corrigée de la recette que si le dernier rescan quotidien de son image ne relève aucune faille CRITICAL ou HIGH et qu’elle est publiée après le catalogue du plan : une révision devenue vulnérable n’est plus proposée. `paas dependencies accept --app` accepte le nom de l’app. Mode `manual` : un push ou une reconstruction d’un commit dont la liste est proposée rejoint cette proposition, sans seconde production. Constructions Python depuis la source : l’inventaire des bibliothèques intégrées nomme le paquet source de chacune, que le scan rapproche des avis de sécurité. |
| Corrections (v2.51.3) | Liste des apps supprimées (`GET /v1/apps?lifecycle=deleted`, `paas apps deleted`) : servie par pages de 100 au plus (`limit`, `offset`, `meta.total`), les plus récemment supprimées d’abord, sans builds, installation ni panne ; la liste des apps ne lit plus ni SBOM ni journal de tests. Recette Python 3.12 Wolfi : la préparation tourne sur l’image de build de la recette ; sa révision de sécurité Python 3.12.15 sera utilisable une fois son catalogue publié. |

## 5 nonies. Disponible depuis v2.52.0 (en production depuis le 2026-10-22 ; corrections v2.52.1 et v2.52.2 le 2026-10-23)

| Sujet | Ce qui change |
|---|---|
| Services des apps Node et Go (v2.52.0, R-0019.1 à R-0019.3) | Redis 7.4 et MariaDB 11.8 à côté de PostgreSQL 16, MySQL 8.4 et MongoDB : trois services privés au plus, un de chaque réservation, et la capture du courrier. Redis : `persistence` `aof`, `eviction` `noeviction`, liaison `REDIS_URL` et `REDIS_SSL_CA` ; son `local_endpoint` ouvre un tunnel local en TLS vérifié. MariaDB : réservée comme MySQL avec son moteur, liée par `MYSQL_URL`. Image `paas-entry` de cette version. |
| Services des apps PHP (v2.52.0, EX-06, R-0019.3) | MariaDB 11.8, PostgreSQL 16 et Redis 7.4 en plus de MySQL 8.4 : trois services au plus, un de chaque réservation. L'entrée PHP lie et vérifie chacun avant de servir (PostgreSQL en `verify-full`, Redis en TLS avec AUTH). Avec un cycle de vie, PostgreSQL demande une recette à `pdo_pgsql`. Une app qui ajoute un service garde son installation. |
| Extensions PostgreSQL (v2.52.0, R-0019.6) | Toute liste des dix extensions de l'image publiée, chacune à sa version, sur tous les runtimes qui servent PostgreSQL. PostGIS et PostgreSQL 17 : pas encore. |
| Bases MySQL et MariaDB (v2.52.0, R-0029.3) | `databases` : sept bases nommées au plus, liées par `MYSQL_DATABASES_JSON` ; `privileges` `CREATE_DATABASE` : l'app crée ses bases `app_*`, aucune autre. PHP, Python simple, Node, Go. Fixés à la création du service. |
| Réglage serveur (v2.52.0, EX-07) | `options` `log_bin_trust_function_creators` à `true`, liste close ; le serveur réservé tourne sans journal binaire. |
| Corrections (v2.52.0) | Avec PostgreSQL et MySQL ou MariaDB, `DATABASE_URL` nomme toujours PostgreSQL : son ordre dépendait d'identifiants aléatoires (recette Python simple). |
| Corrections (v2.52.1) | Les préparations du build (PHP, Go, npm, pnpm, Node installé) admettent les profils de service composés comme le plan de contrôle : Redis en Go et en Node, MariaDB en PHP et en pnpm, bases nommées et droit `CREATE_DATABASE`, extensions PostgreSQL. Elles les refusaient en v2.52.0 (`ENV_AUTO_N2_PROFILE_IDENTITY`, `ENV_GO_N2_IDENTITY`, `ENV_NPM_N2_IDENTITY`, `ENV_PNPM_N2_IDENTITY`). |
| Corrections (v2.52.2) | Un service ajouté à une app déjà installée (un Redis à côté de sa base) garde l'instance en Node, Go, Python et Ruby, comme en PHP : l'entrée arrêtait chaque démarrage (`ENTRY_LIFECYCLE_IDENTITY_CHANGED`, `TECHNICAL_IDENTITY_CHANGED`). Un service retiré ou déplacé reste refusé. Image `paas-entry` de cette version. |

## 5 decies. Disponible depuis v2.56.0 (en production depuis le 2026-10-25)

| Sujet | Ce qui change |
|---|---|
| Borne haute de PHP (v2.74.57) | `build.php.composer_ignore_php_upper_bound` : un verrou dont les paquets s'arrêtent à un PHP plus ancien (`php <8.2`) s'installe sur le PHP de la recette (`--ignore-platform-req=php+`) ; la borne basse reste contrôlée. |
| Composer (R-0006, PR-0072, EX-12.2) | Inventaire `installed.json` au format de Composer 1 lu et analysé ; un `vendor/` livré avec ses paquets de développement entre dans l'image avec ses seuls paquets de production ; `build.php.composer_project` (projet Composer hors racine) ; archives sans commit épinglées par le `paas.xml` (`build.php.composer_archives`, `build.php.composer_archive_hosts`) ; `npm-asset` et `bower-asset` acquis du registre npm par leur intégrité ; `build.php.composer_moved` (un commit verrouillé lu dans le dépôt GitHub qui le sert encore) ; greffon `cweagans/composer-patches` déclaré, ses correctifs des fichiers de l'arbre. |
| Apps PHP (PR-0074, EX-16, R-0004.6) | `storage.writable` ; `web.extensionless` (`php`, `html` : une adresse sans extension servie par son fichier) ; `source.limits.private_paths`, la borne des chemins privés jusqu'à 128. |
| Frontaux npm de PHP et Ruby (PR-0033) | `build.frontend.mode = build-node-v1` : la plateforme construit le frontal npm, ses sorties seules entrent dans l'image ; en PHP, après Composer (`build.frontend.after_composer`), copié vers une cible déclarée (`build.frontend.target`, collisions nommées), `build.files` (fichiers qu'un amont fait créer avant son build) ; un projet npm sans verrou a le sien produit une fois ; projets npm à côté d'un projet sous la racine ; workspaces déclarés par motifs. |
| Gems Ruby (PR-0032) | Les gems du `Gemfile.lock` acquises depuis rubygems.org, vérifiées et installées hors réseau, sources GIT comprises ; un `Gemfile` sans verrou a son `Gemfile.lock` produit une fois par la plateforme ; `build.files` ; `build.ruby.bundle_with` (groupes facultatifs installés et chargés). |
| Installation et comptes (PR-0023) | Une étape HTTP déclare la cible du formulaire qu'elle lit (`action`) et lit des valeurs de sa réponse par une expression (`capture_regex` : un jeton anti-CSRF d'une page HTML), reprises dans le chemin d'une étape suivante, masquées où l'étape le dit ; l'entrée Ruby crée un compte par les formulaires de l'app, comme l'entrée PHP ; un compte se connecte avec un secret déclaré. |
| Mot de passe de bordure (EX-17) | `edge.access.basic_auth_secret`, toutes les recettes sauf le Dockerfile : voir [PAASXML-SECURITE.md](PAASXML-SECURITE.md). |
| Processus (PR-0026, EX-03) | Voir la section 4 : workers, crons et release dans leurs propres pods en Node, PHP et Go ; app sans web ; workers et crons du conteneur dans toutes les recettes ; la fenêtre de stabilité d'une release surveille chacun de ses processus. |
| Stockage (EX-18, EX-11.3) | `storage.links` en Node et Go ; `source.ignore_directories` : un dossier de l'arbre laissé de côté entier (ni lu, ni compté, ni exporté, ni dans l'image). |
| Sources (EX-14, R-0076.1) | `source.gitlinks` : chaque sous-module (chemin, URL https publique, commit ; 11 au plus) acquis à son commit par la préparation et inscrit au reçu (`gitlinks.json`) ; un sous-module privé se laisse de côté par `source.ignore_directories`. Arbres jusqu'à 100 000 fichiers et 200 000 entrées avec les dossiers, lus par le protocole Git ; au-delà, refus avec les deux comptes et les deux bornes. |
| Sites statiques (EX-15, EX-19) | `build.static.index` ; la racine du dépôt publiable ; les entrées cachées et les fichiers de la plateforme laissés de côté de tout dossier publié, inscrits au reçu. |
| Dockerfile (R-0025.1) | `build.dockerfile` : `path`, `context`, `target` ; bases tierces admises par la liste publiée, jamais une image d'application ; le Dockerfile lu comme BuildKit le lit. |
| Profils N3 et composition (R-0025.4, R-0025.2) | Un `paas.xml` qui nomme la recette d'un profil N3 (`seafile13-native-closure-v1`, `node24-pnpm11-python312-closure-v1`) est projeté sur le profil et jugé comme son `paas.toml` publié. `processes[].build` (l'image propre d'un processus) se déclare et se refuse à sa clé tant que la plateforme construit une image par push. |
| Corrections (v2.56.0) | Les plans PHP et Ruby techniques portent le code de leur préparation par son empreinte : une app replanifie à son prochain push. Un plan retenu par la détection nomme ses codes. Un champ de formulaire d'installation fait des seules liaisons publiques d'un service n'est pas un secret ; un secret composé avec du texte sous un nom sensible est admis, rendu entier comme secret. Une archive d'un hôte déclaré suit ses redirections https. |

## 5 undecies. Disponible depuis v2.57.0 (en production depuis le 2026-10-25)

| Sujet | Ce qui change |
|---|---|
| Go sans processus web (EX-03.1, PR-0026) | Chaque recette Go des catalogues `2026.10.25.go.11` et `2026.10.25.go126.3` publie les profils `web`, `worker` et `job` : une app Go dont le seul processus est un worker (sans port ni route, sondé par sa commande `healthcheck.type` `exec` ou par un port local `tcp`) est servie ; jusque-là refusée (`ENV_PROFILE_UNKNOWN`). Une app dont les seuls processus sont des crons est servie depuis v2.57.1 (section 5 duodecies). |
| Go 1.27.3 et 1.26.10 | Recettes `go-1.27.3-*` et `go-1.26.10-*` dans ces mêmes catalogues, mêmes variantes que les lignes 1.27 et 1.26 ; outillages de build v10, images d'exécution glibc et git révisées. Un `paas.xml` qui nomme un catalogue Go antérieur garde sa recette, mais son image ne passe plus la politique CVE par défaut : passer à `2026.10.25.go.11` ou `2026.10.25.go126.3`. |
| Ruby 3.4.11 | Les deux recettes Ruby en Ruby 3.4.11 : `2026.10.25.ruby.7` (`ruby34-bundler-offline-v2`), `2026.10.25.ruby.9` (`ruby34-pnpm-offline-v1`, pnpm 10.34.6) et `2026.10.25.ruby.8` (pnpm 10.34.5) ; une image d'exécution commune ; fermetures de dépendances inchangées. Avec ces catalogues, `build.runtime_version` vaut `3.4.11`. Un `paas.xml` qui nomme un catalogue Ruby antérieur garde sa recette, mais son image ne passe plus la politique CVE par défaut : passer à ces catalogues. Les catalogues `2026.10.25.ruby.4`, `2026.10.25.ruby.5` et `2026.10.25.ruby.6` ne construisent pas (`RUBY_RUNTIME_ABI_UNSUPPORTED`) : ne pas les nommer. |
| Suppression d'une app | La purge qui suit la corbeille retire chaque objet avec ce qui le contrôle ; un objet sans contrôleur est retiré lui-même ; la fiche de l'app attend que ses objets soient partis. |

## 5 duodecies. Disponible depuis v2.57.1 (en production depuis le 2026-10-25)

| Sujet | Ce qui change |
|---|---|
| Apps faites seulement de crons (EX-03) | Une app sans processus web dont les seuls processus sont des crons (Node en npm et pnpm depuis v2.73.11 ; Go avec les catalogues `2026.10.25.go.11` et `2026.10.25.go126.3`) est servie : sa release est prête quand ses CronJobs la portent sur son image, `paas releases list` la lit `scheduled`, et les commandes qui gardent l'image en service (`paas run`, …) passent. Jusqu'en v2.57.0, sa release échouait (`admission_runtime_missing_or_ambiguous`) alors que ses crons tournaient. v2.73.14 : l'app passe à l'état `scheduled` à la promotion de sa release (elle restait en attente du premier déploiement), les exécutions de ses crons ne font plus son état, et une exécution en échec est l'événement `cron.run_failed` de l'app ; `paas status` dit qu'elle n'a pas de métriques et nomme sa dernière exécution en échec. |
| Crons à côté du web | Une exécution de cron en cours ne fait plus refuser la mise en service d'une app qui a aussi un web (`admission_runtime_unattributed_pod`) : elle est rattachée à son cron. |
| Suppression d'une app | La purge retire aussi le cluster MySQL de l'app (InnoDBCluster), et ce que des apps déjà purgées ont laissé. |

## 5 terdecies. Disponible depuis v2.58.1 (en production depuis le 2026-10-25)

| Sujet | Ce qui change |
|---|---|
| Meilisearch (EX-05) | Une app Go ou Node (npm, pnpm) déclare `services.<nom>.type` `meilisearch`, version `1.46.0` : la plateforme lui réserve un serveur dédié sur son image, en TLS vérifié (l'autorité et le nom du service), sa clé maîtresse dans son environnement, 1 Gi gardé, accessible aux seuls pods de l'app. L'app reçoit `MEILI_URL`, `MEILI_MASTER_KEY` et `MEILI_SSL_CA` ; `local_endpoint` ouvre un relais HTTP sur 127.0.0.1 qui parle TLS vérifié au serveur. Un Meilisearch qui démarre retient la release dans la fenêtre des bases (`N2_MEILISEARCH_PENDING_RETRY_SAME_BUILD`), et l'erreur `database_not_ready` le nomme. |

## 5 quaterdecies. Disponible depuis v2.59.0 (en production depuis le 2026-10-26)

| Sujet | Ce qui change |
|---|---|
| PostGIS (R-0019.6) | Une app Python, Ruby, PHP, Node ou Go déclare `postgis` (seul, avec `postgis_topology` ou avec d'autres extensions publiées) dans `services.<nom>.extensions` d'un PostgreSQL `16` : la plateforme lui réserve son PostgreSQL sur son image PostGIS (PostGIS 3.6.4, pgvector 0.8.7), en TLS vérifié, les extensions créées à l'amorçage, 512 Mi. |
| Images des services | Les images des services réservés des apps (PostgreSQL, MySQL, MariaDB, Redis, MongoDB, Meilisearch) sont rescannées chaque jour avec les images publiées ; elles ne sont pas des bases de Dockerfile. |

## 5 quindecies. Disponible depuis v2.60.0 (en production depuis le 2026-10-26 ; LDAP depuis v2.60.1)

| Sujet | Ce qui change |
|---|---|
| OpenSearch, RabbitMQ, S3, LDAP (R-0019.4, EX-05) | Une app Go ou Node (npm, pnpm, Yarn) déclare `services.<nom>.type` `opensearch`, `rabbitmq`, `s3` ou `ldap` à sa version publiée : la plateforme lui réserve son serveur dédié sur son image, en TLS vérifié (l'autorité et le nom du service), un utilisateur et l'identifiant du service dans son environnement, 1 Gi gardé, accessible aux seuls pods de l'app. L'app reçoit l'URL, l'utilisateur, le mot de passe ou la clé, l'autorité et les valeurs fixes du service (section 2) ; `local_endpoint` ouvre un relais sur 127.0.0.1 qui parle TLS vérifié au serveur. Un service qui démarre retient la release dans la fenêtre des bases (`N2_<TYPE>_PENDING_RETRY_SAME_BUILD`), et l'erreur `database_not_ready` le nomme. |

## 5 sexdecies. Disponible depuis v2.61.0 (en production depuis le 2026-10-26 ; plus de trois services à la fois depuis v2.61.2)

| Sujet | Ce qui change |
|---|---|
| Services en PHP (R-0019.4, EX-05, R-0019.3) | Une app PHP déclare un service de chaque réservation : PostgreSQL ; MySQL ou MariaDB ; Redis ; Meilisearch ; OpenSearch ; RabbitMQ ; S3 ; LDAP (huit au plus, trois jusqu'à v2.60.1). L'entrée PHP lie chacun (URL, utilisateur, mot de passe ou clé, autorité) et le vérifie avant de servir ; `local_endpoint` lui ouvre un relais sur 127.0.0.1 qui parle TLS vérifié au serveur. En Node et Go, neuf au plus (MongoDB en plus). |
| Volume déclaré | `services.<nom>.storage` d'un service, base comprise (v2.74.52) : `1Gi`, `2Gi`, `5Gi`, `10Gi` ou `20Gi`, réservé à cette taille, dans tous les runtimes qui le servent. |
| Annuaire LDAP | Le serveur réservé tient les liaisons simultanées dans sa mémoire réservée (256 Mi). |
| PHP 8.4.27 (catalogue `2026.10.26.php.26`) | Les quatorze recettes PHP en 8.4.27 (`php-8.4.27-apache-alpine-…`, mêmes extensions que la recette 8.4.26 du même nom) : la 8.4.26 porte CVE-2026-109618 (CRITICAL) et CVE-2026-109619 (HIGH), que la porte CVE par défaut refuse. Un `paas.xml` passe `build.runtime_version` à `8.4.27`, `build.recipe` à la recette 8.4.27 et `build.catalogue` à `2026.10.26.php.26` ; un build refusé sur une recette 8.4.26 nomme sa correction. |

## 5 septdecies. Disponible depuis v2.62.0 (en production depuis le 2026-10-27)

| Sujet | Ce qui change |
|---|---|
| Services en Python (R-0019.4, EX-05, R-0019.3) | Une app Python, recette simple ou fermée, déclare un service de chaque réservation : PostgreSQL ; MySQL ou MariaDB ; Redis ; Meilisearch ; OpenSearch ; RabbitMQ ; S3 ; LDAP (huit au plus, trois jusqu'à v2.61.2), chaque service décrit avec le volume que sa déclaration nomme (`1Gi` à `20Gi`). L'entrée Python lie chacun (URL, utilisateur, mot de passe ou clé, autorité) et le vérifie avant de lancer l'app, par son protocole ; `local_endpoint` lui ouvre un relais sur 127.0.0.1 qui parle TLS vérifié au serveur, et la variable d'URL du service vise ce relais. |
| MySQL en Python | MySQL 8.4.10 se réserve pour une app Python, par sa norme publiée (le plan ne lisait que les variantes : MariaDB 11.8.9 seul). |
| Corrections | Le relais de l'entrée Python (Redis compris) mène chaque connexion jusqu'à sa fermeture ; l'environnement d'un service lit les valeurs de tout service déclaré. |
| PHP 8.4.27 | La révision de sécurité des recettes PHP (catalogue `2026.10.26.php.26`, section 5 sexdecies) figure au journal de cette version. |

## 5 octodecies. Disponible depuis v2.71.0 (en production depuis le 2026-10-31)

Le plan juge l'arbre que le build produit, pas le seul arbre Git.

| Sujet | Ce qui change |
|---|---|
| PHP : ce que Composer écrit (PR-0129) | `build.php.composer_written` déclare les fichiers et dossiers que l'installation Composer écrit dans l'arbre par ses greffons autorisés (`build.php.composer_plugins`, mode `composer-install-lock-v1`) : le contrôleur frontal et les fichiers de projet qu'un greffon de recettes copie, les ressources des modules qu'un greffon expose sous `public/_resources`. 16 chemins au plus, absents du dépôt, aucun dans un autre. Le plan les tient pour l'arbre (contrôleur frontal, racine web). Le build relève l'arbre avant l'installation et le compare après : une écriture non déclarée, un fichier du dépôt modifié ou retiré, un chemin déclaré absent, un lien hors de l'arbre refusent le build en les nommant ; les chemins déclarés entrent dans l'image avec leur reçu (`/opt/paas-dependencies/composer.written.json`). |
| PHP : page de la racine web | Sans contrôleur frontal déclaré, la racine web porte `index.php` (qui répond aussi aux adresses qui ne nomment aucun fichier), sinon un `index.html` ou le fichier que lit la sonde de santé (`healthcheck.path`), servis sans repli vers PHP. Un fichier écrit au build (`files` rendu au build, `build.php.composer_written`) compte, comme pour `web.front_controller`. |
| PHP : scripts du vendor | Une commande du cycle de vie ou de création de compte peut lancer un binaire qu'un paquet de production du verrou Composer déclare (`bin`), dans son paquet ou par son relais `vendor/bin` (`php vendor/bin/sake db:build`). |
| Node : module lancé (PR-0016) | Le module lancé peut être un fichier que le `paas.xml` rend au build (`files`, `render` build) ou une sortie déclarée du build elle-même (`build.node.outputs`, un fichier). |
| Sites statiques déclarés (PR-0131) | Une recette statique déclarée (runtime `static`) ne lit que sa configuration et le Dockerfile amont déclaré par son empreinte (`build.source_dockerfile`) : le projet à côté du dossier publié, son verrou et ses fichiers de build restent des données ; un `.gitattributes` qui ne transforme aucun fichier est une donnée de la préparation. |
| Corrections | Une recette déclarée répond par le refus exact de son plan (code et détail) au lieu d'un plan automatique non prêt ; le refus d'un fichier qui changerait le build le nomme. v2.71.1 : un projet dont le code vient tout entier de ses paquets Composer porte son source par les chemins de `build.php.composer_written` (l'admission Git le refusait) ; `paas config plan` refuse comme le push un commit sans source ; le refus d'un point d'entrée (`ENV_FILE_ENTRYPOINT_REQUIRED`) nomme l'argument et les formes du runtime ; `build.test.image` est décrit tel qu'il est : les tests tournent sur l'arbre Git, une recette standard dans sa propre image de test. v2.71.2 : un dossier que l'installation Composer crée au-dessus d'un chemin de `build.php.composer_written` ou d'un chemin d'installation d'un paquet (un thème installé dans `themes/<thème>`) n'est plus refusé comme écriture non déclarée (`ENV_PHP_COMPOSER_WRITTEN_UNDECLARED`). |

## 5 novodecies. Disponible depuis v2.72.0 (en production depuis le 2026-11-01)

Le build sans réseau sert ce que le projet télécharge et lance les scripts d'installation déclarés.

| Sujet | Ce qui change |
|---|---|
| Ressources téléchargées par le build (PR-0081) | `assets` déclare chaque ressource que le build télécharge : adresse https, SHA-256 et, au besoin, les en-têtes de la requête. La préparation les acquiert et les vérifie ; pendant le build, sans réseau, un miroir local les sert à leur adresse : dans les recettes pnpm, et en PHP à l'installation Composer des greffons déclarés (`build.php.composer_plugins`). Une adresse non déclarée est refusée et nommée (`ENV_ASSET_UNDECLARED`), un hôte que le build ne peut joindre aussi (`ENV_ASSET_HOST_UNDECLARED`, qui nomme l'hôte). `dest` n'est pas raccordé. |
| pnpm : scripts d'installation (T-05.4) | `build.node.install_scripts` nomme les paquets (`.` pour le projet) dont la plateforme lance elle-même les scripts d'installation, sans réseau et dans l'ordre déclaré, après l'installation qui les a tous ignorés : à la compilation, après l'installation de production et dans les tests. Ce qu'ils téléchargent vient des ressources déclarées. |
| PHP : recettes Symfony Flex (PR-0129) | Symfony Flex installe ses recettes depuis les ressources déclarées ; sans déclaration ni `symfony.lock`, le plan nomme les index à déclarer (`ENV_COMPOSER_FLEX_RECIPES_UNDECLARED`). Une commande du cycle de vie peut lancer un fichier déclaré dans `build.php.composer_written` (`bin/console`). Flex ne les appliquant qu'après `composer update`, la plateforme les installe elle-même depuis v2.73.0 (section 5 vicies). |
| Node : paquets au binaire natif (PR-0063) | Un paquet de production dont le binaire natif ne vient que de son script d'installation est refusé au plan, nommé avec sa version, son script et son binaire (`ENV_NODE_NATIVE_BINARY_UNAVAILABLE`), d'après une caractérisation publiée : `sqlite3` 4 et 5, `@louislam/sqlite3` 15, `sharp` avant 0.33, `bcrypt` 5. `build.node.native_unused` déclare ceux que l'application ne charge pas (npm, pnpm, Yarn classique) ; en pnpm, un paquet dont les scripts sont déclarés est couvert. |
| Node 22 et Node 16 (PR-0017) | Node 22.23.4 et Node 16.20.2 en npm (verrou source) et en Yarn classique, chacun sur sa ligne de catalogue (`node-npm-source-22`, `node-npm-source-16`, `node-yarn-22`, `node-yarn-16`), choisis par la recette déclarée (`build.recipe`) et le catalogue de sa ligne (`build.catalogue`) : section 2. Node 16, sans support de son éditeur depuis le 11/09/2023, est servi avec un avertissement du plan (`build.runtime_end_of_life`) ; son npm (11.19.0) tourne sur Node 22, hors du chemin des scripts, qui tournent sur Node 16. |
| Corrections | v2.72.1 : un plan pnpm qui déclare des ressources (`assets`) ou des scripts d'installation (`build.node.install_scripts`) n'est plus refusé pour sa taille (`ENV_PLAN_LIMIT`) : il voyage compressé, jusqu'à 128 Kio, comme ceux de npm, de Yarn et de Go ; un plan sans ces déclarations est inchangé. v2.72.2 : les scripts déclarés tournent aussi pour un paquet installé comme dépendance d'une dépendance, dans le magasin virtuel de pnpm (le moteur d'un ORM sous son outil en ligne de commande), dans chacune de ses copies installées, une fois chacune. v2.72.3 : un hôte qu'un build pnpm ou PHP sans réseau ne peut joindre est imputé au client et à la clé `assets` (`ENV_ASSET_HOST_UNDECLARED`, qui nomme l'hôte), et non plus à la plateforme. |

## 5 vicies. Disponible depuis v2.73.0 (en production depuis le 2026-11-01)

Les recettes Symfony Flex installées par la plateforme, le verrou npm complété depuis le registre, des refus dits en
entier.

| Sujet | Ce qui change |
|---|---|
| PHP : recettes Symfony Flex (PR-0129) | Avec `symfony/flex` parmi les greffons (`build.php.composer_plugins`), sans `symfony.lock` et avec des ressources déclarées (`assets`), la plateforme installe les recettes Flex juste après l'installation Composer (`composer recipes:install`), sans réseau, depuis les ressources déclarées : ses index, puis les recettes, que le build nomme (`ENV_ASSET_UNDECLARED`). Ce qu'elles écrivent dans l'arbre est nommé jusqu'à sa déclaration dans `build.php.composer_written`. Les fichiers de la racine où Flex tient ses sections (`.env` et ses variantes, `.gitignore`, `Makefile`, `phpunit.xml`, `symfony.lock`) sont mis de côté : l'image garde ceux du dépôt, le journal du build nomme les variables que les recettes ajoutent à un `.env` (jamais leurs valeurs), à déclarer dans `env` ou `secrets` si l'app les lit. Docker n'est jamais configuré. |
| PHP : dossier déclaré | Un dossier déclaré dans `build.php.composer_written` (`public`) tient pour le plan le contrôleur frontal et les scripts des commandes qui s'y trouvent ; le build vérifie après l'installation qu'ils ont été écrits (`ENV_PHP_COMPOSER_WRITTEN_MISSING`). |
| npm : entrée sans `resolved` (F10) | Une entrée du verrou qui porte son `integrity` sans `resolved` est l'archive du registre officiel à son nom et à sa version exacte, vérifiée par cette integrity, et le verrou que npm installe la reçoit ; `ENV_AUTO_NPM_RESOLVED_REQUIRED` ne vise plus que les entrées sans l'un ni l'autre (un instantané du registre les complète). |
| Diagnostics | Le refus d'une préparation est résumé par son code et son détail, et l'extrait du journal donne sa ligne au lieu de la pile Python. Un hôte injoignable dans une recette qui sert les ressources déclarées ne dit plus que la plateforme ne les fournit pas. Le rapport d'une commande du cycle de vie en échec donne les 5 premières lignes et les 15 dernières d'une sortie plus longue (« début et fin de sa sortie ») : le message d'une exception n'est plus perdu. |
| Tests sur l'arbre construit (v2.73.3) | `<tree>built</tree>` dans `build.test` (recette de la plateforme) : les tests tournent dans le dossier de travail de l'image construite et finie, tel qu'il est servi (les fichiers rendus au build, ce qu'écrit l'installation, les dépendances de production), sans rien réinstaller ; `source`, par défaut, garde l'arbre Git préparé. Un export qui échoue fait échouer le build (`ENV_TEST_TREE_EXPORT_FAILED`). |
| Corrections | v2.73.1 : les builds de Node 22 et de Node 16 en npm (verrou source) et en Yarn classique ne s'arrêtent plus à la préparation (`ENV_NPM_RECIPE_REQUIRED`) ; l'installation des recettes Symfony Flex ne lit plus les dépôts Composer du projet (Packagist compris), que l'étape de Flex qui suit les recettes interrogeait sans réseau : un dépôt Composer du projet n'a pas à être déclaré dans `assets`. v2.73.2 : une dépendance npm groupée transitive (marquée `inBundle`, livrée dans l'archive du paquet qui la groupe) n'est plus refusée à la préparation quand le plan l'admet. v2.73.3 : les tests voient l'environnement que déclare leur image de test (le `OPENSSL_CONF` de la chaîne Node 16, `SSL_CERT_FILE`, `GOFLAGS`…) ; des tests qui n'ont pas pu s'exécuter (préparation de la plateforme en échec) sont imputés à la plateforme (`tests_unavailable`), plus au client. v2.73.4 : PHP, un lien de stockage (`storage.links`) dont le chemin est écrit par l'installation Composer (`build.php.composer_written` : `var/`, `files/` des recettes Symfony Flex) remplace ce chemin au build ; il se posait dans le dossier écrit, qui restait celui de l'image. v2.73.5 : pour une app Go ou Node, une étape HTTP du cycle de vie qui attend une redirection (`expect_status` 3xx) lit la réponse même, sans la suivre ; une commande du cycle de vie en échec donne le début et la fin de sa sortie. v2.73.6 : pour une app Node (npm, Yarn, pnpm), une variable de `build.env` qui vaut exactement `{{app.public_url}}` ou `{{app.host}}` reçoit au build l'adresse de l'app, celle de la release, sous tout nom ; `build.secrets` est lu : chaque secret déclaré de l'app est monté en variable d'environnement sur les commandes du build seules, avec la valeur de la release (générée avant le premier build, scellée, fournie, factice déclaré), jamais dans une couche ni dans le plan ; avec l'un ou l'autre, les tests tournent sur l'arbre construit (`build.test.tree` = `built`). v2.73.7 : une app pnpm qui déclare `build.node.runtime_libraries` = `openssl3` (code natif qui charge OpenSSL 3, comme les moteurs de Prisma) sur la recette `node-24.20.0-pnpm-workspace-v3` du catalogue `2026.11.01.node-libraries.4` est servie par l'image minimale avec OpenSSL 3 (libssl3 3.0.22 de l'archive de sécurité de Debian), rien n'étant copié au build. v2.73.8 : l'export de l'arbre construit pour les tests (`build.test.tree` = `built`) est borné à 600 s (au-delà, le build échoue, nommé), et les étapes d'un build s'adressent au même démon BuildKit. v2.73.9 : en pnpm, l'arbre servi garde les liens de l'arbre de build dont il a déjà la cible : une dépendance de développement que la production installe aussi, que le code construit importe depuis le projet (Next.js et `prettier`), n'arrête plus l'app à son lancement. v2.73.10 : l'arbre construit des tests (`build.test.tree` = `built`) est extrait du registre par l'empreinte de l'image, sans démon BuildKit (toujours borné à 600 s). v2.73.11 : une app Node sans processus web (un worker sondé par sa commande, ou des crons seuls) est servie en npm et en pnpm, sans port ; jusque-là refusée au plan (`ENV_TECHNICAL_NODE_PORT`). v2.73.12 : `paas logs` montre les exécutions d'un cron, et `--process` trouve un processus par son nom même quand la plateforme le déploie sous son type (le cron ou le worker d'une app sans processus web). v2.73.13 : la recette `python-3.14.10-wolfi-v1` (catalogue `2026.11.02.python.1`) sert la ligne Python 3.14, ses étiquettes de roues mesurées dans sa chaîne de build, où se fait la préparation ; la recette `python-3.12.16-wolfi-v1` sur des images révisées (catalogue `2026.11.02.python.2`), sa chaîne avec les en-têtes des bibliothèques d'images ; un processus Python peut nommer un lanceur que l'app déclare ; `build.python.dependency_manager` pip sans `requirements.txt` produit la liste. v2.73.14 : ce lanceur passe la réception du push d'une configuration déclarée ; une liste produite à côté d'un `uv.lock` sert le gestionnaire déclaré. v2.73.15 : un lien de stockage Node sur un dossier que l'arbre livre n'arrête plus le build (EXDEV). v2.73.16 : une requête de l'installation HTTP PHP attend le délai déclaré, au lieu de 30 s. v2.73.17 : une étape juge la redirection qu'elle attend. v2.73.18 : un démarrage que l'entrée de la plateforme refuse le dit (son code et ce qu'il nomme) ; un POST dont le formulaire part ailleurs indique `direct` ; `lifecycle.install` et `lifecycle.install_http` se déclarent ensemble en PHP. |

## 5 unvicies. Disponible de v2.74.4 à v2.74.16 (en production depuis le 2026-11-03)

Ce qui manquait aux dernières apps : Go et son code généré, les verrous npm et pnpm tels que l'amont les écrit, les modules natifs en npm et en Yarn, Node 14 et 16 pour les vieux frontaux, les grandes images.

| Sujet | Ce qui change |
|---|---|
| Go | Les étapes déclarées qui génèrent du code (`go run`, `templ generate`) tournent avec les modules vérifiés, `go.mod` et `go.sum` en lecture seule, puis l'étage refait `go mod vendor`. Un module que rien n'importe n'a plus à figurer dans `go.sum` par son contenu ; un module sans `require` n'a ni `go.sum` ni vendor à fournir. Un frontend sur un autre Node que celui de la recette (`build.node.version`) n'est pas reconstruit pour les tests |
| pnpm | Une archive de commit GitHub ou une archive https épinglée par son SHA-512 s'acquiert et s'installe hors réseau ; un nom de paquet en majuscules passe ; limites nommées (256 Mio par paquet, 1 Gio décompressé, 2 Gio en tout) ; une étape dans le dossier d'un membre du workspace lit les programmes de ses scripts chez ce membre ; un verrou peut porter le SHA-1 exact qu'enregistre un ancien paquet du registre |
| `build.node.runtime_dependencies` (pnpm) | Comme en npm : les dépendances de développement qu'un processus servi lit (la CLI d'une migration, `prisma migrate deploy`) sont installées avec la production, avec ce dont elles dépendent ; chaque nom est une dépendance de développement d'un membre installé (`ENV_PNPM_RUNTIME_DEPENDENCY_UNDECLARED`) |
| npm : verrous | Un verrou dont des paquets n'ont ni `resolved` ni `integrity` est complété une fois par la plateforme (`paas/dependencies/package-lock.json`, à ses versions), sans instantané publié par application ; un projet qui groupe ses propres dépendances (`bundleDependencies` à sa racine) est admis |
| npm et Yarn : modules natifs | `build.node.install_scripts` et `assets`, comme en pnpm : les scripts déclarés tournent après l'installation hors réseau, sous le miroir des ressources déclarées (sqlite3, sharp, bcrypt). En PHP aussi, pour le frontal (`build.frontend.mode = build-node-v1`) |
| `build.node.runtime_tools` (npm) | `npx` : l'image reçoit un `npx` qui lance un exécutable des dépendances installées, celles de `runtime_dependencies` comprises, et ne télécharge rien |
| Node 14 et 16 | La ligne `node-npm-source-14` (`node-14.21.3-npm-source-v2`), pour ce qu'aucun Node récent ne construit (node-sass 4) ; Node 14 n'a plus de support : le catalogue le dit, et la porte CVE des applications reste. Le frontal npm d'une recette PHP ou Go se construit sur le Node majeur que nomme `build.node.version` |
| `build.steps` | Une étape peut lancer `touch` sur un chemin de l'arbre : un fichier vide que le build attend et que l'amont demande de créer (`.env.production`) |
| Python | Une construction depuis les sources est réparée pour la glibc mesurée de l'image (`manylinux_2_44`) ; un source C ancien que GCC 14 refuse se construit avec `CFLAGS = -fpermissive` dans `build.python.source_builds[].env` ; le nom et la version de l'application sont enregistrés (`importlib.metadata`) ; catalogue `2026.11.03.python.3` : en-têtes d'OpenLDAP et de SASL ; une liste de plusieurs centaines de paquets tient dans le plan (`ENV_PLAN_TRANSPORT_LIMIT`) |
| Sites Node | `build.static.publish_root` peut nommer un dossier que le framework cache (`.output/public`, `.vitepress/dist`) |
| `build.resources` | `cpu` et `memory` disent ce dont un build a besoin : admis jusqu'à 8 CPU et 24 Gio, ce que le constructeur partagé offre à un build, refusés au plan au-delà (`ENV_BUILD_RESOURCES_BEYOND_BUILDER`) ; rien n'est réservé |
| `build.test.tree` | Le plan nomme le fichier rendu au build que lit un test de l'arbre Git (`ENV_TEST_TREE_RENDERED_FILE`) ou que déclare une liste du build (`ENV_BUILD_OUTPUT_RENDERED`) |
| `healthcheck.type = tcp` | Un processus web se sonde par son port : une app entièrement derrière une authentification répond 401 à toute sonde HTTP |
| PHP : installation | Le serveur privé d'une installation HTTP sert un `build.php.front_controller` placé sous la racine comme la production ; il envoie `User-Agent` et `Accept`, comme un navigateur ; le formulaire d'un compte supplémentaire déjà créé n'est plus rejoué quand les contrôles `ready` prouvent le résultat ; une réponse 5xx ou vide montre ce que le PHP a écrit, le message d'une erreur fatale compris ; un client du relais MySQL (`local_endpoint`) ne reçoit plus `MYSQL_SSL_CA` ; une commande du cycle de vie peut lancer un script que le paas.xml rend au build (`files`) |
| MySQL réservé | Le mot de passe d'application d'une réservation nouvelle tient en 32 caractères (128 bits aléatoires) : le formulaire d'un ancien installateur qui s'arrête là le lit ; une réservation qui existe garde le sien |
| `source.limits.tree_entries` | Jusqu'à 200 000 entrées |
| API | `GET /v1/apps/{id}?include_deleted=true` lit une app de la corbeille par son identifiant, dans le tenant de l'appelant |
| Plateforme | Le plan d'un grand monorepo pnpm passe de 36 s à 1 s, et le plan de contrôle répond pendant qu'il planifie ; le constructeur offre 8 CPU et 24 Gio ; le SBOM d'une image de plusieurs centaines de milliers de fichiers ne dépasse plus le délai de sa tâche (syft 1.56.0, 3 minutes au lieu de plus d'une heure) ; une tâche qui échoue après la construction de l'image n'est plus lue dans le journal de cette construction |

## 5 duovicies. Disponible de v2.74.17 à v2.74.21 (en production depuis le 2026-11-03)

Les derniers manques des apps du relevé, et les diagnostics que le rejeu de la campagne WordPress a encore trouvés.

| Sujet | Ce qui change |
|---|---|
| Go | Catalogues `2026.11.03.go.12` et `2026.11.03.go126.4` : l'image d'exécution d'une recette cgo porte libstdc++ |
| `storage.removable` (PHP) | Un dossier de l'arbre que l'application supprime elle-même (son `install/` une fois installée), remis au service |
| Python simple | Tous les programmes que déclare le projet (`[project.scripts]`) ont leur lanceur ; une app qui ne déclare ni variable, ni secret, ni cycle de vie démarre et reçoit son adresse |
| MariaDB | Le relais local de `services.<nom>.local_endpoint` sert MariaDB comme MySQL, en clair sur 127.0.0.1, en Node et en Go |
| Node et Go (paas-entry) | `lifecycle.*.stdin_template` et `lifecycle.*.env` ; un compte supplémentaire par commande native (`accounts.create`), son mot de passe sur l'entrée, jamais dans ses arguments ; la première exécution en échec gardée à côté de la dernière |
| PHP : installation | Un POST relu poste ce qu'un navigateur envoie du formulaire (champs texte, cases, options) ; une installation jamais finie accepte un nouveau compte initial ; `lifecycle.interrupted` `restart` et `refuse` ; un compte n'est inscrit au journal qu'avec une preuve ; un compte peut poster du JSON directement (`direct` avec `json`) |
| `paas config plan` | Code de sortie 3 quand le seul refus est une liste de dépendances à produire ; un `paas.xml` pas encore commité est planifié comme le push le trouvera ; une préparation des tests de plus de 8 Kio est refusée (`ENV_TEST_SETUP_LIMIT`, voie : `build.test.tree built`) |
| pnpm sous turbo | Le pnpm relancé reste sur la version servie, même en mode strict ; `--env-mode=loose` reste nécessaire pour les variables du build et les ressources déclarées (`assets`) |
| Refus | Chaque clé refusée est nommée, la clé absente une seule fois ; une clé qu'une recette n'exécute pas dit quoi faire ; une valeur scellée sous un autre nom donne la commande pour la sceller de nouveau ; une bibliothèque que l'image n'a pas est nommée (`runtime.library.<nom>`) |
| Statut d'une app | `running` dit qu'elle sert une release : sans release servie, `error` après un échec, `pending` jusque-là. Des tests sans résultat sont à la charge de la plateforme (`tests_unavailable`) |
| Branches | Seule la branche de livraison de l'app se construit et se déploie |

## 5 tervicies. Disponible de v2.74.22 à v2.74.27 (en production depuis le 2026-11-04)

Rust, et ce que la vérification complète d'un clone de la release a trouvé.

| Sujet | Ce qui change |
|---|---|
| Rust | `build.runtime` rust, recette `rust-1.99.1-v1`, catalogue `2026.11.04.rust.1` : construit depuis le `Cargo.lock`, sans réseau (`cargo vendor --locked` à la préparation, chaque empreinte vérifiée, puis `cargo build --release --locked --offline`). `build.rust` : `toolchain` (une version de Rust 1 jusqu'à celle de la recette), `binaries`, `features`, `default_features`, `package`, `root` |
| Rust : ce qui tourne | Chaque binaire en `/app/<nom>` ; cycle de vie, comptes par commande ou par HTTP et services par le moteur de la plateforme, comme en Go ; `cargo test` hors réseau sur les mêmes paquets. Image servie : glibc 2.44, libstdc++, OpenSSL 3, SQLite, zlib, zstd, lz4, libsodium, libpq |
| C et C++ (v2.74.33, EX-08.1) | `build.runtime` native, recette `c-gcc-16.2.0-v1`, catalogue `2026.11.04.c.2` : `build.native.system` (autotools, cmake, meson, make), `root`, `configure`, `build`, `install` ; construit sans réseau par le système du projet, GCC 16 ; installé sous `/app` sur un système glibc 2.44 |
| .NET (v2.74.39, R-0027.2) | `build.runtime` dotnet, recette `dotnet-10.0.114-v1`, catalogue `2026.11.04.dotnet.1` : `build.dotnet.project`, `framework`, `properties`, `sources` ; la plateforme produit la liste NuGet (`paas/dependencies/nuget.lock.json`, chaque paquet avec son SHA-512) ; restauration et publication sans réseau ; `net6.0` à `net9.0` sur le runtime 10 ; v2.74.42 : le frontal (`frontend`, `frontend_target`, `build.node`, npm ou Yarn classique), une publication par une cible du projet (`msbuild_target`, `output`), `runtime.packages` |
| Elixir (v2.74.51, R-0027.5) | `build.runtime` elixir, recette `mix-1.19.5-v1`, catalogue `2026.11.05.mix.1` : `build.elixir.root`, `mix_env`, `release`, `tasks`, `frontend`, `frontend_target` ; les dépendances s'installent sans réseau depuis le `mix.lock`, chaque paquet Hex vérifié par son empreinte, chaque dépendance Git à son commit ; la release est servie ; `runtime.packages` s'y installe |
| Perl (v2.74.49, EX-08.2) | `build.runtime` perl, recette `perl-5.44.0-v1`, catalogue `2026.11.05.perl.2` : `build.perl.root`, `without_features`, `archives`, `replace` (une distribution de la snapshot par une autre version) ; les modules s'installent dans `local/` sans réseau, depuis le `cpanfile.snapshot`, chaque distribution vérifiée par le `CHECKSUMS` de son auteur ; sans `DBD::Pg` ni `DBD::mysql` ; `runtime.packages` s'y installe |
| Bun (v2.74.48, R-0017.2) | `build.runtime` bun, recette `bun-1.4.4-v1`, catalogue `2026.11.05.bun.1` : `build.bun.root`, `build_script`, `development` ; Bun installe depuis le `bun.lock` de l'arbre, chaque paquet vérifié, sans script ; le build tourne sans réseau ; l'image servie porte Bun et Node 24 ; `runtime.packages` s'y installe |
| Java (v2.74.45, R-0027.3) | `build.runtime` jvm, recettes `java-17.0.21-v1`, `java-21.0.13-v1`, `java-25.0.5-v1`, catalogue `2026.11.04.java.1` : `build.jvm.build_tool` (maven, gradle ou, v2.81.45, ant avec Ivy), `artifact`, `root`, `goals`, `properties`, `profiles`, `modules` ; la plateforme produit la liste de ses artefacts (`paas/dependencies/maven.lock.json`, chaque fichier avec son SHA-256) ; le build tourne sans réseau ; le frontal se déclare par `frontend`, `frontend_target` et `build.node` (npm ou Yarn classique) ; `runtime.packages` s'installe sur l'image Java |
| C et C++ : bibliothèques | `build.native.libraries` : 117 noms publiés par la recette, chacun épinglé, en-têtes au build ; ce que le programme lie est installé dans l'image servie depuis la même source signée, lu par le scan et le SBOM ; un nom hors de la liste est refusé au plan, avec la liste ; libkiwix, libzim et libtorrent-rasterbar n'y sont pas |
| Arbre du commit | Un arbre sous le plafond de 200 000 entrées est lu en entier, avec ses dossiers (400 000 entrées) ; les messages donnent ce plafond |
| Sondes | Un processus que sa sonde en échec fait redémarrer et qui s'arrête proprement (code 0) est décrit par sa sonde, plus par « s'arrête sans erreur » |

## 5 quatervicies. Disponible depuis v2.74.28 (en production depuis le 2026-11-04)

Les paquets système.

| Sujet | Ce qui change |
|---|---|
| `runtime.packages` | `<runtime><packages><item>ffmpeg</item></packages></runtime>` : un nom de la liste publiée, ou `nom=version` si c'est la version publiée. Installés sans réseau, depuis l'index signé de la distribution, par l'étape de finition de l'image : le scan, le SBOM et la signature les voient comme tout paquet de l'image. Un nom hors de la liste : `ENV_RUNTIME_PACKAGE_UNPUBLISHED`, qui donne la liste |
| Images qui en reçoivent | Wolfi : Python 3.12 et 3.14, Go, Ruby, Rust, Elixir, composition, Node ; Alpine : PHP, statique. Une app Node sur image minimale est servie par le même Node sur Wolfi, un programme Go statique par l'image Go de Wolfi (v2.74.29) ; la recette et le build ne changent pas. Une autre image sans gestionnaire de paquets : `ENV_RUNTIME_PACKAGES_RECIPE` |
| La liste | Une ligne du magasin des catalogues (`runtime-packages`), pas du code : une révision de sécurité est une publication, que le build suivant lit. Ce que l'image porte déjà n'est pas réinstallé |
| Limite | Les paquets sont dans l'image servie, pas dans l'image de test : `build.test.command` ne les trouve pas |

## 5 quinvicies. Disponible depuis v2.74.30 (en production depuis le 2026-11-04)

Les ports autres que le web.

| Sujet | Ce qui change |
|---|---|
| `tcp_ports` | `<tcp_ports><item><name>irc</name><port>6667</port></item></tcp_ports>` : raccordé sur toutes les recettes, Dockerfile compris. `target_port` : le port du conteneur, le même par défaut. `protocol` : `tcp` ou `udp`. `process` : le processus qui écoute, `web` par défaut |
| Ouverture | Chaque déploiement enregistre ce qu'il déclare ; seul un port que l'opérateur a approuvé pour cette app s'ouvre. `paas apps info` dit `awaiting_approval`, puis `open` et l'adresse |
| Adresse | Une adresse partagée, un port pour une app. Une adresse propre à l'app, sur décision de l'opérateur, si elle doit écouter sur un port standard déjà pris. L'app voit l'adresse d'un nœud du cluster, pas celle de son client |
| Limites | Au-dessous de 1024 : 25, 110, 143, 465, 587, 993, 995. Pas encore de proxy par protocole : deux apps ne partagent pas un port sur l'adresse partagée, quel que soit le nom demandé |

## 5 sexvicies. Fonctions (API `/v1/functions`), v2.76.0 (en production depuis v2.81.0, le 2026-11-09)

Une fonction lance, à la demande, une commande de l'image prouvée d'une app, dans une microVM (Kata Containers, Cloud
Hypervisor) sur un nœud de travail. Chaque appel a son entrée, son résultat et son issue. Elle n'est pas déclarée dans
le `paas.xml` : elle se crée par l'API ou par `paas functions`.

| Sujet | Ce qui change |
|---|---|
| Créer | `POST /v1/functions`. Champs : `app_id` et `build_id` (un build prouvé d'une app du tenant) ; `name` (unique parmi les fonctions en service) ; `command` (argv ; absent : celle de l'image) ; `memory` (64Mi à 64Gi) ; `cpu` (1 à 16) ; `timeout_seconds` (1 à 3600) ; `max_concurrency` (1 à 100). Un GPU qu'aucun nœud n'offre est refusé (`function_gpu_unavailable`) |
| Appeler | `POST /v1/functions/{id}/invoke` (ou `spawn`, ou `map` pour une liste), avec `input` (JSON, 64 Kio au plus). La réponse est immédiate (`pending`). Au-delà de `max_concurrency` appels en cours : `function_concurrency_limit` |
| Contrat de la commande | L'utilisateur est 65532. L'entrée est dans `PAAS_INPUT`. Le résultat s'écrit dans le fichier `PAAS_OUTPUT_FILE` (1 Mio au plus). Les sorties standard et d'erreur forment le journal. Réseau : la résolution DNS et le port 8080 des services de la plateforme, rien d'autre |
| Suivre | `GET /v1/functions/{id}/invocations/{inv}` donne `phase` (`pending`, `running`, `succeeded`, `failed`, `cancelled`), `reason` et `responsibility` (Cust ou Paas), `exit_code`, `started_at`, `finished_at` et `duration_seconds`. Une fois l'appel réussi, il donne aussi `output` pendant 24 h (texte, ou base64 selon `output_encoding`). `DELETE` annule un appel en cours. `…/logs` donne le journal |
| Raisons | Cust : `FUNCTION_EXIT_NONZERO`, `FUNCTION_MEMORY_EXCEEDED`, `FUNCTION_TIMEOUT`, `FUNCTION_OUTPUT_TOO_LARGE`, `FUNCTION_CANCELLED`, `FUNCTION_DELETED`. Paas : `FUNCTION_RUNTIME_UNAVAILABLE` (aucun nœud ne porte le moteur, ou il ne crée pas la microVM), `FUNCTION_UNSCHEDULABLE`, `FUNCTION_IMAGE_UNAVAILABLE`, `FUNCTION_START_FAILED`, `FUNCTION_NOT_STARTED`, `FUNCTION_OUTPUT_UNREADABLE`, `FUNCTION_JOB_LOST` |
| Installation | Profil `functions` : le moteur sur chaque nœud de travail (KVM requis) |

## 5 septvicies. Courrier réel, v2.78.1 (en production depuis v2.81.0, le 2026-11-09)

Le relais de courrier de la plateforme, et le serveur de courrier d'une app.

| Sujet | Ce qui change |
|---|---|
| Envoi | `services.<nom>` `smtp`, `provider` `shared`, `mode` `relay` : le relais de la plateforme remet les messages aux serveurs des destinataires, signés en DKIM pour le domaine de la plateforme. Liés : `host`, `port`, `user`, `password`, `url`, `from`, `encryption`. Servi aux apps que paas-entry lance (Go, Rust, C et C++, .NET, Java, Bun, Perl, Lua, Erlang, Elixir, Crystal, Haskell, Racket, Objective-C, Node avec pnpm ou avec un service) |
| Compte | Créé au premier déploiement qui déclare le relais, gardé ensuite, retiré avec l'app. L'expéditeur `<sous-domaine de l'app>@<domaine de la plateforme>` est imposé, à l'enveloppe comme à l'en-tête `From`. Une limite de destinataires par heure ; au-delà, un refus temporaire |
| Sans relais | `mail_relay_unavailable` (Paas) : l'installation n'en a pas. Le mode `capture` reste servi |
| Serveur de l'app | Sur une adresse propre (`--dedicated`), `externalTrafficPolicy` est `Local` : l'app lit l'adresse de son client ; le processus qui écoute est placé sur le nœud qui annonce l'adresse. Port 25 ouvert : `paas apps info` donne les enregistrements à poser (A, MX, SPF ; le PTR chez le fournisseur de l'adresse) |
| Limites | Un seul domaine d'expédition, celui de la plateforme. PHP, Python et Ruby gardent la capture |

## 5 octovicies. Boîte IMAP et port 53, v2.78.2 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Boîte IMAP | `services.<nom>` `imap` (Dovecot 2.4.5) : réservée pour l'app, TLS vérifié, un compte `app`, son volume ; liés : `url` (`imaps://…:31993`), `host`, `port`, `user`, `password` ; relais en clair sur 127.0.0.1 (`local_endpoint`). Apps lancées par paas-entry, PHP et Python ; pas Ruby |
| Limite | La boîte ne reçoit rien d'Internet : une boîte existante chez un fournisseur se lit par son adresse et ses identifiants en `secrets.*` |
| Port 53 | `tcp_ports` admet 53 (DNS), en TCP et en UDP, sous l'approbation de l'opérateur ; une adresse propre si une autre app le tient |

## 5 novovicies. Ports : adresse privée et routage TLS, v2.78.3 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Adresse privée | Un port approuvé s'ouvre par défaut sur l'adresse privée de l'installation (le réseau privé de ses nœuds, non routé sur Internet) ; sur l'adresse publique sur décision de l'opérateur. `paas apps info` dit `(private)` ou `(public)` |
| Plusieurs apps sur un port | `tcp_ports[].route` `sni` : un protocole en TLS dès le premier octet (IMAPS, SMTPS, POP3S, LDAPS, MQTT ou AMQP sur TLS) se partage sur un port de l'adresse ; le routeur TLS de la plateforme mène chaque connexion à l'app qui tient le nom demandé (son hôte de la plateforme, ses domaines vérifiés), sans déchiffrer. Port inférieur à 10000 |
| Limites | SSH et les protocoles sans nom gardent un port propre à l'app ; le MX de la plateforme pour le courrier entrant, le proxy IMAP et POP par identifiant et le proxy SSH par nom d'utilisateur ne sont pas dans cette version |

## 5 tricies. Plusieurs ports HTTP et WebSocket, v2.78.4 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Frontal du conteneur web | `web.front` : le port que sert la plateforme (`listen`) mène chaque requête, par le préfixe de son chemin, au processus web ou à un worker de son conteneur (`mode = in-process`), sur son port déclaré ou sur `routes[].port` ; un chemin qu'aucune route ne prend va au processus web. Servi par paas-entry (Go, Node, PHP et les autres runtimes qu'il lance) |
| WebSocket | `routes[].websocket` : la bascule de protocole passe vers ce processus ; une route sans lui ne la passe pas ; un chemin qu'aucune route ne prend la passe au processus web, comme sans frontal |
| Origines nommées | `http_endpoints` sur n'importe quel port du conteneur web (1024 ou plus), pour toute recette qui lance son processus web ; jusqu'en v2.78.3, la recette npm seule et le port du web seul |
| Port d'un worker du conteneur | Déclaré, il s'expose par une route du frontal ou une origine nommée |
| Limites | Ni Ruby, ni Python, ni site publié, ni processus dans son propre pod ; jusqu'en v2.81.33, la plateforme ne servait pas elle-même un dossier construit à côté d'un processus (un SPA était servi par le processus web) : elle le sert depuis v2.81.34 (section 5 septricies) |

## 5 untricies. Courrier entrant et IMAP/POP partagés, v2.78.5 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| MX de la plateforme | `tcp_ports[].route` `mx` (port 25) : la plateforme reçoit le courrier des domaines vérifiés de l'app sur son adresse publique partagée, vérifie chaque destinataire auprès du serveur de l'app et le lui remet ; tout autre domaine est refusé |
| IMAP et POP partagés | `route` `login` (IMAP 143, POP3 110) : STARTTLS exigé, puis la connexion va à l'app qui tient le domaine de l'identifiant (`compte@domaine`) ; les clients se connectent à l'hôte entrant de la plateforme |
| `paas apps info` | Un port routé dit sa route et, pour `mx` et `login`, l'enregistrement MX ou le serveur que ses clients utilisent |
| Limites | SSH garde un port propre par app ; le serveur de l'app voit le MX ou le proxy de la plateforme comme pair |

## 5 duotricies. GPU, v2.79.1 (en production depuis v2.81.0, le 2026-11-09 ; sans nœud GPU)

| Sujet | Ce qui change |
|---|---|
| `resources.gpu` | Raccordé : une classe (`h100_80gb`, `a100_80gb`, `a100_40gb`, `l40s`, `rtx4090`) et un nombre de GPU par pod du processus web ; placés sur un nœud de la classe avec la classe d'exécution NVIDIA |
| PyTorch pour CUDA | `build.python.wheel_profile` `pytorch-cuda` : PyTorch construit pour CUDA et ses bibliothèques, depuis la liste de l'app ; demande `resources.gpu` |
| Sans GPU dans le cluster | L'app est construite, scannée, signée ; son déploiement est refusé par son nom (`N0_GPU_UNAVAILABLE`), la version en place reste servie |
| Limites | Pas de quota de GPU par tenant ; seuls les pods du processus web reçoivent des GPU ; aucune vérification sur un GPU avant l'arrivée du serveur |

## 5 tritricies. Modèles dans l'image, v2.79.2 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Fichiers posés dans l'arbre | `assets[].dest` raccordé dans la recette Python simple : chaque fichier (adresse, SHA-256) téléchargé avant le build, vérifié et posé à sa destination ; l'image le porte, rien n'est téléchargé au démarrage |
| Bornes | 2 Gio par fichier, 8 Gio en tout, 30 minutes |
| Limites | Les autres recettes gardent `dest` non raccordé ; l'inférence comme service vient en v2.79.5 |

## 5 quatertricies. Plusieurs conteneurs, v2.79.3 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Images par processus | `processes[].build` (recette ou Dockerfile, ses tests, `root`) : une image par processus, construite depuis le même commit, testée, scannée, signée ; la release attend toutes les images ; le retour arrière les restaure |
| Réseau privé de l'app | Un worker sert les autres processus sur son port (Service interne, jamais publié) ; adresse par `{{process.<nom>.host}}`, `.port`, `.url` et `PAAS_PROCESS_<NOM>_*` ; le frontal y mène |
| App construite par son Dockerfile | Workers, crons, jobs et releases à côté du web ; volumes ; capacités Linux ; variables et secrets appliqués à la release |
| Limites | Les fichiers déclarés et le cycle de vie restent ceux de l'image du web |

## 5 quintricies. memcached, PostgreSQL 17 et sauvegardes des bases, v2.79.4 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| PostgreSQL 17 | `services.<nom>` `postgresql` `version` 17 : sa base réservée, ses extensions (celles de 16, à leurs versions de 17 : `ltree` 1.3, pgvector 0.8.7) ; PostGIS sur 16 seulement ; une base garde sa version (passer à 17 = migrer ses données) |
| Sauvegardes | Une base PostgreSQL d'un plan payant : une sauvegarde complète par jour et ses journaux archivés, 7 jours (`standard`, `business`) ou 35 avec restauration à un instant (`pro`, `enterprise`) ; `paas addons info` dit le niveau et la dernière sauvegarde |
| memcached | `services.<nom>` `memcached` (1.6.45) : réservé pour l'app, TLS vérifié, un compte `app` et son mot de passe, 192 Mio d'objets ; liés : `url` (`memcached://…:11211`), `host`, `port`, `user`, `password` ; relais en clair sur 127.0.0.1 (`local_endpoint`), qui s'authentifie pour chaque connexion. Apps lancées par paas-entry, PHP et Python ; pas Ruby |
| Limites | Le protocole texte seulement (memcached refuse le binaire et SASL) ; un cache en mémoire, perdu à un redémarrage |

## 5 sextricies. Inférence privée, v2.79.5 (en production depuis v2.81.0, le 2026-11-09)

| Sujet | Ce qui change |
|---|---|
| Déclaration | `services.<nom>` `inference` (0.40.15), `provider` dedicated, `tls` required, `storage`, `ca_file`, et `model` qui nomme un asset : `name` (minuscules, chiffres, `_`, `.`, `-`), `url` (https) et `sha256` d'un fichier GGUF, sans `dest` ni `headers` |
| Service | Ollama sur le processeur (4 Gio, 1 à 4 processeurs) : il acquiert le modèle à son premier démarrage (une heure au plus), vérifie son SHA-256, le garde et le charge ; TLS vérifié et une clé ; l'API compatible OpenAI sous `/v1` et les routes d'inférence d'Ollama ; ni pull, ni create, ni delete |
| Liaison | `url` (`https://…:11434/v1`), `host`, `port`, `password` (la clé), `model` (`<nom>:latest`) ; INFERENCE_URL, INFERENCE_API_KEY, INFERENCE_MODEL, INFERENCE_SSL_CA ; relais en clair sur 127.0.0.1 (`local_endpoint`), la clé à envoyer. Apps lancées par paas-entry, PHP et Python ; pas Ruby |
| Limites | Un modèle par service, pour la vie de la réservation (un autre modèle : un autre service) ; le volume le contient une fois ; un modèle à la mesure de 4 Gio de mémoire |

## 5 septricies. Corrections et ajouts de v2.81.1 à v2.81.68 (en production du 2026-11-09 au 2026-11-11)

La recette de v2.81.0 sur des apps réelles : chaque défaut trouvé est corrigé par une version, publiée et déployée.

| Sujet | Ce qui change |
|---|---|
| Un dossier servi par le frontal (v2.81.34, EX-13) | Une route de `web.front` sert un dossier au lieu d'un processus : `root` (à la place de `upstream`), un chemin absolu de l'image sous `/app`, hors des volumes (un site construit, une sortie du build), ou un dossier d'un volume déclaré (des fichiers que l'app écrit, servis en bac à sable : `Content-Security-Policy: sandbox`). `fallback` : la page que reçoit une navigation qu'aucun fichier ne sert (celle d'une application monopage, `index.html`) ; absente du dossier au démarrage, le frontal ne démarre pas (`FRONT_FALLBACK_MISSING`). GET et HEAD, `ETag` et `Last-Modified`, plages (`Range`) ; ni liste de dossier ni fichier caché (`.well-known` est servi) ; `Cache-Control: no-cache` sur le HTML et la page de repli. Une route `root` n'a ni `port` ni `websocket` |
| Crons suspendus et repris (v2.81.32, EX-03) | `paas scale <cron> 0` suspend un cron : plus aucune exécution ; `paas scale <cron> 1` le reprend, et une exécution manquée depuis moins de 10 minutes part aussitôt ; un autre nombre est refusé. `paas ps` liste les crons, avec leur planning et leur état (planifié, en cours, suspendu). Une app faite seulement de crons, tous suspendus, est `scaled-zero` |
| Une valeur fournie atteint la release en service (v2.81.35) | `paas secrets provide` sur une app déjà servie rend de nouveau ses variables et ses fichiers et redémarre ses processus ; un cron la lit à sa prochaine exécution. La réponse dit où la valeur est allée. Jusqu'en v2.81.34, elle attendait le déploiement suivant |
| App Python sans processus web (v2.81.27 à v2.81.29, EX-03) | La recette Python simple sert une app dont le premier processus est un worker (sans port, sondé par sa commande ou un port TCP local) ou un cron (son CronJob le lance à chaque exécution). Ce cron monte les volumes de l'app ; chaque release remplace son CronJob entier, sa suspension gardée. Ruby et le Python fermé sans processus web restent refusés par leur nom |
| Python : un arbre sans liste de dépendances (v2.81.31, EX-23) | Les paquets de `build.python.additional_packages` d'un arbre qui n'a ni `requirements.txt`, ni `pyproject.toml`, ni `setup.cfg` deviennent la liste que la plateforme produit |
| Relais IMAP sur 143 (v2.81.30, R-0028.3) | Le relais local d'une boîte IMAP (`services.<nom>.local_endpoint.port`) peut écouter sur 143, le port du protocole, pour un outil qui vise `127.0.0.1:143` ; un autre port sous 1025 reste refusé |
| pnpm : `updateConfig` (v2.81.33) | `pnpm-workspace.yaml` peut porter `updateConfig`, que seuls `pnpm update` et `pnpm outdated` lisent |
| Lignes de langages de v2.77 (v2.81.8 à v2.81.22) | Les images et catalogues de Lua, Erlang/OTP, Crystal, Haskell, Racket, Objective-C, emscripten et Dart/Flutter sont construits et publiés ; leurs plans voyagent au budget élargi (v2.81.12). Dart : `build.dart.hook_defines`, les `hooks.user_defines` des hooks de build du verrou, écrits dans la copie de build (la SQLite du système pour `sqlite3`, sans téléchargement, v2.81.16) ; le build Flutter sans réseau de bout en bout (étapes de génération, `--no-pub`, `--no-example`), ses tests lancés depuis une copie du SDK. Crystal : `build.crystal.git_branch`, le dépôt Git du commit que lisent des macros de compilation (v2.81.13). Haskell : les cibles construites en place ; l'image d'exécution porte la commande `openssl` |
| C et C++ (v2.81.24 à v2.81.26) | Catalogue c.5 : conflits mesurés sur les paquets, paquets CMake complets ; l'image servie porte les pilotes SQL de Qt 5 et les jeux de caractères de glibc (`iconv`) |
| Site statique (v2.81.11) | static.2 : le serveur nginx révisé (musl et zlib corrigés), sans faille HIGH ni CRITICAL |
| Ports privés (v2.81.23) | L'adresse privée des ports des apps n'est annoncée que sur l'interface privée des nœuds (`PRIVATE_NETWORK_INTERFACE`, contrat du site) |
| PHP dans les étapes de build (v2.81.36, PR-0033) | Dans l'étape Node qu'une recette PHP joue après Composer (`build.frontend.after_composer`), une étape de `build.steps` lance le PHP de la recette : `php [-d NOM=VALEUR]… <script de l'arbre> [arguments]` (la génération des actifs d'un Symfony : `bin/console mautic:assets:generate`), sans réseau ; ailleurs, refusée (`ENV_NODE_STEP_PHP`). Le PHP du build fait confiance au miroir des ressources déclarées (v2.81.37 : Dart Sass d'un sass-bundle) |
| Montées Composer déclarées (v2.81.38 à v2.81.40) | `build.php.composer_updates` révise le verrou d'un `composer.json` qui déclare des dépôts Git (`vcs`, `git`, `github`, `gitlab`) ou des dossiers (`path`) : leurs paquets restent tels que verrouillés, et la montée de l'un d'eux est refusée par son nom ; la révision ne bloque plus sur les avis de sécurité (le scan de la plateforme reste la barrière) ; l'app est planifiée sur le verrou révisé |
| MariaDB par le relais PHP (v2.81.41, EX-06) | `services.<nom>.local_endpoint` d'un service MariaDB d'une app PHP : un client qui n'ouvre jamais TLS joint MariaDB en clair sur 127.0.0.1, le relais parle TLS vérifié au serveur (Movim 0.35.5 sur MariaDB 11.8.9) |
| Copie de stockage d'un fichier rendu au build (v2.81.41) | En PHP, `storage.seeds.from` peut nommer un fichier que le paas.xml rend au build (`files`, render build) : l'entrée PHP le recopie de l'image vers le volume au démarrage, une seule fois |
| Images PHP révisées (v2.81.42) | Catalogue `2026.11.10.php.28` : les quatorze recettes PHP 8.4.27 sur libxslt 1.1.43-r4 (deux failles HIGH publiées le 2026-11-10, qui bloquaient au scan tout build sur une recette full) et Alpine 3.24.4 (zlib 1.4) ; mêmes ids, version de recette +1. Une app passe `build.catalogue` à `2026.11.10.php.28` |
| Explications de refus (v2.81.42) | L'index des refus, que montrent l'API, `paas config plan` et cette référence, dit ce que fait la plateforme pour le relais local (MariaDB en PHP), la copie de stockage et la liste de dépendances d'un `composer.json` |
| Images PHP révisées (v2.81.76) | Catalogue `2026.11.12.php.30` : les quinze recettes PHP 8.4.27 sur Apache httpd 2.4.71-r0 (CVE-2026-119618, CRITICAL sur 2.4.69, publiée le 2026-11-12 : elle refusait au scan tout build d'une app PHP) ; mêmes ids, PHP, extensions et configuration ; une app PHP en service se met à jour en se reconstruisant |
| Vérifications HTTP en PHP, Python et Ruby (v2.81.74, v2.81.75, PR-1635) | `lifecycle.http_checks` (`path`, `expect_status`, `expect_body`) : une page qui répond 200 sans le texte attendu n'est plus servie. Les entrées les jouent à chaque démarrage, après la transition et avant de servir, pendant 60 s ; une release refusée l'est sous `lifecycle_http_check_failed` (Cust), qui nomme la vérification, le statut reçu et le texte attendu |
| Le bord en IPv4 (v2.81.68) | Le bord joint le Service d'une app par sa seule adresse IPv4, comme le routeur TLS. Il alternait entre IPv4 et IPv6 : une app qui ne sert qu'une famille d'adresses, ou répond autrement en IPv6, renvoyait une requête sur deux refusée ou vide (mesuré : Universal Media Server 15.9.0, ses fichiers d'interface) |
| Montées déclarées Java et .NET (v2.81.67) | `build.jvm.dependency_updates` (`groupId:artifactId@version`) et `build.dotnet.dependency_updates` (`Paquet.Id@version`), 64 au plus : la plateforme les lisait depuis v2.77.0, le paas.xml les refusait (clé inconnue). Maven : chaque POM du réacteur (la racine, puis ses modules) gère l'artefact à sa version, et ses dépendances directes qui écrivent leur propre version la prennent, dans le projet et dans chaque profil. Mesuré : Universal Media Server 15.9.0, jackson 2.21.8 et guava 33.7.2-jre, ses 9 failles HIGH levées (build build-b309389b) |
| Un but Maven nommé par son exécution (v2.81.65, v2.81.66) | `build.jvm.goals` accepte `plugin:but@exécution` (`assembly:single@make-jar-with-dependencies` après `prepare-package`) : le build produit le seul jar servi quand la phase `package` assemble aussi une distribution qui exige des fichiers absents ; la liste Maven que produit la plateforme l'accepte aussi (v2.81.66) |
| Frontal Yarn berry d'un build Java ou .NET (v2.81.64) | Le frontal d'un build Java (`build.jvm.frontend`) ou .NET (`build.dotnet.frontend`) peut être en Yarn 2 et suivants, comme celui d'un build Go : la plateforme remplit son miroir sans lancer Yarn, l'étage du frontal installe sans réseau (mesuré : Universal Media Server 15.9.0, react-client en Yarn 4.18.1) |
| Frontal Bun d'un build Go (v2.81.63) | `build.node.package_manager` bun : un frontal que Bun seul verrouille (`bun.lock`) est construit par Bun 1.4.4 sur la recette `go-1.27.3-node24-bun-v12` du catalogue `2026.11.11.go.13` : Bun remplit son cache depuis le verrou, l'étage du frontal installe sans réseau et lance `build_script`, le build Go copie ses `outputs`. Le même catalogue sert l'image git révisée des recettes qui portent git (libexpat 2.10.0). Mesuré : DMARCguard 1.7.3 |
| Projets construits avant la publication (v2.81.61, v2.81.62) | `build.dotnet.prebuild` (recette .NET) : des projets de l'arbre, 8 au plus, construits dans l'ordre (`dotnet build -c Release`, hors réseau) avant la publication, pour une app qui référence les DLL d'une bibliothèque par leur chemin (`HintPath`) ; leurs paquets entrent dans la liste NuGet que produit la plateforme. L'arbre d'un second dépôt se pousse avec l'app : un projet d'un sous-module est refusé, nommé avec son sous-module (v2.81.62), le plan ne lisant que l'arbre poussé. Mesuré : Technitium DNS Server 15.6.2 et sa bibliothèque, DNS servi en TCP et UDP sur l'adresse privée |
| Module autonome (v2.81.60) | `build.node.standalone` (recette pnpm servie) : quand le serveur se suffit (son bundler l'a réuni avec ses dépendances), l'image servie ne porte que l'arbre et les sorties du build, sans installation de production ni magasin ; une dépendance déclarée que le serveur ne charge pas (un compilateur) n'y est plus, ni ses failles. npm et Yarn installent la production et refusent la clé |
| Alertes Falco (v2.81.59) | Une alerte répétée dans les dix minutes compte sur sa ligne (occurrences, dernière vue) au lieu d'en écrire une nouvelle |
| Usage d'une app supprimée (v2.81.58) | L'usage d'une app reste compté jusqu'à sa purge, même quand l'heure est mesurée après elle : la plateforme garde une trace de chaque app purgée (tenant, sous-domaine, dates). La purge d'une app en corbeille n'est plus bloquée une heure par la réadoption de sa base |
| Quota d'un site qui ne limite rien (v2.81.55, v2.81.57) | Sans palier gratuit appliqué (`PAAS_QUOTA_ENFORCER_ENABLED` absent), l'usage est mesuré toutes les 5 minutes, le quota n'est jamais annoncé bloqué (`enforced: false`, pourcentages à 0) et aucune app n'est mise en pause ; la console montre la consommation seule, sans limite ni barre |
| Stockage, apps et addons du quota (v2.81.56, v2.81.57) | Le stockage est ce que les apps occupent à la dernière heure mesurée, plus la somme des Gio·h du mois ; le quota compte les apps non supprimées et leurs addons. Une ligne de consommation à prix nul n'a pas de barre |
| SBOM d'un build (v2.81.54) | Le rappel qui enregistre le SBOM réessaie pendant 90 s une erreur passagère (5xx, connexion refusée ou perdue), comme celui des tests ; un autre refus termine l'étape avec son code HTTP et l'erreur de la plateforme. Un refus isolé faisait échouer le build sans dire pourquoi |
| Maintenance d'une app à processus d'image propre (v2.81.53) | Redémarrage, mise à l'échelle et `paas run` sont admis avec le pod d'un processus à image propre en service : la plateforme reconnaît l'image que la release a admise pour lui. Ils étaient refusés (`admission_runtime_serving_identity_mismatch`) |
| Release d'une app à processus d'image propre (v2.81.52) | La release retrouve les images de ses processus à image propre, admises au push : elle est promue, le compte initial devient lisible (`submit_installation_credentials`) et un retour arrière vers elle restaure ces images. Elle était marquée en échec alors qu'elle servait (`admission_served_observation_mismatch`) |
| Relais local PostgreSQL (v2.81.51) | `services.<nom>.local_endpoint` d'un PostgreSQL, dans les recettes que sert paas-entry (Node, Go, recettes compilées) : l'app se joint en clair à 127.0.0.1 par `{{services.<nom>.local_url}}` (`postgres://…`, sans `sslmode`) ; le relais ouvre TLS vérifié jusqu'au service et retire de l'offre du serveur SCRAM-SHA-256-PLUS, que libpq refuse sur une connexion en clair. Pour un client qui ne fait confiance qu'aux autorités publiques (le pool de Lemmy). En PHP, le client se joint en TLS avec l'autorité du service |
| Identifiants d'avis des exceptions CVE (v2.81.50) | `security.cve_exceptions[].id` et les exceptions de l'opérateur nomment aussi les avis des autres bases que le scan rapporte : `NSWG-ECO-N` (Node.js), `RUSTSEC-AAAA-N`, `GO-AAAA-N`, `PYSEC-AAAA-N`, `TEMP-N-X` (Debian), en plus de CVE et GHSA |
| Processus à image propre à côté d'un cycle de vie (v2.81.47 à v2.81.49, R-0025.2) | Une app qui déclare un cycle de vie peut avoir un processus à image propre (`processes[].build`) : il reçoit les variables, secrets et liaisons de l'app par son environnement et démarre à côté du web ; sa configuration dérivée ne porte pas les services de l'app et garde les sous-modules, fichiers inertes et chemins laissés de côté de son dossier ; un déploiement applique le web d'abord ; `paas config plan` admet, planifie et contrôle l'export de son image sur son dossier. Un processus de l'image du web dans son propre pod reste refusé à côté d'un cycle de vie (Lemmy et lemmy-ui) |
| Révisions d'Ivy en propriétés (v2.81.46) | La résolution d'Ivy lit les propriétés que lui donne le build d'Ant : le `build.properties` du dossier du build, puis `build.jvm.properties`, qui l'emportent ; un `ivy.xml` dont une révision est une propriété (`rev="${x.version}"`) se résout |
| Build Ant avec Ivy (v2.81.45, R-0027.3) | `build.jvm.build_tool` = `ant` : `build.xml` dans le dossier où il tourne, ses cibles dans `goals`, les `-D` dans `properties` ; Ivy 2.5.3 résout `ivy.xml` depuis Maven Central dans la liste produite (`paas/dependencies/maven.lock.json`, avec le jar d'Ivy), le build hors réseau résout depuis elle seule ; un `ivysettings.xml` de l'arbre est refusé (`ENV_JAVA_IVY_SETTINGS_UNSUPPORTED`) (YaCy 1.941) |
| Recette PHP avec brotli (v2.81.44, EX-04.3) | `php-8.4.27-apache-alpine-full-brotli-v15`, l'image full du catalogue 2026.11.10.php.28 et l'extension brotli (`php84-pecl-brotli` 0.21.0), dans le catalogue `2026.11.10.php.29` : une app dont le `composer.json` exige `ext-brotli` la déclare (`build.recipe`), avec la liste exacte de ses extensions (TransLite) |
| Compte initial lu dans un fichier (v2.81.43) | En PHP, le compte initial que crée l'installateur natif (`lifecycle.install`, sans `account.create`) peut recevoir son mot de passe dans un fichier que l'entrée rend avant lui (`lifecycle.start_files`, gabarit avec `{{account.password}}`), comme sur son entrée standard : un installateur en ligne de commande qui lit son compte dans son fichier de configuration (Mautic : `mautic:install` lit `admin_*` dans `config/local.php`) ; jamais en argument |

## 5 octotricies. De v2.82.0 à v2.86.0 (en production depuis le 2026-11-13)

| Fonction | Ce qui change |
|---|---|
| Plage de ports TCP (v2.86.0) | `tcp_ports[].port_range` « A-B » (256 ports au plus, au-dessus de 1023, chacun au même numéro, sans `target_port` ni `route`) s'ouvre en un seul accord de l'opérateur, sur une adresse privée propre à l'app (le pool de l'installation, `PAAS_TCP_PRIVATE_POOL`), qui garde l'adresse du client (relais TURN) ; l'app lit cette adresse dans `{{app.tcp_address}}` (`PAAS_APP_TCP_ADDRESS`). Une entrée sans `port` ni `port_range` est refusée au plan |
| Téléchargements d'un Dockerfile (v2.86.0) | La plateforme lit le Dockerfile sans l'exécuter et télécharge elle-même, hors du pod de build, ce qu'il va chercher : base d'une distribution nommée par étiquette (figée à son empreinte), paquets apt, fichiers HTTPS (`curl`, `wget`, `ADD https://`), épinglés par leur SHA-256 au premier passage ; le build les sert sans Internet. Un téléchargement qu'elle ne sait pas lire est refusé, ligne nommée (`ENV_DOCKERFILE_DOWNLOAD_UNSERVED`) |
| PHP 8.5 (v2.85.0, catalogue `2026.11.13.php.31`) | `php-8.5.12-apache-alpine-v1` (PHP, Apache et les modules de toute la ligne : gd, mbstring, curl, dom, openssl, zip…) et `php-8.5.12-apache-alpine-full-v2` (les extensions de la variante full ; OPcache est intégré à PHP 8.5) |
| Node 26 avec pnpm (v2.85.0, catalogue `2026.11.13.node26.1`) | `engines.node` 26 : la recette `node-26.13.0-pnpm-workspace-v5`, construite et servie par Node 26.13.0 (pnpm 10 à 12) |
| Recette Go avec frontal Yarn et cgo (v2.84.0, catalogue `2026.11.12.go.14`) | `go-1.27.3-node24-yarn-cgo-v13` ; un frontal Yarn classique avec ses espaces de travail se déclare par `build.node.workspaces`, tels que son `package.json` les écrit |
| Go : module du même dépôt et verrous Buf (v2.84.0) | Un `replace` vers un module du même dépôt (`./pkg/…`, avec son `go.mod`) est admis ; les verrous Buf v1 (condensé B4) sont vérifiés auprès du registre ; après les montées déclarées, la ligne de `go.sum` d'un module nouveau est prise à la base de sommes de Go |
| Montées de dépendances (v2.83.0, v2.85.0) | npm : un dépendant monté dans la même liste se lit à sa version déclarée ; pnpm : un paquet partagé passe à la version qu'une montée exige ; Gradle : `build.jvm.dependency_updates`, forcées par un script d'init ; Python : `build.python.dependency_updates` sans liste exacte dans l'arbre ; Yarn classique servi : produites après le push |
| Python : listes de dépendances nommées (v2.85.0) | `build.python.requirements_files` : les fichiers `.txt` d'où un projet aux dépendances dynamiques (`project.dynamic`) tire les siennes, 8 au plus |
| Arbre Node (v2.83.0) | Une dépendance npm `file:` vers un dossier de l'arbre est liée comme un espace de travail ; un `node_modules` que l'arbre versionne comme son code se déclare par `source.vendored_node_modules` ; la recette pnpm servie lit un projet placé sous la racine (`build.node.root`) |
| Sonde qui lit la réponse (v2.82.0) | `healthcheck.expect_body` : un texte que la réponse doit contenir ; la sonde lit le corps (une page d'erreur rendue en 200 n'est plus prête) ; avec `lifecycle.http_checks`, la sonde de démarrage attend leur passage |
| Journal du cycle de vie (v2.82.0) | Chaque commande qui réussit (code, fin de sa sortie) et chaque étape HTTP qui passe sont écrites au journal, secrets masqués ; `failure.json` nomme la dernière étape réussie |
| Composer (v2.82.0) | `ext-Zend-OPcache` est servi par l'OPcache de la recette ; les montées (`build.php.composer_updates`) d'un verrou au content-hash périmé passent, et les extensions des seules dépendances de développement ne les arrêtent plus |
| Publiés le 2026-11-13, après le déploiement | La liste C `c.6` (libvips) et la ligne Go `go.15` (libvips, libtensorflow, ONNX Runtime) ; SSH et borg dans une image servie (`packages.8` : `openssh-server` et la roue `borgbackup==1.4.5` que la plateforme construit) |
| Publiée plus tard | La ligne Meteor (`build.runtime` meteor, `build.meteor`) attend que l'outil de Meteor 3.6 soit révisé (failles CRITICAL de ses dépendances npm) |

## 5 novotricies. v2.87.0 (en production depuis le 2026-11-13)

| Fonction | Ce qui change |
|---|---|
| Aucune application reconnue à son nom (v2.87.0) | La plateforme ne traite jamais une application par son nom : un arbre poussé sans configuration n'est plus reconnu à ses fichiers ni à ses dépendances comme un logiciel connu ; il est lu et planifié comme sa famille (langage, gestionnaire de paquets, verrous), ou refusé par le refus nommé de sa famille. Ce qui est propre à une application se déclare dans son `paas.xml`. |
| Variables d'une image (v2.87.0) | Les variables qu'une image lit pour sa base ne se déduisent plus du nom de l'image : elles se déclarent depuis les champs du service (`services.*.env`, gabarits `{{services.<n>.…}}`) ; le langage de l'instrumentation OpenTelemetry se déclare quand l'image ne le dit pas. |
| Publié le 2026-11-13 : PHP (catalogue `2026.11.13.php.32`) | Les six images PHP 8.4 qui chargent `pgsql` passent à libpq 18.7 (les 38 failles HIGH de libpq 18.6 refusaient leurs builds au scan), les deux images PHP 8.5 à zlib 1.4 ; les recettes gardent leurs identifiants, les plans figés gardent leur catalogue. |

## 5 quadragies. v2.88.0 (en production depuis le 2026-11-14)

| Fonction | Ce qui change |
|---|---|
| Repli d'une application monopage (v2.88.0) | `build.static.fallback` nomme le document que le serveur HTTP de la plateforme rend à un chemin qui ne désigne aucun fichier du site publié (les routes de l'application, un lien profond), au lieu d'une réponse 404. |
| Mises à jour npm à côté des archives Git (v2.88.0) | `build.node.dependency_updates` s'applique quand le verrou tient des archives Git que le build fournit (`build.node.git_archives`) ; ces archives restent à leur commit. |
| Mises à jour Composer et vendor livré (v2.88.0) | `build.php.composer_updates` s'applique à côté de `build.php.composer_rebuild_committed_vendor` : le dossier `vendor` livré est reconstruit depuis le verrou révisé. |
| Verrous Yarn incomplets (v2.88.0) | Une dépendance qu'aucune entrée du `yarn.lock` ne verrouille (les variantes d'un autre système) est réparée une fois par la plateforme au lieu d'être refusée ; le verrou de l'arbre reste tel quel. |
| Python (v2.88.0) | Un paquet qu'un `uv.lock` ou un `poetry.lock` prend à l'index PyTorch des builds pour processeur est acquis par l'empreinte que le verrou épingle ; une mise à jour de `build.python.dependency_updates` remplace l'épinglage exact de son paquet dans les listes de l'app. |
| Données de dépendances publiées (v2.88.0, N1.DATA) | Les correctifs de verrou (npm, Composer), de manifestes et de dépendances JVM, et les instantanés du registre npm, sont des documents publiés au magasin des catalogues, que le `paas.xml` désigne par leur empreinte : un correctif nouveau se publie sans nouvelle version de la plateforme. Un instantané vaut pour le verrou dont il est tiré : la préparation le reconstruit depuis le registre officiel et ne l'admet qu'à son empreinte (`ENV_NPM_REGISTRY_SNAPSHOT_SCOPE` au plan pour un instantané tiré d'un autre verrou). |
| Erreurs nommées (v2.88.0) | Une extension PostgreSQL que la base refuse de créer est nommée, avec la clé `services.<nom>.extensions` qui la déclare ; un Prisma qui ne trouve pas OpenSSL 3 dans les images de la plateforme (avant 4.13.0) est refusé au plan, la voie de sortie nommée ; une résolution Maven au-delà de son budget dit la phase où elle s'est arrêtée ; une préparation des tests en échec propose `<test><tree>built</tree></test>`. |

## 5 unquadragies. v2.89.0 (en production depuis le 2026-11-14)

| Fonction | Ce qui change |
|---|---|
| PHP 8.5 servi par Apache (v2.89.0) | La configuration Apache que la plateforme rend charge le module de la ligne PHP de la recette (`mod_php85.so` pour 8.5) ; le build la lit avec Apache (`httpd -t`) et échoue, en la nommant, si la recette ne peut pas la servir, au lieu de chaque démarrage. |
| Montées Composer d'un projet en sous-dossier (v2.89.0) | Avec `build.php.composer_project`, les montées déclarées (`build.php.composer_updates`) sont produites et installées pour le verrou du projet (`paas/dependencies/<projet>/composer.lock`), au lieu d'être ignorées. |
| Montées Composer et dépôts déclarés (v2.89.0) | Une montée se fait à côté d'un dépôt `package` écrit dans le `composer.json` (ses paquets restent tels que le verrou les tient) ; un dépôt encore refusé est nommé, par son adresse ou ses paquets. Un paquet que le verrou installe depuis sa source Git seule s'acquiert par l'archive de son commit sur sa forge (GitHub, Codeberg, gitlab.com, framagit.org). |
| Roues Python épinglées par leur adresse (v2.89.0) | `build.python.wheel_origins` déclare les origines https (un préfixe exact qui finit par `/`, par exemple les publications d'un dépôt GitHub) d'où un `uv.lock` épingle des roues par leur adresse avec leur empreinte : la plateforme les acquiert hors du build, vérifiées par cette empreinte, et ne suit les redirections de GitHub que vers les hôtes de ses fichiers ; une adresse hors de ces origines est refusée, nommée. |

## 5 duoquadragies. v2.90.0 (en production depuis le 2026-11-14)

| Fonction | Ce qui change |
|---|---|
| Montées Python à côté de l'index de PyTorch (v2.90.0) | Les montées déclarées (`build.python.dependency_updates`) révisent un `uv.lock` ou un `poetry.lock` qui prend un paquet sur un index que sert la plateforme (`torch` `+cpu`, l'index de PyTorch) : la résolution reste complète, ce paquet garde sa version et l'empreinte du verrou, et le profil `pytorch-cpu` admet la liste révisée ; une montée de ce paquet-là se change dans la liste de l'app (`ENV_PYTHON_DEPENDENCY_UPDATE_INDEX`). |
| Montées Python écrites comme l'index (v2.90.0) | Une montée s'écrit comme le registre écrit la version : `nom@X.Y`, `nom@X.Y.Z` ou `nom@X.Y.Z.postN` ; une pré-version, une version de développement ou locale et une plage sont refusées, le refus nommant les formes admises. |
| Verrou Yarn d'un projet à espaces de travail (v2.90.0) | La plateforme produit le verrou d'un projet Yarn classique à espaces de travail (`build.node.workspaces`) : les manifestes des membres sont lus avec celui du projet, une entrée hors de sa plage depuis un membre se répare comme une autre, et la liste produite est périmée dès qu'un manifeste de membre change. |
| Meteor (v2.90.0) | Le serveur du bundle s'installe sans réseau ; un arbre Meteor garde le Dockerfile qu'il déclare (`build.source_dockerfile`) ; ses services déclarés, MongoDB compris, sont réservés et liés. |
| Recettes publiées après les producteurs (v2.90.0) | Les producteurs admettent une recette par sa chaîne d'outils (famille, capacité, gestionnaire de paquets), non par une liste d'identifiants : une recette publiée après eux (Node 26 avec npm) n'est plus refusée à la préparation. |

## 6. Prévu

Chaque capacité est développée comme une option générique : aucune app n'est codée dans la plateforme, l'app
qui en a besoin la déclare dans son `paas.xml`. L'ordre suit la feuille de route ; il peut changer.

| Identifiant | Contenu |
|---|---|
| EX-02, T-05.4 | Modules natifs Node (liaisons précompilées publiées, ou compilation en bac à sable hors réseau) et correctifs `patch-package` de l'amont appliqués hors réseau : Wiki.js (extract-files), cusdis (moteurs Prisma) ; ressources déclarées et scripts d'installation en npm et Yarn. Disponibles depuis v2.72.0 : ressources déclarées servies hors réseau en pnpm et PHP, scripts d'installation déclarés en pnpm, refus au plan des paquets au binaire posé par leur script (section 5 novodecies) |
| N0.NET | Liens déclarés entre apps : disponibles depuis v2.30.0 (section 5 ter). Règles de sortie, IPv6 : prévus |
| N2.BRUBY, N2.BPY | Combinaisons runtime × service manquantes (Ruby avec MySQL ou MariaDB). Disponibles depuis v2.62.0 : Python avec MySQL (section 5 septdecies) ; depuis v2.52.0 (section 5 nonies) : PHP avec PostgreSQL et Redis, Node et Go avec Redis et MariaDB, plusieurs services par app (N2.BPHP, N2.BNG, N2.MULTI) |
| N2.PGEXT, N2.OPTIONS | PostgreSQL 17 ; réplicas, sauvegarde et PITR. Disponibles depuis v2.52.0 : les extensions de l'image publiée, les bases nommées et le droit de créer des bases ; PostGIS depuis v2.59.0 |
| N0.PROC | Job (commande ponctuelle) ; processus séparés à côté d'un cycle de vie. Disponibles depuis v2.56.0 : worker, cron et release séparés en Node, PHP et Go (section 4) |
| N2.OPENSEARCH, N2.RABBITMQ, N2.S3, N2.CLICKHOUSE, N2.VALKEY | ClickHouse, Valkey, memcached, InfluxDB 2 ; Meilisearch, OpenSearch, RabbitMQ, S3 et LDAP en Ruby. Disponibles depuis v2.58.1 et v2.60.0 en Node et Go, depuis v2.61.0 en PHP, depuis v2.62.0 en Python : Meilisearch, OpenSearch, RabbitMQ, S3, LDAP |
| N0.RUNTIME, N0.EDGE, N0.BUILD, N1.MULTIRT, N1.STATIC | Paquets système, autres réglages d'entrée par app, secrets de build, statique prouvé. Disponibles depuis v2.56.0 : mot de passe de bordure, frontal npm dans les recettes PHP et Ruby |
| N1.JVM, N1.ELIXIR, N1.RUST, N1.DOTNET, N1.VERSIONS | Nouveaux runtimes et versions |
| N1.COMPOSE | Disponible depuis v2.79.3 (section 5 quatertricies) : une image par processus (`processes[].build`) ; le Dockerfile de l'app est disponible depuis v2.34.0, hors de la racine depuis v2.56.0 |
| N2.SMTP, N2.IMAP, N0.TCP, N0.DOMAINS | Domaines d'expédition propres à l'app. Disponibles : ports TCP (v2.74.30), courrier réel, boîte IMAP, courrier entrant et IMAP/POP partagés (v2.78.1 à v2.78.5), domaines vérifiés de l'app |
| N0.GPU, N2.INFERENCE, N0.STORAGE | Nœuds GPU, quotas de GPU. Disponibles depuis v2.79.1 à v2.79.5 : `resources.gpu`, modèles dans l'image, inférence privée |
| N0.SCALE, N0.DEPLOY | Réplicas, autoscaling, placement ; stratégies de déploiement |
