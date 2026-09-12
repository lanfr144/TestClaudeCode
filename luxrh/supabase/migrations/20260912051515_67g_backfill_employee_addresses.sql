-- 67g — Poser les quatre adresses de tous les salariés existants
--
-- La règle veut que les quatre adresses soient renseignées sur toute la période,
-- pour tout le monde. Les salariés déjà en base n'en ont aucune dans la nouvelle
-- table : sans reprise, `fn_verifier_couverture_adresses` signalerait un trou
-- pour chacun d'eux — exact, mais inexploitable.
--
-- On recopie donc le domicile légal dans les quatre types, avec
-- `origine = copie_domicile` pour que chacun sache que ce n'est pas une saisie.
-- La période part du plus ancien contrat — au plus tôt la candidature — et court
-- jusqu'à la sentinelle du 31/12/2037.
--
-- Rappel du constat de la migration 57 : **9 salariés sur 322 seulement portent
-- un code postal**. La reprise pose donc surtout des adresses incomplètes, et
-- c'est précisément ce que la couverture doit rendre visible plutôt que de le
-- laisser croire réglé.

do $$
declare
  e          record;
  t          record;
  v_depuis   date;
  v_creees   int := 0;
  v_salaries int := 0;
begin
  for e in select id, company_id, address_line, postal_code, city, country
           from employees order by id
  loop
    v_depuis := coalesce(
      (select min(start_date) from contracts where employee_id = e.id),
      current_date);
    v_salaries := v_salaries + 1;

    for t in select code from ref_type_adresse order by ordre loop
      if not exists (select 1 from adresses_salarie
                      where employee_id = e.id and type_adresse = t.code
                        and deleted_at is null) then
        insert into adresses_salarie (company_id, employee_id, type_adresse, ligne,
                                      code_postal, localite, pays, debut_validite,
                                      fin_validite, origine, note)
        values (e.company_id, e.id, t.code,
                coalesce(e.address_line, '(adresse non renseignée)'),
                e.postal_code, e.city,
                coalesce(fn_normaliser_pays(e.country), 'LUX'),
                v_depuis, date '2037-12-31', 'copie_domicile',
                case when e.address_line is null and e.postal_code is null
                     then 'Reprise d''un dossier sans adresse : à compléter.' end);
        v_creees := v_creees + 1;
      end if;
    end loop;
  end loop;

  raise notice 'Salariés traités : %, adresses créées : %', v_salaries, v_creees;
end $$;

do $$
declare v_incomplets int;
begin
  select count(*) into v_incomplets
  from employees e
  where (select count(distinct type_adresse) from adresses_salarie a
          where a.employee_id = e.id and a.deleted_at is null) < 4;
  if v_incomplets > 0 then
    raise exception 'Reprise incomplète : % salarié(s) n''ont pas leurs quatre adresses.',
                    v_incomplets;
  end if;
end $$;
