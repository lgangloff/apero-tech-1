-- Démo live : à taper (ou lancer) dans psql.
--   docker compose exec db psql -U postgres -f /demo/apero.sql

create table api.apero (
  id    int generated always as identity primary key,
  nom   text not null,
  type  text check (type in ('boisson', 'grignotage')),
  degre numeric
);

insert into api.apero (nom, type, degre) values
  ('Pastis', 'boisson',    45),
  ('Chips',  'grignotage', null),
  ('Bière',  'boisson',    5);

-- Les droits, c'est du SQL classique.
grant select         on api.apero to anon;     -- tout le monde peut lire
grant select, insert on api.apero to membre;   -- seuls les membres ajoutent

-- PostgREST ne voit la nouvelle table qu'après ce signal.
notify pgrst, 'reload schema';
