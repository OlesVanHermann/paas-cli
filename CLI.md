# CLI `paas-apps` : référence

`paas-apps` est la nouvelle CLI du PaaS di2amp.

Elle s'installe à côté de `paas`, sans le remplacer. Sa version suit celle de la
plateforme : la 2.48.0, vérifiée contre l'API 2.48.0, offre deux niveaux :
- `paas-apps api`, qui donne accès aux **433 opérations** de l'API client ;
- des commandes métier, pour la session, la lecture des applications, des
  builds et des releases, et le diagnostic complet d'un échec (voir
  [Diagnostiquer un échec](#diagnostiquer-un-échec)). Les autres viendront au
  fil des lots.

## Installation

Les exécutables pour Linux x86_64 et ARM64 (glibc 2.34 ou plus récente) sont
à la racine du dépôt, avec leurs sommes SHA-256 :

```bash
arch=$(uname -m)                                   # x86_64 ou aarch64
sha256sum --check --ignore-missing SHA256SUMS
install -D -m 0755 "paas-apps-linux-$arch" ~/.local/bin/paas-apps
paas-apps --version
```

Pour télécharger un seul exécutable sans cloner le dépôt, suivez le
[README](README.md#installer-la-cli).

## Options globales

| Option | Variable d'environnement | Rôle |
|---|---|---|
| `--api-url URL` | `PAAS_API_URL` | Origine de l'API. Par défaut, celle de la session, sinon `https://console.di2amp.com`. Les formes `…/api` sont acceptées |
| `--app APP` | `PAAS_APP` | Application (nom ou UUID) pour les commandes `apps info`, `apps security-updates`, `builds`, `releases`, `ps` et `secrets` |
| `--json` | | JSON au lieu des tableaux |
| `--timeout N` | | Délai maximal par requête, en secondes (30 par défaut) |

Variables d'environnement supplémentaires :

| Variable | Rôle |
|---|---|
| `PAAS_CREDENTIALS_FILE` | Fichier de session. Par défaut `~/.paas/credentials.json`, partagé avec `paas` 2.25 |
| `PAAS_TOKEN` | Jeton Bearer pour la CI, prioritaire sur le fichier de session |
| `PAAS_EMAIL` | E-mail par défaut de `login` |

## Commandes

| Commande | Effet |
|---|---|
| `login --email E [--password-stdin]` | Ouvre une session et l'enregistre (fichier en 0600, dossier en 0700) |
| `logout` | Révoque le jeton d'accès et supprime la session locale. **Le serveur révoque aussi les accès Git actifs du compte sur toutes les sessions** |
| `whoami` | Identité de la session : e-mail, rôle, tenant, utilisateur, méthode |
| `health` | Version de l'API et état de ses dépendances (sans session) |
| `regions` | Régions d'hébergement (sans session) |
| `apps list [--region R]` | Applications actives du tenant, triées par nom ; colonne `FAILURE` : qui doit agir sur l'échec du dernier déploiement (`Cust` ou `Paas`), son code et la capacité qui manque à la plateforme (API 2.31.0) |
| `apps info [NOM]` | Détail d'une application (`NOM`, sinon `--app`) et, quand son dernier déploiement a échoué, son erreur complète ; ligne `failure` (API 2.48.0) : la même imputation que `apps list` |
| `apps security-updates [NOM] [--mode manual\|automatic]` | Mises à jour de sécurité d'une application (API 2.47.0), quand la plateforme publie une révision corrigée de la base de son image : `manual` (par défaut) : une alerte nomme les CVE et la révision corrigée, vous reconstruisez ou poussez ; `automatic` : la plateforme commite la configuration corrigée dans le dépôt de l'app, la construit et la déploie. `--mode` règle le choix, puis le mode et les mises à jour s'affichent |
| `builds list [--limit N]` | Derniers builds de `--app` (10 par défaut, 100 au plus), avec le code d'échec de chacun (colonne `FAILURE`) |
| `builds info BUILD` | Un build, ses étapes et, quand il a échoué, son erreur complète |
| `builds cve BUILD [--limit N] [--offset N]` | Rapport CVE d'un build : verdict, politique appliquée, chaque faille avec ce qui bloque et ce qui est accepté (et jusqu'à quand), puis la marche à suivre |
| `builds test BUILD` | Tests du locataire d'un build : commande, statut, code de sortie, durée, image et journal |
| `builds bases` | Bases qu'un Dockerfile peut prendre en `FROM` (API 2.34.0) et, depuis l'API 2.47.0, le dernier rescan quotidien de chaque image publiée (colonne `RESCAN`) : `clean`, `revision_due DATE` (une révision corrigée est due à cette date), `overdue DATE`, `unavailable` (le scan n'a pas pu tourner), `-` (jamais rescannée). Sans `--app` |
| `releases list [--limit N]` | Dernières releases de `--app`, avec leur état courant et le code d'échec de chacune (10 par défaut, 100 au plus) ; dit comment servir une release appliquée à 0 réplique (`scaled-zero`) et où fournir les valeurs qu'attend une release `awaiting_secrets` (API 2.48.0) |
| `releases info ID` | Une release : état enregistré, prise en charge et, quand elle a échoué, son erreur complète (et celle de sa release liée) ; ce qu'attend une release `scaled-zero` ou `awaiting_secrets` |
| `ps` | Processus de `--app` (API 2.48.0) : répliques voulues et prêtes, redémarrages des pods de la release courante, état (`scaled-zero`, `running`, `degraded`, `not-ready`) et pods ; un pod d'une release remplacée encore vivant est marqué `(superseded)` |
| `secrets provided` | Valeurs que vous fournissez à `--app` (API 2.48.0) : chaque nom que son `paas.xml` déclare `secrets.<NOM>.provide`, son état (`provided`, `missing`, `placeholder`) et la release qui attend les valeurs manquantes ; aucune valeur n'est jamais affichée |
| `secrets provide NOM [--value-file FICHIER]` | Fournit la valeur de `NOM` : lue dans le fichier (sans son saut de ligne final), sinon sur l'entrée standard (saisie sans écho au clavier), **jamais en argument**, envoyée dans le corps de la requête. Dit ce qui reste à fournir ; quand rien ne manque, la release qui attendait repart sans nouveau push |

Le mot de passe se lit **uniquement** sur l'entrée standard
(`--password-stdin`), ou se saisit au clavier. Il n'existe pas d'option
`--password`.

```bash
printf '%s' "$MOT_DE_PASSE" | paas-apps login --email moi@exemple.fr --password-stdin
paas-apps --app mon-app builds list --limit 5
paas-apps --json apps list | jq -r '.[].name'
```

## Diagnostiquer un échec

Quand un build ou un déploiement échoue, l'API donne son erreur complète
(`paas.error.v1`, voir [API.md](API.md#échec-dun-build-ou-dun-déploiement--paaserrorv1)).
`releases info`, `builds info` et `apps info` l'affichent ainsi :

```
✗ Image refusée par la porte de sécurité : 1 faille (1 HIGH) n'est couverte ni par une exception ni par la politique CVE de l'app.
  code    security_scan_blocked
  stage   scan
  deploy  8c2f…
  build   build-19fa3b18

Policy: block_on=high (CRITICAL and HIGH block), from paas.xml; 18 cve_exceptions declared
Scan: CRITICAL 0, HIGH 24; accepted: CRITICAL 0, HIGH 23
Blocking: 1 occurrence(s) of 1 distinct finding(s):
┌────────────────┬──────────┬─────────┬───────────┬──────────────────┬─────────┬───────┐
│ CVE            ┆ SEVERITY ┆ PACKAGE ┆ INSTALLED ┆ FIXED            ┆ TARGET  ┆ TITLE │
…
Next steps:
  1. Aucune version corrigée n'est publiée pour ces failles : seule l'acceptation du risque permet de servir l'image
  2. Accepter ces failles une par une dans paas.xml (mode A) : compléter chaque raison, ajuster l'échéance
     paas.xml:
       <security>
         <cve_exceptions>
           <item><id>CVE-…</id><package>braces</package><expires>…</expires>
…
```

Dans l'ordre : la cause en une phrase, le code et l'étape, qui doit agir,
l'explication, les détails propres au code (failles bloquantes et acceptées,
diagnostics du `paas.xml`, tâches en échec, commande de test, état du
conteneur, événements), la fin du journal de l'étape, puis les étapes de la
marche à suivre avec leur commande, leur extrait de `paas.xml` et leur
documentation. Les commandes proposées par l'API sont celles de la CLI `paas`.

Depuis l'API 2.31.0, la ligne `owner` dit qui doit agir, suivie de la phrase
de la plateforme :

```
  owner   Paas (platform, missing capability admission.recipe_files; decided by admission_recipe_unreadable)
  owner   Cust (customer; decided by ENV_PHP_INDEX_REQUIRED)
```

- `Cust` : le `paas.xml` ou le dépôt de l'application se corrige ; la marche
  à suivre dit quoi changer.
- `Paas` : la plateforme ne sait pas encore installer l'application ; elle
  nomme la capacité qui lui manque, et ses opérateurs sont prévenus.
- `presumed: cause not established` : la cause n'est pas établie, elle est
  présumée côté plateforme ; `inferred from the code family` : le code n'est
  pas encore documenté, il est classé par sa famille.
- `now` (API 2.48.0) : l'imputation affichée sur la ligne `owner` est celle
  du verdict, enregistrée avec lui ; quand les règles du jour décident
  autrement, la ligne `now` donne leur lecture, avec leur version et celle
  du verdict (`before 2.48.0` pour un verdict plus ancien). La phrase et la
  marche à suivre affichées suivent cette lecture :
  `now     Cust (customer; decided by V2_SECRET_NOT_PROVIDED) (rules 2.48.0, the verdict's: before 2.48.0)`.
- `passing incident in …` (API 2.47.0) : un incident passager de la
  plateforme (la base du scanner injoignable un moment, par exemple, code
  `security_scan_unavailable`) ; rien ne manque, reconstruire le même commit
  suffit.

Depuis l'API 2.47.0, quand toutes les failles qui bloquent une image sont
dans sa base et que la plateforme a publié une révision corrigée de cette
base, les détails du scan la nomment
(`Corrected revision published: recipe … , catalogue … (fixes CVE-…)`, ou
`base …` pour le `FROM` d'un Dockerfile), et la première étape de la marche à
suivre donne la ligne à écrire.

Depuis l'API 2.31.1, la marche à suivre suit qui doit agir. Pour `Paas`, sa
première étape dit ce que la plateforme doit lever, et aucune étape ne demande
de corriger le `paas.xml` ou le dépôt ; « Reconstruire ce commit quand la
plateforme sera corrigée » relance le même commit. Pour une cause présumée,
les étapes de diagnostic restent. Un build arrêté par le scan du pipeline
renvoie à son rapport (`paas builds cve <build> --app <app>`).

Les diagnostics d'un plan refusé (`plan_refused`) forment une table dont la
première colonne, `WHO`, dit qui doit agir sur chacun : `Cust` ou `Paas`.

Dans une table (`releases list`, `builds list`), une erreur sur une ligne
commence par `[Cust]` ou `[Paas]`.

Un échec enregistré avant l'API 2.28.0 n'a que son code et son message : la
CLI les affiche, avec la vraie cause des anciens codes connus (par exemple une
image refusée par son scan CVE, que l'ancien message attribuait à la source).

`--json` donne l'objet complet, typé dans le contrat (`error`, `failure`,
`last_error`).

## Toutes les opérations : `paas-apps api`

| Commande | Effet |
|---|---|
| `api list [--tag DOMAINE] [--search TEXTE]` | Liste les opérations : identifiant, méthode, chemin, résumé |
| `api show OPÉRATION` | Décrit une opération : requête, paramètres de chemin, authentification, réponse, idempotence, méthode SDK |
| `api call OPÉRATION [PARAMÈTRES…]` | Appelle une opération et affiche la réponse telle quelle (JSON indenté) |

Options de `api call` :

| Option | Rôle |
|---|---|
| `PARAMÈTRES…` | Paramètres de chemin, dans l'ordre du chemin. L'application peut venir de `--app` ou de `PAAS_APP` |
| `-q, --query CLÉ=VALEUR` | Paramètre de requête (répétable). `lifecycle` et `include_deleted` sont refusés |
| `-d, --data JSON\|@FICHIER\|-` | Corps JSON : littéral, depuis un fichier, ou depuis l'entrée standard |
| `--idempotency-key CLÉ` | En-tête `Idempotency-Key` (honoré seulement par les opérations qui le déclarent) |
| `--yes` | Envoie une écriture sans demander confirmation |
| `-o, --output FICHIER` | Écrit la réponse dans un fichier (obligatoire pour une réponse binaire dans un terminal) |

```bash
paas-apps api list --tag addons
paas-apps api show create_addon_generic
paas-apps --app mon-app api call list_app_addons
paas-apps api call create_addon_generic mon-app -d '{"type":"postgres","plan":"standard"}' --yes
paas-apps api call get_invoice_pdf <id> -o facture.pdf
```

Toute opération autre que GET (création, modification, suppression)
demande une confirmation, ou `--yes`. Sans terminal, `--yes` est
obligatoire. La liste complète, avec les paramètres et les schémas, est dans
la [référence de l'API](API-REFERENCE.md).

## Codes de sortie

| Code | Signification |
|---|---|
| 0 | Succès |
| 1 | Erreur (dont argument manquant, par exemple pas d'application) |
| 2 | Usage incorrect |
| 3 | Authentification : pas de session, session expirée ou refusée |
| 4 | Introuvable (404) |
| 5 | Réseau ou délai dépassé |
| 6 | Erreur du serveur (5xx) |
| 7 | Réponse non conforme au contrat |

## Comportement

- **Session** : le fichier garde le même format que `paas` 2.25, et les deux
  CLI peuvent partager la même session. Le jeton d'accès est rafraîchi
  automatiquement moins de 5 minutes avant son expiration, ou après un 401. Le
  fichier est alors réécrit de façon atomique, en 0600.
- **Erreurs complètes** (`paas.error.v1`) : affichées entières, car la
  plateforme n'y cite jamais la valeur d'un secret ; seule une ligne qui
  porte un marqueur d'identifiant (jeton, en-tête `Bearer`, clé privée) est
  masquée.
- **Autres messages du serveur** : ils sont masqués quand ils ressemblent à
  un secret (jeton, clé, chaîne encodée longue).
- **Nouvelles tentatives** : jusqu'à 2 pour une lecture, sur 429, 502, 503,
  504, délai dépassé ou connexion refusée. `Retry-After` est respecté.
