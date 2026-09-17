-- 117 — Journal des retouches, et arbitrage du remboursement
--
-- ### Un pointage retouché laisse une trace
--
-- L'Inspection du travail et des mines contrôle le registre du temps. Une
-- correction manuelle de pointage ou d'adresse d'étape est légitime — un oubli,
-- un traceur en panne — mais elle doit se voir : qui, quand, quoi, et pourquoi.
-- Sans cela, un registre corrigé et un registre falsifié se ressemblent.
--
-- `journal_ecritures` existe déjà et voit toutes les écritures, mais il est
-- générique et volumineux. Ce journal-ci est spécialisé : il ne retient que les
-- retouches du suivi de temps, avec le **motif** que l'auteur doit fournir —
-- c'est ce qu'on présente à un contrôle.
--
-- ### Le remboursement des trajets, et le principe de faveur
--
-- Trois normes peuvent l'ouvrir : le contrat, la convention collective, le
-- règlement intérieur. La disposition la plus favorable au salarié s'applique,
-- et le moteur **dit laquelle a gagné** — une décision dont on ne peut pas
-- nommer le fondement ne se conteste pas.

create table log_audit_suivi_temps (
  id             uuid primary key default gen_random_uuid(),
  societe_id     uuid not null references societes(id) on delete cascade,
  salarie_id     uuid references salaries(id) on delete set null,
  objet          text not null,
  objet_id       uuid,
  action         text not null,
  valeur_avant   jsonb,
  valeur_apres   jsonb,
  motif          text,
  auteur         uuid,
  auteur_role    text,
  survenu_le     timestamptz not null default now(),

  constraint audit_objet_connu check (
    objet in ('segment_temps', 'releve_temps', 'creneau', 'trajet', 'etape_trajet')),
  constraint audit_action_connue check (
    action in ('creation', 'modification', 'suppression', 'requalification'))
);

comment on table log_audit_suivi_temps is
  'Journal des retouches manuelles du suivi de temps et des trajets. Pièce de conformité présentée lors d''un contrôle de l''Inspection du travail et des mines : sans lui, un registre corrigé et un registre falsifié se ressemblent.';
comment on column log_audit_suivi_temps.id is 'Identifiant de l''entrée.';
comment on column log_audit_suivi_temps.societe_id is 'Société concernée. Clé d''isolation.';
comment on column log_audit_suivi_temps.salarie_id is 'Salarié dont le temps a été retouché. Conservé même si le salarié est supprimé — d''où le « set null » plutôt qu''une cascade.';
comment on column log_audit_suivi_temps.objet is 'Nature de l''objet retouché : segment, relevé, créneau, trajet, étape.';
comment on column log_audit_suivi_temps.objet_id is 'Identifiant de l''objet, conservé même après sa suppression : c''est souvent la suppression qu''il faut pouvoir expliquer.';
comment on column log_audit_suivi_temps.action is 'Ce qui a été fait : création, modification, suppression, requalification.';
comment on column log_audit_suivi_temps.valeur_avant is 'État avant la retouche, en jsonb. Nul pour une création.';
comment on column log_audit_suivi_temps.valeur_apres is 'État après la retouche. Nul pour une suppression.';
comment on column log_audit_suivi_temps.motif is 'Pourquoi la retouche a eu lieu. C''est la colonne que lit un contrôleur ; une correction sans motif est une correction qu''il faudra justifier de mémoire.';
comment on column log_audit_suivi_temps.auteur is 'Compte qui a opéré la retouche.';
comment on column log_audit_suivi_temps.auteur_role is 'Rôle sous lequel il agissait.';
comment on column log_audit_suivi_temps.survenu_le is 'Horodatage de la retouche.';

create index idx_audit_suivi_societe on log_audit_suivi_temps (societe_id, survenu_le desc);
create index idx_audit_suivi_salarie on log_audit_suivi_temps (salarie_id, survenu_le desc);
create index idx_audit_suivi_objet on log_audit_suivi_temps (objet, objet_id);

alter table log_audit_suivi_temps enable row level security;

-- Lecture par la société et par la personne concernée ; **aucune** politique
-- d'écriture depuis l'API. Le journal s'alimente par déclencheur : un journal
-- qu'on peut écrire à la main ne prouve rien.
create policy audit_suivi_lecture on log_audit_suivi_temps for select
  using (has_company_access(societe_id) or is_self_employee(salarie_id));

