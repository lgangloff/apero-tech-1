# Apéro Tech #1 : OTP et PostgREST

Slides et code des démos de l'Apéro Tech #1 : comment fonctionnent les codes de double authentification, puis comment PostgREST transforme une base Postgres en API REST.

| Dossier | Contenu |
| --- | --- |
| `slides/` | Les slides, en un seul fichier HTML qui fonctionne hors ligne |
| `otp/` | La démo OTP : le calcul TOTP en Java, sans dépendance |
| `postgrest/` | La démo PostgREST : SQL, Docker et requêtes pour VS Code |

## Les slides

Ouvrir `slides/index.html` dans un navigateur.

- Flèches, espace ou clic pour avancer et reculer
- `N` affiche les notes de l'orateur, `F` passe en plein écran
- `#12` à la fin de l'URL ouvre directement la slide 12
- L'impression en PDF sort une slide par page

La slide de titre affiche un vrai code TOTP calculé dans la page. La slide de démo OTP sert de plan B : on y colle le secret généré par `Totp.java`, et elle affiche le même code que le téléphone.

## Démo 1 : les codes à usage unique (OTP)

Prérequis : Java 25 ou plus, et `qrencode` pour afficher le QR code dans le terminal (`brew install qrencode` ou `apt install qrencode`).

```bash
cd otp

# Crée un secret dans demo-secret.txt et affiche son QR code
java Totp.java enroll | qrencode -t ansiutf8

# Affiche le code courant, mis à jour chaque seconde
java Totp.java
```

Scanner le QR code avec une appli d'authentification (Google Authenticator, Authy, etc.), passer le téléphone en mode avion : le terminal et le téléphone affichent le même code au même instant.

`Totp.java` est un fichier source compact de Java 25 : pas de classe, pas d'import, et il se lance sans compilation préalable. Le calcul suit la RFC 6238 et a été vérifié avec ses vecteurs de test.

## Démo 2 : PostgREST

Prérequis : Docker, et VS Code avec l'extension [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client).

```bash
cd postgrest

# Postgres et PostgREST ; init.sql crée les rôles au premier démarrage
docker compose up -d

# La partie live : la table apero, ses données et ses droits
docker compose exec db psql -U postgres -f /demo/apero.sql
```

Ouvrir ensuite `apero.http` dans VS Code et lancer les requêtes une par une avec « Send Request » :

| Requête | Ce qu'elle montre | Réponse attendue |
| --- | --- | --- |
| 1 à 3 | Lire, filtrer, trier, sans écrire de backend | 200 |
| 4 | Ajouter sans jeton | 401 |
| 5 | Ajouter avec le jeton du rôle `membre` | 201 |
| 6 | Supprimer avec ce même jeton | 403 |
| 7 | La jointure déduite de la clé étrangère (après `bonus.sql`) | 200 |
| 8 | La description OpenAPI générée | 200 |

Pour la requête 7 : `docker compose exec db psql -U postgres -f /demo/bonus.sql`.

Le jeton du rôle `membre` est déjà dans `apero.http`. Si le secret change dans `docker-compose.yml`, `./token.sh` en fabrique un nouveau avec bash et openssl.

Pour rejouer la démo depuis le début : `docker compose down -v`, puis les deux commandes ci-dessus.

| Fichier | Rôle |
| --- | --- |
| `docker-compose.yml` | Postgres 17 et PostgREST, avec 4 lignes de configuration |
| `init.sql` | Le schéma `api` et les rôles `anon`, `membre` et `authenticator` |
| `apero.sql` | La table créée en direct, et ses `GRANT` |
| `bonus.sql` | Une deuxième table reliée par une clé étrangère |
| `apero.http` | Les requêtes de la démo, pour REST Client |
| `token.sh` | Fabrique le JWT signé en HMAC-SHA256 |

Tout ce qui est ici est fait pour une démo : mots de passe et secrets en clair, à ne pas réutiliser ailleurs.

## Polices

Les slides embarquent Big Shoulders Display, Atkinson Hyperlegible et IBM Plex Mono, toutes trois sous licence SIL Open Font License.
