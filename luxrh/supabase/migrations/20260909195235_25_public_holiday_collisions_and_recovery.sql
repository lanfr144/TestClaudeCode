
-- =========================================================================
--  Deux jours fériés peuvent tomber le même jour : l'Ascension (Pâques + 39)
--  coïncide avec la Journée de l'Europe quand Pâques tombe le 31 mars, ce qui
--  s'est produit en 2024. Le salarié ne perd pas le second : il est récupérable.
--  Même logique pour un jour férié tombant un jour non travaillé.
-- =========================================================================
alter table public_holidays drop constraint if exists public_holidays_holiday_date_collective_agreement_id_key;

alter table public_holidays
  add column if not exists is_recoverable boolean not null default false,
  add column if not exists recovery_reason text;

-- Un même jour férié ne doit pas être généré deux fois, mais deux fêtes
-- distinctes peuvent partager une date.
create unique index if not exists public_holidays_year_name_key
  on public_holidays(year, name, coalesce(collective_agreement_id, '00000000-0000-0000-0000-000000000000'::uuid));

create or replace function fn_generate_public_holidays(p_year int)
returns setof public_holidays language plpgsql security definer set search_path = public as $$
declare easter date := fn_easter_sunday(p_year);
begin
  insert into public_holidays(year, holiday_date, name, is_mobile) values
    (p_year, make_date(p_year,1,1),   'Jour de l''An', false),
    (p_year, easter + 1,              'Lundi de Pâques', true),
    (p_year, make_date(p_year,5,1),   'Fête du Travail', false),
    (p_year, make_date(p_year,5,9),   'Journée de l''Europe', false),
    (p_year, easter + 39,             'Ascension', true),
    (p_year, easter + 50,             'Lundi de Pentecôte', true),
    (p_year, make_date(p_year,6,23),  'Fête nationale', false),
    (p_year, make_date(p_year,8,15),  'Assomption', false),
    (p_year, make_date(p_year,11,1),  'Toussaint', false),
    (p_year, make_date(p_year,12,25), 'Noël', false),
    (p_year, make_date(p_year,12,26), 'Saint-Étienne', false)
  on conflict (year, name, coalesce(collective_agreement_id, '00000000-0000-0000-0000-000000000000'::uuid))
  do update set holiday_date = excluded.holiday_date;

  -- Remise à plat avant réévaluation, pour rester idempotent.
  update public_holidays set is_recoverable = false, recovery_reason = null
   where year = p_year and collective_agreement_id is null;

  -- Collision : la fête fixe est réputée consommée par la fête mobile ;
  -- la seconde ouvre droit à récupération.
  with doubles as (
    select holiday_date from public_holidays
    where year = p_year and collective_agreement_id is null
    group by holiday_date having count(*) > 1
  ),
  ranked as (
    select h.id, row_number() over (partition by h.holiday_date order by h.is_mobile desc, h.name) as rn
    from public_holidays h join doubles d on d.holiday_date = h.holiday_date
    where h.year = p_year and h.collective_agreement_id is null
  )
  update public_holidays h
     set is_recoverable = true,
         recovery_reason = 'Deux jours fériés légaux coïncident : celui-ci ouvre droit à un jour de récupération.'
    from ranked r
   where h.id = r.id and r.rn > 1;

  -- Jour férié tombant un dimanche : compensation due (art. L.232-4).
  update public_holidays
     set is_recoverable = true,
         recovery_reason = coalesce(recovery_reason,
           'Jour férié tombant un dimanche : un jour de compensation est dû.')
   where year = p_year and collective_agreement_id is null
     and extract(dow from holiday_date) = 0;

  return query select * from public_holidays
    where year = p_year and collective_agreement_id is null
    order by holiday_date, name;
end $$;

revoke execute on function fn_generate_public_holidays(int) from anon, public, authenticated;

-- Régénération de l'ensemble des années déjà présentes, plus 2024 pour la collision.
select fn_generate_public_holidays(g) from generate_series(2024, 2030) g;

-- Nombre de jours fériés effectivement chômés et nombre de récupérations dues.
create or replace function fn_holiday_summary(p_year int, p_cba uuid default null)
returns jsonb language sql stable set search_path = public as $$
  select jsonb_build_object(
    'year', p_year,
    'declared', count(*),
    'distinct_dates', count(distinct holiday_date),
    'recoverable', count(*) filter (where is_recoverable),
    'days', coalesce(jsonb_agg(jsonb_build_object(
        'date', holiday_date, 'name', name, 'mobile', is_mobile,
        'recoverable', is_recoverable, 'reason', recovery_reason
      ) order by holiday_date, name), '[]'::jsonb))
  from public_holidays
  where year = p_year and (collective_agreement_id is null or collective_agreement_id = p_cba);
$$;
