-- Reconstitué depuis la base le 10 septembre 2026 : cette migration était appliquée
-- sans fichier correspondant dans le dépôt. Voir docs/ecarts-a-corriger.md.
-- Suite de 45 : l'import cherchait les CCT sur la seule organisation cible et
-- creait donc un doublon lorsqu'une CCT nationale du meme code etait deja la.
-- La recherche passe par fn_cba_by_code, qui voit le partage comme le propre.
do $do$
declare
  src text;
  avant int;
begin
  src := pg_get_functiondef('fn_import_referential(jsonb,text)'::regprocedure);
  avant := length(src);

  src := replace(src,
    'if exists (select 1 from collective_agreements' || chr(10) ||
    '                where organization_id = org and code = ligne ->> ''code''',
    'if exists (select 1 from collective_agreements' || chr(10) ||
    '                where (organization_id = org or organization_id is null)' || chr(10) ||
    '                  and code = ligne ->> ''code''');

  src := replace(src,
    '    select id into cba from collective_agreements' || chr(10) ||
    '     where organization_id = org and code = ligne ->> ''collective_agreement_code''' || chr(10) ||
    '     order by valid_from desc limit 1;',
    '    cba := fn_cba_by_code(ligne ->> ''collective_agreement_code'', org);');

  src := replace(src,
    '      select id into cba from collective_agreements' || chr(10) ||
    '       where organization_id = org and code = ligne ->> ''collective_agreement_code''' || chr(10) ||
    '       order by valid_from desc limit 1;',
    '      cba := fn_cba_by_code(ligne ->> ''collective_agreement_code'', org);');

  if length(src) = avant then
    raise exception 'Aucun remplacement applique : le corps de fn_import_referential a change.';
  end if;

  execute src;
end $do$;
