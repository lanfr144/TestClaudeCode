
-- =========================================================================
--  Matricule CCSS : 13 chiffres = date de naissance (8) + numéro d'ordre (3)
--  + clé de Luhn + clé de Verhoeff. Le 2e chiffre du numéro d'ordre porte le
--  sexe : impair pour un homme, pair pour une femme.
-- =========================================================================
create type sex_kind as enum ('male', 'female', 'unspecified');

alter table employees add column if not exists sex sex_kind not null default 'unspecified';

create or replace function fn_national_id_birth_date(p_id text)
returns date language plpgsql immutable set search_path = public as $$
declare clean text;
begin
  clean := regexp_replace(coalesce(p_id, ''), '\D', '', 'g');
  if length(clean) <> 13 then return null; end if;
  begin
    return to_date(substr(clean, 1, 8), 'YYYYMMDD');
  exception when others then
    return null;
  end;
end $$;

create or replace function fn_national_id_sex(p_id text)
returns sex_kind language plpgsql immutable set search_path = public as $$
declare clean text;
begin
  clean := regexp_replace(coalesce(p_id, ''), '\D', '', 'g');
  if length(clean) <> 13 then return null; end if;
  -- 2e chiffre du numéro d'ordre, soit la 10e position.
  return case when substr(clean, 10, 1)::int % 2 = 1 then 'male' else 'female' end::sex_kind;
end $$;

-- Contrôle détaillé : l'interface doit pouvoir dire pourquoi un matricule est refusé.
create or replace function fn_check_national_id(
  p_id text, p_birth date default null, p_sex sex_kind default null)
returns jsonb language plpgsql immutable set search_path = public as $$
declare clean text; base text; errs jsonb := '[]'::jsonb;
        d date; s sex_kind; luhn_ok boolean; verhoeff_ok boolean;
begin
  if p_id is null or p_id = '' then
    return jsonb_build_object('valid', true, 'empty', true, 'errors', errs);
  end if;

  clean := regexp_replace(p_id, '\D', '', 'g');
  if length(clean) <> 13 then
    return jsonb_build_object('valid', false, 'errors',
      jsonb_build_array(jsonb_build_object('code','length',
        'message', 'Le matricule doit comporter 13 chiffres (' || length(clean) || ' saisi(s)).')));
  end if;

  base := substr(clean, 1, 11);
  d := fn_national_id_birth_date(clean);
  s := fn_national_id_sex(clean);
  luhn_ok := fn_luhn_check_digit(base) = substr(clean, 12, 1)::int;
  verhoeff_ok := fn_verhoeff_check_digit(base) = substr(clean, 13, 1)::int;

  if d is null then
    errs := errs || jsonb_build_object('code','birth_date',
      'message','Les 8 premiers chiffres ne forment pas une date valide.');
  elsif d > current_date then
    errs := errs || jsonb_build_object('code','birth_date_future',
      'message','La date de naissance encodée est dans le futur.');
  end if;

  if not luhn_ok then
    errs := errs || jsonb_build_object('code','luhn',
      'message','La première clé de contrôle (Luhn, 12e chiffre) ne correspond pas.');
  end if;
  if not verhoeff_ok then
    errs := errs || jsonb_build_object('code','verhoeff',
      'message','La seconde clé de contrôle (Verhoeff, 13e chiffre) ne correspond pas.');
  end if;

  if p_birth is not null and d is not null and p_birth <> d then
    errs := errs || jsonb_build_object('code','birth_date_mismatch',
      'message','Le matricule encode le ' || to_char(d,'DD.MM.YYYY')
        || ', la fiche indique le ' || to_char(p_birth,'DD.MM.YYYY') || '.');
  end if;

  if p_sex is not null and p_sex <> 'unspecified' and s is not null and p_sex <> s then
    errs := errs || jsonb_build_object('code','sex_mismatch',
      'message','Le 2e chiffre du numéro d''ordre indique '
        || case when s = 'male' then 'un homme' else 'une femme' end
        || ', la fiche indique ' || case when p_sex = 'male' then 'un homme' else 'une femme' end || '.');
  end if;

  return jsonb_build_object(
    'valid', jsonb_array_length(errs) = 0,
    'birth_date', d, 'sex', s,
    'errors', errs);
end $$;

create or replace function fn_valid_national_id(p_id text)
returns boolean language sql immutable set search_path = public as $$
  select (fn_check_national_id(p_id) ->> 'valid')::boolean;
$$;

-- Fabrique un matricule cohérent avec la date de naissance et le sexe.
create or replace function fn_make_national_id(p_birth date, p_serial int, p_sex sex_kind default 'unspecified')
returns text language plpgsql immutable set search_path = public as $$
declare d1 int; d2 int; d3 int; base text;
begin
  d1 := (p_serial / 100) % 10;
  d2 := (p_serial / 10) % 10;
  d3 := p_serial % 10;
  if p_sex = 'male'   and d2 % 2 = 0 then d2 := (d2 + 1) % 10; end if;
  if p_sex = 'female' and d2 % 2 = 1 then d2 := (d2 + 1) % 10; end if;
  base := to_char(p_birth, 'YYYYMMDD') || d1::text || d2::text || d3::text;
  return base || fn_luhn_check_digit(base)::text || fn_verhoeff_check_digit(base)::text;
end $$;

-- L'enregistrement refuse un matricule incohérent, et renvoie la raison exacte.
create or replace function fn_set_employee_sensitive(p_employee uuid, p_national_id text, p_iban text)
returns void language plpgsql volatile security definer set search_path = public as $$
declare e employees; chk jsonb; msgs text;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not can_manage_company(e.company_id) then raise exception 'Accès refusé'; end if;

  if p_national_id is not null and p_national_id <> '' then
    chk := fn_check_national_id(p_national_id, e.birth_date, e.sex);
    if not (chk ->> 'valid')::boolean then
      select string_agg(x ->> 'message', ' ') into msgs from jsonb_array_elements(chk -> 'errors') x;
      raise exception 'Matricule CCSS invalide : %', msgs;
    end if;
  end if;

  update employees set
    national_id_enc = case when p_national_id is null or p_national_id = '' then national_id_enc
                           else fn_encrypt_field(regexp_replace(p_national_id, '\D', '', 'g')) end,
    national_id_hint = case when p_national_id is null or p_national_id = '' then national_id_hint
                            else right(regexp_replace(p_national_id, '\D', '', 'g'), 4) end,
    iban_enc = case when p_iban is null or p_iban = '' then iban_enc
                    else fn_encrypt_field(replace(upper(p_iban), ' ', '')) end
  where id = p_employee;
end $$;

revoke execute on function fn_check_national_id(text, date, sex_kind) from anon, public;
grant execute on function fn_check_national_id(text, date, sex_kind) to authenticated;
