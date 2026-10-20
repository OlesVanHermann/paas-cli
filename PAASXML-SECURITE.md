# Sécurité : ce que la plateforme impose, ce que le paas.xml déclare

État au 2026-10-18, plateforme v2.48.1. Les règles ci-dessous sont mesurées : `paas config plan`, scans et
déploiements en production (app neuve `ns-cve-304104`, Nightscout 15.0.8, sans exception de l'opérateur ; porte des
secrets mesurée le 2026-10-13 sur v2.36.0).

## 1. La porte de l'image servie

Chaque push lance la même chaîne : clone du commit, préparation hors réseau des dépendances verrouillées,
build, tests du locataire (`build.test`), scan Trivy de l'image, SBOM, signature cosign. Seule une image
signée dont le scan est vérifié est admise.

| Règle | Détail |
|---|---|
| Seuil par défaut | 0 CRITICAL et 0 HIGH **non acceptées** dans l'image servie. Le scan lit les paquets réellement installés dans l'image, pas les manifestes du dépôt. Il ne relève que les failles CRITICAL et HIGH. |
| Acceptation par le paas.xml | Le locataire déclare ce qu'il accepte dans `security` (section 2), sans intervention de l'opérateur. La politique est figée avec le build ; le scan l'applique et la garde. |
| Refus | Le déploiement échoue avec l'erreur complète `security_scan_blocked` (`paas.error.v1`, ancien code `admission_security_evidence_invalid`) : chaque faille bloquante avec son paquet, la version installée et la version corrigée quand elle existe, la politique appliquée et sa source, ce qui est déjà accepté, puis la marche à suivre avec les extraits `paas.xml` prêts à coller (mode A et mode B). Visible dans `paas deploy`, `paas builds list`, `paas builds cve <build>`, `paas apps info`, la console et l'API (`error` du déploiement, `last_error` de l'app). |
| Exception de l'opérateur | Toujours possible : **une app, une CVE, un paquet**, HIGH seulement (jamais une CRITICAL), justification, propriétaire, 180 jours au plus. Elle s'ajoute à ce que déclare le paas.xml, pour les scans enregistrés après son octroi. |
| Une seule politique (v2.36.0) | Le pipeline ne juge plus : il relaie le verdict de la plateforme, qui applique la section `security` du paas.xml et les exceptions de l'opérateur. `scan_policy` du build nomme la politique appliquée. |
| Constats de secrets (v2.36.0) | Le détecteur de secrets du scan a sa propre porte, soumise à `block_on` : par défaut, un constat HIGH ou CRITICAL (clé privée, jeton…) bloque l'image. `security.secret_exceptions` accepte un constat un par un (section 2) ; le refus nomme la règle, le fichier et la ligne. |
| Images publiées rescannées (v2.47.0) | Chaque image que la plateforme publie (recettes, outillage, bases admises des Dockerfile) est rescannée chaque jour ; une révision corrigée est publiée sous 72 h quand l'amont corrige une faille HIGH ou CRITICAL (`paas builds bases`). Un refus sur une faille de l'image de base nomme la révision corrigée ; `paas apps security-updates <app> --mode manual\|automatic` choisit l'alerte (défaut) ou le commit, le build et le service automatiques de la révision. |
| Revérification | Les deux portes d'admission et la restauration d'une app revérifient l'instantané du scan : une acceptation échue entre le scan et le déploiement fait refuser le déploiement. Les pods en service ne sont jamais arrêtés pour une échéance. |

Circuit pour un logiciel dont l'amont impose des versions vulnérables (Nightscout, CryptPad, Etherpad, Ghost,
ERPNext, SuiteCRM…) : **déclarer les acceptations dans le paas.xml, commiter, pousser.** Le README de chaque
exemple liste les failles connues ; l'exemple nightscout de la bibliothèque paas.xml porte un bloc complet prouvé en production.

## 2. Options de sécurité du paas.xml (v2.28.0, N0.SECURITY)

