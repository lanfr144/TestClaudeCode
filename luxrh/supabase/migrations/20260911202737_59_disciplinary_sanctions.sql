-- 59 — Sanctions disciplinaires
--
-- Trois degrés, dont la frontière n'est pas décorative
-- -----------------------------------------------------
--   mineure      n'altère ni la présence ni la rémunération ;
--   lourde       affecte le contrat ou les conditions de travail, et n'est
--                valable qu'à condition de figurer dans les textes internes ;
--   rupture      le contrat prend fin.
--
-- Deux distinctions que le modèle doit porter, sous peine d'être faux :
--
--   · **Mise à pied conservatoire ≠ mise à pied disciplinaire.** La première
--     n'est pas une sanction : elle écarte le salarié le temps d'instruire, et
--     **maintient le salaire**. La seconde prive de rémunération. Les confondre
--     transforme une mesure d'attente en punition non prévue.
--
--   · **Rétrogradation et mutation modifient le contrat.** Elles passent donc
--     par `fn_amend_contract`, jamais par un `update` direct. Si la baisse de
--     rémunération est substantielle, l'accord du salarié ou une procédure
--     propre s'impose.
--
-- Tables de référence, pas d'énumération
-- ---------------------------------------
-- `sanction_categories` et `sanction_types` sont des tables datées, alimentées
-- par DML. Ajouter un type de sanction, ou en dater la fin, ne demande plus de
-- migration — et un type retiré reste lisible dans les sanctions qui le
-- référencent, ce qu'une contrainte `check` ne permet pas.
--
-- Ce qui n'est pas inventé
-- ------------------------
-- Le délai entre la connaissance des faits et la notification est une durée
-- légale : il vit dans `legal_parameters` sous
-- `sanction_notification_deadline_days`, déclaré et **vide**. Tant qu'il n'est
-- pas chargé, `fn_sanction_check` dit qu'il ne peut pas vérifier le délai
-- plutôt que d'en supposer un.
--
-- Protection des données
-- ----------------------
-- Un dossier disciplinaire est une donnée personnelle sensible. D'où : RLS
-- stricte (gestionnaires de la société et la personne concernée), audit des
-- écritures, `retention_until` pour borner la conservation, et suppression
-- logique pour que le dossier reste cohérent après effacement d'une ligne.

-- ===========================================================================
-- 1. Les degrés
-- ===========================================================================

create table if not exists sanction_categories (
  code        text primary key,
  label       text not null,
  rank        smallint not null,
  description text not null,
  valid_from  date not null default date '1900-01-01',
  valid_to    date,
  constraint sanction_category_range check (valid_to is null or valid_to > valid_from)
);

comment on table sanction_categories is $c$Les trois degrés de la sanction disciplinaire. Table de référence datée plutôt qu'énumération : un degré peut être renommé, ajouté ou retiré par DML, sans migration ni indisponibilité.$c$;
comment on column sanction_categories.rank is $c$Gravité croissante. Sert à ordonner, jamais à décider : c'est le type de sanction qui porte les règles.$c$;

insert into sanction_categories (code, label, rank, description) values
  ('minor',       'Sanction mineure (conservatoire ou morale)', 1,
   'N''altère ni la présence du salarié ni sa rémunération.'),
  ('heavy',       'Sanction lourde (structurelle ou financière)', 2,
   'Affecte le contrat ou les conditions de travail. Doit figurer dans les textes internes de l''entreprise pour être valable.'),
  ('termination', 'Rupture du contrat de travail', 3,
   'Sanction suprême : le contrat prend fin.')
on conflict (code) do update set label = excluded.label, rank = excluded.rank,
  description = excluded.description;

-- ===========================================================================
-- 2. Le catalogue des sanctions
-- ===========================================================================

create table if not exists sanction_types (
  code                    text primary key,
  category_code           text not null references sanction_categories(code),
  label                   text not null,
  description             text not null,
  affects_presence        boolean not null default false,
  affects_pay             boolean not null default false,
  requires_internal_rules boolean not null default false,
  is_contract_change      boolean not null default false,
  ends_contract           boolean not null default false,
  needs_notice            boolean,
  legal_ref               text,
  note                    text,
  valid_from              date not null default date '1900-01-01',
  valid_to                date,
  constraint sanction_type_range check (valid_to is null or valid_to > valid_from)
);

