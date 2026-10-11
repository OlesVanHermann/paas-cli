# bookstack — exemple paas.xml

Exemple de `paas.xml` pour **bookstack 26.09.1**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh bookstack mon-app      # sans nom, l'app s'appelle « bookstack »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (réversible ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub v26.09.1, commit 31d94dd8b98e3334dc01b66bed6d514719a2f85d. Le seul ajout au contenu amont est ce fichier XML. Les capacités encore absentes sont consignées dans le cahier des charges PaaS.

Source exacte (fichier [`source`](source)) : https://github.com/BookStackApp/BookStack, étiquette `v26.09.1`, commit `31d94dd8b98e3334dc01b66bed6d514719a2f85d`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-04).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan bookstack` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh bookstack <app>` : release en service moins de 5 min après le push, connexion du compte `paasadmin` vérifiée.
- Contrat `v2.9.0`, recette `php-8.4.26-apache-alpine-iconv-v7`, services : mysql.

## Exceptions CVE

Aucune : le scan de l'image validée ne garde aucune faille HIGH ni CRITICAL.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan bookstack` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service.
