-- 78 — Les colonnes à nom simple passent au français
--
-- Troisième et dernier bloc du renommage. 47 noms : `name`, `status`, `label`,
-- `year`, `key`, `unit`. Ce sont les plus délicats, et pour deux raisons
-- distinctes.
--
-- CÔTÉ CODE : le mot désigne autre chose ailleurs
-- ===============================================
-- En TypeScript, `name` est aussi bien une colonne qu'une propriété de `Error`,
-- un attribut HTML, un champ de `File`. La réécriture du code est donc limitée
-- aux **littéraux de chaîne** — là où la base est forcément en jeu — et le
-- compilateur sert de filet pour le reste : après régénération des types, il
-- désigne chaque accès de propriété devenu faux, fichier et ligne.
--
-- CÔTÉ BASE : le mot est parfois un mot-clé, ou une valeur
-- ========================================================
-- Trois pièges, tous trouvés par un essai à blanc — une exécution complète
-- suivie d'une exception volontaire, qui annule tout et rend la liste des
-- défauts d'un seul coup.
--
-- 1. **Unités temporelles.** `extract(year from x)`, `date_trunc('month', x)`,
--    `interval '3 months'`. Ici `year` et `month` ne sont pas des colonnes mais
--    la syntaxe elle-même. Substitués, ils donnaient `extract(annee from x)` —
--    erreur de syntaxe — ou `date_trunc('mois', x)` — erreur à l'exécution
--    seulement, ce qui est pire. Les huit expressions rationnelles de protection
--    ci-dessous les restituent dans leur contexte syntaxique.
--
-- 2. **Valeurs d'énumération.** `headcount`, `sector` et `published` ne sont pas
--    seulement des colonnes : ce sont aussi des valeurs de `famille_parametre`,
--    `portee_convention` et `statut_planning`. Substituer le littéral sans
--    renommer la valeur donnait « invalid input value for enum ». Les trois
--    valeurs sont donc traduites, ce qui est de toute façon cohérent.
--
-- 3. **Types composites.** Traités en 77d après avoir été oubliés en 77. La
--    boucle ci-dessous couvre `relkind in ('r', 'c')` : tables ordinaires **et**
--    attributs de types composites.
--
-- ET LE CAS DÉJÀ RENCONTRÉ
-- =========================
-- Quatre fonctions renvoient `table(...)`. Renommer une colonne de sortie change
-- le type de retour, et `create or replace` est refusé. Le repli supprime puis
-- recrée — en révoquant le `grant execute` implicite à PUBLIC, sans quoi la revue
-- de sécurité serait annulée en silence.

set search_path = public;

create table if not exists renommage_simple (ancien text primary key, nouveau text not null);
truncate renommage_simple;
insert into renommage_simple values
  ('amount','montant'),('authority','autorite'),('basis','assiette'),('block','bloc'),
  ('category','categorie'),('changes','modifications'),('city','localite'),('color','couleur'),
  ('comment','commentaire'),('cost','cout'),('country','pays'),('days','jours'),
  ('derived','derive'),('difference','ecart'),('email','courriel'),('family','famille'),
  ('headcount','effectif'),('hours','heures'),('key','cle'),('kind','genre'),
  ('label','libelle'),('month','mois'),('months','mois'),('name','nom'),
  ('origin','origine'),('periodicity','periodicite'),('phone','telephone'),
  ('profit','resultat'),('published','publie'),('rank','rang'),('rate','taux'),
  ('reason','motif'),('relationship','lien_parente'),('residency','residence'),
  ('revenue','chiffre_affaires'),('rules','regles'),('scope','portee'),('sector','secteur'),
  ('severity','severite'),('sex','sexe'),('stage','echelon'),('state','etat'),
  ('status','statut'),('title','titre'),('unit','unite'),('userid','identifiant'),
  ('year','annee');

