# Exemples : une app en une commande

Treize logiciels connus, en cinq langages (PHP, Go, Node, Ruby, Python), prêts à
installer sur le PaaS di2amp : `push.sh` en installe un en une commande, `clean.up`
le retire. Chaque dossier contient :
- `paas.xml`, la seule chose ajoutée au logiciel, qui reste inchangé ;
- `source`, l'adresse, l'étiquette et le commit exacts de son code amont ;
- `README.md`, ce que l'exemple installe et comment il a été vérifié ;
- `valeurs` (Kanboard seulement), un secret dont le logiciel impose la valeur.

| Exemple | Langage | Logiciel | Données | Politique CVE |
|---|---|---|---|---|
| [wordpress](wordpress/) | PHP | WordPress 7.1.2 | MySQL 8.4, volume de médias | par défaut |
| [drupal](drupal/) | PHP | Drupal 11.4.7 | MySQL 8.4, volume de fichiers | par défaut |
| [dokuwiki](dokuwiki/) | PHP | DokuWiki 2026-07-14c | fichiers sur volume, sans base | par défaut |
| [bookstack](bookstack/) | PHP | BookStack 26.09.1 | MySQL 8.4, volume d'envois | par défaut |
| [kanboard](kanboard/) | PHP | Kanboard 1.2.54 | SQLite sur volume | par défaut |
| [freshrss](freshrss/) | PHP | FreshRSS 1.30.0 | SQLite sur volume | par défaut |
| [piwigo](piwigo/) | PHP | Piwigo 16.4.0 | MySQL 8.4, volume | par défaut |
| [opencart](opencart/) | PHP | OpenCart 4.1.0.4 | MySQL 8.4, volume | par défaut |
| [filebrowser](filebrowser/) | Go | FileBrowser Quantum 1.5.8 | fichiers sur volume | **liste d'exceptions** |
| [listmonk](listmonk/) | Go | listmonk 6.2.0 | PostgreSQL 16, volume d'envois | **contrôle désactivé** |
| [etherpad](etherpad/) | Node | Etherpad 3.3.7 | PostgreSQL 16, deux volumes | **contrôle désactivé** |
| [discourse](discourse/) | Ruby | Discourse 2026.8.0 | PostgreSQL 16, Redis 7.4, SMTP, trois volumes | **contrôle désactivé** |
| [erpnext](erpnext/) | Python | ERPNext 16.37.0 | MariaDB 11.8, Redis 7.4, volume | **liste d'exceptions** |

Les treize fonctionnent : les dix premiers ont été installés de bout en bout le
11 octobre 2026, etherpad, discourse et erpnext le 19 octobre (voir
« Vérification »).

## Ce que montre un exemple : N1, N0, N2

Le `paas.xml` déclare les trois niveaux de la plateforme :
- **N1, la recette** : le langage et son outillage, que la plateforme construit
  hors ligne (PHP 8.4, Go 1.27, Node 24 avec npm ou pnpm, Ruby 3.4, Python 3.14
  avec Node) ;
- **N0, les processus, le stockage et le cycle de vie** : processus web et
  workers, volumes, installation et mises à jour du logiciel ;
- **N2, les services** : bases PostgreSQL, MySQL ou MariaDB dédiées, Redis,
  relais SMTP, réservés pour l'app.

