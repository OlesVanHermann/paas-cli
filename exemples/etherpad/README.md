# etherpad — exemple paas.xml

Exemple de `paas.xml` pour **Etherpad 3.3.7** (Node), prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh etherpad mon-app      # sans nom, l'app s'appelle « etherpad »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (restaurable pendant la corbeille ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub ether/etherpad-lite v3.3.7 (release de sécurité GHSA-4mx2-rqx5-2pp6), arbre inchangé ; seul ajout au contenu amont : ce fichier. Les interfaces d'administration et OIDC sont construites par le script amont `build:ui`.

Source exacte (fichier [`source`](source)) : https://github.com/ether/etherpad-lite, étiquette `v3.3.7`, commit `b24997e72e493d6dd6ed72d347a77eb456865571`.

## Ce que l'exemple montre

- **N1, la recette** : Node 24.20.0 et pnpm (`node-24.20.0-pnpm-workspace-v2`), comme l'image amont : la production n'installe que la racine, le serveur et ses outils.
- **N0, processus et stockage** : un processus `web` ; deux volumes, `var` (1 Gio) et `plugins` (1 Gio).
- **N2, les services** : une base PostgreSQL 16 dédiée, en TLS vérifié.

## Validation

- Installé de bout en bout le 2026-10-19 par `./push.sh etherpad <app>` (plateforme 2.49.5, `paas` 2.49.5) : `/health` rend 200 (`releaseId` 3.3.7) ; connexion du compte `paasadmin` vérifiée (page « Etherpad ») ; sans identifiant ou avec un mauvais mot de passe : 401 ; Etherpad écrit sa session dans sa base PostgreSQL.
- Fichier d'origine vérifié en service sur la plateforme di2amp le 2026-10-18 (plateforme 2.48.0).
- Contrat `v2.15.0`, recette `node-24.20.0-pnpm-workspace-v2`, services : postgresql.

## Exceptions CVE

**Contrôle CVE désactivé (mode B).** Le `paas.xml` déclare `<security><block_on>none</block_on></security>` : le scan tourne toujours et son rapport reste lisible, mais aucune faille ne refuse l'image. Etherpad 3.3.7, dernière version publiée, embarque des paquets npm vulnérables, et aucune version publiée n'en est exempte. Le scan de la plateforme du 2026-10-19 en relève 3 HIGH (Node.js), aucune CRITICAL.

Relisez le rapport (`paas-apps --app <app> builds cve <build>`) à chaque build. `<block_on>critical</block_on>` n'accepte que les HIGH ; une liste d'exceptions nommées (mode A, voir [filebrowser](../filebrowser/)) n'accepte que les failles qu'elle nomme.

## Adapter

- **Toutes les pages sont réservées aux utilisateurs déclarés** (`"requireAuthentication":true` dans le `settings.json` rendu au démarrage). Les utilisateurs sont ceux du mécanisme natif d'Etherpad : `administrator`, le compte de `<account>`, administrateur ; `paasadmin`, au mot de passe `PAASADMIN_PASSWORD`, non administrateur. Pour des pads publics, passez `requireAuthentication` à `false` dans ce gabarit.
- Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan etherpad` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, secret `PAASADMIN_PASSWORD`.
