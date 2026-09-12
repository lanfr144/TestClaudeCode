-- Reconstitué depuis la base le 10 septembre 2026 : cette migration était appliquée
-- sans fichier correspondant dans le dépôt. Voir docs/ecarts-a-corriger.md.
-- Le compteur du registre d'export ne regardait que le premier niveau : il
-- annoncait 8 lignes pour un export de 4 societes et 322 salaries. Un registre
-- de traitements qui sous-estime d'un facteur 40 ne prouve rien.
--
-- Il compte desormais les objets JSON a tous les niveaux, ce qui correspond aux
-- lignes de table : un salarie, un contrat, une prestation en sont chacun un.
create or replace function fn_payload_rows(p_payload jsonb)
returns integer language sql immutable as $$
  select coalesce(case jsonb_typeof(p_payload)
    when 'object' then 1 + (select coalesce(sum(fn_payload_rows(v)), 0)
                              from jsonb_each(p_payload) e(k, v)
                             where jsonb_typeof(v) in ('object', 'array'))
    when 'array'  then (select coalesce(sum(fn_payload_rows(v)), 0)
                          from jsonb_array_elements(p_payload) v)
    else 0
  end, 0)::integer;
$$;

comment on function fn_payload_rows(jsonb) is
  'Nombre d''objets JSON du document, tous niveaux confondus : ordre de grandeur du volume exporte.';
