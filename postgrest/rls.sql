-- Row Level Security : chacun ne modifie que ses propres apports.
-- À lancer après la partie « Les droits » (requêtes 1 à 6 de apero.http) :
--   docker compose exec db psql -U postgres -f /demo/rls.sql

-- Qui fait la requête ? PostgREST range le contenu du jeton dans request.jwt.claims,
-- cette fonction en extrait le claim "sub" (alice, bob…). Le nullif évite une erreur
-- quand la variable existe mais est vide. Supabase fournit la même chose : auth.uid().
create function public.jwt_sub() returns text
  language sql stable
  as $$ select nullif(current_setting('request.jwt.claims', true), '')::json->>'sub' $$;

-- Chaque apport est signé par son auteur, sans qu'il ait à l'écrire.
alter table api.apero add column apporte_par text default public.jwt_sub();
update api.apero set apporte_par = 'bob';   -- tout ce qui existe déjà vient de Bob

-- On active la RLS : sans politique, plus personne ne verrait aucune ligne.
alter table api.apero enable row level security;

-- Tout le monde lit toutes les lignes (le GRANT décide déjà qui a le droit de lire).
create policy lire_tout on api.apero
  for select using (true);

-- Un membre n'ajoute, ne modifie et ne supprime que ses propres apports.
create policy mes_apports on api.apero
  for all to membre
  using      (apporte_par = public.jwt_sub())   -- les lignes qu'il peut modifier ou supprimer
  with check (apporte_par = public.jwt_sub());  -- les lignes qu'il a le droit d'écrire

-- Les membres peuvent maintenant supprimer… mais seulement leurs lignes.
grant delete on api.apero to membre;

notify pgrst, 'reload schema';
