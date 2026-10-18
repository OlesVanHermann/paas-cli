# Version

La version publiée porte un tag Git `vX.Y.Z`. `paas-apps --version` donne la
version installée.

## v2.48.0 — 2026-10-18

- **CLI `paas-apps` 2.48.0**, vérifiée contre l'API client **2.48.0** (433
  opérations, chacune présente sur le serveur en service). Elle publie aussi
  tout le contenu de la 2.47.0 ci-dessous, jamais publiée seule :
  - `secrets provided` et `secrets provide NOM` : les valeurs que vous
    fournissez à une application (`secrets.<NOM>.provide` dans son
    `paas.xml`). Sa release, construite, testée, scannée et signée, les
    attend toutes (état `awaiting_secrets`) ; `secrets provide` lit la valeur
    dans un fichier (`--value-file`) ou sur l'entrée standard (saisie sans
    écho au clavier), jamais en argument, l'envoie dans le corps de la
    requête, et la release repart sans nouveau push ;
  - `ps` : les processus d'une application et les pods de sa release
    courante ; un pod d'une release remplacée encore vivant est marqué
    `(superseded)` ; les redémarrages comptés sont ceux de la release
    courante ; l'état suit les répliques prêtes (`scaled-zero`, `running`,
    `degraded`, `not-ready`) ;
  - qui doit agir : l'imputation affichée est celle du verdict, enregistrée
    avec lui et la version de ses règles ; quand les règles du jour décident
    autrement, une ligne `now` le dit à côté, et la marche à suivre suit
    cette lecture. `apps list` et `apps info` (nouvelle ligne `failure`)
    donnent la même imputation, et sa reclassification une fois datée par la
    plateforme ;
  - releases qui attendent : une release appliquée à 0 réplique
    (`scaled-zero`) est celle de l'application, servie par
    `paas scale web 1` ; une release `awaiting_secrets` attend vos valeurs.
    `releases list` et `releases info` le disent.
- **SDK et contrat** : `list_provided_secrets`, `provide_secret` (la valeur
  est un `Secret`, jamais affichée ni tracée) ; `App.current_release` (la
  release servie) ; `PodRef.release_id` et `current` ; `AppAddon.last_error` ;
  `Responsibility.rules` et `decided_at` ; `PaasError.reclassification` et
  `reviewed_rules` ; code `secrets_not_provided` ; raisons de rollout
  `not_created` et `not_started`, et la cause que le journal établit
  (`details.runtime_gap`).

## v2.47.0 — 2026-10-18

- **CLI `paas-apps`** pour Linux x86_64 et ARM64. Sa version est celle de la
  plateforme qu'elle sert : vérifiée contre l'API client **2.47.0** (431
  opérations, chacune présente sur le serveur en service) :
  - `paas-apps api` donne accès à toutes les opérations de l'API client ;
  - commandes métier pour la session (dont la connexion dans le navigateur),
    les applications, les builds et les releases ;
  - diagnostic complet d'un build ou d'un déploiement en échec
    (`paas.error.v1`), avec **qui doit agir** : `Cust` quand le `paas.xml` ou
    le dépôt se corrige, `Paas` quand la plateforme ne sait pas encore le
    faire (la capacité qui lui manque est nommée) ou quand un incident
    passager l'a arrêtée (la reconstruction du même commit suffit) ; la marche
    à suivre s'accorde avec qui doit agir ; rapport CVE (`builds cve`) et
    tests (`builds test`) d'un build ; quand les failles qui bloquent une
    image sont dans sa base et que la plateforme en a publié une révision
    corrigée, le diagnostic la nomme ;
  - chaque diagnostic d'un plan refusé commence par qui doit agir (colonne
    `WHO` : `Cust` ou `Paas`) ;
  - `apps list` montre, pour chaque application en échec, qui doit agir et
    le code de l'échec (colonne `FAILURE`) ;
  - `apps security-updates` : ce que fait une application quand la plateforme
    publie une révision corrigée de la base de son image, une alerte qui nomme
    les failles et la révision (`manual`) ou une mise à jour commitée dans son
    dépôt, construite et déployée par la plateforme (`automatic`), et
    l'historique de ces mises à jour ;
  - `builds bases` : les bases qu'un Dockerfile peut prendre en `FROM`, leur
    rôle et leur recette, avec le dernier rescan quotidien de chaque image
    publiée.
- **SDK et contrat** : une méthode par opération de l'API client, dont les
  mises à jour de sécurité (`get_security_updates`,
  `set_security_updates_mode`) et les bases admises (`list_build_bases`) ;
  `paas.error.v1` porte `responsibility.transient` ; le rapport CVE d'un build
  porte les secrets détectés dans l'image, sans leur valeur.
- **Documentation** : guide de la CLI, guide et référence de l'API, contrat
  OpenAPI, skills pour agents IA (`paas-cli`, `paas-api`). Le README dit ce
  que la plateforme construit : un `paas.xml`, ou un `Dockerfile` avec un
  `paas.toml` qui déclare la commande de test, à ses conditions.
- **`exemples/`** : dix logiciels à installer en une commande par leur
  `paas.xml` (`push.sh`) et à retirer (`clean.up`), avec trois politiques CVE
  en exemple : par défaut, liste d'exceptions, contrôle désactivé.
- **README** : la voie Dockerfile de la plateforme — `runtime` `dockerfile`
  dans `paas.xml`, bases admises listées par `paas-apps builds bases`
  (outillage et images des recettes publiées), `pip` à empreintes.
