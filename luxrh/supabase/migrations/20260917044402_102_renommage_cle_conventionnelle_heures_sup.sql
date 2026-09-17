-- 102 — `overtime_money_pct` devient `remuneration_heure_sup_pct`
--
-- La clé portait deux défauts. Elle était en anglais dans un projet dont tout le
-- reste est en français, et elle **collidait** avec l'ancien nom d'un paramètre
-- légal : deux espaces de nommage différents, un seul mot, et un lecteur qui ne
-- peut plus dire lequel il a sous les yeux.
--
-- Le nom retenu dit la grandeur. La valeur stockée est 140, c'est-à-dire la
-- **rémunération totale** de l'heure supplémentaire — cent pour cent du salaire
-- horaire plus la majoration de quarante. `majoration_heures_sup_pct` aurait
-- désigné les quarante, et la confusion aurait coûté un facteur trois et demi.
--
-- Les deux reprises se font dans la même migration. Séparer la clé stockée du
-- corps qui la lit produit exactement le défaut des migrations 78 : la fonction
-- cherche une clé que la donnée ne porte plus, `->>` rend NULL, et le contrôle
-- de non-régression conventionnelle devient muet au lieu d'échouer.
--
-- Ses trois voisines — `night_pct`, `sunday_pct`, `holiday_pct` — restent en
-- anglais : elles n'étaient pas dans la demande, et renommer une partie d'un
-- groupe homogène est pire que de n'en renommer aucune. À traiter d'un bloc.

do $$
declare
  touchees_donnees int;
  touchees_code    int := 0;
  r                record;
  corps            text;
  avant            text;
begin
  -- 1. la donnée
  update regles_convention
     set regles = (regles - 'overtime_money_pct')
                  || jsonb_build_object('remuneration_heure_sup_pct',
                                        regles -> 'overtime_money_pct')
   where regles ? 'overtime_money_pct';
  get diagnostics touchees_donnees = row_count;

  -- 2. le code qui la lit
  for r in
    select p.oid, p.proname
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and pg_get_functiondef(p.oid) like '%''overtime_money_pct''%'
  loop
    corps := pg_get_functiondef(r.oid);
    avant := corps;
    corps := replace(corps, '''overtime_money_pct''', '''remuneration_heure_sup_pct''');
    if corps <> avant then
      execute corps;
      touchees_code := touchees_code + 1;
      raise notice 'réécrite : %', r.proname;
    end if;
  end loop;

  raise notice '% ligne(s) de règles et % routine(s) reprises.',
               touchees_donnees, touchees_code;

  -- Trois conventions portaient la clé, une routine la lit. Si l'un des deux
  -- comptes tombe à zéro alors que l'autre ne l'est pas, la reprise est
  -- incomplète et le contrôle conventionnel serait faussé.
  if touchees_donnees > 0 and touchees_code = 0 then
    raise exception 'ARRÊT : % ligne(s) renommée(s) mais aucune routine reprise.', touchees_donnees;
  end if;
end
$$;

-- Plus aucune trace de l'ancien nom, ni dans la donnée ni dans le code.
do $$
declare
  restant_donnees int;
  restant_code    text;
begin
  select count(*) into restant_donnees
  from regles_convention where regles ? 'overtime_money_pct';

  select string_agg(proname, ', ') into restant_code
  from pg_proc
  where pronamespace = 'public'::regnamespace
    and pg_get_functiondef(oid) like '%''overtime_money_pct''%';

  if restant_donnees > 0 or restant_code is not null then
    raise exception 'ARRÊT : % ligne(s) et routine(s) % portent encore l''ancien nom.',
                    restant_donnees, coalesce(restant_code, 'aucune');
  end if;
end
$$;
