-- 64c — Le calcul des primes passe par fn_applicable_cbas
--
-- Défaut de la migration 64b, trouvé au premier essai réel : la fonction
-- résolvait la convention applicable en interrogeant `contract_collective_agreements`
-- seule. Or cette table est **vide** sur le déploiement : le rattachement se fait
-- au niveau de la société, parfois du service, et seulement parfois du contrat.
--
-- `fn_applicable_cbas` fait déjà ce travail, et le fait mieux — elle couvre les
-- trois niveaux et filtre sur le service et la catégorie professionnelle.
-- Réinventer une résolution plus étroite à côté d'elle produisait une fonction
-- qui ne trouvait jamais rien : tous les créneaux ressortaient « sans règle ».
--
-- La leçon vaut d'être écrite : avant d'écrire une résolution, vérifier que le
-- moteur n'en a pas déjà une — et l'essayer sur les données réelles, pas sur
-- l'idée qu'on s'en fait.
--
-- Ce que la fonction ne fait jamais
-- ----------------------------------
-- Deviner. Un créneau sans règle applicable n'est pas ignoré : il ressort dans
-- `sans_regle`, avec sa durée et le motif. Une assiette qu'elle ne sait pas
-- résoudre ressort dans `non_calculables`. Le total annoncé est donc toujours
-- accompagné de ce qu'il ne couvre pas — un montant partiel présenté comme
-- complet se recopierait dans une paie.

create or replace function fn_primes_conditions(
  p_employee uuid,
  p_du       date,
  p_au       date
) returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_company     uuid;
  c             record;
  r             cct_regle_prime%rowtype;
  v_lignes      jsonb := '[]'::jsonb;
  v_sans_regle  jsonb := '[]'::jsonb;
  v_non_calc    jsonb := '[]'::jsonb;
  v_total       numeric := 0;
  v_assiette    numeric;
  v_montant     numeric;
  v_quantite    numeric;
  v_contrat     record;
begin
  if p_du is null or p_au is null then
    raise exception 'Indiquez une période : une prime se calcule sur des dates, pas sur un solde.';
  end if;

  select company_id into v_company from employees where id = p_employee;
  if v_company is null then
    raise exception 'Salarié introuvable : %', p_employee;
  end if;
  if not (has_company_access(v_company) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé aux primes de ce salarié.';
  end if;

  for c in
    select cc.*, cr.libelle as condition_libelle, cr.famille
    from creneau_condition cc
    join ref_condition_travail cr on cr.code = cc.condition_code
    where cc.employee_id = p_employee
      and cc.deleted_at is null
      and cc.date_prestation between p_du and p_au
    order by cc.date_prestation, cc.heure_debut
  loop
    select ct.id, ct.monthly_gross, ct.weekly_hours
      into v_contrat
    from contracts ct
    where ct.employee_id = p_employee
      and ct.start_date <= c.date_prestation
      and (ct.end_date is null or ct.end_date >= c.date_prestation)
    order by ct.start_date desc
    limit 1;

    r := null;
    if v_contrat.id is not null then
      -- Les trois niveaux de rattachement, par la fonction qui les connaît déjà.
      select p.* into r
      from cct_regle_prime p
      join fn_applicable_cbas(v_contrat.id, c.date_prestation) a
        on a.collective_agreement_id = p.collective_agreement_id
      where p.condition_code = c.condition_code
        and p.debut_validite <= c.date_prestation
        and p.fin_validite   >  c.date_prestation
        and c.minutes >= p.seuil_minutes
      order by p.debut_validite desc
      limit 1;
    end if;

    if r.id is null then
      v_sans_regle := v_sans_regle || jsonb_build_object(
        'date', c.date_prestation, 'condition', c.condition_code,
        'libelle', c.condition_libelle, 'minutes', c.minutes,
        'motif', case
          when v_contrat.id is null then 'aucun contrat en vigueur à cette date'
          else 'aucune règle conventionnelle applicable pour cette condition à cette date, '
               'ou seuil d''exposition non atteint' end);
      continue;
    end if;

    v_quantite := case r.unite
                    when 'heure'      then c.minutes / 60.0
                    when 'prestation' then 1
                    when 'jour'       then 1
                    when 'mois'       then 1
                  end;

    if r.montant is not null then
      v_montant := r.montant * v_quantite;
    else
      v_assiette := case r.assiette
        when 'salaire_mensuel' then v_contrat.monthly_gross
        when 'salaire_horaire' then
          case when coalesce(v_contrat.weekly_hours, 0) > 0
               then v_contrat.monthly_gross * 12.0 / 52.0 / v_contrat.weekly_hours
               else null end
        else null
      end;

      if v_assiette is null then
        v_non_calc := v_non_calc || jsonb_build_object(
          'date', c.date_prestation, 'condition', c.condition_code,
          'regle', r.libelle, 'assiette', r.assiette,
          'motif', format('Assiette « %s » non résoluble : le moteur sait résoudre '
                          'salaire_mensuel et salaire_horaire.', coalesce(r.assiette, '(absente)')));
        continue;
      end if;
      v_montant := v_assiette * r.taux_pct / 100.0 * v_quantite;
    end if;

    v_total := v_total + v_montant;
    v_lignes := v_lignes || jsonb_build_object(
      'date', c.date_prestation,
      'condition', c.condition_code,
      'libelle', c.condition_libelle,
      'famille', c.famille,
      'site', c.client_site_id,
      'heure_debut', c.heure_debut, 'heure_fin', c.heure_fin,
      'minutes', c.minutes,
      'regle', r.libelle,
      'unite', r.unite,
      'taux_pct', r.taux_pct, 'montant_unitaire', r.montant,
      'assiette', r.assiette, 'assiette_valeur', round(v_assiette, 4),
      'montant', round(v_montant, 2),
      'article', r.article, 'source', r.source_url);
  end loop;

  return jsonb_build_object(
    'employee_id', p_employee, 'du', p_du, 'au', p_au,
    'lignes', v_lignes,
    'total', round(v_total, 2),
    'sans_regle', v_sans_regle,
    'non_calculables', v_non_calc,
    'complet', jsonb_array_length(v_sans_regle) = 0 and jsonb_array_length(v_non_calc) = 0,
    'message', case
      when jsonb_array_length(v_sans_regle) = 0 and jsonb_array_length(v_non_calc) = 0 then null
      else format('Total partiel : %s créneau(x) sans règle applicable et %s non calculable(s). '
                  'Le montant ci-dessus ne les couvre pas.',
                  jsonb_array_length(v_sans_regle), jsonb_array_length(v_non_calc))
    end);
end $$;

comment on function fn_primes_conditions(uuid, date, date) is
  'Calcule les primes de conditions dues sur une période, en croisant les créneaux réellement travaillés, les règles de la convention applicable au contrat, et l''assiette. Renvoie toujours ce qu''elle n''a pas su calculer : un total partiel présenté comme complet se recopierait dans une paie.';

revoke execute on function fn_primes_conditions(uuid, date, date) from public, anon;
grant  execute on function fn_primes_conditions(uuid, date, date) to authenticated;
