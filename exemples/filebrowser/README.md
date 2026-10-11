# filebrowser — exemple paas.xml

Exemple de `paas.xml` pour **filebrowser 1.5.8-stable**, prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh filebrowser mon-app      # sans nom, l'app s'appelle « filebrowser »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-app` (réversible ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub gtsteffaniak/filebrowser v1.5.8-stable (FileBrowser Quantum), commit 84024e2, arbre inchangé ; seul ajout au contenu amont : ce fichier. Construction de l'amont (make build) : le frontend que npm construit dans backend/http/embed est embarqué dans le binaire Go, compilé sans cgo comme le profil « slim » de l'amont (aperçus PDF et vidéo indisponibles : ni MuPDF ni ffmpeg dans l'image).

Source exacte (fichier [`source`](source)) : https://github.com/gtsteffaniak/filebrowser, étiquette `v1.5.8-stable`, commit `84024e258b4e71d32b8cce48c69ae5172a65fe08`.

## Validation

- Fichier d'origine en service sur la plateforme di2amp (version du 2026-10-06).
- Planifié sans erreur le 2026-10-11 par `./push.sh --plan filebrowser` sur le commit amont exact : `paas` 2.30.0, catalogue de production.
- Installé de bout en bout le 2026-10-11 par `./push.sh filebrowser <app>` : image acceptée grâce aux exceptions ci-dessous, release en service moins de 4 min après le push, connexion du compte `paasadmin` vérifiée.
- Contrat `v2.17.0`, recette `go-1.27.1-node24-npm-v5`.

## Exceptions CVE

**Exemple de liste d'exceptions (mode A).** Le scan garde quatre failles HIGH. Le `paas.xml` les accepte une par une, chacune avec son paquet, sa raison et sa date limite (2027-04-09) :
- CVE-2026-78667, CVE-2026-78669 et CVE-2026-97031 dans la bibliothèque standard de Go 1.27.1, la version de la recette `go-1.27.1-node24-npm-v5` (corrigées en Go 1.27.2, que la plateforme ne propose pas encore) ;
- CVE-2026-78669 dans `golang.org/x/net` v0.59.0, épinglé par FileBrowser (corrigée en v0.60.0 ; la v2.0.0-stable épingle encore v0.59.0).

Le blocage par défaut reste en place : toute autre faille HIGH ou CRITICAL refuse l'image. `paas-apps --app <app> builds cve <build>` montre chaque faille acceptée, par quoi et jusqu'à quand. Retirez une exception dès que sa faille est corrigée : recette Go 1.27.2 pour les trois de la bibliothèque standard, nouvelle version de FileBrowser pour `golang.org/x/net`.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan filebrowser` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)).

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. Un nom de secret ne peut pas commencer par `PAAS_`, préfixe réservé aux variables de la plateforme. Le reste est identique au fichier en service, à une addition près : la section `<security>` (politique CVE).