create or replace function fn_tracer_suivi_temps()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_societe uuid;
  v_salarie uuid;
  v_objet   text := tg_argv[0];
begin
  if tg_op = 'DELETE' then
    v_societe := old.societe_id; v_salarie := old.salarie_id;
  else
    v_societe := new.societe_id; v_salarie := new.salarie_id;
  end if;

  insert into log_audit_suivi_temps
    (societe_id, salarie_id, objet, objet_id, action,
     valeur_avant, valeur_apres, motif, auteur)
  values (
    v_societe, v_salarie, v_objet,
    case when tg_op = 'DELETE' then old.id else new.id end,
    case tg_op when 'INSERT' then 'creation'
               when 'UPDATE' then 'modification'
               else 'suppression' end,
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end,
    case when tg_op <> 'DELETE' then new.note else old.note end,
    auth.uid()
  );

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

comment on function fn_tracer_suivi_temps() is
  'Déclencheur du journal des retouches. Le motif est repris de la colonne « note » de l''objet : c''est là que l''auteur explique sa correction.';

create trigger trg_audit_segments
  after insert or update or delete on segments_temps
  for each row execute function fn_tracer_suivi_temps('segment_temps');

create trigger trg_audit_trajets
  after insert or update or delete on trajets
  for each row execute function fn_tracer_suivi_temps('trajet');

-- ------------------------------------------- le remboursement des trajets
alter table contrats add column trajets_remboursables boolean;
comment on column contrats.trajets_remboursables is
  'Le contrat ouvre-t-il le remboursement des trajets ? Nul lorsque le contrat est muet — et le muet n''est pas le refus : c''est alors la convention ou le règlement qui décide.';

alter table societes add column trajets_remboursables_reglement boolean;
comment on column societes.trajets_remboursables_reglement is
  'Le règlement intérieur ouvre-t-il le remboursement des trajets ? Nul lorsqu''il est muet.';

create or replace function fn_trajets_remboursables(p_contrat uuid, p_on date default current_date)
returns table (remboursable boolean, origine text, detail text)
language plpgsql
stable
as $$
declare
  c           record;
  par_contrat boolean;
  par_conv    boolean;
  par_regl    boolean;
begin
  select ct.*, s.trajets_remboursables_reglement
    into c
  from contrats ct
  join societes s on s.id = ct.societe_id
  where ct.id = p_contrat;

  if not found then
    raise exception 'Contrat % introuvable.', p_contrat;
  end if;

  par_contrat := c.trajets_remboursables;
  par_regl    := c.trajets_remboursables_reglement;

  select bool_or((r.regles->>'trajets_remboursables')::boolean)
    into par_conv
  from conventions_du_contrat cc
  join regles_convention r on r.convention_id = cc.convention_id
  where cc.contrat_id = p_contrat
    and cc.debut_validite <= p_on and cc.fin_validite > p_on
    and r.regles ? 'trajets_remboursables';

  -- Principe de faveur : il suffit qu'une norme l'ouvre. Le silence d'une norme
  -- n'est pas un refus — seul un « non » explicite en est un, et il ne prive pas
  -- le salarié de ce qu'une autre norme lui accorde.
  if coalesce(par_contrat, false) then
    remboursable := true; origine := 'contrat';
    detail := 'Le contrat de travail ouvre le remboursement.';
  elsif coalesce(par_conv, false) then
    remboursable := true; origine := 'convention';
    detail := 'La convention collective applicable ouvre le remboursement.';
  elsif coalesce(par_regl, false) then
    remboursable := true; origine := 'reglement';
    detail := 'Le règlement intérieur ouvre le remboursement.';
  elsif par_contrat is null and par_conv is null and par_regl is null then
    remboursable := null; origine := 'aucune';
    detail := 'Aucune des trois normes ne se prononce. La question reste ouverte : '
              || 'ce n''est pas un refus.';
  else
    remboursable := false; origine := 'aucune';
    detail := 'Aucune norme n''ouvre le remboursement.';
  end if;
  return next;
end;
$$;

comment on function fn_trajets_remboursables(uuid, date) is
  'Le contrat ouvre-t-il le remboursement des trajets ? Applique le principe de faveur entre contrat, convention collective et règlement intérieur, et nomme la norme qui a emporté la décision. Rend NULL quand aucune ne se prononce — le silence n''est pas un refus.';

revoke execute on function fn_trajets_remboursables(uuid, date) from public;
grant execute on function fn_trajets_remboursables(uuid, date) to authenticated;
