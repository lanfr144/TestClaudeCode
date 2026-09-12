-- 65 — Refus impossible sans contre-proposition
--
-- Le principe
-- -----------
-- Un employeur qui refuse un congé sans rien proposer laisse le salarié devant
-- un mur. Le refus sec est donc supprimé : refuser **oblige** à proposer une
-- alternative, qui naît au statut `proposed`. Le salarié accepte, ou refuse à
-- son tour — et la main revient à l'employeur.
--
-- Le chaînage
-- -----------
-- `absence_parente_id` relie chaque proposition à celle qu'elle remplace. La
-- chaîne se lit dans les deux sens : d'où vient cette proposition, et qu'est-elle
-- devenue. C'est ce qui permet de montrer au salarié, ou à un juge, la
-- succession exacte des échanges.
--
-- Garde-fou : la chaîne est bornée. Sans borne, deux entêtements produisent une
-- suite infinie de propositions et personne ne tranche jamais.

alter table absences add column if not exists absence_parente_id uuid
  references absences(id) on delete set null;
alter table absences add column if not exists proposee_par text;
alter table absences add column if not exists rang_proposition smallint not null default 0;

comment on column absences.absence_parente_id is $c$Proposition que celle-ci remplace. Chaîne la demande initiale et les contre-propositions successives : c'est l'historique de la négociation, lisible dans les deux sens.$c$;
comment on column absences.proposee_par is $c$Qui a formulé cette proposition : « salarie » pour la demande initiale, « employeur » pour une contre-proposition.$c$;
comment on column absences.rang_proposition is $c$Profondeur dans la chaîne. Zéro pour la demande initiale. Borné, pour qu'une négociation sans fin ne soit pas possible.$c$;

create index if not exists idx_absences_parente on absences (absence_parente_id)
  where absence_parente_id is not null;

-- Une proposition ne peut pas être sa propre parente, ni se rattacher à une
-- absence d'un autre salarié.
alter table absences drop constraint if exists absence_pas_sa_propre_parente;
alter table absences add constraint absence_pas_sa_propre_parente
  check (absence_parente_id is null or absence_parente_id <> id);

insert into expected_parameters (param_key, read_by, note) values
  ('absence_max_contre_propositions', 'fn_refuser_absence',
   'Nombre maximal de contre-propositions dans une chaîne de négociation. Réglage applicatif, non légal : à fixer par l''organisation. À défaut, le moteur applique une borne de sécurité et le dit.')
on conflict (param_key) do update set read_by = excluded.read_by, note = excluded.note;

-- ===========================================================================
-- Refuser, c'est proposer autre chose
-- ===========================================================================

create or replace function fn_refuser_absence(
  p_absence     uuid,
  p_motif       text,
  p_nouveau_debut date,
  p_nouveau_fin   date,
  p_commentaire text default null
) returns jsonb language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  a          absences%rowtype;
  v_max      numeric;
  v_nouveau  uuid;
  v_impact   jsonb;
begin
  select * into a from absences where id = p_absence;
  if a.id is null then
    raise exception 'Demande d''absence introuvable : %', p_absence;
  end if;
  if not can_manage_company(a.company_id) then
    raise exception 'Accès refusé : seul un gestionnaire de la société peut répondre à une demande.';
  end if;
  if a.status not in ('pending') then
    raise exception 'Cette demande n''est pas en attente de l''employeur (statut « % »).', a.status;
  end if;
  if p_motif is null or btrim(p_motif) = '' then
    raise exception 'Un refus porte son motif : le salarié doit savoir pourquoi.';
  end if;
  if p_nouveau_debut is null or p_nouveau_fin is null then
    raise exception 'Un refus s''accompagne d''une contre-proposition : indiquez les dates '
                    'que vous proposez à la place. Refuser sans proposer laisse le salarié '
                    'devant un mur.';
  end if;
  if p_nouveau_fin < p_nouveau_debut then
    raise exception 'La contre-proposition se termine avant de commencer.';
  end if;
  if p_nouveau_debut = a.start_date and p_nouveau_fin = a.end_date then
    raise exception 'La contre-proposition est identique à la demande : ce n''est pas une '
                    'alternative, c''est un refus déguisé.';
  end if;

  -- Borne de la négociation. À défaut de paramètre chargé, une borne de sécurité
  -- s'applique, et la réponse le dit plutôt que de laisser croire à un réglage.
  v_max := fn_param_num('absence_max_contre_propositions', current_date);

  if a.rang_proposition + 1 > coalesce(v_max, 5) then
    raise exception 'Chaîne de négociation trop longue (% propositions). %',
      a.rang_proposition + 1,
      case when v_max is null
           then 'Borne de sécurité de 5 appliquée : le paramètre '
                'absence_max_contre_propositions n''est pas chargé.'
           else 'Borne fixée à ' || v_max || '.' end;
  end if;

  update absences
     set status = 'refused',
         decided_by = auth.uid(),
         decided_at = now(),
         decision_note = p_motif
   where id = a.id;

  insert into absences (company_id, employee_id, absence_type_id, start_date, end_date,
                        days_count, status, comment, requested_by, certificate_received,
                        declared_by_employee, certificate_original_received,
                        absence_parente_id, proposee_par, rang_proposition, child_id)
  values (a.company_id, a.employee_id, a.absence_type_id, p_nouveau_debut, p_nouveau_fin,
          0, 'proposed', p_commentaire, auth.uid(), false, false, false,
          a.id, 'employeur', a.rang_proposition + 1, a.child_id)
  returning id into v_nouveau;

  -- Le moteur dit tout de suite ce que la contre-proposition impliquerait.
  begin
    v_impact := fn_leave_request_impact(a.employee_id, a.absence_type_id,
                                        p_nouveau_debut, p_nouveau_fin);
  exception when others then
    v_impact := jsonb_build_object('indisponible', sqlerrm);
  end;

  return jsonb_build_object(
    'ok', true,
    'demande_refusee', a.id,
    'contre_proposition', v_nouveau,
    'rang', a.rang_proposition + 1,
    'du', p_nouveau_debut, 'au', p_nouveau_fin,
    'motif', p_motif,
    'impact', v_impact,
    'message', 'Refus enregistré et contre-proposition transmise au salarié, qui peut '
               'l''accepter ou la refuser à son tour.');
