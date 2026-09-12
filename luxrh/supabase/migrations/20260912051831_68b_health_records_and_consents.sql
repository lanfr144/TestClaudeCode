-- 68b — Fiche santé, indicateurs de secours, consentements
--
-- Suite de la migration 68, qui n'ajoutait que les valeurs de rôle.

-- ===========================================================================
-- 1. Les indicateurs de secours — ce que le dispatching a le droit de savoir
-- ===========================================================================

create table if not exists ref_indicateur_secours (
  code            text primary key,
  libelle         text not null,
  consigne        text not null,
  visible_dispatching boolean not null default true,
  visible_secours     boolean not null default true,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text,
  constraint ris_periode check (fin_validite > debut_validite)
);

comment on table ref_indicateur_secours is $c$Indicateurs dérivés de la fiche santé, destinés au dispatching et aux secours. Ils disent ce qu'il faut faire sans révéler la pathologie : « porte de l'adrénaline » plutôt que « allergique aux guêpes ». C'est ce qui permet au planning de faire son travail sans accéder à une donnée de santé.$c$;
comment on column ref_indicateur_secours.consigne is $c$Ce qu'il faut faire, en clair, pour qui n'est ni médecin ni RH. C'est le texte qu'un secouriste lit.$c$;
comment on column ref_indicateur_secours.visible_dispatching is $c$Vrai si l'indicateur guide l'affectation — une interdiction de lieu, par exemple. Faux pour un indicateur purement médical d'urgence.$c$;

insert into ref_indicateur_secours (code, libelle, consigne, visible_dispatching, visible_secours, ordre) values
  ('porte_adrenaline',       'Porte un auto-injecteur d''adrénaline',
   'La personne dispose d''un auto-injecteur. En cas de réaction, l''utiliser sans délai et appeler les secours.',
   false, true, 1),
  ('porte_antihistaminique', 'Porte un antihistaminique',
   'La personne dispose d''un antihistaminique à prendre en cas de réaction.',
   false, true, 2),
  ('meche_cauterisation',    'Nécessite une mèche de cautérisation',
   'Médicament cutané externe qui coagule au contact du sang. À appliquer en cas de saignement.',
   false, true, 3),
  ('diabete_sucre_insuline', 'Diabétique — sucre ou insuline',
   'En cas de malaise, information à transmettre immédiatement aux secours pour guider l''administration de sucre ou d''insuline.',
   false, true, 4),
  ('interdiction_lieu_chats','Ne pas affecter à un lieu signalant des chats',
   'Interdiction d''affectation. Le planning doit écarter tout lieu où la présence de chats est signalée.',
   true, false, 10),
  ('interdiction_lieu_chiens','Ne pas affecter à un lieu signalant des chiens',
   'Interdiction d''affectation.', true, false, 11),
  ('eviter_travail_hauteur', 'Éviter le travail en hauteur',
   'Restriction d''affectation à prendre en compte au planning.', true, false, 12)
on conflict (code) do update
  set libelle = excluded.libelle, consigne = excluded.consigne,
      visible_dispatching = excluded.visible_dispatching,
      visible_secours = excluded.visible_secours, ordre = excluded.ordre;

alter table ref_indicateur_secours enable row level security;
drop policy if exists ref_indicateur_secours_lecture on ref_indicateur_secours;
create policy ref_indicateur_secours_lecture on ref_indicateur_secours
  for select to authenticated using (true);

-- ===========================================================================
-- 2. La fiche santé — donnée brute, accès étroit
-- ===========================================================================

create table if not exists fiche_sante (
  id               uuid primary key default extensions.gen_random_uuid(),
  company_id       uuid not null,
  employee_id      uuid,
  enfant_id        uuid references employee_children(id) on delete cascade,
  allergies        text,
  pathologies      text,
  medecin_traitant text,
  medecin_telephone text,
  groupe_sanguin   text,
  note             text,
  maj_le           timestamptz not null default now(),
  maj_par          uuid,
  deleted_at       timestamptz,
  deleted_by       uuid,
  constraint fs_personne check (num_nonnulls(employee_id, enfant_id) = 1),
  constraint fs_deleted_pair check ((deleted_at is null) = (deleted_by is null)),
  constraint fs_une_par_personne unique (employee_id, enfant_id)
);

