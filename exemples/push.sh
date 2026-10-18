#!/usr/bin/env bash
# Installe un exemple sur le PaaS di2amp par le chemin normal d'un client : l'arbre
# amont exact (ou le code de l'exemple), le paas.xml de l'exemple, puis git push.
#
#   ./push.sh wordpress             installe l'exemple wordpress dans l'app « wordpress »
#   ./push.sh wordpress mon-blog    même exemple, app « mon-blog »
#   ./push.sh --plan wordpress      vérifie tout hors ligne, sans rien créer ni pousser
#
# Prérequis : git, jq, la CLI paas 2.30 ou plus récente et une session
# (paas login --web). Le travail se fait dans $PAAS_EXEMPLES_DIR
# (par défaut ~/paas-exemples) : <app>/ pour le dépôt, <app>.secrets/ pour
# les secrets, en fichiers 0600 : tirés au hasard, ou imposés par le logiciel
# (fichier valeurs de l'exemple), puis scellés. Aucun mot de passe n'est affiché.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKDIR=${PAAS_EXEMPLES_DIR:-$HOME/paas-exemples}
PLAN_ONLY=0
# L'app visée est toujours celle nommée ici, jamais celle de l'environnement.
unset PAAS_APP
# Git ne demande jamais d'identifiant au terminal : un accès manquant échoue tout de suite.
export GIT_TERMINAL_PROMPT=0

die() { printf 'erreur : %s\n' "$*" >&2; exit 1; }
step() { printf '\n== %s\n' "$*"; }
usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --plan) PLAN_ONLY=1; shift ;;
        -h|--help) usage 0 ;;
        -*) die "option inconnue : $1 (voir --help)" ;;
        *) break ;;
    esac
done
[ $# -ge 1 ] && [ $# -le 2 ] || usage 2
EXAMPLE=${1%/}
APP=${2:-$EXAMPLE}
SRC="$HERE/$EXAMPLE"
if [ ! -f "$SRC/paas.xml" ] || [ ! -f "$SRC/source" ]; then
    die "exemple inconnu : $EXAMPLE (disponibles : $(cd "$HERE" && ls -d -- */ | tr -d / | tr '\n' ' '))"
fi
printf '%s' "$APP" | grep -qE '^[a-z][a-z0-9-]{1,38}[a-z0-9]$' \
    || die "nom d'app invalide : $APP (3 à 40 caractères : minuscules, chiffres, tirets)"

# Source : l'arbre amont (adresse, étiquette, commit attendu) ou, pour un exemple
# qui apporte son propre code, le dossier de l'exemple et son arbre Git attendu.
field() { sed -n "s/^$1=//p" "$SRC/source" | head -1; }
LOCAL=$(field local)
if [ -n "$LOCAL" ]; then
    TREE=$(field tree)
    [ -d "$SRC/$LOCAL" ] && printf '%s' "$TREE" | grep -qE '^[0-9a-f]{40}$' \
        || die "$SRC/source incomplet : local (un dossier de l'exemple) et tree (40 caractères) sont requis"
else
    URL=$(field url)
    REF=$(field ref)
    COMMIT=$(field commit)
    [ -n "$URL" ] && [ -n "$REF" ] && printf '%s' "$COMMIT" | grep -qE '^[0-9a-f]{40}$' \
        || die "$SRC/source incomplet : url, ref et commit (40 caractères) sont requis"
fi
# Version minimale de la CLI : 2.30, ou celle que fixe le fichier source de l'exemple.
MIN_PAAS=$(field paas)
MIN_PAAS=${MIN_PAAS:-2.30.0}

for tool in git jq paas; do
    command -v "$tool" >/dev/null || die "$tool introuvable"
done
version=$(paas --version | awk '{print $2}')
printf '%s %s' "$version" "$MIN_PAAS" | awk '{
    split($1, v, "."); split($2, m, ".")
    for (i = 1; i <= 3; i++) if (v[i] + 0 != m[i] + 0) exit !(v[i] + 0 > m[i] + 0)
    exit 0 }' \
    || die "paas $version : la version $MIN_PAAS ou plus récente est requise (curl -fsSL https://get.di2amp.com/install.sh | sh)"
paas whoami >/dev/null 2>&1 || die "aucune session : lancez « paas login --web »"

REPO="$WORKDIR/$APP"
SECRETS="$WORKDIR/$APP.secrets"
mkdir -p "$WORKDIR"

