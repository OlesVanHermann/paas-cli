# erpnext — exemple paas.xml

Exemple de `paas.xml` pour **ERPNext 16.37.0** (Python), prêt à adapter. Il ne modifie pas le logiciel : il s'ajoute à l'arbre amont tel quel.

## Installer

Depuis le dossier `exemples/` (prérequis : [README des exemples](../README.md)) :

```bash
./push.sh erpnext mon-erp       # sans nom, l'app s'appelle « erpnext »
```

Le script clone la source amont, ajoute ce `paas.xml`, scelle les secrets, vérifie le plan, crée l'app et pousse. La plateforme construit, teste, scanne, signe, déploie et installe le logiciel : création du site Frappe, installation d'ERPNext, comptes. Compter six minutes environ.

Secrets tirés au hasard et scellés par le script (valeurs dans `~/paas-exemples/<app>.secrets/`) : `PAASADMIN_PASSWORD`.

Retirer l'app : `./clean.up mon-erp` (restaurable pendant la corbeille ; voir [Retirer une app](../README.md#retirer-une-app)).

## Logiciel d'origine

Sources GitHub frappe/erpnext v16.37.0, arbre inchangé ; seul ajout au contenu amont : ce fichier. Frappe vient de la composition que le fichier déclare, avec la fermeture de dépendances Python et Node que la plateforme publie pour ERPNext.

Source exacte (fichier [`source`](source)) : https://github.com/frappe/erpnext, étiquette `v16.37.0`, commit `af63cde4941570ec7b9e12422c68302762cfcf91`.

## Ce que l'exemple montre

- **N1, la recette** : Python 3.14 avec Node 24 (`python314-node24-closure-v1`), la recette fermée de la plateforme pour Frappe et ERPNext.
- **N0, processus, stockage et cycle de vie** : un processus `web` et quatre workers (`application`, `realtime`, `queue`, `scheduler`) ; un volume `data` (2 Gio) ; une installation qui crée le site, installe ERPNext et ses comptes, avec des contrôles en base avant et après les mises à jour.
- **N2, les services** : MariaDB 11.8 dédiée et Redis 7.4, tous deux en TLS exigé : la plateforme dépose leurs certificats d'autorité dans `/data/tls/`, et Redis passe par un relais local (`127.0.0.1:6379`) qui parle au serveur en TLS vérifié.

## Validation

- Installé de bout en bout le 2026-10-19 par `./push.sh erpnext <app>` (plateforme 2.49.7, `paas` 2.49.7) : image acceptée par les deux exceptions ci-dessous, release en service environ six minutes après le push ; connexion du compte `paasadmin@example.com` vérifiée par l'API d'ERPNext (utilisateur système, rôle System Manager) ; un mauvais mot de passe est refusé (401) ; un document créé (ToDo) puis relu dans la base. Frappe 16.36.1, ERPNext 16.37.0.
- Sans section `<security>`, le premier build du 19 octobre a été refusé par la porte CVE : deux failles HIGH, nommées ci-dessous.
- Contrat `v2.9.0`, recette `python314-node24-closure-v1`, services : mariadb, redis.

## Exceptions CVE

**Liste d'exceptions (mode A).** Le `paas.xml` accepte deux failles nommées, chacune avec son paquet, sa raison et sa date limite (2027-04-16) ; toute autre faille HIGH ou CRITICAL bloque l'image :
- CVE-2025-26240 dans `pdfkit` 1.0.0, dépendance de Frappe pour les PDF : aucune version corrigée n'est publiée ;
- CVE-2026-106443 dans `weasyprint` 68.0, autre dépendance PDF de Frappe : corrigée en 70.0, que la fermeture d'ERPNext publiée par la plateforme n'a pas encore.

Retirez chaque exception dès qu'une version corrigée est dans la fermeture. `paas-apps --app <app> builds cve <build>` montre les deux failles et l'exception qui accepte chacune.

## Adapter

Variables (`<env>`), ressources, volumes, services : modifiez `paas.xml`, puis vérifiez avec `./push.sh --plan erpnext` ou `paas config plan` (voir [Installer à la main](../README.md#installer-à-la-main)). Le plan avertit que `DATABASE_URL` et `MYSQL_URL`, que la plateforme injecte, visent le serveur sans paramètre TLS : un client qui les lit doit ouvrir lui-même la connexion TLS, avec le certificat `/data/tls/mysql-ca.pem`.

## Différences avec le fichier en service

Les valeurs scellées sont remplacées par `A-SCELLER` : elles ne s'ouvrent que dans le tenant qui les a scellées. Le compte de démonstration porte des noms neutres : utilisateur `paasadmin`, adresse `paasadmin@example.com`, secret `PAASADMIN_PASSWORD`. La section `<security>` (deux exceptions) est ajoutée au fichier de la bibliothèque.
