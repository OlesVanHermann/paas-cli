# Version

La version publiée porte un tag Git `vX.Y.Z`. `paas-apps --version` donne la
version installée.

## v0.3.4 — 2026-10-11

- **CLI `paas-apps`** pour Linux x86_64 et ARM64, vérifiée contre l'API
  **2.31.0** (428 opérations) :
  - `paas-apps api` donne accès à toutes les opérations de l'API ;
  - commandes métier pour la session (dont la connexion dans le navigateur),
    les applications, les builds et les releases ;
  - diagnostic complet d'un build ou d'un déploiement en échec
    (`paas.error.v1`), avec **qui doit agir** : `Cust` quand le `paas.xml` ou
    le dépôt se corrige, `Paas` quand la plateforme ne sait pas encore le
    faire (la capacité qui lui manque est nommée) ; rapport CVE
    (`builds cve`) et tests (`builds test`) d'un build ;
  - `apps list` montre, pour chaque application en échec, qui doit agir et
    le code de l'échec (colonne `FAILURE`).
- **Documentation** : guide de la CLI, guide et référence de l'API, contrat
  OpenAPI, skills pour agents IA (`paas-cli`, `paas-api`).
- **`exemples/`** : dix logiciels à installer en une commande par leur
  `paas.xml` (`push.sh`) et à retirer (`clean.up`), avec trois politiques CVE
  en exemple : par défaut, liste d'exceptions, contrôle désactivé.
