# listmonk — exemple paas.xml

Exemple de `paas.xml` pour **listmonk 6.2.0**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh listmonk mon-app      # sans nom, l'app s'appelle « listmonk »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (restaurable pendant la corbeille ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub knadh/listmonk v6.2.0, commit ef0a758, arbre inchangé ; seul ajout au contenu amont : ce fichier. Construction de l'amont (Makefile : build-email-builder, build-frontend, build) : l'éditeur d'e-mails puis le frontend d'administration, chacun installé par Yarn depuis son yarn.lock, puis le binaire Go sans cgo. Les ressources (frontend, statiques, i18n, requêtes SQL) sont lues sur le disque, mode prévu par l'amont quand le binaire ne porte pas leur archive stuffbin.

Source exacte (fichier [`source`](source)) : https://github.com/knadh/listmonk, étiquette `v6.2.0`, commit `ef0a75872463f10a4848af6c547d1c057405453a`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-07).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan listmonk` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh listmonk <app>` : image acceptée par la politique ci-dessous, release en service moins de 5 min après le push, connexion du compte `paasadmin` vérifiée.
- Contrat `v2.18.0`, recette `go-1.27.1-node24-yarn-v6`, services : postgresql.

## Exceptions CVE

**Exemple de contrôle CVE désactivé (mode B).** Le `paas.xml` déclare `<security><block_on>none</block_on></security>` : le scan tourne toujours et son rapport reste lisible, mais aucune faille, CRITICAL comprises, ne refuse l'image. Il garde quatre failles HIGH, toutes marquées « accepted (policy) » :
- CVE-2026-78667, CVE-2026-78669 et CVE-2026-97031 dans la bibliothèque standard de Go 1.27.1, la version de la recette `go-1.27.1-node24-yarn-v6` (corrigées en Go 1.27.2, que la plateforme ne propose pas encore) ;
- CVE-2026-78669 dans `golang.org/x/net` v0.57.0, retenu par les dépendances de listmonk (corrigée en v0.60.0 ; la v6.2.0 est la dernière version publiée).

Ce mode accepte aussi toute faille future, sans la nommer : réservez-le aux essais, et relisez le rapport (`paas-apps --app <app> builds cve <build>`) à chaque build. `<block_on>critical</block_on>` n'accepte que les HIGH ; sans section `<security>`, le blocage par défaut (HIGH et CRITICAL) revient.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan listmonk` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service, à une addition près : la section `<security>` (politique CVE).
