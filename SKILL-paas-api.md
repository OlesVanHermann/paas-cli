---
name: paas-api
description: Appelle directement l'API HTTP tenant du PaaS di2amp (https://console.di2amp.com/api/v1) avec curl et jq, sans exposer les secrets. Couvre les 433 opérations de l'API client — applications, addons, builds, déploiements, configuration et secrets, domaines, volumes, observabilité, équipe, tenant, facturation, IA, fonctions — avec la référence complète dans API-REFERENCE.md, et la lecture de l'erreur complète d'un build ou d'un déploiement en échec (paas.error.v1 : cause, failles CVE, diagnostics du paas.xml, tests, démarrage, marche à suivre). À utiliser pour interroger, diagnostiquer ou piloter le PaaS di2amp sans la CLI, ou pour connaître le format exact d'une requête ou d'une réponse.
---

# API tenant du PaaS di2amp

- Base : `https://console.di2amp.com/api` ; tous les chemins commencent par `/v1/`.
- **Référence complète** : `API-REFERENCE.md`, à côté de ce fichier. Elle
  donne, pour chaque opération, la requête, les paramètres typés, le corps,
  la réponse et l'appel CLI ; les types sont décrits à la fin.
- Contrat machine : `openapi.yaml` dans le dépôt.

## Trouver la bonne opération

1. Choisissez le domaine :

   | Domaine | Contenu |
   |---|---|
   | `apps` | applications, processus, redémarrage, mise à l'échelle |
   | `addons` | bases de données, caches, sauvegardes |
   | `config` | variables, secrets |
   | `deploys` | déploiements, retour arrière |
   | `builds` | builds, preuves de sécurité, rapport CVE, tests |
   | `domains` | domaines personnalisés |
   | `volumes` | volumes persistants |
   | `observability` | journaux, métriques, alertes |
   | `git` | dépôt lié et accès Git |
   | `team` | équipe |
   | `tenant` | SSO, réseau, RGPD |
   | `billing` | facturation |
   | `ai` | IA |
   | `functions` | fonctions serverless |
   | `environments` | environnements d'exécution |
   | `auth` | connexion, jetons, clés |
   | `meta` | santé, régions, conformité |

2. Dans `API-REFERENCE.md`, allez à la section « Domaine `<domaine>` » : son
   tableau liste les opérations, avec leur requête et un résumé d'une ligne.
3. Lisez la section de l'opération : paramètres, corps (types détaillés dans
   la section « Types », à la fin), forme de la réponse, idempotence.

## Session : dans le navigateur, jamais de mot de passe

La personne se connecte dans son navigateur. L'agent ne demande, ne lit ni ne
stocke jamais de mot de passe ; rien n'est à mettre dans un fichier de
configuration.

1. Ouvrez la session avec la CLI `paas-apps` du dépôt (installation : README) :

   ```bash
   paas-apps whoami || paas-apps login --web   # ouvre le navigateur ; rend la main une fois connecté
   ```

   Lancez la commande avec un délai d'au moins 5 minutes, et dites à la
   personne de se connecter dans la fenêtre qui s'ouvre. L'adresse affichée
   peut aussi être ouverte à la main. Agent sur une machine distante : le
   navigateur doit joindre `localhost` de cette machine. Fixez le port avec
   `PAAS_LOGIN_CALLBACK_PORT=8765 paas-apps login --web`, et ouvrez le tunnel
   `ssh -L 8765:localhost:8765 <serveur>` sur le poste de la personne.
2. Les appels curl lisent le jeton dans le fichier de session (droits 0600),
   sans jamais l'afficher ni le passer en argument :

```bash
API=https://console.di2amp.com/api
CRED="${PAAS_CREDENTIALS_FILE:-$HOME/.paas/credentials.json}"

# L'en-tête est écrit sur l'entrée standard de curl (-K -), jamais en argument
paas() {  # paas MÉTHODE CHEMIN [CORPS_JSON]
  { jq -r '"header = \"Authorization: Bearer \(.access_token)\""' "$CRED"
    printf 'header = "Content-Type: application/json"\n'; } \
    | curl -sS --max-time 30 -K - -X "$1" "$API$2" ${3:+--data-binary "$3"}
}
paas GET /v1/auth/me | jq '.data'
paas GET /v1/apps/mon-app/addons | jq '.data[] | {type, plan, status}'
paas POST /v1/apps/mon-app/addons '{"type":"postgres","plan":"standard"}'
```

3. Une réponse 401 signale une session expirée. `paas-apps whoami` la
   rafraîchit et réécrit le fichier ; relancez ensuite l'appel. Si le
   rafraîchissement échoue, refaites `paas-apps login --web`.