Les README d'etherpad, de discourse et d'erpnext les détaillent (section
« Ce que l'exemple montre »). En Python, seule la recette fermée de la
plateforme (Python avec Node) prend aujourd'hui des services : c'est celle
d'ERPNext.

## Politique CVE : trois exemples

Chaque image construite est scannée ; la porte de sécurité la refuse si une
faille n'est pas acceptée. Les exemples montrent les trois réglages :
- **par défaut** (huit exemples, aucune section `<security>`) : toute faille
  HIGH ou CRITICAL bloque l'image. Ces huit-là n'en ont aucune ;
- **liste d'exceptions** ([filebrowser](filebrowser/), [erpnext](erpnext/), mode A) : chaque
  faille acceptée est nommée, avec son paquet, sa raison et sa date limite ;
  toute autre faille HIGH ou CRITICAL bloque toujours :

  ```xml
  <security>
    <cve_exceptions>
      <item><id>CVE-2026-78667</id><package>stdlib</package><expires>2027-04-09</expires>
        <reason>Pourquoi ce risque est accepté, et quand le retirer</reason></item>
    </cve_exceptions>
  </security>
  ```

- **contrôle désactivé** ([listmonk](listmonk/), [etherpad](etherpad/),
  [discourse](discourse/), mode B) : le scan tourne et
  son rapport reste lisible, mais rien ne bloque, CRITICAL comprises. À
  réserver aux essais ; `<block_on>critical</block_on>` n'accepte que les
  HIGH :

  ```xml
  <security><block_on>none</block_on></security>
  ```

FileBrowser et listmonk en ont besoin : leur image garde quatre failles
HIGH, trois dans la bibliothèque standard de Go 1.27.1 (la version des
recettes Go de la plateforme, corrigée en 1.27.2) et une dans
`golang.org/x/net` (corrigée en v0.60.0, qu'aucune de leurs versions
publiées n'utilise encore).
Etherpad et Discourse aussi : aucune de leurs versions publiées n'est exempte
de paquets npm ou de gems vulnérables (Discourse 2026.9.0 corrige les siens,
mais la plateforme n'en publie pas encore la fermeture de dépendances). ERPNext
nomme deux failles : pdfkit 1.0.0, sans version corrigée, et weasyprint 68.0,
corrigée en 70.0, que sa fermeture n'a pas encore.
`paas-apps --app <app> builds cve <build>` montre chaque faille, si elle
bloque ou par quoi elle est acceptée.

## Prérequis

- `git` et `jq` ;
- la CLI `paas` 2.30 ou plus récente :
  `curl -fsSL https://get.di2amp.com/install.sh | sh` ;
- une session : `paas login --web` (connexion dans le navigateur).

## Installer

```bash
cd exemples
./push.sh wordpress mon-blog     # sans nom, l'app prend le nom de l'exemple
```

Le script :
1. clone le code amont à l'étiquette du fichier `source` et vérifie son commit ;
2. ajoute `paas.xml` ;
3. écrit chaque mot de passe dans un fichier 0600 hors du dépôt
   (`~/paas-exemples/<app>.secrets/`) : tiré au hasard, ou pris dans le
   fichier `valeurs` quand le logiciel en impose la valeur. Il le scelle avec
   `paas secrets seal` et l'inscrit, scellé, dans `paas.xml` : aucun mot de
   passe n'est affiché ni passé en argument ;
4. commite, puis vérifie hors ligne avec `paas config plan` ;
5. crée l'app, ouvre un accès Git temporaire (`paas git credentials
   configure`) et pousse.

Le push lance toute la chaîne de la plateforme : build, tests, scan CVE,
signature, déploiement, puis installation du logiciel et de ses comptes. Pour
suivre :

```bash
paas builds list --app mon-blog
paas apps info mon-blog                  # adresse, état, dernière erreur complète
paas-apps --app mon-blog releases list   # avec la CLI de ce dépôt
```

- `./push.sh --plan wordpress` s'arrête après le plan : rien n'est créé ni
  poussé.
- Relancer la même commande reprend là où elle s'était arrêtée.
- Le script refuse une app existante qu'il n'a pas créée lui-même : choisissez
  un autre nom.
- `PAAS_EXEMPLES_DIR` change le dossier de travail (`~/paas-exemples` par
  défaut).

## Se connecter

Chaque exemple crée un compte de démonstration `paasadmin` (adresse
`paasadmin@example.com`). Son mot de passe est dans
`~/paas-exemples/<app>.secrets/PAASADMIN_PASSWORD`. Son rôle dépend du
logiciel : administrateur dans WordPress, Discourse et ERPNext (System
Manager), client de la boutique dans OpenCart, simple utilisateur dans Etherpad
(son administrateur y est le compte `administrator`) ; la section `<accounts>`
ou `<account>` du `paas.xml` dit comment il est créé.
`KANBOARD_INITIAL_PASSWORD` vaut le mot de passe initial que Kanboard écrit
pour son compte `admin` (`admin`, fichier `kanboard/valeurs`) : l'installation
s'en sert une fois pour se connecter, puis le remplace par un mot de passe
généré.
L'adresse de l'app est donnée à la fin du script et par `paas apps info <app>`.

## Installer à la main

Les mêmes étapes, sans le script (valeurs de `<exemple>/source`) :

```bash
git clone --depth 1 --branch <ref> <url> mon-app && cd mon-app
git rev-parse HEAD                                 # doit donner <commit>
cp ../exemples/<exemple>/paas.xml .
```

1. Pour chaque `<sealed>A-SCELLER</sealed>` : écrivez la valeur dans un
   fichier hors du dépôt (celle du fichier `valeurs` de l'exemple quand il en
   donne une, sinon la vôtre), lancez
   `paas secrets seal --name <NOM> --value-file <fichier>`, puis remplacez
   `A-SCELLER` par le résultat. Une valeur scellée ne s'ouvre que dans la
   plateforme, pour votre tenant et ce nom de secret : elle peut être commitée.
2. Commitez, puis vérifiez hors ligne (code 0 : planifié) :

   ```bash
   git add paas.xml && git commit -m "paas.xml"
   paas environments:catalogue-store > ../catalogue-store.json
   paas config plan --catalogue ../catalogue-store.json
   ```

3. Créez l'app et poussez. Le dépôt d'une app neuve a déjà un premier commit :
   le commit poussé porte l'arbre complet, avec ce premier commit pour parent.

   ```bash
   paas apps create mon-app
   git remote add paas "$(paas apps info mon-app --json | jq -r .git_url)"
   paas git credentials configure mon-app     # accès d'écriture valable 15 min
   git fetch paas main
   git push paas "$(git commit-tree 'HEAD^{tree}' -p FETCH_HEAD -m 'mon-app')":refs/heads/main
   ```

## Adapter un exemple

Variables (`<env>`), ressources, volumes et services se règlent dans
`paas.xml`. Vérifiez chaque changement par `./push.sh --plan <exemple>` (ou
`paas config plan`) avant de pousser : le plan refuse une clé inconnue ou une
valeur invalide, avec un diagnostic `CODE@chemin`.

## Retirer une app

```bash
./clean.up --dry-run mon-blog    # montre ce qui serait retiré
./clean.up mon-blog
```

`clean.up` retire une app installée par `./push.sh` depuis ce poste, et
refuse toute autre app. Il :
1. révoque l'accès Git encore actif ;
2. supprime l'app. Elle reste restaurable pendant le délai de corbeille que
   la suppression annonce (`paas apps restore <uuid>` ; le script affiche
   l'UUID ; `paas apps inspect-deleted <uuid>` dit ce qui bloquerait) ; ce
   délai passé, la plateforme efface tout ce qu'elle laisse (dépôt, volumes,
   images, fiche) et n'en garde que les traces (audit, journal) ;
3. range le dossier local, secrets compris, dans
   `~/paas-exemples/.corbeille/<date>-<app>/`, avec l'UUID de l'app.

Pour réinstaller, rétablissez l'app, ou relancez `./push.sh` : le nom d'une
app supprimée se réutilise.

## Vérification

- Chaque `paas.xml` est dérivé d'un fichier en service sur la plateforme
  di2amp ; seuls ses secrets sont remplacés par `A-SCELLER` et son compte de
  démonstration porte des noms neutres.
- Le 11 octobre 2026, `./push.sh --plan` a planifié les dix exemples sans
  erreur, chacun sur son commit amont exact (`paas` 2.30.0, catalogue de
  production) : 26 s pour les dix, clones compris.
- Le même jour, `./push.sh` a installé les dix exemples de bout en bout :
  chaque release était en service moins de 5 minutes après le push, et la
  connexion du compte `paasadmin` a été vérifiée dans le logiciel lui-même :
  tableau de bord de WordPress, de Kanboard et de BookStack, profil
  d'administrateur de Drupal, session de DokuWiki et de FreshRSS, API de
  Piwigo et de FileBrowser, compte client d'OpenCart, profil de listmonk.
  Pour FileBrowser et listmonk, le rapport du scan montre les quatre failles
  acceptées, l'une par les exceptions, l'autre par la politique.
- Les dix sont replanifiés sans erreur avec leurs fichiers finaux
  (`./push.sh --plan`, 26 s pour les dix).
- Le 19 octobre 2026, `./push.sh` a installé etherpad, discourse et erpnext de
  bout en bout (`paas` 2.49.5 et 2.49.7), et la connexion du compte `paasadmin`
  a été vérifiée dans le logiciel : page d'Etherpad (et 401 sans identifiant),
  API de Discourse (un sujet créé, relu et trouvé par la recherche), API
  d'ERPNext (System Manager, un document créé puis relu). Discourse a ensuite
  été retiré par `./clean.up` puis effacé par la plateforme : plus aucune
  ressource, à aucun niveau.
- `./clean.up` a retiré chaque app de test : accès Git révoqué, app
  supprimée, dossier local rangé avec son UUID. Une relance de `./push.sh` sur
  une app déjà poussée reprend sans nouveau build ; le nom d'une app supprimée
  se réutilise ; `push.sh` et `clean.up` refusent tous deux une app existante
  qu'ils n'ont pas installée.
