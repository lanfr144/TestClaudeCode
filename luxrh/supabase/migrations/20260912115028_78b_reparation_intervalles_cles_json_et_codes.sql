-- 78b — Réparation des trois dégâts collatéraux du renommage
--
-- La migration 78 a substitué des noms de colonnes dans les corps de fonctions.
-- Trois catégories de texte ressemblaient à des noms de colonnes sans en être,
-- et les 190 vérifications les ont révélées. La plus grave n'aurait produit
-- aucune erreur : seulement de mauvais résultats.
--
-- 1. LES INTERVALLES CONSTRUITS PAR CONCATÉNATION
-- ================================================
-- La migration 78 protégeait `interval '3 months'` et `date_trunc('month', x)`.
-- Elle ne protégeait pas `(n || ' months')::interval`, où l'unité est une chaîne
-- assemblée à l'exécution. Six fonctions produisaient donc
-- « invalid input syntax for type interval: "18 mois" ». Erreur franche, visible.
--
-- 2. LES CLÉS JSON DES DONNÉES STOCKÉES — le vrai danger
-- =======================================================
-- `parametres_legaux.valeur_json` et `regles_convention.regles` contiennent des
-- objets dont les clés sont des DONNÉES, pas du schéma : {"months": 2,
-- "to_years": 5}, {"weekly_hours": 40, "reference_period_months": 4}. La
-- migration 78 a réécrit les fonctions pour lire ->> 'mois' et
-- ->> 'heures_hebdomadaires', mais les données n'ont pas bougé.
--
-- Une lecture JSON d'une clé absente ne lève pas d'erreur : elle renvoie NULL.
-- Le préavis, le salaire minimum, les taux de cotisation et la période de
-- référence auraient donc été calculés faux, en silence. C'est précisément ce
-- que la règle 5 du projet interdit.
--
-- On aligne les données sur le code plutôt que l'inverse : le code est en
-- français, l'import et l'export du référentiel le sont aussi, et laisser huit
-- clés en anglais au milieu aurait rendu le format incohérent.
--
-- 3. LES CODES DE TABLE DE DOMAINE
-- =================================
-- ref_unite_essai portait les codes `weeks` et `months` — les seuls codes
-- anglais restants, les autres tables de domaine créées depuis emploient déjà
-- `heure`, `jour`, `mois`. fn_probation comparait unite_essai = 'mois' contre
-- une donnée valant 'months' : la comparaison n'aurait jamais été vraie, et le
-- calcul de période d'essai serait tombé dans sa branche par défaut. Sans
-- erreur, là encore.

set search_path = public;

-- ============================================================ 1. les intervalles
do $intervalles$
declare
  f       record;
  v_def   text;
  v_avant text;
  v_n     int := 0;
begin
  for f in
    select p.oid, p.proname from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f'
      and p.prosrc ~ '''\s*(mois|annee|jours|heures|minutes|semaines)\s*''\s*\)?\s*::\s*interval'
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    v_def := regexp_replace(v_def, '''(\s*)mois(\s*)''(\s*\))?::interval',
                            '''\1months\2''\3::interval', 'g');
    v_def := regexp_replace(v_def, '''(\s*)annee(\s*)''(\s*\))?::interval',
                            '''\1years\2''\3::interval', 'g');
    v_def := regexp_replace(v_def, '''(\s*)jours(\s*)''(\s*\))?::interval',
                            '''\1days\2''\3::interval', 'g');
    v_def := regexp_replace(v_def, '''(\s*)heures(\s*)''(\s*\))?::interval',
                            '''\1hours\2''\3::interval', 'g');
    v_def := regexp_replace(v_def, '''(\s*)semaines(\s*)''(\s*\))?::interval',
                            '''\1weeks\2''\3::interval', 'g');
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% fonction(s) : unites d''intervalle restituees.', v_n;
end $intervalles$;

-- ==================================================== 2. les clés JSON stockées
create or replace function fn_renommer_cles_json(p_valeur jsonb, p_map jsonb)
returns jsonb language sql immutable as $fn$
  select case jsonb_typeof(p_valeur)
    when 'object' then (
      select coalesce(jsonb_object_agg(
               coalesce(p_map ->> cle, cle),
               fn_renommer_cles_json(p_valeur -> cle, p_map)), '{}'::jsonb)
      from jsonb_object_keys(p_valeur) as cle)
    when 'array' then (
      select coalesce(jsonb_agg(fn_renommer_cles_json(e, p_map) order by o), '[]'::jsonb)
      from jsonb_array_elements(p_valeur) with ordinality as t(e, o))
    else p_valeur
  end;
$fn$;

comment on function fn_renommer_cles_json(jsonb, jsonb) is
  'Renomme récursivement les clés d''un document JSON selon une table de correspondance. Écrite pour la migration 78b, qui devait aligner les clés des référentiels stockés sur le code passé au français. Conservée : un futur changement de nom de clé se fera de la même façon.';

revoke execute on function fn_renommer_cles_json(jsonb, jsonb) from public, anon;

do $cles$
declare
  v_map jsonb := jsonb_build_object(
    'months',                  'mois',
    'days',                    'jours',
    'label',                   'libelle',
    'rate',                    'taux',
    'weekly_hours',            'heures_hebdomadaires',
    'break_minutes',           'pause_minutes',
    'reference_period_months', 'periode_reference_mois',
    'index_ref',               'indice_reference');
  v_a int;
  v_b int;
begin
  update parametres_legaux
     set valeur_json = fn_renommer_cles_json(valeur_json, v_map)
   where valeur_json is not null
     and fn_renommer_cles_json(valeur_json, v_map) is distinct from valeur_json;
  get diagnostics v_a = row_count;

  update regles_convention
     set regles = fn_renommer_cles_json(regles, v_map)
   where regles is not null
     and fn_renommer_cles_json(regles, v_map) is distinct from regles;
  get diagnostics v_b = row_count;

  raise notice '% parametre(s) legaux et % bloc(s) de regles alignes.', v_a, v_b;
end $cles$;

-- ============================================== 3. les codes de ref_unite_essai
insert into ref_unite_essai (code, libelle, ordre, note)
values ('semaines', 'Semaines', 1, 'Durée d''essai exprimée en semaines.'),
       ('mois',     'Mois',     2, 'Durée d''essai exprimée en mois.')
on conflict (code) do update set libelle = excluded.libelle, note = excluded.note;

update contrats set unite_essai = 'semaines' where unite_essai = 'weeks';
update contrats set unite_essai = 'mois'     where unite_essai = 'months';

delete from ref_unite_essai where code in ('weeks', 'months');