comment on table sanction_types is $c$Catalogue des sanctions applicables, daté. Chaque type porte ses effets — présence, rémunération, contrat — et ce qu'il exige de l'employeur. Le moteur lit ces drapeaux ; il ne les devine pas.$c$;
comment on column sanction_types.requires_internal_rules is $c$Vrai si la sanction n'est valable qu'à condition de figurer dans les textes internes de l'entreprise. C'est le cas de toutes les sanctions lourdes.$c$;
comment on column sanction_types.is_contract_change is $c$Vrai si la sanction modifie le contrat. Elle passe alors par fn_amend_contract et, si la baisse de rémunération est substantielle, requiert l'accord du salarié ou une procédure propre.$c$;
comment on column sanction_types.affects_pay is $c$Vrai si la rémunération est suspendue ou réduite. Distingue la mise à pied disciplinaire de la conservatoire, qui maintient le salaire.$c$;
comment on column sanction_types.needs_notice is $c$Vrai si un préavis est dû, faux s'il ne l'est pas, nul si la question ne se pose pas. Le calcul du préavis lui-même reste à fn_notice_period.$c$;

insert into sanction_types (code, category_code, label, description, affects_presence, affects_pay,
                            requires_internal_rules, is_contract_change, ends_contract, needs_notice, note) values
  ('written_warning', 'minor', 'Avertissement écrit',
   'Notification formelle adressée au salarié pour lui reprocher un comportement ou une mauvaise exécution de ses tâches.',
   false, false, false, false, false, null, null),
  ('reprimand', 'minor', 'Blâme ou réprimande',
   'Reproche solennel inscrit au dossier du salarié.',
   false, false, false, false, false, null, null),
  ('suspension_disciplinary', 'heavy', 'Mise à pied disciplinaire',
   'Le salarié est écarté de l''entreprise pendant une durée déterminée, avec privation de salaire.',
   true, true, true, false, false, null,
   'Durée déterminée : la borne éventuelle relève des textes internes ou de la convention, pas du moteur.'),
  ('transfer', 'heavy', 'Mutation ou transfert de fonctions',
   'Changement de lieu de travail ou de service à titre de punition.',
   false, false, true, true, false, null,
   'Modifie le contrat dès lors que le lieu ou la fonction y sont stipulés.'),
  ('demotion', 'heavy', 'Rétrogradation',
   'Passage à un niveau de qualification ou à un poste inférieur.',
   false, true, true, true, false, null,
   'Si la baisse de rémunération est substantielle, la mesure est traitée comme une modification du contrat : accord du salarié ou procédure spécifique.'),
  ('suspension_precautionary', 'termination', 'Mise à pied conservatoire',
   'Mesure d''urgence immédiate, généralement avec dispense de travail et maintien temporaire du salaire, dans l''attente de la notification d''un licenciement pour faute grave.',
   true, false, false, false, false, null,
   'Conservatoire et non disciplinaire : elle ne sanctionne pas, elle met à l''écart le temps d''instruire. Le salaire est maintenu.'),
  ('dismissal_notice', 'termination', 'Licenciement avec préavis',
   'Rupture du contrat pour des motifs réels et sérieux liés au comportement ou aux aptitudes professionnelles du salarié.',
   true, true, false, false, true, true, null),
  ('dismissal_gross_misconduct', 'termination', 'Licenciement pour motif grave, avec effet immédiat',
   'Rupture instantanée du contrat, sans indemnités ni préavis, pour une faute d''une gravité telle qu''elle rend la poursuite de la relation de travail définitivement impossible.',
   true, true, false, false, true, false, null)
on conflict (code) do update
  set category_code = excluded.category_code, label = excluded.label,
      description = excluded.description, affects_presence = excluded.affects_presence,
      affects_pay = excluded.affects_pay, requires_internal_rules = excluded.requires_internal_rules,
      is_contract_change = excluded.is_contract_change, ends_contract = excluded.ends_contract,
      needs_notice = excluded.needs_notice, note = excluded.note;

alter table sanction_categories enable row level security;
alter table sanction_types      enable row level security;
drop policy if exists sanction_categories_read on sanction_categories;
create policy sanction_categories_read on sanction_categories for select to authenticated using (true);
drop policy if exists sanction_types_read on sanction_types;
create policy sanction_types_read on sanction_types for select to authenticated using (true);

-- ===========================================================================
-- 3. Les textes internes de l'entreprise
-- ===========================================================================
-- Sans eux, aucune sanction lourde n'est valable. Le moteur ne peut pas le
-- vérifier si la base ne sait pas s'ils existent.

alter table companies add column if not exists internal_rules_adopted_on date;
alter table companies add column if not exists internal_rules_reference text;

comment on column companies.internal_rules_adopted_on is $c$Date d'adoption des textes internes de l'entreprise. Sans eux, aucune sanction lourde n'est valable — le moteur le vérifie.$c$;