end $$;

comment on function fn_refuser_absence(uuid, text, date, date, text) is
  'Refuse une demande d''absence ET crée la contre-proposition dans le même geste. Un refus sec est impossible : la fonction exige des dates de remplacement, un motif, et refuse une « alternative » identique à la demande.';

revoke execute on function fn_refuser_absence(uuid, text, date, date, text) from public, anon;
grant  execute on function fn_refuser_absence(uuid, text, date, date, text) to authenticated;

-- ===========================================================================
-- Le salarié répond à la contre-proposition
-- ===========================================================================

create or replace function fn_repondre_contre_proposition(
  p_absence uuid,
  p_accepte boolean,
  p_motif   text default null
) returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare a absences%rowtype;
begin
  select * into a from absences where id = p_absence;
  if a.id is null then
    raise exception 'Proposition introuvable : %', p_absence;
  end if;
  if not is_self_employee(a.employee_id) then
    raise exception 'Seul le salarié concerné répond à une contre-proposition.';
  end if;
  if a.status <> 'proposed' then
    raise exception 'Cette ligne n''est pas une contre-proposition en attente (statut « % »).', a.status;
  end if;

  if p_accepte then
    update absences
       set status = 'approved', decided_by = auth.uid(), decided_at = now(),
           decision_note = coalesce(p_motif, 'Contre-proposition acceptée par le salarié.')
     where id = a.id;
    return jsonb_build_object('ok', true, 'absence', a.id, 'statut', 'approved',
      'message', 'Contre-proposition acceptée. L''absence est validée.');
  end if;

  if p_motif is null or btrim(p_motif) = '' then
    raise exception 'Un refus porte son motif : l''employeur doit savoir pourquoi la '
                    'contre-proposition ne convient pas.';
  end if;

  update absences
     set status = 'refused', decided_by = auth.uid(), decided_at = now(),
         decision_note = p_motif
   where id = a.id;

  -- La main revient à l'employeur : une nouvelle demande naît, chaînée, en
  -- attente de sa réponse.
  insert into absences (company_id, employee_id, absence_type_id, start_date, end_date,
                        days_count, status, comment, requested_by, certificate_received,
                        declared_by_employee, certificate_original_received,
                        absence_parente_id, proposee_par, rang_proposition, child_id)
  values (a.company_id, a.employee_id, a.absence_type_id, a.start_date, a.end_date,
          0, 'pending', p_motif, auth.uid(), false, true, false,
          a.id, 'salarie', a.rang_proposition + 1, a.child_id);

  return jsonb_build_object('ok', true, 'absence', a.id, 'statut', 'refused',
    'message', 'Contre-proposition refusée. La main revient à l''employeur.');
end $$;

comment on function fn_repondre_contre_proposition(uuid, boolean, text) is
  'Le salarié accepte ou refuse une contre-proposition. Un refus rouvre le tour à l''employeur, en chaînant la nouvelle demande — la négociation reste tracée de bout en bout.';

revoke execute on function fn_repondre_contre_proposition(uuid, boolean, text) from public, anon;
grant  execute on function fn_repondre_contre_proposition(uuid, boolean, text) to authenticated;

-- ===========================================================================
-- Lire la négociation
-- ===========================================================================

create or replace function fn_chaine_absence(p_absence uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare a absences%rowtype; v_racine uuid; v_chaine jsonb;
begin
  select * into a from absences where id = p_absence;
  if a.id is null then raise exception 'Absence introuvable : %', p_absence; end if;
  if not (has_company_access(a.company_id) or is_self_employee(a.employee_id)) then
    raise exception 'Accès refusé à cette absence.';
  end if;

  -- Remonter à la demande initiale, puis redescendre toute la chaîne.
  with recursive amont as (
    select x.* from absences x where x.id = p_absence
    union all
    select p.* from absences p join amont m on p.id = m.absence_parente_id
  )
  select id into v_racine from amont where absence_parente_id is null limit 1;

  with recursive aval as (
    select x.* from absences x where x.id = coalesce(v_racine, p_absence)
    union all
    select e.* from absences e join aval d on e.absence_parente_id = d.id
  )
  select jsonb_agg(jsonb_build_object(
           'id', id, 'rang', rang_proposition, 'par', proposee_par,
           'du', start_date, 'au', end_date, 'statut', status,
           'motif', decision_note, 'decide_le', decided_at)
         order by rang_proposition, start_date)
    into v_chaine
  from aval;

  return jsonb_build_object('racine', v_racine, 'chaine', coalesce(v_chaine, '[]'::jsonb),
                            'longueur', jsonb_array_length(coalesce(v_chaine, '[]'::jsonb)));
end $$;

comment on function fn_chaine_absence(uuid) is
  'Restitue toute la négociation autour d''une absence : demande initiale, contre-propositions, réponses, dans l''ordre. C''est ce qu''on montre au salarié — ou à un juge.';

revoke execute on function fn_chaine_absence(uuid) from public, anon;
grant  execute on function fn_chaine_absence(uuid) to authenticated;