comment on table fiche_sante is $c$Fiche santé d'un salarié ou d'un de ses enfants. DONNÉE DE SANTÉ au sens de l'article 9 du RGPD : accès réservé à la personne, à la médecine du travail et aux RH d'urgence. Le dispatching n'y accède jamais — il lit les indicateurs dérivés.$c$;
comment on column fiche_sante.allergies is $c$Donnée brute. Ne jamais exposer au planning : c'est l'indicateur dérivé qui circule.$c$;
comment on constraint fs_personne on fiche_sante is
  'Une fiche vise un salarié OU un enfant, jamais les deux ni aucun.';

alter table fiche_sante enable row level security;

drop policy if exists fiche_sante_lecture on fiche_sante;
create policy fiche_sante_lecture on fiche_sante
  for select to authenticated
  using (
    deleted_at is null and (
      -- La personne elle-même, ou le parent pour son enfant.
      (employee_id is not null and is_self_employee(employee_id))
      or (enfant_id is not null and exists (
            select 1 from employee_children c
             where c.id = fiche_sante.enfant_id and is_self_employee(c.employee_id)))
      -- Médecine du travail et RH d'urgence, sur leur périmètre.
      or has_role('medecine_travail'::app_role, company_id)
      or has_role('rh_urgence'::app_role, company_id)
    ));

drop policy if exists fiche_sante_ecriture on fiche_sante;
create policy fiche_sante_ecriture on fiche_sante
  for all to authenticated
  using (
    (employee_id is not null and is_self_employee(employee_id))
    or (enfant_id is not null and exists (
          select 1 from employee_children c
           where c.id = fiche_sante.enfant_id and is_self_employee(c.employee_id)))
    or has_role('medecine_travail'::app_role, company_id))
  with check (
    (employee_id is not null and is_self_employee(employee_id))
    or (enfant_id is not null and exists (
          select 1 from employee_children c
           where c.id = fiche_sante.enfant_id and is_self_employee(c.employee_id)))
    or has_role('medecine_travail'::app_role, company_id));

create trigger audit_fiche_sante after insert or update or delete on fiche_sante
  for each row execute function fn_audit();

-- ===========================================================================
-- 3. Les indicateurs portés par une personne
-- ===========================================================================

create table if not exists personne_indicateur_secours (
  id             uuid primary key default extensions.gen_random_uuid(),
  company_id     uuid not null,
  employee_id    uuid,
  enfant_id      uuid references employee_children(id) on delete cascade,
  indicateur     text not null references ref_indicateur_secours(code),
  precision_lieu text,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  pose_par       uuid,
  created_at     timestamptz not null default now(),
  constraint pis_personne check (num_nonnulls(employee_id, enfant_id) = 1),
  constraint pis_periode check (fin_validite > debut_validite),
  constraint pis_unique unique (employee_id, enfant_id, indicateur, debut_validite)
);

comment on table personne_indicateur_secours is $c$Indicateurs de secours portés par une personne. Dérivés de la fiche santé par la médecine du travail : ils circulent là où la donnée brute ne va pas. C'est ce qui permet au dispatching d'écarter une affectation sans savoir pourquoi.$c$;
comment on column personne_indicateur_secours.precision_lieu is $c$Précision d'affectation quand l'indicateur en appelle une — un type de lieu, un environnement. Jamais une pathologie.$c$;

alter table personne_indicateur_secours enable row level security;

drop policy if exists pis_lecture on personne_indicateur_secours;
create policy pis_lecture on personne_indicateur_secours
  for select to authenticated
  using (
    has_company_access(company_id)
    or (employee_id is not null and is_self_employee(employee_id))
    or (enfant_id is not null and exists (
          select 1 from employee_children c
           where c.id = personne_indicateur_secours.enfant_id and is_self_employee(c.employee_id))));

