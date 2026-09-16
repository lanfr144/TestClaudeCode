-- 99 — `fn_jalons_carriere` citait un statut d'absence inexistant
--
-- La migration 98 filtrait `a.statut = 'approuvee'`. L'énumération
-- `statut_absence` ne connaît que `en_attente`, `valide`, `refuse`, `annule` et
-- `propose` : « approuvee » date d'avant la traduction du référentiel en français.
--
-- PL/pgSQL ne vérifie pas les littéraux d'énumération à la création de la
-- fonction — le corps est stocké en texte et n'est analysé qu'à l'exécution.
-- La migration 98 a donc réussi, et la fonction aurait échoué au premier appel
-- avec « invalid input value for enum statut_absence ». C'est le même piège que
-- les migrations 76 à 78 : ce qui n'est pas exécuté n'est pas vérifié.

do $$
declare
  corps text;
  avant text;
begin
  corps := pg_get_functiondef('fn_jalons_carriere(uuid, date)'::regprocedure);
  avant := corps;
  corps := replace(corps, 'a.statut = ''approuvee''', 'a.statut = ''valide''');

  if corps = avant then
    raise exception 'ARRÊT : le littéral « approuvee » est introuvable — la fonction a-t-elle déjà été reprise ?';
  end if;

  execute corps;
end
$$;

-- La correction se vérifie en appelant réellement la fonction : c'est le seul
-- moyen de forcer l'analyse du corps.
do $$
declare
  societe uuid;
begin
  select id into societe from societes limit 1;
  if societe is null then
    raise notice 'Aucune société : contrôle d''exécution impossible.';
    return;
  end if;

  -- `has_company_access` est faux hors session applicative ; on éprouve donc le
  -- corps en interceptant le refus attendu. Toute autre erreur remonte.
  begin
    perform fn_jalons_carriere(societe);
    raise notice 'Appel abouti.';
  exception
    when sqlstate 'P0001' then
      if sqlerrm like 'Accès refusé%' then
        raise notice 'Refus d''accès attendu — le corps a bien été analysé sans erreur de type.';
      else
        raise;
      end if;
  end;
end
$$;
