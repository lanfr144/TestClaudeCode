-- Reconstitué depuis la base le 10 septembre 2026 : cette migration était appliquée
-- sans fichier correspondant dans le dépôt. Voir docs/ecarts-a-corriger.md.
-- Les paliers d'anciennete des grilles CCT sont numeriques (une grille peut
-- commencer a 2,5 ans), pas entiers. L'import les convertissait en integer et
-- rejetait « 0.0 ». Trouve par un aller-retour export puis import reel.
do $do$
declare src text; avant int;
begin
  src := pg_get_functiondef('fn_import_referential(jsonb,text)'::regprocedure);
  avant := length(src);
  src := replace(src, '''seniority_from_years'')::integer', '''seniority_from_years'')::numeric');
  src := replace(src, '''seniority_to_years'')::integer',   '''seniority_to_years'')::numeric');
  if length(src) <> avant then
    raise exception 'Le remplacement ne devait pas changer la longueur.';
  end if;
  if position('seniority_from_years'')::integer' in src) > 0 then
    raise exception 'Un cast integer subsiste.';
  end if;
  execute src;
end $do$;
