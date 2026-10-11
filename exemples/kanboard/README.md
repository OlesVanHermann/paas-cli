# kanboard — exemple paas.xml

Exemple de `paas.xml` pour **kanboard 1.2.54**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh kanboard mon-app      # sans nom, l'app s'appelle « kanboard »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`, tiré au hasard ; `KANBOARD_INITIAL_PASSWORD`, le mot de passe initial que Kanboard écrit pour son compte `admin` (`admin`, fichier [`valeurs`](valeurs)), que l'installation remplace aussitôt par un mot de passe généré.

Retirer l'app : `./clean.up mon-app` (réversible ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub Kanboard v1.2.54, commit 9ce6a5edc. Le seul ajout au contenu amont est ce fichier XML.

Source exacte (fichier [`source`](source)) : https://github.com/kanboard/kanboard, étiquette `v1.2.54`, commit `9ce6a5edc5b646ef15780cb445bc6d2c39d9898f`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-05).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan kanboard` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh kanboard <app>` : release en service moins de 5 min après le push, connexion du compte `paasadmin` vérifiée.
- Contrat `v2.9.2`, recette `php-8.4.26-apache-alpine-sqlite-intl-v4`.

## Exceptions CVE

Aucune : le scan de l'image validée ne garde aucune faille HIGH ni CRITICAL.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan kanboard` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service.
