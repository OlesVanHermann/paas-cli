# API tenant du PaaS di2amp : guide

Ce guide explique les règles communes à toute l'API. Le détail des **437
opérations** de l'API client, domaine par domaine, est dans la
**[référence générée](API-REFERENCE.md)**. Le contrat machine, qui fait foi, est
[`openapi.yaml`](openapi.yaml) (OpenAPI 3.0.3), vérifié contre
l'API **2.48.0**.

| Élément | Valeur |
|---|---|
| URL de base | `https://console.di2amp.com/api` |
| Versionnement | Chemins préfixés par `/v1/` |
| Format | JSON (`Accept: application/json`, `Content-Type: application/json`) |
| Authentification | Jeton Bearer (JWT), sauf pour les 29 opérations publiques |

| Domaine | Opérations |
|---|---|
| [`apps`](API-REFERENCE.md#domaine-apps) : applications, cycle de vie, processus, restauration | 63 |
| [`ai`](API-REFERENCE.md#domaine-ai) : agents IA, points de terminaison IA, GPU, fine-tuning | 45 |
| [`addons`](API-REFERENCE.md#domaine-addons) : bases de données, caches, recherche, sauvegardes | 42 |
| [`auth`](API-REFERENCE.md#domaine-auth) : connexion, MFA, OAuth, sessions, jetons, clés | 40 |
| [`billing`](API-REFERENCE.md#domaine-billing) : offres, consommation, factures, paiement | 36 |
| [`tenant`](API-REFERENCE.md#domaine-tenant) : SSO, identité, SMTP, réseau, RGPD | 36 |
| [`config`](API-REFERENCE.md#domaine-config) : variables, secrets, coffres externes | 34 |
| [`observability`](API-REFERENCE.md#domaine-observability) : journaux, métriques, traces, alertes, statut | 29 |
| [`builds`](API-REFERENCE.md#domaine-builds) : builds, preuves de sécurité, tests, pipelines | 22 |
| [`deploys`](API-REFERENCE.md#domaine-deploys) : déploiements, promotion, canary, retour arrière | 14 |
| [`git`](API-REFERENCE.md#domaine-git) : dépôt lié, accès Git, sources externes | 13 |
| [`meta`](API-REFERENCE.md#domaine-meta) : santé, régions, conformité | 10 |
| [`functions`](API-REFERENCE.md#domaine-functions) : fonctions serverless | 10 |
| [`team`](API-REFERENCE.md#domaine-team) : membres, invitations, espaces | 10 |
| [`environments`](API-REFERENCE.md#domaine-environments) : environnements d'exécution | 9 |
| [`volumes`](API-REFERENCE.md#domaine-volumes) : volumes persistants et instantanés | 9 |
| [`domains`](API-REFERENCE.md#domaine-domains) : domaines personnalisés | 6 |

## Authentification

1. `POST /v1/auth/login` avec `{"email", "password"}` renvoie une paire de
   jetons. D'autres parcours existent : inscription, OAuth, MFA, SSO (voir
   [`auth`](API-REFERENCE.md#domaine-auth)).
2. Chaque appel authentifié envoie `Authorization: Bearer <access_token>`. Un
   jeton personnel ou une clé API s'utilise de la même façon.
3. Le jeton d'accès est un JWT. La claim `exp` donne son expiration (en
   secondes Unix) et la claim `tenant` son tenant. Rafraîchissez-le avant
   l'expiration avec `POST /v1/auth/refresh` (`{"refresh_token"}`) ; les
   clients officiels le font quand il reste moins de 5 minutes.
4. `POST /v1/auth/logout` révoque le jeton d'accès présenté. Le serveur
   révoque aussi les **accès Git actifs de l'utilisateur, sur toutes ses
   sessions**. Ne l'appelez pas depuis un script ou un test qui partage le
   compte.

**Ne passez jamais un mot de passe ou un jeton en argument d'une commande** :
il serait visible dans `ps`, dans `/proc` et dans l'historique du shell. Avec
curl, transmettez l'en-tête par l'entrée standard. `printf` est une commande
interne du shell et n'apparaît pas dans la liste des processus :

```bash
printf 'header = "Authorization: Bearer %s"\n' "$PAAS_TOKEN" \
  | curl -sS --max-time 30 -K - https://console.di2amp.com/api/v1/apps
```

Pour le login, construisez le corps avec `jq` à partir de variables et
envoyez-le par l'entrée standard :

```bash
jq -n --arg email "$PAAS_EMAIL" --arg password "$PAAS_PASSWORD" \
   '{email: $email, password: $password}' \
  | curl -sS -H 'Content-Type: application/json' --data-binary @- \
      https://console.di2amp.com/api/v1/auth/login
```

## Enveloppes

Chaque opération déclare la forme de sa réponse (`x-paas-envelope`) :

| Enveloppe | Forme |
|---|---|
| `data` | `{"data": …}` (le cas le plus courant) |
| `data-meta` | `{"data": […], "meta": {"total", "limit", "offset"}}` |
| `bare` | la valeur seule (`/v1/healthz`, `/v1/regions`…) |
| `none` | aucun corps (204) |
| `raw` | contenu brut : fichier (PDF, archive), texte, redirection |
| `stream` | flux continu (journaux, terminal WebSocket) |

Un client robuste qui reçoit une réponse sans `data` la lit telle quelle.

## Erreurs

| Forme | Quand | Exemple |
|---|---|---|
| JSON `ErrorDocument` | erreur métier | `{"error":{"code":"not_found","message":"app 'x' not found (unknown name or id)"}}` |
| `text/plain` | corps de requête rejeté avant traitement (422) | `Failed to deserialize the JSON body into the target type: missing field ...` |
| corps vide | route inexistante (404) ou méthode refusée (405) | |

`ErrorDocument.error` contient toujours `code` et `message`. Selon le cas, il
contient aussi :
- `field` : le champ en cause ;
- `keys` : les clés refusées, noms seulement ;
- `action` : l'étape suivante conseillée.

Un 404 **avec** corps JSON signifie que la ressource est inconnue dans votre
tenant ; un 404 **sans** corps, que la route n'existe pas sur ce serveur.

| Statut | Signification | Nouvelle tentative |
|---|---|---|
| 400 | requête impossible dans l'état actuel (par exemple restaurer une application qui n'est pas supprimée) | non |
| 401 | jeton absent, invalide, expiré ou révoqué | après rafraîchissement, une fois |
| 404 | ressource ou route inconnue | non |
| 422 | corps invalide | non |
| 429, 502, 503, 504 | surcharge ou indisponibilité | oui pour une lecture ; pour une écriture, seulement avec une `Idempotency-Key` honorée |

## Échec d'un build ou d'un déploiement : paas.error.v1

Un build, un scan, un plan, une admission ou un démarrage qui échoue n'est
pas une erreur HTTP : la lecture réussit (200) et l'objet porte son **erreur
complète**, un objet `PaasError` de schéma `paas.error.v1` (API 2.28.0 et
suivantes). Tout y est pour corriger sans autre requête.

| Où | Champ | Opérations |
|---|---|---|
| Déploiement | `error` (et `failure_code` = `error.code`, `failure_kind` = `error.stage`) | `list_deploys`, `get_deploy` |
| Release liée à un déploiement | `release.error` | `get_deploy` |
| Build | `failure` (le champ `error` garde l'ancienne chaîne de preuve) | `list_builds`, `get_build` |
| Application | `last_error` : l'erreur du dernier déploiement quand il a échoué, sinon `null` | `get_app` |
| Liste des applications | `last_failure` : le code de l'échec du dernier déploiement et qui doit agir, sinon `null` | `list_apps` |
| Rapport CVE refusé | `error` | `get_cve_for_build` |

| Champ | Contenu |
|---|---|
| `schema` | Toujours `paas.error.v1` |
| `code` | Code stable (voir ci-dessous) ; `legacy_code` : le code d'avant 2.28.0 |
| `stage` | Étape en échec : `intake`, `plan`, `clone`, `prepare`, `build`, `test`, `scan`, `sign`, `admission`, `rollout`, `runtime` |
| `summary` | Ce qui a échoué et pourquoi, en une phrase |
| `message` | L'explication détaillée |
| `app_id`, `deploy_id`, `build_id`, `commit`, `occurred_at` | Le contexte de l'échec |
| `details` | Propre au code |
| `remediation` | Marche à suivre, dans l'ordre : `title`, et selon l'étape `command` (CLI `paas`), `paas_xml` (extrait à ajouter ou corriger), `docs` |
| `log_excerpt` | Fin du journal de l'étape : `step`, `exit_code`, `lines`, `truncated` |
| `links` | Chemins d'API liés (`build`, `cve`, `tests`…) |
| `responsibility` | Qui doit agir (API 2.31.0), voir ci-dessous |

### Qui doit agir : `Cust` ou `Paas`

Depuis l'API 2.31.0, chaque erreur porte `responsibility`. Les erreurs
enregistrées avant cette version la portent aussi.

| Champ | Contenu |
|---|---|
| `owner` | `customer` : le `paas.xml` ou le dépôt de l'application se corrige ; `platform` : la plateforme ne sait pas encore installer l'application |
| `label` | `Cust` ou `Paas` : le badge à afficher |
| `basis` | `documented` (index des codes de refus), `rule` (nature de l'échec), `family` (code pas encore documenté, classé par sa famille), `presumption` (cause non établie, présumée côté plateforme) |
| `code` | Le code qui décide : code de refus (`ENV_…`, `V2_…`), code d'exécution (`TECHNICAL_…`), raison du rollout, ou le code de l'erreur |
| `capability` | Pour la plateforme : la capacité qui lui manque (`composer.archive_size`, `pipeline.scan_gate`…) |
| `summary` | La phrase à montrer telle quelle |
| `rules`, `decided_at` | API 2.48.0 : la version des règles qui ont décidé et la date du verdict ; l'imputation est enregistrée avec lui et servie telle quelle à chaque lecture |
| `transient` | API 2.47.0 : `true` pour un incident passager de la plateforme (la base du scanner injoignable un moment : `security_scan_unavailable`, `capability` `pipeline.scan_database`) ; rien ne manque, reconstruire le même commit suffit. Absent sinon |

Pour `Paas`, les opérateurs de la plateforme sont prévenus : un correctif de
l'application ne lèvera pas le refus. Chaque diagnostic d'un `plan_refused`
porte aussi `owner`, `capability` et `basis`, et `refusal` (`code`, `path`,
`rule`) quand un refus générique nomme le contrôle en cause. `last_failure`,
dans `list_apps`, donne pour chaque application `code`, `stage`, `owner`,
`label`, `basis`, `capability` et `reason_code` (le code qui décide) ;
`get_app` donne le même objet depuis l'API 2.48.0. Quand les règles du jour
décident autrement que le verdict, l'erreur porte `reclassification` (leur
lecture, avec `rules`, et `at` une fois datée par un passage de la
plateforme) à côté de `responsibility`, jamais à sa place ; la marche à
suivre suit la lecture la plus récente. `last_failure` porte alors
`reclassification` datée.

| `code` | Étape | `details` |
|---|---|---|
| `security_scan_blocked` | `scan` | `policy` (`block_on`, exceptions déclarées, origine), `counts`, `blocking` (chaque faille bloquante : `id`, `severity`, `package`, `installed`, `fixed`, `target`, `title`), `blocking_total`, `blocking_distinct`, `accepted` (failles acceptées, par qui, jusqu'à quand) |
| `plan_refused` | `plan` | `file`, `diagnostics` (code, chemin de la clé du `paas.xml`, message), `diagnostics_total` |
| `build_step_failed`, `build_timed_out` | `build` | `failed_tasks`, `platform_message` et, quand un contrôle documenté a échoué, `refusal` (`code`, `path`, `rule`) |
| `tests_failed` | `test` | `tests` (commande, code de sortie), `failed_tasks`, `platform_message` |
| `admission_refused` | `admission` | `platform_code`, `reason`, `platform_message` |
| `rollout_failed` | `rollout` | `reason` (`oom_killed`, `probe_failed`, `process_exited`, `container_config`, `not_ready`, `unschedulable`, `volume_mount`, `image_pull`, `apply_refused`, `apply_timed_out`), `process`, `verdict`, `container_state`, `containers`, `events`, `probes`, `resources`, `port` |
| `database_not_ready` | `rollout` | `service`, `platform_code`, `readiness_window_seconds`, `container_state`, `containers`, `events` |

Un échec enregistré avant l'API 2.28.0 garde `error_message`, `failure_code`
et `failure_kind` sur le déploiement. `last_error` en donne alors un objet de
repli : `code` (l'ancien `failure_code`, sinon `deploy_failed`), `stage`,
`summary`, `message`, `build_id`, sans `occurred_at` ni `details`.

Pour un client :
- affichez `summary`, puis `message`, puis `remediation` : ces textes sont
  écrits pour être montrés tels quels et ne citent jamais la valeur d'un
  secret ;
- un code inconnu se lit comme les autres : `summary`, `message`,
  `remediation` et `details` restent valables ;
- après correction (`paas.xml` commité, exception déclarée, correctif de la
  plateforme), reconstruisez le même commit : `paas builds rebuild` (CLI
  `paas` 2.30.0), ou poussez un nouveau commit.

## Idempotence

Les opérations marquées `x-paas-idempotency-key: supported` acceptent
l'en-tête `Idempotency-Key`. Rejouer la même requête avec la même clé ne
l'exécute qu'une fois. Les autres écritures ne doivent **jamais** être
rejouées automatiquement : une nouvelle tentative pourrait les exécuter deux
fois.

## Références d'application

Dans les chemins `/v1/apps/{app_id}/…`, `{app_id}` accepte le **nom** ou
l'**UUID** de l'application. Elle est cherchée dans votre tenant ; si elle n'y
est pas, la réponse est 404 `not_found`.

## Pagination

Les listes paginées (`data-meta`), comme les builds et les déploiements, ne
servent que la **première page** :
- `limit` va de 1 à 100 ;
- il n'y a pas de page suivante, et `offset` est sans effet ;
- `meta.total` vaut le nombre d'éléments renvoyés.

Les autres listes renvoient tout.

## Valeurs et compatibilité

- Les états sont des **chaînes libres**. Les valeurs listées dans la
  référence sont celles observées en service, pas une liste fermée : traitez
  toute valeur inconnue comme valide.
- Les dates sont des chaînes ISO 8601 (UTC).
- De nouveaux champs peuvent apparaître : ignorez ceux que vous ne connaissez
  pas.