if [ -n "$LOCAL" ]; then
    step "1. Code de l'exemple : $EXAMPLE/$LOCAL"
    if [ -d "$REPO/.git" ]; then
        echo "déjà copié : $REPO"
    else
        mkdir -p "$REPO"
        cp -R "$SRC/$LOCAL/." "$REPO/"
        git -C "$REPO" init --quiet -b main
        git -C "$REPO" add -A
        git -C "$REPO" -c user.name=paas-exemples -c user.email=paas-exemples@example.invalid \
            commit --quiet -m "$EXAMPLE : code de l'exemple"
    fi
    # Le premier commit du dépôt porte le code de l'exemple, octet pour octet.
    root=$(git -C "$REPO" rev-list --max-parents=0 HEAD | head -1)
    [ "$(git -C "$REPO" rev-parse "$root^{tree}")" = "$TREE" ] \
        || die "$REPO ne part pas de l'arbre attendu $TREE (le dossier $EXAMPLE/$LOCAL a-t-il changé ?)"
    echo "arbre de l'exemple vérifié : $TREE"
else
    step "1. Source amont : $URL, $REF"
    if [ -d "$REPO/.git" ]; then
        echo "déjà cloné : $REPO"
    else
        git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$REF" "$URL" "$REPO"
    fi
    git -C "$REPO" merge-base --is-ancestor "$COMMIT" HEAD 2>/dev/null \
        || die "$REPO ne part pas du commit attendu $COMMIT (l'étiquette $REF a-t-elle bougé ?)"
    echo "commit amont vérifié : $COMMIT"
fi

step "2. paas.xml et secrets scellés"
[ -f "$REPO/paas.xml" ] || cp "$SRC/paas.xml" "$REPO/paas.xml"
mkdir -p "$SECRETS"
chmod 0700 "$SECRETS"
names=$(grep -oE '<[A-Z][A-Z0-9_]*><sealed>A-SCELLER</sealed>' "$REPO/paas.xml" \
    | sed -E 's/^<([A-Z0-9_]+)>.*/\1/' | sort -u || true)
for name in $names; do
    file="$SECRETS/$name"
    # Valeur imposée par le logiciel (fichier « valeurs » de l'exemple) :
    # scellée telle quelle, jamais tirée au hasard.
    fixed=""
    [ ! -f "$SRC/valeurs" ] || fixed=$(sed -n "s/^$name=//p" "$SRC/valeurs" | head -1)
    if [ -n "$fixed" ]; then
        (umask 077 && printf '%s' "$fixed" > "$file")
        echo "valeur imposée par le logiciel : $name (fichier $EXAMPLE/valeurs)"
    elif [ ! -s "$file" ]; then
        # 32 caractères alphanumériques tirés de /dev/urandom.
        value=$(set +o pipefail; head -c 512 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32)
        [ "${#value}" -eq 32 ] || die "tirage aléatoire trop court pour $name"
        (umask 077 && printf '%s' "$value" > "$file")
        unset value
    fi
    sealed=$(paas secrets seal --name "$name" --value-file "$file")
    printf '%s' "$sealed" | grep -qE '^paas-sealed:[A-Za-z0-9_.:=+/-]+$' \
        || die "scellement de $name : sortie inattendue de paas secrets seal"
    sed "s|<$name><sealed>A-SCELLER</sealed>|<$name><sealed>$sealed</sealed>|" "$REPO/paas.xml" > "$REPO/paas.xml.tmp"
    mv "$REPO/paas.xml.tmp" "$REPO/paas.xml"
    echo "scellé : $name (valeur dans $file)"
done
! grep -q '<sealed>A-SCELLER</sealed>' "$REPO/paas.xml" || die "une valeur reste à sceller dans $REPO/paas.xml"

step "3. Commit"
git -C "$REPO" add paas.xml
if git -C "$REPO" diff --cached --quiet; then
    echo "paas.xml déjà commité"
else
    git -C "$REPO" \
        -c user.name="$(git -C "$REPO" config user.name || echo paas-exemples)" \
        -c user.email="$(git -C "$REPO" config user.email || echo paas-exemples@example.invalid)" \
        commit --quiet -m "paas.xml : exemple $EXAMPLE"
    echo "commit : $(git -C "$REPO" log -1 --format='%h %s')"
fi

step "4. Plan hors ligne (paas config plan)"
store="$WORKDIR/$APP.catalogue-store.json"
paas environments:catalogue-store > "$store"
(cd "$REPO" && paas config plan --catalogue "$store") \
    || die "plan refusé : corrigez $REPO/paas.xml d'après les diagnostics ci-dessus"
