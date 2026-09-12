-- 64 — Primes liées aux conditions matérielles d'exécution du travail
--
-- Le principe qui commande tout le reste
-- ---------------------------------------
-- **Une prime de condition n'est pas une constante du contrat.** Elle est due
-- quand la personne travaille effectivement dans la condition — sur ce chantier,
-- entre telle et telle heure. Un montant inscrit au contrat serait faux dès la
-- première semaine où le salarié n'y est pas exposé.
--
-- D'où trois niveaux, et non un :
--   1. `ref_condition_travail`  ce qu'est une condition (pénibilité, insalubrité,
--                               danger, et ce que chaque CCT ajoute) ;
--   2. `cct_regle_prime`        ce que la convention prévoit : taux ou montant,
--                               assiette, unité, période — avec son article ;
--   3. `creneau_condition`      ce qui a été réellement fait, avec heure de début
--                               et heure de fin.
--
-- Le calcul croise les trois. Sans le niveau 3, aucune prime n'est calculable :
-- c'est précisément ce qui manquait, et pourquoi ces primes tombaient dans
-- « autre » sans jamais être calculées.
--
-- Rien n'est inventé
-- ------------------
-- Aucun taux n'est inscrit ici. Les taux vivent dans `cct_regle_prime`, saisis
-- depuis le texte déposé à l'ITM, avec `source_url` et `article`. Une règle sans
-- source ne doit pas servir à payer, et la contrainte l'impose.

create table if not exists ref_condition_travail (
  code            text primary key,
  libelle         text not null,
  famille         text not null,
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text,
  constraint rct_periode check (fin_validite > debut_validite)
);

comment on table ref_condition_travail is $c$Conditions matérielles d'exécution du travail ouvrant droit à prime. Les trois familles générales sont posées ; chaque convention collective en précise le détail et y ajoute les siennes, par insert et sans migration.$c$;
comment on column ref_condition_travail.famille is $c$Famille générale : penibilite, insalubrite, danger. Sert à regrouper, jamais à calculer — c'est la règle conventionnelle qui porte le taux.$c$;

insert into ref_condition_travail (code, libelle, famille, description, ordre) values
  ('penibilite_generale',  'Pénibilité',   'penibilite',
   'Conditions d''exécution éprouvantes : posture, port de charges, cadence, exposition prolongée.', 1),
  ('insalubrite_generale', 'Insalubrité',  'insalubrite',
   'Milieu insalubre : saleté, odeurs, agents biologiques, contact avec des déchets.', 2),
  ('danger_general',       'Danger',       'danger',
   'Exposition au risque pendant la prestation : hauteur, électricité, machines, circulation.', 3)
on conflict (code) do update
  set libelle = excluded.libelle, famille = excluded.famille,
      description = excluded.description, ordre = excluded.ordre;

alter table ref_condition_travail enable row level security;
drop policy if exists ref_condition_travail_lecture on ref_condition_travail;
create policy ref_condition_travail_lecture on ref_condition_travail
  for select to authenticated using (true);

create table if not exists cct_regle_prime (
  id                  uuid primary key default extensions.gen_random_uuid(),
  collective_agreement_id uuid not null references collective_agreements(id) on delete cascade,
  condition_code      text not null references ref_condition_travail(code),
  nature_prime        text not null references ref_nature_prime(code),
  libelle             text not null,
  -- Un taux OU un montant, jamais les deux : une règle ambiguë ne se calcule pas.
  taux_pct            numeric(7,4),
  montant             numeric(10,2),
  assiette            text,
  unite               text not null,
  seuil_minutes       integer not null default 0,
  categorie_visee     text,
  article             text,
  source_url          text not null,
  debut_validite      date not null default date '1970-01-01',
  fin_validite        date not null default date '2037-12-31',
  note                text,
  constraint crp_periode check (fin_validite > debut_validite),
  constraint crp_taux_ou_montant check (num_nonnulls(taux_pct, montant) = 1),
  constraint crp_taux_exige_assiette check (taux_pct is null or assiette is not null),
  constraint crp_unite_connue check (unite in ('heure', 'jour', 'mois', 'prestation')),
  constraint crp_source_non_vide check (btrim(source_url) <> ''),
  constraint crp_seuil_positif check (seuil_minutes >= 0)
);

