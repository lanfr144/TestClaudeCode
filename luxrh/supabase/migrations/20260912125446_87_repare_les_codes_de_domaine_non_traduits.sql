-- 87 — Réparation : les codes de domaine de la migration 85 n'avaient pas bougé
--
-- Défaut introduit par moi, et attrapé par les 190 vérifications :
--
--     Key (action)=(DECHIFFREMENT) is not present in table "ref_action_acces"
--
-- Le bloc « tables de domaine » de la migration 85 s'appuyait sur la variable
-- `FOUND` après un `EXECUTE` d'un `select` sans `into`. PL/pgSQL ne la positionne
-- pas dans ce cas : la condition de garde était donc toujours fausse et la boucle
-- n'a rien exécuté. Les corps de fonctions, eux, ont bien été réécrits vers les
-- nouveaux codes — d'où une base incohérente : les fonctions écrivaient des
-- valeurs que les tables ne connaissaient pas.
--
-- La leçon : ne jamais se reposer sur un effet de bord implicite dans du SQL
-- dynamique. Ici, `select ... into` puis un test explicite.
--
-- La duplication de ligne passe désormais par une table temporaire plutôt que
-- par l'opérateur `#=` de `hstore`, qui n'est pas installé.

set search_path = public;

do $refs$
declare
  r       record;
  fk      record;
  v_n     int;
  v_faits int := 0;
begin
  for r in
    select * from (values
      ('ref_action_acces','READ','LECTURE'),
      ('ref_action_acces','DECRYPT','DECHIFFREMENT'),
      ('ref_action_acces','DOWNLOAD','TELECHARGEMENT'),
      ('ref_compensation_heures_sup','money','argent'),
      ('ref_compensation_heures_sup','rest','repos'),
      ('ref_lien_enfant','child','enfant'),
      ('ref_lien_enfant','adopted','adopte'),
      ('ref_lien_enfant','foster','recueilli'),
      ('ref_lien_enfant','stepchild','enfant_conjoint'),
      ('ref_nature_prime','thirteenth_month','treizieme_mois'),
      ('ref_nature_prime','seniority','anciennete'),
      ('ref_nature_prime','exceptional','exceptionnelle'),
      ('ref_nature_prime','notice_waiver','renonciation_preavis'),
      ('ref_nature_prime','other','autre'),
      ('ref_statut_heures_sup','requested','demande'),
      ('ref_statut_heures_sup','hr_approved','valide_rh'),
      ('ref_statut_heures_sup','approved','valide'),
      ('ref_statut_heures_sup','rejected','refuse'),
      ('ref_statut_heures_sup','cancelled','annule'),
      ('ref_statut_verification_adresse','outside','hors_perimetre'),
      ('ref_statut_verification_adresse','unknown','indeterminee'),
      ('ref_sujet_export','employee','salarie'),
      ('ref_sujet_export','company','societe'),
      ('ref_sujet_export','organization','organisation'),
      ('ref_sujet_export','referential','referentiel'),
      ('categories_sanction','minor','mineure'),
      ('categories_sanction','heavy','lourde'),
      ('categories_sanction','termination','rupture'),
      ('types_sanction','written_warning','avertissement_ecrit'),
      ('types_sanction','reprimand','blame'),
      ('types_sanction','suspension_disciplinary','mise_a_pied_disciplinaire'),
      ('types_sanction','transfer','mutation'),
      ('types_sanction','demotion','retrogradation'),
      ('types_sanction','suspension_precautionary','mise_a_pied_conservatoire'),
      ('types_sanction','dismissal_notice','licenciement_avec_preavis'),
      ('types_sanction','dismissal_gross_misconduct','licenciement_faute_grave')
    ) as x(tbl, ancien, nouveau)
  loop
    -- Test explicite : pas de `FOUND` implicite après un EXECUTE.
    execute format('select count(*) from public.%I where code = %L', r.tbl, r.ancien)
      into v_n;
    if v_n = 0 then
      continue;
    end if;

    -- a. Dupliquer la ligne sous le nouveau code, via une table temporaire :
    --    aucune énumération de colonnes, donc rien à reprendre si le catalogue
    --    en gagne une.
    execute format('create temporary table t_copie as select * from public.%I where code = %L',
                   r.tbl, r.ancien);
    execute format('update t_copie set code = %L', r.nouveau);
    execute format('insert into public.%I select * from t_copie', r.tbl);
    execute 'drop table t_copie';

    -- b. Basculer toutes les tables qui référencent ce code. Les clés étrangères
    --    sont lues dans le catalogue : aucune liste tenue à la main.
    for fk in
      select tc.relname as tbl, att.attname as col
      from pg_constraint co
      join pg_class tc on tc.oid = co.conrelid
      join pg_class rc on rc.oid = co.confrelid
      join pg_namespace ns on ns.oid = tc.relnamespace and ns.nspname = 'public'
      join pg_attribute att on att.attrelid = tc.oid and att.attnum = co.conkey[1]
      where co.contype = 'f' and rc.relname = r.tbl
    loop
      execute format('update public.%I set %I = %L where %I = %L',
                     fk.tbl, fk.col, r.nouveau, fk.col, r.ancien);
    end loop;

    -- c. Retirer l'ancien.
    execute format('delete from public.%I where code = %L', r.tbl, r.ancien);
    v_faits := v_faits + 1;
  end loop;
  raise notice '% code(s) de domaine traduit(s).', v_faits;
end $refs$;

-- Contrôle : aucun code anglais ne doit subsister dans ces tables.
do $controle$
declare v_restes text;
begin
  select string_agg(t || '.' || c, ', ') into v_restes from (
    select 'ref_action_acces' as t, code as c from ref_action_acces
     where code in ('READ','DECRYPT','DOWNLOAD')
    union all select 'ref_compensation_heures_sup', code from ref_compensation_heures_sup
     where code in ('money','rest')
    union all select 'ref_lien_enfant', code from ref_lien_enfant
     where code in ('child','adopted','foster','stepchild')
    union all select 'ref_statut_heures_sup', code from ref_statut_heures_sup
     where code in ('requested','hr_approved','approved','rejected','cancelled')
    union all select 'ref_sujet_export', code from ref_sujet_export
     where code in ('employee','company','organization','referential')
    union all select 'categories_sanction', code from categories_sanction
     where code in ('minor','heavy','termination')
  ) t;
  if v_restes is not null then
    raise exception 'Codes anglais subsistants : %', v_restes;
  end if;
  raise notice 'Tous les codes de domaine sont traduits.';
end $controle$;