if [ "$PLAN_ONLY" -eq 1 ]; then
    printf '\nPlan accepté (--plan) : aucune app créée, rien de poussé.\n'
    exit 0
fi

step "5. Application $APP"
if info=$(paas apps info "$APP" --json 2>/dev/null); then
    # Une app existante n'est reprise que si ce script l'a déjà poussée
    # depuis ce dossier : jamais une app qu'il n'a pas créée.
    known=$(git -C "$REPO" remote get-url paas 2>/dev/null || true)
    [ -n "$known" ] && [ "$known" = "$(printf '%s' "$info" | jq -r '.git_url // empty')" ] \
        || die "l'app $APP existe déjà : choisissez un autre nom (./push.sh $EXAMPLE <nom>)"
    echo "reprise de l'app $APP"
else
    paas apps create "$APP" >/dev/null
    info=$(paas apps info "$APP" --json)
    echo "app créée : $APP"
fi
git_url=$(printf '%s' "$info" | jq -r '.git_url // empty')
[ -n "$git_url" ] || die "l'app $APP n'a pas de dépôt Git"

step "6. Push vers le dépôt de l'app"
if git -C "$REPO" remote get-url paas >/dev/null 2>&1; then
    git -C "$REPO" remote set-url paas "$git_url"
else
    git -C "$REPO" remote add paas "$git_url"
fi
# Un accès Git encore actif (15 min par défaut) sert tel quel : la plateforme
# refuse d'en ouvrir un second (409).
cred=$( (cd "$REPO" && paas git credentials status "$APP" --json 2>/dev/null) | jq -r '.status // empty' 2>/dev/null || true)
if [ "$cred" != active ]; then
    (cd "$REPO" && paas git credentials configure "$APP" >/dev/null)
elif git -C "$REPO" ls-remote paas >/dev/null 2>&1; then
    echo "accès Git encore actif : réutilisé"
else
    die "un accès Git est déjà actif pour $APP, mais pas dans ce dossier : attendez son expiration (paas git credentials status $APP) ou révoquez-le (paas git credentials revoke $APP)"
fi
tree=$(git -C "$REPO" rev-parse "HEAD^{tree}")
if [ -n "$LOCAL" ]; then
    message="$EXAMPLE : code de l'exemple (arbre $TREE) et paas.xml"
else
    message="$EXAMPLE : arbre amont $REF ($COMMIT) et paas.xml"
fi
# Le dépôt de l'app a sa propre histoire (souvent un premier commit) : le
# commit poussé porte l'arbre complet, avec la tête distante pour parent.
rc=0
git -C "$REPO" ls-remote --exit-code paas refs/heads/main >/dev/null 2>&1 || rc=$?
case "$rc" in
    0|2) ;;
    *) die "lecture du dépôt de l'app impossible (git ls-remote, code $rc)" ;;
esac
if [ "$rc" -eq 0 ]; then
    git -C "$REPO" fetch --quiet paas main
    head=$(git -C "$REPO" rev-parse FETCH_HEAD)
    if [ "$(git -C "$REPO" rev-parse "$head^{tree}")" = "$tree" ]; then
        new=""
        echo "déjà poussé : $(git -C "$REPO" log -1 --format='%h' "$head")"
    else
        new=$(git -C "$REPO" -c user.name="$(git -C "$REPO" log -1 --format=%an)" \
            -c user.email="$(git -C "$REPO" log -1 --format=%ae)" commit-tree "$tree" -p "$head" -m "$message")
    fi
else
    new=$(git -C "$REPO" -c user.name="$(git -C "$REPO" log -1 --format=%an)" \
        -c user.email="$(git -C "$REPO" log -1 --format=%ae)" commit-tree "$tree" -m "$message")
fi
if [ -n "$new" ]; then
    git -C "$REPO" push --quiet paas "$new:refs/heads/main"
    echo "poussé : $(git -C "$REPO" log -1 --format='%h' "$new") sur main"
fi

url=$(paas apps info "$APP" --json | jq -r '.url // empty')
printf '\nLa plateforme construit et déploie %s : build, tests, scan CVE, signature, déploiement, installation.\n' "$APP"
printf 'Suivre :\n  paas builds list --app %s\n  paas apps info %s\n' "$APP" "$APP"
printf 'Adresse : %s\n' "${url:-voir paas apps info $APP}"
for name in $names; do
    printf 'Secret %s : %s\n' "$name" "$SECRETS/$name"
done
printf 'Retirer l'"'"'app : paas apps delete %s (réversible : dépôt, volumes et historique sont conservés)\n' "$APP"
