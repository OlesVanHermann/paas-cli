# wordpress — exemple paas.xml

Exemple de `paas.xml` pour **wordpress 7.1.2**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh wordpress mon-app      # sans nom, l'app s'appelle « wordpress »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (restaurable pendant la corbeille ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub WordPress 7.1.2, commit 160387b. Le seul ajout au contenu amont est ce fichier XML.

Source exacte (fichier [`source`](source)) : https://github.com/WordPress/WordPress, étiquette `7.1.2`, commit `160387b7312c9407c7fe4b1d3dd2055206749a34`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-05).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan wordpress` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh wordpress <app>` : script terminé en 8 s, build vérifié (tests, scan CVE, signature) puis release en service 2 min après le lancement ; moins de 3 min après le lancement, la connexion de `paasadmin` ouvre le tableau de bord de WordPress 7.1.2.
- Contrat `v2.9.2`, recette `php-8.4.26-apache-alpine-iconv-v7`, services : mysql.

## Exceptions CVE

Aucune : le scan de l'image validée ne garde aucune faille HIGH ni CRITICAL.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan wordpress` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service.