comment on table cct_regle_prime is $c$Règle de prime de condition telle que la convention collective la fixe. Aucune valeur légale générale ici : la loi ne définit pas ces primes, seules les CCT le font. Une règle sans source_url est refusée — elle ne pourrait pas être vérifiée.$c$;
comment on column cct_regle_prime.taux_pct is $c$Taux appliqué à l'assiette. Exclusif du montant : une règle qui porterait les deux serait ambiguë, et la contrainte l'interdit.$c$;
comment on column cct_regle_prime.unite is $c$Ce à quoi la prime se rapporte : heure exposée, jour, mois, ou prestation. Détermine comment le temps relevé se convertit en montant.$c$;
comment on column cct_regle_prime.seuil_minutes is $c$Durée minimale d'exposition ouvrant le droit. Zéro si la moindre minute compte.$c$;
comment on column cct_regle_prime.article is $c$Article de la convention qui fonde la règle. C'est lui que l'application cite au salarié.$c$;
comment on column cct_regle_prime.source_url is $c$Lien vers le texte déposé — les conventions luxembourgeoises sont publiées par l'ITM. Obligatoire.$c$;

create index if not exists idx_cct_regle_prime_cct
  on cct_regle_prime (collective_agreement_id, condition_code, debut_validite);

alter table cct_regle_prime enable row level security;
drop policy if exists cct_regle_prime_lecture on cct_regle_prime;
create policy cct_regle_prime_lecture on cct_regle_prime
  for select to authenticated using (true);
drop policy if exists cct_regle_prime_ecriture on cct_regle_prime;
create policy cct_regle_prime_ecriture on cct_regle_prime
  for all to authenticated using (is_org_admin()) with check (is_org_admin());

-- Le maillon qui manquait. Sans lui, on sait qu'une prime existe et à quel taux,
-- mais pas qui y a droit ni pour combien de temps.
create table if not exists creneau_condition (
  id              uuid primary key default extensions.gen_random_uuid(),
  company_id      uuid not null,
  employee_id     uuid not null,
  shift_id        uuid references shifts(id) on delete cascade,
  time_entry_id   uuid references time_entries(id) on delete cascade,
  client_site_id  uuid,
  condition_code  text not null references ref_condition_travail(code),
  date_prestation date not null,
  heure_debut     time not null,
  heure_fin       time not null,
  minutes         integer generated always as (
                    (extract(epoch from (heure_fin - heure_debut)) / 60)::integer
                    + case when heure_fin < heure_debut then 24 * 60 else 0 end) stored,
  constate_par    uuid,
  note            text,
  created_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  deleted_by      uuid,
  constraint cc_heures_differentes check (heure_debut <> heure_fin),
  constraint cc_rattachement check (shift_id is not null or time_entry_id is not null),
  constraint cc_deleted_pair check ((deleted_at is null) = (deleted_by is null)),
  constraint cc_appartient_au_salarie
    foreign key (employee_id, company_id) references employees (id, company_id)
    on update cascade on delete cascade
);

comment on table creneau_condition is $c$Créneau réellement travaillé sous une condition ouvrant droit à prime : qui, quand, où, de quelle heure à quelle heure. C'est ce relevé qui rend la prime calculable — sans lui, la règle conventionnelle reste lettre morte.$c$;
comment on column creneau_condition.minutes is $c$Durée exposée, calculée par la base. Un créneau qui franchit minuit est compté correctement.$c$;
comment on column creneau_condition.shift_id is $c$Vacation planifiée. Le créneau se saisit au planning, puis se confirme au registre du temps.$c$;
comment on column creneau_condition.time_entry_id is $c$Journée du registre du temps. C'est elle qui fait foi pour le paiement, le planning n'étant qu'une prévision.$c$;
comment on constraint cc_rattachement on creneau_condition is
  'Un créneau se rattache au planning ou au registre du temps : flottant, il ne se rapporterait à aucune prestation.';

create index if not exists idx_creneau_condition_salarie
  on creneau_condition (employee_id, date_prestation) where deleted_at is null;
create index if not exists idx_creneau_condition_shift
  on creneau_condition (shift_id) where deleted_at is null;

alter table creneau_condition enable row level security;
drop policy if exists creneau_condition_lecture on creneau_condition;
create policy creneau_condition_lecture on creneau_condition
  for select to authenticated
  using (deleted_at is null and (has_company_access(company_id) or is_self_employee(employee_id)));
drop policy if exists creneau_condition_ecriture on creneau_condition;
create policy creneau_condition_ecriture on creneau_condition
  for insert to authenticated with check (can_manage_company(company_id));
drop policy if exists creneau_condition_maj on creneau_condition;
create policy creneau_condition_maj on creneau_condition
  for update to authenticated using (can_manage_company(company_id))
  with check (can_manage_company(company_id));

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'cc_site_appartient_a_la_societe') then
    alter table creneau_condition
      add constraint cc_site_appartient_a_la_societe
      foreign key (client_site_id, company_id) references client_sites (id, company_id)
      on update cascade on delete set null (client_site_id);
  end if;
end $$;