Décision du 2026-10-10 : « il faut A et B. je peux accepter les exceptions avec A, l'une par une. ou le mode
bourin je veux pas savoir B deploie juste. » Les deux modes coexistent ; ils demandent une plateforme
v2.28.0 ou plus, quelle que soit la `paas_spec_version` déclarée (un fichier v2.25.0 peut les porter).

```xml
<security>
  <!-- Mode A : une faille dans un paquet, quelle que soit sa sévérité, jusqu'à la fin du jour expires (UTC). -->
  <cve_exceptions>
    <item><id>CVE-2026-93687</id><package>braces</package><expires>2027-04-10</expires>
      <reason>Aucune version corrigée publiée ; braces 3.0.3 est une dépendance directe du logiciel</reason></item>
  </cve_exceptions>
  <!-- Mode B : seuil de blocage. high (défaut), critical (HIGH acceptées), none (rien ne bloque). -->
  <block_on>critical</block_on>
</security>
```

| Clé | Valeurs | Comportement |
|---|---|---|
| `security.cve_exceptions[]` | `id` (`CVE-…` ou `GHSA-…`), `package`, `reason`, `expires` (date `AAAA-MM-JJ` réelle) | Accepte cette faille dans ce paquet, **CRITICAL comprise**, jusqu'à la fin du jour `expires` en UTC. Aucune durée maximale n'est imposée ; l'erreur d'un scan bloqué propose aujourd'hui + 180 jours. Une seconde entrée pour la même faille dans le même paquet est refusée (`V2_DUPLICATE_NAME`) ; un identifiant ou une date invalide aussi (`V2_VALUE_INVALID`). |
| `security.block_on` | `high` (défaut), `critical`, `none` | Sévérité à partir de laquelle une faille non acceptée bloque l'image. `critical` accepte toutes les HIGH ; `none` n'en bloque aucune. `medium` et `low` sont refusés (`V2_VALUE_INVALID`) : le scan ne relève que CRITICAL et HIGH. |
| `security.secret_exceptions[]` (v2.36.0) | `rule` (règle du détecteur, par exemple `private-key`), `path` (fichier du constat), `expires`, `reason` | Accepte ce constat de ce fichier jusqu'à la fin du jour `expires` (UTC), pour un exemple livré par l'amont (clé de test, fichier d'exemple). `block_on` `none` les accepte tous. |
| `security.sbom`, `security.require_mfa_for_console` | — | Pas encore raccordées : refusées (`V2_PROJECTION_UNSUPPORTED_KEY`). |

Ce que la plateforme garde et montre :

- Le scan tourne toujours et reste enregistré, avec ses compteurs bruts et un instantané de tout ce qu'il
  accepte : pour chaque faille, sa sévérité, sa source (`paas.xml`, `policy` pour le seuil, `operator`), son
  échéance et sa raison. `paas builds cve <build>` affiche la politique (`block_on` et sa source, nombre
  d'exceptions déclarées) et l'état de chaque faille (`✗ BLOCKING` ou `accepted (source, until …)`).
- La ligne commitée et poussée vaut acceptation du risque : pas de déclaration supplémentaire. Le commit, son
  auteur et la politique figée avec le build restent dans la preuve.
- Une exception de l'opérateur ne couvre jamais une CRITICAL ; une acceptation du paas.xml le peut.
- Les protections de la plateforme restent en place, car elles protègent les autres clients et non l'app :
  isolation réseau des bases réservées, exécution sans privilège, signature, admission par Git seulement.

Affichage d'une échéance : la plateforme enregistre l'instant de fin, le minuit UTC du lendemain
(`expires 2027-04-10` → `2027-04-11T00:00:00Z`). La console affiche « jusqu'au 2027-04-10 inclus (UTC) » ;
`paas builds cve` et l'API donnent l'instant de fin.

## 3. Secrets

| Mode | Usage |
|---|---|
| `generate` | Valeur tirée par la plateforme : `<generate>hex</generate>` (ou `base64`) et `<bytes>32</bytes>`. |
| `sealed` | Valeur choisie par le client, scellée par `paas secrets seal --name <NOM> --value-file <fichier>` (ou sur l'entrée standard, jamais en argument). Elle ne s'ouvre que dans la plateforme, pour votre tenant et ce nom de secret ; elle peut être commitée. |
| `provide` (`tenant`) | Valeur fournie hors Git, après le push (v2.48.0) : la release, construite, testée, scannée et signée, l'attend (`awaiting_secrets`) ; `paas secrets provide NOM` la lit sur l'entrée standard ou dans un fichier, jamais en argument, et l'envoie dans le corps de la requête ; la release repart sans nouveau push. Prouvé en production. |

- Nom : `[A-Za-z_][A-Za-z0-9_]*`, 128 caractères au plus. Le préfixe `PAAS_` est réservé à la plateforme
  (`V2_VALUE_INVALID`).
- Un secret est injecté sous son propre nom comme variable d'environnement. Une variable `env` ne peut pas
  porter le même nom (`V2_DUPLICATE_NAME`).
- Les mots de passe des comptes passent par l'entrée standard des commandes natives (`stdin_secret`,
  `stdin_template`), jamais par leurs arguments. Une valeur littérale de mot de passe est refusée.
- Chaque valeur que la plateforme injecte (variables, URL et chaînes de connexion, captures de l'installation)
  est masquée dans les diagnostics et les journaux, brute, encodée en URL ou en base64 ; le masque nomme le
  secret, jamais sa valeur (v2.47.0). Un contrôle d'installation en échec publie sa valeur obtenue masquée de même
  (v2.48.1).

## 4. Chaîne de build

- Le build part toujours du commit poussé sur le dépôt Git de l'app (`forgejo://`). Une image externe est
  refusée (`admission_build_required`), comme une source Git externe.
- Les dépendances viennent des verrous du dépôt, vérifiés, et le build tourne hors réseau.
- Un `Dockerfile` du dépôt n'est construit que sur des bases d'outillage épinglées par digest et autorisées,
  sans image `node` : c'est le sens de `build_policy.vendor_application_image`. Avec un paas.xml, la recette
  technique produit le Dockerfile ; celui de l'amont reste une source inerte, dont `build.source_dockerfile`
  fixe l'empreinte.
- Les images sont signées (cosign) et accompagnées d'un SBOM.

## 5. Réseau

- Bases réservées (PostgreSQL, MySQL, Redis, MongoDB) : TLS vérifié. Depuis la v2.27.0, chaque base n'accepte
  que les pods de son app, plus les sauvegardes et opérateurs de la plateforme (une NetworkPolicy par base).
- Entrée HTTPS : websockets acceptés, 100 Mo par requête, délais de 86 400 s, limite de débit par IP.
- Hôte de l'app : `apps-<8hex>.<domaine des apps>`, que donne `url` (v2.48.0). Le nom court
  `<8hex>.<domaine des apps>` redirige (308) vers lui, tous ses chemins compris (`/login`, `/signup` et `/auth/`
  partaient vers la console avant v2.38.1). Utilisez l'hôte `apps-…` dans la configuration de l'app.
- Routes refusées d'une app PHP (`web.deny_routes`, v2.47.0) : un chemin, quelle que soit sa casse ou son
  extension, et un paramètre de requête par nom et valeur, refusés (403) avant les règles de l'app.
- Liens déclarés entre apps : disponibles depuis v2.30.0 (FEATURES, section 5 ter). Pas encore déclarables
  (prévu) : règles de sortie, domaines personnalisés (N0.DOMAINS), réglages d'entrée par app (N0.EDGE).

## 6. Accès Git

- Pousser en HTTPS : `paas git credentials configure <app>` configure un identifiant de dépôt limité à
  l'écriture du dépôt de l'app, puis `git push`.
- Les clés SSH déclarées ne donnent pas encore accès au dépôt dans tous les cas : utilisez HTTPS.
