-- 63 — Régénération des matricules de démonstration
--
-- La migration 62 a corrigé la règle : la parité se lit en position 11. Les
-- matricules déjà en base avaient été fabriqués avec l'ancienne convention, et
-- **160 sur 322** contredisaient désormais le sexe déclaré. Les laisser en
-- l'état donnerait un `sexe_legal` faux pour la moitié de l'effectif — pire que
-- l'absence de colonne, puisque la valeur aurait l'air d'être calculée.
--
-- Ce sont des données de démonstration, fabriquées : elles se régénèrent. Sur
-- une base réelle, la démarche serait l'inverse — on ne touche pas à un
-- matricule officiel, on signale l'incohérence et on la fait trancher par qui
-- détient la pièce d'identité.
--
-- Résultat vérifié après application : 322 matricules, **zéro écart** entre sexe
-- déclaré et sexe dérivé, et les clés de Luhn et de Verhoeff tiennent toujours
-- pour les 322.

do $$
declare
  e            record;
  v_matricule  text;
  v_serial     int;
  v_corriges   int := 0;
  v_ignores    int := 0;
begin
  for e in
    select id, birth_date, sex, national_id_enc
    from employees
    where national_id_enc is not null and birth_date is not null
    order by id
  loop
    -- On repart du numéro d'ordre existant pour rester au plus près de
    -- l'original : seule la parité change.
    begin
      v_serial := substr(fn_decrypt_field(e.national_id_enc), 9, 3)::int;
    exception when others then
      v_ignores := v_ignores + 1;
      continue;
    end;

    v_matricule := fn_make_national_id(e.birth_date, v_serial, e.sex);

    update employees
       set national_id_enc  = fn_encrypt_field(v_matricule),
           national_id_hint = substr(v_matricule, 1, 4) || '…'
     where id = e.id;
    v_corriges := v_corriges + 1;
  end loop;

  raise notice 'Matricules régénérés : %, ignorés : %', v_corriges, v_ignores;
end $$;

-- Contrôle : plus aucun écart entre le sexe déclaré et le sexe dérivé.
do $$
declare v_ecarts int;
begin
  select count(*) into v_ecarts
  from employees
  where national_id_enc is not null
    and sexe_legal is distinct from sex;
  if v_ecarts > 0 then
    raise exception 'Régénération incomplète : % salarié(s) gardent un écart entre '
                    'sexe déclaré et sexe légal.', v_ecarts;
  end if;
end $$;
