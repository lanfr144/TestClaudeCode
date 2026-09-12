-- Reconstitué depuis la base le 10 septembre 2026 : cette migration était appliquée
-- sans fichier correspondant dans le dépôt. Voir docs/ecarts-a-corriger.md.
-- `to_jsonb(ligne)` serialise une colonne jsonb vide en JSON `null`, et
-- `ligne -> 'value_json'` rend alors le scalaire JSON null -- qui n'est pas un
-- NULL SQL. Chaque parametre importe portait donc une valeur json fantome, et
-- la contrainte `one_value` (une seule des trois colonnes de valeur renseignee)
-- rejetait 166 lignes sur 177. Meme piege pour les regles CCT et les parametres
-- de valorisation des avantages en nature.
do $do$
declare src text; avant int;
begin
  src := pg_get_functiondef('fn_import_referential(jsonb,text)'::regprocedure);
  avant := length(src);

  src := replace(src, 'ligne -> ''value_json''',
                      'nullif(ligne -> ''value_json'', ''null''::jsonb)');
  src := replace(src, 'ligne -> ''rules''',
                      'nullif(ligne -> ''rules'', ''null''::jsonb)');
  src := replace(src, 'ligne -> ''valuation_params''',
                      'nullif(ligne -> ''valuation_params'', ''null''::jsonb)');

  if length(src) <= avant then
    raise exception 'Aucun remplacement applique.';
  end if;
  execute src;
end $do$;