drop policy if exists pis_ecriture on personne_indicateur_secours;
create policy pis_ecriture on personne_indicateur_secours
  for all to authenticated
  using (has_role('medecine_travail'::app_role, company_id)
         or has_role('rh_urgence'::app_role, company_id))
  with check (has_role('medecine_travail'::app_role, company_id)
              or has_role('rh_urgence'::app_role, company_id));

-- ===========================================================================
-- 4. Consentements — salariés et enfants
-- ===========================================================================

alter table employees add column if not exists refus_photos_societe boolean not null default false;
alter table employees add column if not exists souhaite_confidentialite boolean not null default false;

comment on column employees.refus_photos_societe is $c$Le salarié refuse d'apparaître sur les photos de la société. Consentement au sens du RGPD : révocable à tout moment, et sans justification à fournir.$c$;
comment on column employees.souhaite_confidentialite is $c$Le salarié souhaite ne pas apparaître — annuaire, trombinoscope, communications. Distinct du droit à l'effacement, qui porte sur la donnée elle-même.$c$;

alter table employee_children add column if not exists refus_photos_evenements boolean not null default false;
alter table employee_children add column if not exists invitation_evenements boolean not null default false;
alter table employee_children add column if not exists en_situation_handicap boolean not null default false;
alter table employee_children add column if not exists taux_handicap_pct numeric(5,2);

alter table employee_children drop constraint if exists ec_taux_handicap;
alter table employee_children add constraint ec_taux_handicap
  check (taux_handicap_pct is null or (taux_handicap_pct > 0 and taux_handicap_pct <= 100));
alter table employee_children drop constraint if exists ec_taux_exige_handicap;
alter table employee_children add constraint ec_taux_exige_handicap
  check (taux_handicap_pct is null or en_situation_handicap);

comment on column employee_children.refus_photos_evenements is $c$L'enfant ne doit pas apparaître sur les photos des événements familiaux de la société.$c$;
comment on column employee_children.invitation_evenements is $c$L'enfant est convié aux événements de la société — Saint-Nicolas, journée des familles — avec ses parents.$c$;
comment on column employee_children.en_situation_handicap is $c$Situation de handicap. DONNÉE DE SANTÉ : même régime d'accès que la fiche santé.$c$;
comment on constraint ec_taux_exige_handicap on employee_children is
  'Un taux sans situation de handicap déclarée n''a pas de sens : la contrainte l''interdit.';

-- ===========================================================================
-- 5. Ce que le dispatching a le droit de lire
-- ===========================================================================

create or replace function fn_indicateurs_affectation(p_employee uuid, p_le date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_company uuid; v_res jsonb;
begin
  select company_id into v_company from employees where id = p_employee;
  if v_company is null then raise exception 'Salarié introuvable : %', p_employee; end if;
  if not (has_company_access(v_company) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé.';
  end if;

  select jsonb_agg(jsonb_build_object(
           'indicateur', r.code, 'libelle', r.libelle, 'consigne', r.consigne,
           'precision', p.precision_lieu)
         order by r.ordre)
    into v_res
  from personne_indicateur_secours p
  join ref_indicateur_secours r on r.code = p.indicateur
  where p.employee_id = p_employee
    and p.debut_validite <= p_le and p.fin_validite > p_le
    and r.visible_dispatching;

  return jsonb_build_object(
    'employee_id', p_employee, 'le', p_le,
    'indicateurs', coalesce(v_res, '[]'::jsonb),
    'message', 'Indicateurs d''affectation seulement. La donnée médicale qui les fonde '
               'n''est pas accessible par cette fonction, et ne doit pas l''être.');
end $$;

comment on function fn_indicateurs_affectation(uuid, date) is
  'Indicateurs qui guident l''affectation, pour le planning. Ne renvoie jamais la donnée de santé sous-jacente : c''est tout l''objet de la séparation.';

revoke execute on function fn_indicateurs_affectation(uuid, date) from public, anon;
grant  execute on function fn_indicateurs_affectation(uuid, date) to authenticated;
