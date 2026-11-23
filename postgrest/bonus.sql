-- Bonus : une deuxième table reliée à la première par une clé étrangère.
-- PostgREST en déduit tout seul la jointure "qui apporte quoi".
--   docker compose exec db psql -U postgres -f /demo/bonus.sql

create table api.participant (
  id       int generated always as identity primary key,
  prenom   text not null,
  apero_id int references api.apero (id)
);

insert into api.participant (prenom, apero_id) values
  ('Bob',   1),   -- le pastis de Bob, comme dans la démo de la Row Level Security
  ('Alice', 2),
  ('Chloé', 3);

grant select on api.participant to anon, membre;

notify pgrst, 'reload schema';
