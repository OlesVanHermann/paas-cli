# discourse — exemple paas.xml

Exemple de `paas.xml` pour **Discourse 2026.8.0** (Ruby), prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh discourse mon-forum   # sans nom, l'app s'appelle « discourse »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel : migrations, réglages du forum, feuilles de style, comptes. Compter une dizaine de minutes.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-forum` (restaurable pendant la corbeille ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub discourse/discourse v2026.8.0, arbre inchangé ; seul ajout au contenu amont : ce fichier.

Source exacte (fichier [`source`](source)) : https://github.com/discourse/discourse, étiquette `v2026.8.0`, commit `badad7b0456a628e578bc48b9f8c1259422b5d58`.

## Ce que l'exemple montre

- **N1, la recette** : Ruby 3.4.10 avec Node 24.20.0 et pnpm (`ruby34-pnpm-offline-v1`), dépendances hors ligne.
- **N0, processus, stockage et cycle de vie** : un processus `web` (nginx) et un worker `server` (pitchfork) dans le même conteneur ; trois volumes, `uploads` (2 Gio), `state` (1 Gio) et `stylesheets` (1 Gio) ; une installation qui migre la base, importe les réglages du forum et précompile les feuilles de style.
- **N2, les services** : PostgreSQL 16 (TLS vérifié, extensions `hstore`, `pg_trgm`, `unaccent`, `vector`), Redis 7.4 et le relais SMTP de la plateforme, en capture.

## Validation

- Installé de bout en bout le 2026-10-19 par `./push.sh discourse <app>` (plateforme 2.49.5, `paas` 2.49.5) : release en service environ 9 minutes après le push ; connexion du compte `paasadmin` (administrateur) vérifiée par l'API de Discourse ; un sujet créé, relu, puis trouvé par la recherche.
- Puis retiré par `./clean.up` et effacé par la plateforme : plus aucune ressource à aucun niveau (processus, entrée web, base, Redis, volumes, images, dépôt Git, fiche), seules restent les traces (audit, journal).
- Fichier d'origine vérifié en service sur la plateforme di2amp le 2026-10-18 (plateforme 2.48.0).
- Contrat `v2.9.0`, recette `ruby34-pnpm-offline-v1`, services : postgresql, redis, smtp.

## Exceptions CVE

**Contrôle CVE désactivé (mode B).** Le `paas.xml` déclare `<security><block_on>none</block_on></security>` : le scan tourne toujours et son rapport reste lisible, mais aucune faille ne refuse l'image. Discourse 2026.8.0 embarque les gems jwt, oauth, oauth2, oj et rubyzip vulnérables (5 HIGH au scan local du 2026-10-10). Discourse 2026.9.0 les corrige, mais la plateforme n'en publie pas encore la fermeture de dépendances : passez en 2026.9.0 et retirez ce bloc dès qu'elle le sera.

Relisez le rapport (`paas-apps --app <app> builds cve <build>`) à chaque build.

## Adapter

- Le forum est privé : connexion requise, inscription sur invitation seulement (réglages de l'installation, dans `paas.xml`).
- Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan discourse` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`.
