# Fonctionnalités du paas.xml — disponibles et prévues

État au 2026-10-18 : plateforme v2.48.1, CLI 2.48.1, catalogue de production du même jour. « Disponible » veut dire
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
| Runtimes | PHP 8.4 ; Node 24 (npm, workspaces, pnpm, yarn) et Node 22 ; Go 1.26 et 1.27 ; Python 3.12 et 3.14, fermeture Python + Node ; Ruby 3.4 ; Dockerfile à la racine du dépôt (`build.runtime` `dockerfile`, v2.34.0), sur l'outillage et les images des recettes publiées (`paas builds bases`) ; statique (se planifie, jamais prouvé) | JVM (N1.JVM), Elixir (N1.ELIXIR), Rust (N1.RUST), .NET (N1.DOTNET), plusieurs conteneurs (N1.COMPOSE), autres versions majeures (N1.VERSIONS) |
| Build | Budgets de temps publiés par étape (v2.38.0) et `build.resources.timeout_seconds` ; budgets de lecture de l'arbre `source.limits`, fichiers laissés de côté `source.ignore`, fichiers inertes admis par empreinte `source.pinned` (v2.37.0) ; app rangée dans un sous-répertoire d'un monorepo, `source.root` (v2.39.0) ; verrous npm, Yarn et pnpm lus comme leur gestionnaire | `build.resources` `cpu`, `memory` et les clés de tas ou de parallélisme (refusées chacune avec sa raison) |
| Services | PostgreSQL 16, MySQL 8.4, MariaDB 11.8, Redis 7.4, MongoDB 8.0, SMTP en capture ; base dédiée, TLS vérifié ; relais MySQL en boucle locale (`local_endpoint`) en PHP, Node et Go (v2.37.0) | Plusieurs services en PHP, Node et Go (N2.MULTI) ; Valkey, OpenSearch, RabbitMQ, S3, ClickHouse ; envoi réel de courrier (N2.SMTP), IMAP ; extensions PostgreSQL libres (N2.PGEXT) ; options de base (N2.OPTIONS) |
| Processus | Un processus web ; en Python fermé et Ruby, jusqu'à 7 workers supervisés dans le même conteneur ; une réplique | Worker, cron et job séparés (N0.PROC) ; plusieurs réplicas (N0.SCALE) ; stratégies de déploiement (N0.DEPLOY) |
| Stockage | Volumes rwo et rwx, liens, copies initiales | `storage.private` (refusé par la projection, mesuré le 2026-10-15), tmpfs, stockage éphémère, rwx prouvé (N0.STORAGE) |
| Réseau | HTTPS, websockets, 100 Mo par requête ; liens déclarés entre apps `network.linked_services` (v2.30.0, effectifs quand l'isolation entre apps sera activée) ; tous les chemins du nom court, `/login` compris, vont à l'app (v2.38.1) | Ports TCP (N0.TCP), règles de sortie et IPv6 (N0.NET), domaines (N0.DOMAINS), réglages d'entrée par app (N0.EDGE) |
| Sécurité | Une seule politique pour l'image servie (v2.36.0) : porte CVE, politique déclarée dans le `paas.xml` (`security.cve_exceptions` une par une, toute sévérité, ou `security.block_on` `critical` ou `none`), porte des constats de secrets avec `security.secret_exceptions` ; exceptions de l'opérateur (HIGH) ; secrets scellés | `security.sbom`, `security.require_mfa_for_console` |

## 2. Runtimes et recettes publiées (N1)

Un `paas.xml` doit nommer `build.recipe` et `build.catalogue`, et vérifier `build.runtime` : `php`, `node`,
`python`, `go`, `ruby` ou `static`. Le tableau donne les recettes de l'instantané du catalogue de production,
avec pour chacune le dernier catalogue qui la contient (instantané du 2026-10-19, v2.50.0, 64 recettes). Tout catalogue qui contient la recette convient ; un
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
| JVM | `jvm25-clojure-bun-v1` | 25.0.4+7 | ubuntu22.04-glibc2.35 | web | `2026.09.16.jvm.2` | publiée ; `build.jvm` non raccordé (N1.JVM) |
| NODE | `node-22.23.2-pnpm-minimal-v1` | 22.23.2 | debian12-glibc2.36 | web,worker,job | `2026.09.13.go.2` | publiée ; aucun exemple ne l’utilise encore |
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
| PHP | `php-8.4.26-apache-alpine-cache-v5` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée : flarum (2026.10.04.php.20), piwigo (2026.10.07.php.21) |
| PHP | `php-8.4.26-apache-alpine-calendar-v6` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-full-pear-v11` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; full-v10 avec PEAR (`PEAR.php` dans le chemin d’inclusion) ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-full-v10` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-full-sqlite3-v12` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée : Wallos 5.8.3 (classe SQLite3, base créée sur le volume, connexion servie) (2026.10.16.php.24) |
| PHP | `php-8.4.26-apache-alpine-full-tidy-v13` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l'utilise encore (wallabag) (2026.10.16.php.24) |
| PHP | `php-8.4.26-apache-alpine-full-imap-v14` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée au build : Agorakit 1.11 (ddeboer/imap exige ext-imap ; Composer installe, extension chargée) (2026.10.16.php.24) |
| PHP | `php-8.4.26-apache-alpine-iconv-v7` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée : bookstack (2026.10.04.php.20), dokuwiki (2026.10.04.php.20), drupal (2026.10.04.php.20), joomla (2026.10.04.php.20), opencart (2026.10.04.php.20), suitecrm (2026.10.07.php.21), woocommerce (2026.10.04.php.20), wordpress (2026.10.04.php.20) |
| PHP | `php-8.4.26-apache-alpine-imagick-calendar-v9` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée (2026.10.07.php.21) |
| PHP | `php-8.4.26-apache-alpine-imagick-v8` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée : nextcloud (2026.10.07.php.21), typo3 (2026.10.07.php.21) |
| PHP | `php-8.4.26-apache-alpine-pdo-v2` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-pdo-xml-v3` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l’utilise encore |
| PHP | `php-8.4.26-apache-alpine-sqlite-intl-v4` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | prouvée : freshrss (2026.10.04.php.20), kanboard (2026.10.04.php.20) |
| PHP | `php-8.4.26-apache-alpine-v1` | 8.4.26 | alpine3.24-musl | web | `2026.10.16.php.24` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.12.14-bookworm-v1` | 3.12.14 | debian12-glibc2.36 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.12.14-wolfi-v1` | 3.12.14 | wolfi-glibc2.44 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.7-bookworm-v1` | 3.14.7 | debian12-glibc2.36 | web,worker,job | `2026.09.27.php.18` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.7-wolfi-v1` | 3.14.7 | wolfi-glibc2.44 | web,worker,job | `2026.09.24.python.1` | publiée ; aucun exemple ne l’utilise encore |
| PYTHON | `python-3.14.8-wolfi-v1` | 3.14.8 | wolfi-glibc2.44 | web,worker,job | `2026.10.12.python.1` | publiée (v2.34.0) ; images composées par la plateforme, mesurées 0 CRITICAL / 0 HIGH ; aucun exemple ne l’utilise encore |
| PYTHON | `python314-node24-closure-v1` | 3.14.7 | wolfi-glibc2.44 | web | `2026.10.03.python.1` | prouvée : erpnext (2026.10.03.python.1) |
| PYTHON | `seafile13-native-closure-v1` | 3.12.14 | wolfi-glibc2.44 | web | `2026.09.22.native.1` | publiée ; recette native propre à une app (N3), hors doctrine |
| RUBY | `ruby34-bundler-offline-v2` | 3.4.10 | wolfi-glibc2.44 | web | `2026.09.18.ruby.2` | publiée ; aucun exemple ne l’utilise encore |
| RUBY | `ruby34-pnpm-offline-v1` | 3.4.10 | wolfi-glibc2.44 | web | `2026.09.30.ruby.3` | prouvée : discourse (2026.09.30.ruby.3) |
| STATIC | `static-nginx-1.30.4-alpine3.24-v1` | HTML5-CSS-JavaScript-static | alpine3.24-musl | web | `2026.09.27.php.18` | publiée ; refusée par la porte CVE par défaut depuis le 2026-10-15 (`CVE-2026-103111`, HIGH, pcre2 de l'image nginx) : prendre la 1.30.6 |
| STATIC | `static-nginx-1.30.6-alpine3.24-v1` | HTML5-CSS-JavaScript-static | alpine3.24-musl | web | `2026.10.15.static.1` | prouvée (v2.39.3) : site de test construit et servi, 0 CRITICAL / 0 HIGH ; ligne de catalogue `static`, build et tests sur l'image Python Wolfi de la plateforme |

Extensions des recettes PHP 8.4.26 (`build.php.extensions` doit correspondre exactement à la recette) :

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
| PHP | MySQL 8.4 | 1 |
| Node (npm, pnpm) | PostgreSQL 16, MySQL 8.4, MongoDB 8.0 ; SMTP en capture | 1, plus la capture SMTP |
| Go | PostgreSQL 16, MySQL 8.4, MongoDB 8.0 ; SMTP en capture | 1, plus la capture SMTP |
| Python fermé (`python314-node24-closure-v1`) | MariaDB 11.8, Redis 7.4 | jusqu'à 3 |
| Ruby | PostgreSQL 16 par variante publiée, Redis 7.4 ; SMTP en capture | jusqu'à 3 |
| Python simple (`python-3.14.7-bookworm-v1`) | aucun | 0 |

- PostgreSQL avec extensions : seulement une variante publiée, liste exacte, version `16`. `hstore, pg_trgm,
  unaccent, vector` (exemple discourse) ou `cube, earthdistance, pg_trgm, unaccent, uuid-ossp, vector`.
- En Node et Go, un service exige le cycle de vie du moteur (`lifecycle.state_directory`), `tls=required` et
  `ca_file`, le chemin où écrire l'autorité de certification.
- `local_endpoint` (v2.37.0) : relais MySQL en boucle locale, en clair côté app et en TLS vérifié vers le serveur,
  pour un client qui ne parle pas TLS. `DATABASE_URL` et `MYSQL_URL` injectées visent alors le relais ; sans relais
  ni URL propre au service, le plan avertit (`services.url_without_tls`).
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
- Options refusées aujourd'hui : `backup`, `plan`, `quota`, `privileges`, `databases`.
- La matrice complète, avec la raison de chaque refus, est en annexe de [PAASXML-REFERENCE.md](PAASXML-REFERENCE.md).

## 4. Processus, stockage, cycle de vie (N0)

| Domaine | Ce qui est disponible |
|---|---|
| Processus | Un processus `web`, port ≥ 1024, sonde HTTP (`healthcheck`), une réplique. En Python fermé et Ruby : un web et jusqu'à 7 workers `in-process`, supervisés ensemble ; arrêt du groupe en 120 s au plus. |
| Ressources | `resources.cpu`, `memory`, `cpu_limit`, `memory_limit`. Un pod qui demande plus que n'alloue le plus grand nœud est refusé avant le build, au push comme à `paas builds rebuild` (`N0_RESOURCES_LARGER_THAN_NODES`, v2.38.1), avec une demande qui tient. |
| Temps de build | Budgets publiés par étape : prepare 600 s, build 3 600 s, tests 2 100 s, build entier 3 600 s ; `build.resources.timeout_seconds` (60 à 21 600 s) relève prepare et build (v2.38.0) ; `paas config plan` les affiche ; un dépassement nomme l'étape, le budget et la durée. |
| Volumes | Jusqu'à 32, de 1 à 1024 Gio, `rwo` (`local-path`) ou `rwx` (`paas-cephfs`, jamais prouvé). `preserve_on_delete=true` obligatoire ; supprimer l'app garde le volume. Une réplique avec un volume rwo. Un volume réservé déplacé est refusé au gel du plan (`ENV_STORAGE_RESERVED_VOLUME_CHANGED`). |
| Liens et copies | `storage.links` (chemin de l'app vers un volume), `storage.seeds` (copie initiale `absent-only`). `storage.private` n'est pas raccordé (refusé par la projection, mesuré le 2026-10-15) ; la variable de gabarit `{{storage.private}}` existe. |
| Variables | `env` (gabarits `{{…}}` : secrets, services, app), `env_stages`, `files` (rendus au build ou au démarrage). `http_endpoints` : recette npm stable seulement, chaque `target_port` égal au port du process web ; refusé en PHP (`ENV_COMPONENTS_REQUIRE_SEPARATE_QUALIFICATION`). |
| Comptes | `account` et `accounts` : compte d'administration créé par une commande native ou un formulaire, mot de passe par l'entrée standard. PHP : un contrôle `ready` doit lire le compte (`ENV_TECHNICAL_ACCOUNT_CHECK_REQUIRED`). Node npm : avec un service déclaré seulement (moteur de `paas-entry`), comptes supplémentaires par HTTP. |
| Cycle de vie | `install`, `prepare`, `upgrade` (commandes natives, entrée standard jusqu'à 16 Kio) ; en PHP `install_http`, `install_php`, verrou (`lock`) et reprise (`interrupted`) ; en Python fermé `install_python` ; `checks` (SQL en lecture seule), `file_checks`, `http_checks`, `mail_sink`, `start_files`, `init` (script du dépôt avant le serveur). Node npm : sans service, seule `init` est lue ; avec un service, le moteur de `paas-entry` lit `state_directory`, `install`, `upgrade`, `http_checks`, `mail_sink` et les comptes, et refuse `init` (mesuré le 2026-10-15). |
| Entrée HTTPS | Websockets acceptés, 100 Mo par requête, délais de 86 400 s, limite de débit par IP. Hôte de l'app : `apps-<8hex>.<domaine des apps>`. |

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
| `database_not_ready` (v2.29.2) | rollout | Le build a réussi, mais une base réservée de l'app (MySQL, PostgreSQL, Redis, MongoDB) n'est pas prête après 120 s : rien n'est déployé. L'état du pod de la base, ses avertissements, la fin de son journal et la marche à suivre (base jamais initialisée : supprimer puis recréer l'app ; base lente : redéployer le même build). |

Depuis v2.31.0, chaque erreur dit qui doit agir : `Cust` quand le `paas.xml` ou le dépôt se corrige, `Paas` quand la
plateforme ne sait pas encore le faire, avec la capacité qui lui manque et la façon dont c'est établi (`paas config
plan` l'affiche aussi, `[Cust]` ou `[Paas]`). Les codes et leur règle sont dans la section « Codes de refus » de
[PAASXML-REFERENCE.md](PAASXML-REFERENCE.md).

## 5 ter. Disponible depuis v2.30.0 (en production le 2026-10-10)

| Sujet | Ce qui change |
|---|---|
| Placement des apps | Comportement de la plateforme, sans clé : chaque pod d'une app (web, autres processus, tâches de release, tâches ponctuelles, tâches planifiées) et chaque build `paas.xml` préfèrent les serveurs qui ne portent pas le control-plane (sur ce cluster : un deuxième nœud et un troisième nœud plutôt que le nœud du control-plane). C'est une préférence : un pod qui ne tient sur aucun autre serveur va quand même sur le nœud du control-plane. Un pod qui monte un volume `local-path` reste sur le serveur de ce volume, créé là où le premier pod de l'app a démarré : une app neuve s'installe donc hors de le nœud du control-plane, une app existante à volume `local-path` reste où elle est ; une app sans volume ou à volume CephFS suit la préférence à son prochain déploiement. Les bases réservées ne changent pas encore de placement. Prouvé le 2026-10-10 : app neuve emoncms (build sur un deuxième nœud, scan, volume, base et pod web sur un troisième nœud), reconstruction de ns-cve-304104 (build sur un deuxième nœud, son pod web reste sur le nœud du control-plane avec son volume `local-path`). Les 55 caches de build qui retenaient des builds sur le nœud du control-plane ont été supprimés le même jour. |
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
| Releases et suivi (v2.48.0) | Release appliquée à 0 réplique (`paas scale web 0`) : publiée dormante (`scaled-zero`) ; `paas scale web 1` la sert. Fenêtre de stabilité à trois horloges (placement et tirage, démarrage, observation). `paas ps` : pods de la release courante ; `paas logs --since` ; journal de la release et audit de l'app. |
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

## 5 octies. Disponible depuis v2.51.0 et v2.51.1 (en production depuis le 2026-10-20)

| Sujet | Ce qui change |
|---|---|
| Recette Python simple (v2.51.0) | La recette Python simple lit le `paas.xml` : `build.python`, `build.env`, `build.steps`, cycle de vie (`lifecycle.*`), comptes, processus internes ; PostgreSQL 16 en TLS vérifié (par le pilote de l’app : psycopg 3 ou psycopg2) et Redis 7.4. Listes figées lues depuis `poetry.lock`, `uv.lock`, `Pipfile.lock` ou un `requirements.txt` épinglé avec ses empreintes. Un paquet sans roue pour l’interpréteur se déclare dans `build.python.source_builds` : il est construit depuis le sdist épinglé, hors réseau, et les bibliothèques que la réparation intègre à la roue sont analysées par le scan. Montages persistants ; Dockerfile amont déclarable (`build.source_dockerfile`). |
| Listes de dépendances produites par la plateforme (v2.51.0, EX-23) | Un arbre sans liste exacte (npm sans `package-lock.json`, Python à plages ou sans empreintes dans `requirements.txt`, `pyproject.toml` ou `setup.cfg`, Composer sans `composer.lock`) n’a rien à ajouter : au push, la plateforme résout la liste une fois, depuis le registre officiel, avec les empreintes, et l’écrit dans le Git de l’app (`paas/dependencies/`, provenance `paas/dependencies.json`) sur la branche `paas/dependency-list/<id>`. Mode `automatic` (par défaut) : intégrée à votre branche par avance rapide ; `manual` : proposée, acceptée par `paas dependencies accept`. La liste est figée : chaque build l’installe hors réseau, le reçu dit qu’elle vient de la plateforme ; elle ne change que sur demande (`paas dependencies produce`). Liste modifiée, périmée ou d’une autre app : refusée par son nom. CLI `paas dependencies list\|show\|produce\|accept\|mode`, page Sécurité de la console, API `/v1/apps/{app}/dependency-lists`. |
| Verrou Yarn réparé (v2.51.0, R-0090.3) | Frontend Yarn 1 d’un build Go dont le `yarn.lock` a des entrées hors de leur plage : la plateforme les répare une fois de la même façon (registre, empreintes, plan, reçu). Votre `yarn.lock` n’est pas modifié ; les builds suivants installent la liste réparée hors réseau. |
| Manifeste npm hors racine (v2.51.0) | `build.node.manifest` nomme le `package.json` qu’un arbre garde sous la racine (`install/package.json`), pour un projet npm à la racine sans `package.json` : la préparation le place à la racine de la copie de build, le reçu le nomme. |
| Corrections (v2.51.0) | Composer : un métapaquet est admis dans un verrou, sans archive à acquérir. |
| Corrections (v2.51.1) | Listes npm et Yarn produites : les résolveurs s’exécutent en service (ils sortaient sans résultat). Constructions Python depuis la source : l’inventaire des bibliothèques intégrées est exporté là où la build écrit (la build échouait). `paas builds rebuild` d’un commit dont la liste est à produire la fait produire, comme un push ; un refus restant nomme `paas dependencies produce`. CLI : un build en échec à sa préparation se lit « failed ». |

## 6. Prévu

Chaque capacité est développée comme une option générique : aucune app n'est codée dans la plateforme, l'app
qui en a besoin la déclare dans son `paas.xml`. L'ordre suit la feuille de route ; il peut changer.

| Identifiant | Contenu |
|---|---|
| EX-02, T-05.4 | Modules natifs Node (liaisons précompilées publiées, ou compilation en bac à sable hors réseau) et correctifs `patch-package` de l'amont appliqués hors réseau : Wiki.js (extract-files), cusdis (moteurs Prisma) |
| N0.NET | Liens déclarés entre apps : disponibles depuis v2.30.0 (section 5 ter). Règles de sortie, IPv6 : prévus |
| N1.DATA | Correctifs de verrou et instantanés de registre publiés comme données, sans recompiler la plateforme |
| N2.BPHP, N2.BNG, N2.BRUBY, N2.BPY | Combinaisons runtime × service manquantes (PHP × PostgreSQL ou Redis, Node et Go × Redis ou MariaDB, Ruby et Python × autres bases) |
| N2.MULTI | Plusieurs services par app en PHP, Node et Go |
| N2.PGEXT, N2.OPTIONS | Extensions PostgreSQL déclarables ; privilèges, bases nommées, réplicas, sauvegarde et PITR |
| N0.PROC | Worker, cron, release et job séparés |
| N2.OPENSEARCH, N2.RABBITMQ, N2.S3, N2.CLICKHOUSE, N2.VALKEY | Nouveaux services |
| N0.RUNTIME, N0.EDGE, N0.BUILD, N1.MULTIRT, N1.STATIC | Paquets système, réglages d'entrée par app, secrets de build, assets Node dans une recette PHP, statique prouvé |
| N1.JVM, N1.ELIXIR, N1.RUST, N1.DOTNET, N1.VERSIONS | Nouveaux runtimes et versions |
| N1.COMPOSE | Plusieurs conteneurs (le Dockerfile de l'app est disponible depuis v2.34.0, section 5 quater) |
| N2.SMTP, N2.IMAP, N0.TCP, N0.DOMAINS | Courrier réel, ports TCP, domaines personnalisés |
| N0.GPU, N2.INFERENCE, N0.STORAGE | GPU, inférence, stockage des modèles |
| N0.SCALE, N0.DEPLOY | Réplicas, autoscaling, placement ; stratégies de déploiement |
