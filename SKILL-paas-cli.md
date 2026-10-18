---
name: paas-cli
description: Utilise la CLI `paas-apps` du PaaS di2amp pour agir sur le PaaS depuis un terminal ou un script shell. Couvre la session, les applications, les builds et les releases, le diagnostic complet d'un build ou d'un déploiement en échec (cause, failles CVE bloquantes, diagnostics du paas.xml, tests, démarrage, marche à suivre), toutes les autres opérations de l'API (addons, configuration, secrets, déploiements, domaines, volumes, journaux, équipe, facturation, IA…) via `paas-apps api`, et l'installation en une commande d'un logiciel connu (WordPress, Drupal… : `exemples/push.sh`). À utiliser dès qu'une tâche demande de consulter, de diagnostiquer ou de modifier quelque chose sur le PaaS di2amp en ligne de commande.
---

# CLI `paas-apps` du PaaS di2amp

`paas-apps` (2.48.0, API 2.48.0) pilote l'API tenant du PaaS di2amp ; sa
version suit celle de la plateforme. Elle offre deux niveaux :
- des **commandes métier** lisibles : session, applications, builds,
  releases, processus (`ps`), valeurs à fournir (`secrets`), diagnostic des
  échecs, mises à jour de sécurité, bases admises d'un Dockerfile, santé,
  régions ;
- **`paas-apps api`**, qui donne accès aux **433 opérations** de l'API client,
  chacune par son identifiant (`operationId`).

## 1. Vérifier l'outil et la session

```bash
paas-apps --version          # absent : voir « Installer la CLI » dans le README du dépôt
paas-apps whoami             # code 3 : pas de session valide
```

La session vit dans `$PAAS_CREDENTIALS_FILE`, sinon dans
`~/.paas/credentials.json`, partagé avec `paas` 2.25. En CI, `PAAS_TOKEN`
(jeton Bearer) est prioritaire.

## 2. Ouvrir une session : dans le navigateur

Sans session valide, ouvrez-la dans le navigateur :

```bash
paas-apps login --web     # ouvre la page de connexion du PaaS ; rend la main une fois connecté
```

- La personne se connecte dans la fenêtre qui s'ouvre (mot de passe, MFA ou
  SSO, sur la page du PaaS). La CLI reçoit la session et l'écrit dans le
  fichier de session.
- Ni l'agent ni le terminal ne voient de mot de passe, et aucun fichier de
  configuration n'en contient.
- Lancez la commande avec un délai d'au moins 5 minutes, et dites à la personne
  de se connecter dans le navigateur. L'adresse affichée peut aussi être
  ouverte à la main.
- Agent sur une machine distante : le navigateur doit joindre `localhost` de
  cette machine. Fixez le port avec
  `PAAS_LOGIN_CALLBACK_PORT=8765 paas-apps login --web`, et ouvrez le tunnel
  `ssh -L 8765:localhost:8765 <serveur>` sur le poste de la personne.

Ne demandez jamais de mot de passe, et ne le faites jamais passer par la
conversation : une commande lancée depuis la conversation y reste enregistrée
avec son texte, y compris avec le préfixe `!`. Un `PAAS_TOKEN` doit être
exporté avant le lancement de l'agent : exporté par une commande isolée, il
disparaît à la fin de cette commande.

En intégration continue seulement, le mot de passe ne passe **jamais** en
argument : il serait visible dans `ps`, dans `/proc` et dans l'historique.
Lisez-le depuis une variable avec `printf`, qui est une commande interne du
shell :

```bash
printf '%s' "$PAAS_PASSWORD" | paas-apps login --email "$PAAS_EMAIL" --password-stdin
```

Pour un test ou une automatisation, isolez la session, et ne la déconnectez
pas (voir les règles plus bas) :

```bash
export PAAS_CREDENTIALS_FILE=/dev/shm/paas-session-$$/credentials.json
```

## 3. Commandes métier

| But | Commande |
|---|---|
| Identité | `paas-apps whoami` |
| Santé et version de l'API | `paas-apps health` |
| Régions | `paas-apps regions` |
| Applications, et qui doit agir sur chaque échec (`Cust` ou `Paas`, colonne `FAILURE`) | `paas-apps apps list [--region gra11]` |
| Une application, et pourquoi son dernier déploiement a échoué | `paas-apps apps info NOM` (ou `--app NOM`, ou `PAAS_APP=NOM`) |
| Derniers builds, avec leur code d'échec | `paas-apps --app NOM builds list --limit 5` |
| Un build, ses étapes et son échec complet | `paas-apps --app NOM builds info BUILD_ID` |
| Rapport CVE d'un build : ce qui bloque, ce qui est accepté | `paas-apps --app NOM builds cve BUILD_ID` |
| Tests d'un build : commande, code de sortie, journal | `paas-apps --app NOM builds test BUILD_ID` |
| Bases admises pour le `FROM` d'un Dockerfile, et dernier rescan de chaque image publiée (`RESCAN`) | `paas-apps builds bases` |
| Mises à jour de sécurité d'une application : mode et historique | `paas-apps apps security-updates NOM` |
| Choisir le mode des mises à jour de sécurité | `paas-apps apps security-updates NOM --mode manual` (ou `automatic`) |
| Releases avec leur état courant et leur code d'échec | `paas-apps --app NOM releases list --limit 5` |
| Une release et son échec complet | `paas-apps --app NOM releases info RELEASE_ID` |
| Processus et pods de la release courante (`(superseded)` : release remplacée) | `paas-apps --app NOM ps` |
| Valeurs à fournir (`secrets.<NOM>.provide`) et leur état | `paas-apps --app NOM secrets provided` |
| Fournir une valeur : fichier privé ou entrée standard, jamais en argument | `paas-apps --app NOM secrets provide NOM_VALEUR --value-file FICHIER` |

