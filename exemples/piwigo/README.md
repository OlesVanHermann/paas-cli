# piwigo — exemple paas.xml

Exemple de `paas.xml` pour **piwigo 16.4.0**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh piwigo mon-app      # sans nom, l'app s'appelle « piwigo »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (réversible ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Piwigo 16.4.0 : arbre du tag officiel (GitHub Piwigo/Piwigo, tag 16.4.0, commit bef1a4ac424b4e986589e4cfc9f4d134f1b16f15), inchangé ; seul ajout au contenu amont : ce fichier.

Source exacte (fichier [`source`](source)) : https://github.com/Piwigo/Piwigo, étiquette `16.4.0`, commit `bef1a4ac424b4e986589e4cfc9f4d134f1b16f15`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-08).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan piwigo` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh piwigo <app>` : release en service moins de 5 min après le push, connexion du compte `paasadmin` vérifiée.
- Contrat `v2.23.0`, recette `php-8.4.26-apache-alpine-cache-v5`, services : mysql.

## Exceptions CVE

Aucune : le scan de l'image validée ne garde aucune faille HIGH ni CRITICAL.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan piwigo` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service.
