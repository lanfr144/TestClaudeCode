-- 62 — Sexe légal dérivé du matricule : correction de la position
--
-- Le défaut
-- ---------
-- `fn_national_id_sex` lisait la **position 10** du matricule, soit le chiffre
-- du milieu du numéro d'ordre NNN. Or la parité d'un nombre à trois chiffres se
-- lit sur son dernier chiffre : la **position 11**. Le générateur
-- `fn_make_national_id` ajustait lui aussi le mauvais chiffre (d2 au lieu de d3),
-- si bien que lecteur et générateur s'accordaient entre eux — et s'écartaient
-- tous deux de la règle.
--
-- Mesuré avant correction : sur 322 salariés, **160 matricules** contredisaient
-- le sexe déclaré une fois lus en position 11. Exactement la moitié, ce qui est
-- la signature d'un tirage à pile ou face — donc d'une règle fausse, pas d'un
-- jeu de données bancal.
--
-- Ce que la migration fait, et ne fait pas
-- -----------------------------------------
-- Elle corrige les deux fonctions et ajoute la colonne dérivée, **sans**
-- recalculer les matricules existants : c'est la migration 63 qui régénère le
-- jeu de démonstration, une fois la règle juste en place.
--
-- Le salarié voit son sexe légal, il ne le change pas
-- ---------------------------------------------------
-- La colonne est recalculée à chaque écriture depuis le matricule : quelle que
-- soit la valeur soumise, c'est la dérivation qui l'emporte. Inutile de rejeter
-- une tentative de modification — elle est sans effet par construction.
--
-- Le masquage au salarié a été écarté : l'article 15 du RGPD donne à la personne
-- l'accès à ses données, y compris dérivées. Cacher au salarié ce que les RH
-- voient fabriquerait le risque qu'on cherchait à écarter.

create or replace function fn_national_id_sex(p_id text)
returns sex_kind language plpgsql immutable set search_path = public as $$
declare clean text;
begin
  clean := regexp_replace(coalesce(p_id, ''), '\D', '', 'g');
  if length(clean) <> 13 then return null; end if;
  -- Positions 9 à 11 : le numéro d'ordre quotidien NNN. Sa parité se lit sur
  -- son dernier chiffre, la position 11 — impair masculin, pair féminin.
  return case when substr(clean, 11, 1)::int % 2 = 1 then 'male' else 'female' end::sex_kind;
end $$;

comment on function fn_national_id_sex(text) is
  'Sexe légal déduit du matricule national : parité du numéro d''ordre NNN (positions 9 à 11), lue sur son dernier chiffre. Impair = masculin, pair = féminin.';

create or replace function fn_make_national_id(
  p_birth date, p_serial integer, p_sex sex_kind default 'unspecified'::sex_kind)
returns text language plpgsql immutable set search_path = public as $$
declare d1 int; d2 int; d3 int; base text;
begin
  d1 := (p_serial / 100) % 10;
  d2 := (p_serial / 10) % 10;
  d3 := p_serial % 10;
  -- C'est d3, dernier chiffre de NNN, qui porte la parité — et non d2.
  if p_sex = 'male'   and d3 % 2 = 0 then d3 := (d3 + 1) % 10; end if;
  if p_sex = 'female' and d3 % 2 = 1 then d3 := (d3 + 1) % 10; end if;
  base := to_char(p_birth, 'YYYYMMDD') || d1::text || d2::text || d3::text;
  return base || fn_luhn_check_digit(base)::text || fn_verhoeff_check_digit(base)::text;
end $$;

comment on function fn_make_national_id(date, integer, sex_kind) is
  'Fabrique un matricule cohérent, pour les jeux d''essai. La parité du sexe est portée par le dernier chiffre du numéro d''ordre, conformément à fn_national_id_sex.';

alter table employees add column if not exists sexe_legal sex_kind;

comment on column employees.sex is $c$Sexe déclaré par le salarié, librement. Modifiable par lui depuis son espace. À ne pas confondre avec sexe_legal, qui est dérivé et non déclaratif. Sera renommé sexe_declare lors du passage au français.$c$;
comment on column employees.sexe_legal is $c$Sexe juridique, DÉRIVÉ du matricule national : parité du numéro d'ordre (position 11). Recalculé à chaque écriture — toute valeur soumise est ignorée, la dérivation fait foi. Nul tant qu'aucun matricule n'est enregistré. Le salarié y a accès (RGPD art. 15) mais ne peut pas le modifier.$c$;

create or replace function fn_derive_sexe_legal()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_matricule text;
begin
  -- La dérivation l'emporte toujours : la colonne n'est pas saisissable.
  if new.national_id_enc is null then
    new.sexe_legal := null;
    return new;
  end if;
  begin
    v_matricule := fn_decrypt_field(new.national_id_enc);
  exception when others then
    -- Un matricule illisible ne doit pas empêcher d'enregistrer le salarié,
    -- mais il ne doit pas non plus laisser croire à un sexe légal connu.
    new.sexe_legal := null;
    return new;
  end;
  new.sexe_legal := fn_national_id_sex(v_matricule);
  return new;
end $$;

revoke execute on function fn_derive_sexe_legal() from public, anon, authenticated;

comment on function fn_derive_sexe_legal() is
  'Recalcule employees.sexe_legal depuis le matricule à chaque écriture. Rend la colonne non saisissable par construction plutôt que par interdiction.';

drop trigger if exists derive_sexe_legal on employees;
create trigger derive_sexe_legal before insert or update on employees
  for each row execute function fn_derive_sexe_legal();