`NOM` est le nom ou l'UUID de l'application.

## 3 bis. Diagnostiquer et corriger un échec

Un build ou un déploiement en échec porte son **erreur complète** : cause en
une phrase, code et étape, détails, fin du journal et marche à suivre.

1. Trouvez l'échec : `paas-apps --app NOM releases list` (colonne `FAILURE`)
   ou `paas-apps apps info NOM` (bloc « Last deploy failed »).
2. Lisez-le en entier : `paas-apps --app NOM releases info RELEASE_ID`
   (ou `builds info BUILD_ID`). En script : `--json`, puis
   `jq '.error'` (release), `jq '.failure'` (build) ou `jq '.last_error'`
   (application).
3. Lisez d'abord **qui doit agir** : la ligne `owner` (en JSON,
   `responsibility`) :
   - `Cust` : le `paas.xml` ou le dépôt de l'application se corrige ; suivez
     la marche à suivre ;
   - `Paas` : la plateforme ne sait pas encore installer l'application ;
     `capability` nomme ce qui lui manque, et ses opérateurs sont prévenus.
     Ne modifiez pas le logiciel de l'application pour contourner : dites-le
     à la personne, avec le code et la capacité ;
   - `presumed` : la cause n'est pas établie, elle est présumée côté
     plateforme ; `inferred from the code family` : le code n'est pas encore
     documenté, il est classé par sa famille ;
   - `passing incident in …` (en JSON, `responsibility.transient`) : un
     incident passager de la plateforme ; rien ne manque, reconstruisez le
     même commit plus tard.
4. Selon le code :
   - `security_scan_blocked` : `builds cve BUILD_ID` liste chaque faille avec
     ce qui bloque et ce qui est accepté. Les étapes proposent l'extrait de
     `paas.xml` à coller (`security.cve_exceptions`, une par une, ou
     `security.block_on`). C'est une **décision de la personne** : ne
     l'acceptez jamais à sa place. Quand les failles sont dans la base de
     l'image et que la plateforme a publié sa révision corrigée, la ligne
     `Corrected revision published: …` la nomme : adopter cette révision
     corrige sans accepter de risque ;
   - `security_scan_unavailable` : la base du scanner était injoignable ;
     incident passager, reconstruisez le même commit ;
   - `plan_refused` : chaque diagnostic nomme la clé du `paas.xml` et la règle ;
   - `tests_failed` : `builds test BUILD_ID` donne la commande, son code de
     sortie et son journal ;
   - `build_step_failed`, `build_timed_out` : la tâche en échec et la fin du
     journal ;
   - `rollout_failed`, `database_not_ready` : la raison (mémoire, sonde,
     processus arrêté…), l'état du conteneur, les événements, et la
     correction du `paas.xml` (par exemple la mémoire doublée) ;
   - code inconnu : `summary`, `message` et la marche à suivre restent valables.
