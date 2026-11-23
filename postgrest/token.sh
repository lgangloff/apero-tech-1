#!/usr/bin/env bash
# Fabrique un JWT signé HS256 pour le rôle "membre", sans aucune librairie.
# Le secret doit être le même que PGRST_JWT_SECRET dans docker-compose.yml.
#   ./token.sh                -> jeton pour le rôle membre
#   ./token.sh membre alice   -> jeton du membre alice : le claim "sub", lu par la Row Level Security
#   ./token.sh anon           -> jeton pour un autre rôle
#
# Un JWT, c'est : base64url(en-tête) . base64url(contenu) . base64url(HMAC-SHA256)
# Le même HMAC que pour les codes OTP, avec SHA-256 au lieu de SHA-1.

set -euo pipefail

SECRET="${JWT_SECRET:-un_secret_de_demo_d_au_moins_32_caracteres}"
ROLE="${1:-membre}"
SUB="${2:-}"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
if [ -n "$SUB" ]; then
  payload=$(printf '{"role":"%s","sub":"%s"}' "$ROLE" "$SUB" | b64url)
else
  payload=$(printf '{"role":"%s"}' "$ROLE" | b64url)
fi
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$SECRET" -binary | b64url)

echo "$header.$payload.$signature"
