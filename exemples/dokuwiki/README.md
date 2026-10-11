# dokuwiki — exemple paas.xml

Exemple de `paas.xml` pour **dokuwiki 2026-07-14c**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh dokuwiki mon-app      # sans nom, l'app s'appelle « dokuwiki »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (réversible ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

DokuWiki 2026-07-14c : arbre amont officiel tel quel, commit `e674707568da10ecfdba47a1c21acccefd168ff9` (github.com/dokuwiki/dokuwiki), dépendances Composer livrées par l'amont ; le seul ajout est ce fichier.

Source exacte (fichier [`source`](source)) : https://github.com/dokuwiki/dokuwiki, étiquette `release-2026-07-14c`, commit `e674707568da10ecfdba47a1c21acccefd168ff9`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-04).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan dokuwiki` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh dokuwiki <app>` : script terminé en 4 s, release en service 2 min après le lancement, puis connexion de `paasadmin` vérifiée ; l'app a ensuite été retirée par `./clean.up <app>`.
- Contrat `v2.9.0`, recette `php-8.4.26-apache-alpine-iconv-v7`.

## Exceptions CVE

Aucune : le scan de l'image validée ne garde aucune faille HIGH ni CRITICAL.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan dokuwiki` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service.