-- 1. Les valeurs d'énumération qui portent un de ces mots.
alter type famille_parametre rename value 'headcount'  to 'effectif';
alter type portee_convention rename value 'sector'     to 'secteur';
alter type statut_planning   rename value 'published'  to 'publie';

-- 2. Colonnes de tables et attributs de types composites.
do $colonnes$
declare
  r       record;
  v_faits int := 0;
begin
  for r in
    select c.relname as tbl, c.relkind, a.attname as ancien, m.nouveau
    from renommage_simple m
    join pg_attribute a on a.attname = m.ancien and a.attnum > 0 and not a.attisdropped
    join pg_class c on c.oid = a.attrelid and c.relkind in ('r', 'c')
    join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
    where c.relname <> 'renommage_simple'
    order by c.relname, a.attnum
  loop
    if r.relkind = 'c' then
      execute format('alter type public.%I rename attribute %I to %I cascade',
                     r.tbl, r.ancien, r.nouveau);
    else
      execute format('alter table public.%I rename column %I to %I',
                     r.tbl, r.ancien, r.nouveau);
    end if;
    v_faits := v_faits + 1;
  end loop;
  raise notice '% colonne(s) ou attribut(s) renomme(s).', v_faits;
end $colonnes$;

-- 3. Les corps de fonctions, avec les protections syntaxiques.
do $fonctions$
declare
  f          record;
  p          record;
  v_def      text;
  v_avant    text;
  v_droits   text[];
  v_g        text;
  v_touchees int := 0;
  v_recreees int := 0;
begin
  for f in
    select p2.oid, p2.proname, p2.proacl,
           pg_get_function_identity_arguments(p2.oid) as args
    from pg_proc p2
    join pg_namespace n on n.oid = p2.pronamespace and n.nspname = 'public'
    where p2.prokind = 'f'
      and not exists (select 1 from pg_depend d where d.objid = p2.oid and d.deptype = 'e')
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    for p in select * from renommage_simple loop
      v_def := regexp_replace(v_def, '\m' || p.ancien || '\M', p.nouveau, 'g');
    end loop;

    -- Les unites temporelles ne sont pas des colonnes : on les restitue.
    v_def := regexp_replace(v_def, '(extract\s*\(\s*)annee\M', '\1year', 'gi');
    v_def := regexp_replace(v_def, '(extract\s*\(\s*)mois\M', '\1month', 'gi');
    v_def := regexp_replace(v_def, 'date_trunc\s*\(\s*''annee''', 'date_trunc(''year''', 'gi');
    v_def := regexp_replace(v_def, 'date_trunc\s*\(\s*''mois''', 'date_trunc(''month''', 'gi');
    v_def := regexp_replace(v_def, '(interval\s*''[^'']*?)\mmois\M', '\1month', 'gi');
    v_def := regexp_replace(v_def, '(interval\s*''[^'']*?)\mannee\M', '\1year', 'gi');
    v_def := regexp_replace(v_def, '(interval\s*''[^'']*?)\mjours\M', '\1days', 'gi');
    v_def := regexp_replace(v_def, '(interval\s*''[^'']*?)\mheures\M', '\1hours', 'gi');

    if v_def is distinct from v_avant then
      begin
        execute v_def;
      exception when others then
        select coalesce(array_agg(
                 format('grant execute on function public.%I(%s) to %I',
                        f.proname, f.args, a.grantee::regrole::text)), '{}')
          into v_droits
        from aclexplode(f.proacl) a
        where a.privilege_type = 'EXECUTE' and a.grantee <> 0;

        execute format('drop function public.%I(%s)', f.proname, f.args);
        execute v_def;
        execute format('revoke execute on function public.%I(%s) from public',
                       f.proname, f.args);
        foreach v_g in array v_droits loop
          execute v_g;
        end loop;
        v_recreees := v_recreees + 1;
      end;
      v_touchees := v_touchees + 1;
    end if;
  end loop;
  raise notice '% fonction(s) reconstruite(s), dont % recreees.', v_touchees, v_recreees;
end $fonctions$;

drop table renommage_simple;
