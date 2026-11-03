-- Exécuté une seule fois, au premier démarrage du conteneur Postgres.
-- Prépare les rôles et le schéma exposé ; la table est créée en direct (apero.sql).

-- Le schéma "api" est le seul que PostgREST expose.
create schema api;

-- Rôle des requêtes sans jeton.
create role anon nologin;

-- Rôle des requêtes portant un JWT { "role": "membre" }.
create role membre nologin;

-- Rôle de connexion de PostgREST : il ne peut rien faire seul (noinherit),
-- il ne fait qu'endosser anon ou membre à chaque requête.
create role authenticator noinherit login password 'mdp_demo';
grant anon, membre to authenticator;

grant usage on schema api to anon, membre;
