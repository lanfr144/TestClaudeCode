-- 64d — L'unité de prime devient une table de domaine
--
-- La migration 64 a créé `cct_regle_prime.unite` avec une contrainte
-- `check (unite in ('heure', 'jour', 'mois', 'prestation'))` — exactement
-- l'anti-patron que la migration 61 venait de supprimer partout ailleurs.
-- Le générateur de schéma portable l'a signalé immédiatement, dans la liste de
-- ce qu'il ne sait pas traduire.
--
-- C'est la valeur d'une règle mécanique : elle attrape celui qui l'a écrite.

create table if not exists ref_unite_prime (
  code           text primary key,
  libelle        text not null,
  description    text,
  ordre          smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note           text,
  constraint rup_periode check (fin_validite > debut_validite)
);

comment on table ref_unite_prime is $c$Unités auxquelles une prime de condition se rapporte. Table de domaine datée, comme toutes les autres : ajouter une unité ne demande pas de migration.$c$;

insert into ref_unite_prime (code, libelle, description, ordre) values
  ('heure',      'Par heure exposée',
   'La durée relevée sur le créneau est convertie en heures.', 1),
  ('jour',       'Par jour',
   'Une fois par journée où la condition est constatée, quelle que soit la durée.', 2),
  ('mois',       'Par mois',
   'Forfait mensuel dès lors que la condition est constatée dans le mois.', 3),
  ('prestation', 'Par prestation',
   'Une fois par créneau constaté, indépendamment de sa durée.', 4)
on conflict (code) do update
  set libelle = excluded.libelle, description = excluded.description, ordre = excluded.ordre;

alter table ref_unite_prime enable row level security;
drop policy if exists ref_unite_prime_lecture on ref_unite_prime;
create policy ref_unite_prime_lecture on ref_unite_prime
  for select to authenticated using (true);

alter table cct_regle_prime drop constraint crp_unite_connue;
alter table cct_regle_prime add constraint cct_regle_prime_unite_ref
  foreign key (unite) references ref_unite_prime (code);

comment on column cct_regle_prime.unite is $c$Ce à quoi la prime se rapporte, parmi ref_unite_prime : heure exposée, jour, mois, ou prestation. Détermine comment le temps relevé se convertit en montant.$c$;