-- ===========================================================================
-- 4. Les sanctions prononcées
-- ===========================================================================

create table if not exists employee_sanctions (
  id                uuid primary key default extensions.gen_random_uuid(),
  company_id        uuid not null,
  employee_id       uuid not null,
  contract_id       uuid references contracts(id) on delete set null,
  sanction_type     text not null references sanction_types(code),
  facts_on          date not null,
  facts_known_on    date not null,
  notified_on       date,
  effective_from    date,
  effective_to      date,
  reason            text not null,
  evidence_document_id uuid references documents(id) on delete set null,
  termination_id    uuid references contract_terminations(id) on delete set null,
  amendment_contract_id uuid references contracts(id) on delete set null,
  employee_heard_on date,
  employee_response text,
  contested_on      date,
  contest_outcome   text,
  note              text,
  retention_until   date,
  created_at        timestamptz not null default now(),
  created_by        uuid,
  updated_at        timestamptz not null default now(),
  updated_by        uuid,
  deleted_at        timestamptz,
  deleted_by        uuid,
  constraint sanction_dates_order check (effective_to is null or effective_from is null
                                         or effective_to >= effective_from),
  constraint sanction_known_after_facts check (facts_known_on >= facts_on),
  constraint sanction_notified_after_known check (notified_on is null or notified_on >= facts_known_on),
  constraint sanction_deleted_pair check ((deleted_at is null) = (deleted_by is null)),
  constraint sanction_belongs_to_employees_company
    foreign key (employee_id, company_id) references employees (id, company_id)
    on update cascade on delete cascade
);

comment on table employee_sanctions is $c$Sanctions disciplinaires prononcées. Donnée personnelle sensible au sens du RGPD : accès restreint aux gestionnaires et à la personne concernée, conservation bornée par retention_until, suppression logique pour que le dossier reste cohérent après effacement.$c$;
comment on column employee_sanctions.facts_on is $c$Date des faits reprochés.$c$;
comment on column employee_sanctions.facts_known_on is $c$Date à laquelle l'employeur en a eu connaissance. C'est elle, et non la date des faits, qui fait courir le délai de notification.$c$;
comment on column employee_sanctions.notified_on is $c$Date de notification au salarié. Une sanction non notifiée n'existe pas à son égard.$c$;
comment on column employee_sanctions.employee_heard_on is $c$Date à laquelle le salarié a été entendu. L'entretien préalable est requis au-delà d'un seuil d'effectif que le moteur lit dans le référentiel.$c$;
comment on column employee_sanctions.termination_id is $c$Rupture correspondante, quand la sanction est un licenciement. Les deux lignes décrivent le même fait sous deux angles.$c$;
comment on column employee_sanctions.amendment_contract_id is $c$Avenant produit par la sanction, quand elle modifie le contrat — rétrogradation, mutation.$c$;
comment on column employee_sanctions.retention_until is $c$Date au-delà de laquelle la sanction ne doit plus être conservée. Un dossier disciplinaire ne se garde pas indéfiniment.$c$;

create index if not exists idx_sanctions_employee on employee_sanctions (employee_id, facts_on desc)
  where deleted_at is null;
create index if not exists idx_sanctions_company on employee_sanctions (company_id, notified_on desc)
  where deleted_at is null;

alter table employee_sanctions enable row level security;

drop policy if exists sanctions_read on employee_sanctions;
create policy sanctions_read on employee_sanctions
  for select to authenticated
  using (deleted_at is null and (can_manage_company(company_id) or is_self_employee(employee_id)));
drop policy if exists sanctions_write on employee_sanctions;
create policy sanctions_write on employee_sanctions
  for insert to authenticated with check (can_manage_company(company_id));
drop policy if exists sanctions_update on employee_sanctions;
create policy sanctions_update on employee_sanctions
  for update to authenticated using (can_manage_company(company_id))
  with check (can_manage_company(company_id));

create trigger audit_sanctions after insert or update or delete on employee_sanctions
  for each row execute function fn_audit();

-- ===========================================================================
-- 5. La durée légale, déclarée et vide
-- ===========================================================================

insert into expected_parameters (param_key, read_by, note) values
  ('sanction_notification_deadline_days', 'fn_sanction_check',
   'Délai maximal entre la connaissance des faits et la notification de la sanction. À charger depuis le Code du travail avec sa plage de validité ; aucune valeur n''est inventée ici.')
on conflict (param_key) do update set read_by = excluded.read_by, note = excluded.note;