5. Corrigez (`paas.xml`, code de l'application), commitez, poussez. Pour
   reconstruire le même commit sans nouveau commit, utilisez la commande
   proposée par la marche à suivre (CLI `paas`).
6. Vérifiez : `releases list`, puis `apps info` (plus de bloc d'échec).

## 3 ter. Installer une app connue : `exemples/`

Le dossier `exemples/` du dépôt installe dix logiciels par leur `paas.xml` :
wordpress, drupal, dokuwiki, bookstack, kanboard, freshrss, piwigo, opencart,
filebrowser, listmonk. Les deux derniers acceptent des failles CVE HIGH
connues : filebrowser par une liste d'exceptions nommées, listmonk en
désactivant le blocage (`block_on` à `none`). Dites-le à la personne avant de
les installer, et ne recopiez pas `block_on` à `none` hors d'un essai. Il faut
`git`, `jq`, la CLI `paas` 2.30 ou plus récente et une session `paas`.

```bash
cd exemples
./push.sh --plan wordpress       # vérifie hors ligne, ne crée rien
./push.sh wordpress mon-blog     # crée l'app « mon-blog » et pousse
paas-apps --app mon-blog builds list
paas-apps apps info mon-blog     # bloc « Last deploy failed » en cas d'échec
./clean.up --dry-run mon-blog    # montre ce qui serait retiré
./clean.up mon-blog              # supprime l'app (réversible) et range son dossier local
```

- `push.sh` et `clean.up` refusent une app existante qu'ils n'ont pas
  installée : ne réutilisez jamais le nom d'une app en service.
- Ne lancez `clean.up` que si la personne a demandé de retirer l'app.
- Les mots de passe sont tirés au hasard dans `~/paas-exemples/<app>.secrets/`
  (fichiers 0600) : ne les lisez pas et ne les affichez pas. Donnez le chemin
  à la personne.

## 4. Toutes les autres opérations : `paas-apps api`

Procédure :
1. **Trouvez l'opération** : `paas-apps api list --tag DOMAINE` ou
   `paas-apps api list --search mot`. Les domaines sont addons, ai, apps,
   auth, billing, builds, config, deploys, domains, environments, functions,
   git, meta, observability, team, tenant et volumes.
2. **Lisez sa description** : `paas-apps api show OPÉRATION`. Elle donne les
   paramètres de chemin, l'authentification, la forme de la réponse et
   l'idempotence.
3. **Appelez-la** : `paas-apps api call OPÉRATION [PARAMÈTRES…] [-q clé=valeur] [-d JSON]`.

```bash
paas-apps --app mon-app api call list_app_addons            # l'application vient de --app
paas-apps api call get_config_keys mon-app                    # paramètres de chemin dans l'ordre
paas-apps api call list_builds mon-app -q limit=3
paas-apps api call create_addon_generic mon-app -d '{"type":"postgres","plan":"standard"}' --yes
paas-apps api call set_config mon-app -d @config.json --yes   # corps depuis un fichier
paas-apps api call get_invoice_pdf ID -o facture.pdf          # contenu binaire vers un fichier
```

La réponse s'affiche **telle que l'API la renvoie**, en JSON indenté, avec
`data` et `meta` : filtrez avec `jq '.data'`. Les paramètres et les schémas
de chaque opération sont dans `API-REFERENCE.md` du dépôt, et dans la skill
`paas-api`.

## 5. Lire les résultats dans un script

Ajoutez `--json` (option globale) aux commandes métier, puis filtrez avec `jq` :

```bash
paas-apps --json apps list | jq -r '.[] | "\(.name)\t\(.status)"'
BUILD=$(paas-apps --app NOM --json builds list --limit 1 | jq -r '.[0].build_id')
```

| Code de sortie | Signification | Que faire |
|---|---|---|
| 0 | Succès | |
| 1 | Erreur (paramètre manquant, écriture non confirmée…) | Lire stderr |
| 2 | Usage | Corriger la commande |
| 3 | Authentification | Ouvrir une session |
| 4 | Introuvable | Vérifier le nom ou l'identifiant |
| 5 | Réseau ou délai dépassé | Réessayer plus tard |
| 6 | Erreur du serveur | Réessayer plus tard, puis signaler |
| 7 | Réponse non conforme | Signaler : l'API a changé |

## 6. Interpréter

- **Build** : son état se lit dans les étapes (`clone`, `build`, `trivy`,
  `sbom`, `signature`, `promotion`). Une étape `failed` le fait échouer, une
  étape `pending` signifie qu'il est en cours. Son erreur complète est dans
  `failure` (`builds info`).
- **Échec** : les textes de l'erreur complète (`summary`, `message`, étapes)
  sont écrits pour être montrés tels quels à la personne ; ils ne citent
  jamais la valeur d'un secret.
- **Release** : `releases list` donne l'état courant (`running` avec les
  réplicas prêts sur le total voulu). `releases info` donne l'état enregistré
  du déploiement. Pour savoir ce qui est servi, utilisez `releases list`.
  `scaled-zero` : release appliquée à 0 réplique, celle de l'application ;
  `paas scale web 1` la sert. `awaiting_secrets` : la release attend des
  valeurs que la personne fournit (`secrets provided`) ; demandez-les-lui,
  ne les inventez pas, et transmettez-les par fichier privé ou entrée
  standard (`secrets provide`).
- **Qui doit agir** : la ligne `owner` est l'imputation du verdict ; une
  ligne `now` donne la lecture des règles du jour quand elle diffère : la
  marche à suivre affichée suit `now`.
- Les listes paginées ne renvoient que la **première page**, 100 éléments au
  plus.

## Règles

- Jamais de mot de passe ni de jeton en argument ou dans un fichier versionné.
- **Une écriture (POST, PUT, PATCH, DELETE) change le PaaS** : vérifiez
  l'opération (`api show`) et l'application visée avant de passer `--yes`.
  Sans terminal, `--yes` est obligatoire.
- **Ne lancez pas `paas-apps logout` sur un compte partagé** : le serveur
  révoque alors les accès Git actifs du compte sur toutes ses sessions, ce
  qui casse le `git push` des autres. Pour quitter une session de test,
  écrasez son fichier (`shred`).
- Ne rejouez pas une écriture qui a échoué sur un délai dépassé, sauf si
  l'opération honore `Idempotency-Key` (`api show`) et que vous fournissez la
  même clé (`--idempotency-key`).