4. En intégration continue seulement, un jeton fourni par l'environnement
   (`PAAS_TOKEN`, exporté avant le lancement de l'agent) remplace le fichier :
   écrivez `printf 'header = "Authorization: Bearer %s"\n' "$PAAS_TOKEN"` à la
   place de la ligne `jq`.

## Secrets : jamais en argument

Un argument de commande est visible dans `ps`, dans `/proc` et dans
l'historique du shell. N'affichez jamais le jeton de session, et ne l'écrivez
pas dans un fichier versionné. La fonction `paas` passe le corps en argument :
réservez-la aux corps sans secret. Pour un corps qui contient un secret
(valeur de variable, mot de passe) :
1. écrivez-le dans un fichier privé, avec `umask 077`, sous `/dev/shm` ;
2. envoyez-le avec `--data-binary @fichier` ;
3. effacez-le avec `shred`.

## Lire une réponse

| Forme (`x-paas-envelope`) | Lecture |
|---|---|
| `data` (la plupart) | `jq '.data'` |
| `data-meta` | `jq '.data'` ; `.meta.total` = nombre d'éléments renvoyés |
| `bare` | la valeur seule |
| `none` | aucun corps (204) |
| `raw` | fichier ou texte : `curl -o fichier` |
| `stream` | flux continu (journaux, terminal) : ne pas appeler avec un simple curl |

- `{app_id}` dans un chemin accepte le **nom ou l'UUID** de l'application.
- Les listes paginées ne servent que la **première page** (`limit` de 1 à
  100, `offset` sans effet) : ne bouclez pas sur des pages.
- Les états sont des chaînes libres : traitez toute valeur inconnue comme
  valide.

## Erreurs

| Réponse | Sens | Action |
|---|---|---|
| 401 JSON `{"error":{"code":"unauthorized",…}}` | Jeton absent, expiré ou révoqué | `paas-apps whoami` (rafraîchit la session), sinon `paas-apps login --web` |
| 404 JSON `{"error":{"code":"not_found",…}}` | Application ou objet inconnu dans le tenant | Vérifier le nom ou l'identifiant |
| 404 **sans corps** | La route n'existe pas sur ce serveur | Ne pas réessayer |
| 400 JSON | Requête impossible dans l'état actuel | Lire `message` et `action` |
| 422 en texte brut | Corps JSON invalide (champ manquant…) | Corriger le corps d'après le schéma |
| 429, 502, 503, 504 | Surcharge ou indisponibilité | Réessayer une lecture, avec une attente croissante |

Le champ `error` peut aussi contenir `field`, `keys` (noms seulement) et
`action`. Avant d'afficher un message d'erreur, vérifiez qu'il ne contient
pas de jeton.

## Un build ou un déploiement en échec : `paas.error.v1`

Un échec n'est pas une erreur HTTP : la lecture répond 200 et l'objet porte
son **erreur complète** (`PaasError`, `"schema": "paas.error.v1"`).

```bash
paas GET /v1/apps | jq -r '.data[] | select(.last_failure) | "\(.name)\t\(.last_failure.label)\t\(.last_failure.code)\t\(.last_failure.capability // .last_failure.reason_code)"'   # qui doit agir, app par app
paas GET /v1/apps/mon-app | jq '.data.last_error'                    # pourquoi l'app ne sert rien de neuf (null : rien)
paas GET /v1/apps/mon-app | jq '.data.last_error.responsibility'     # Cust ou Paas, et pourquoi
paas GET '/v1/apps/mon-app/deploys?limit=5' | jq '.data[] | {id, status, failure_code, summary: .error.summary}'
paas GET /v1/apps/mon-app/deploys/ID | jq '.data.error'              # l'erreur complète d'un déploiement
paas GET /v1/apps/mon-app/builds/BUILD | jq '.data.failure'          # celle d'un build (`error` y reste l'ancienne chaîne)
paas GET '/v1/apps/mon-app/builds/BUILD/cve?limit=100' | jq '.data | {verdict, policy, blocking, error}'
paas GET /v1/apps/mon-app/builds/BUILD/test | jq '.data | {status, command, exit_code, log}'
```

| Champ | Usage |
|---|---|
| `summary`, `message` | La cause en une phrase, puis l'explication : à montrer telles quelles |
| `code`, `stage` | `security_scan_blocked` (scan), `plan_refused` (plan), `build_step_failed` et `build_timed_out` (build), `tests_failed` (test), `admission_refused` (admission), `rollout_failed` et `database_not_ready` (rollout) |
| `details` | Propre au code : failles bloquantes et acceptées, diagnostics du `paas.xml` (clé et règle), commande de test, état du conteneur, événements… |
| `remediation[]` | Marche à suivre, dans l'ordre : `title`, `command` (CLI `paas`), `paas_xml` (extrait prêt à coller), `docs` |
| `log_excerpt` | Fin du journal de l'étape : `lines`, `exit_code`, `truncated` |
| `responsibility` | Qui doit agir (API 2.31.0) : `label` `Cust` (le `paas.xml` ou le dépôt se corrige) ou `Paas` (la plateforme ne sait pas encore le faire ; `capability` nomme ce qui lui manque) ; `basis` : `documented`, `rule`, `family` (déduit de la famille du code), `presumption` (cause présumée) ; `summary` à montrer tel quel ; `transient` (API 2.47.0) : `true` pour un incident passager de la plateforme, que la reconstruction du même commit suffit à passer |

Règles :
- lisez d'abord `responsibility` : pour `Paas`, ne modifiez pas le logiciel
  de l'application pour contourner la plateforme ; dites-le à la personne,
  avec le code et la capacité (les opérateurs de la plateforme sont prévenus) ;
- suivez `remediation` dans l'ordre ; accepter une faille CVE
  (`security.cve_exceptions`, `security.block_on`) est une **décision de la
  personne**, jamais celle de l'agent ;
- un code inconnu se lit comme les autres ;
- un échec antérieur à l'API 2.28.0 n'a que `error_message`, `failure_code`
  et `failure_kind` (et un `last_error` de repli, code `deploy_failed`).

Les codes et le détail de chaque champ sont dans `API.md` du dépôt.

## Règles

- **Une écriture change le PaaS** : vérifiez l'application et l'opération
  avant d'envoyer un POST, PUT, PATCH ou DELETE.
- Ne rejouez **jamais** une écriture après un échec, sauf si l'opération
  honore `Idempotency-Key` (indiqué dans sa référence) et que vous renvoyez
  la même clé.
- **Pas de `POST /v1/auth/logout` dans un script ou un test qui partage un
  compte** : le serveur révoque alors les accès Git actifs du compte sur
  toutes ses sessions.
- N'utilisez pas `lifecycle` ni `include_deleted` sur `/v1/apps`.
- Fixez toujours un délai maximal (`--max-time`).
