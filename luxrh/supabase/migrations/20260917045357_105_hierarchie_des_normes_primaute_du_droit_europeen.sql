-- 105 — La hiérarchie des normes, et la primauté du droit de l'Union
--
-- Le projet appliquait « loi → CCT → contrat ». Il manquait l'étage du dessus.
--
-- Un **règlement** de l'Union est directement applicable : il ne se transpose
-- pas, il s'impose. Le règlement (CE) n° 561/2006 sur les temps de conduite et le
-- règlement (UE) n° 165/2014 sur les tachygraphes — tous deux au corpus, dossier
-- des transports — fixent des durées que le Code du travail ne peut pas
-- assouplir. Une **directive** vaut au contraire par sa transposition ; c'est le
-- texte luxembourgeois qui s'applique, la directive servant à l'interpréter.
--
-- ### Primauté et principe de faveur ne se confondent pas
--
-- En droit du travail, une norme inférieure l'emporte lorsqu'elle est **plus
-- favorable au salarié** : c'est le principe de faveur, et le moteur le met déjà
-- en œuvre pour les conventions collectives.
--
-- Ce principe ne joue pas contre une règle européenne **impérative de sécurité** :
-- une convention collective ne peut pas allonger un temps de conduite au motif
-- qu'elle paierait mieux les heures. Le drapeau `imperatif` distingue les deux :
-- il marque les normes auxquelles rien ne déroge, même en mieux-disant.
--
-- Le moteur **signale** les conflits, il ne les tranche pas seul : quand deux
-- normes de rangs différents fixent une même clé, la décision est rendue visible.
-- Un arbitrage silencieux serait impossible à contester.

create table ref_rang_norme (
  code            text primary key,
  libelle         text not null,
  rang            smallint not null,
  imperatif       boolean not null default false,
  description     text,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);

comment on table ref_rang_norme is
  'Étages de la hiérarchie des normes, du règlement de l''Union au contrat individuel. Table de domaine datée : ajouter un étage ne demande pas de migration.';
comment on column ref_rang_norme.code is 'Identifiant court, porté par chaque paramètre du référentiel.';
comment on column ref_rang_norme.libelle is 'Intitulé lisible de l''étage.';
comment on column ref_rang_norme.rang is 'Position dans la hiérarchie : 1 prime sur 2, qui prime sur 3. Une norme de rang supérieur ne se contourne pas.';
comment on column ref_rang_norme.imperatif is 'Vrai lorsque le principe de faveur ne joue pas : aucune norme inférieure ne peut y déroger, même en mieux-disant. Les durées de conduite en relèvent, les majorations de salaire non.';
comment on column ref_rang_norme.description is 'Ce que l''étage recouvre, et comment il s''applique.';
comment on column ref_rang_norme.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_rang_norme.fin_validite is 'Fin de validité, borne exclue.';
comment on column ref_rang_norme.note is 'Précision libre.';

insert into ref_rang_norme (code, libelle, rang, imperatif, description) values
  ('reglement_ue', 'Règlement de l''Union européenne', 1, true,
   'Directement applicable dans tous les États membres, sans transposition. Prime sur le droit national, y compris sur le Code du travail. Le règlement (CE) n° 561/2006 (temps de conduite) et le règlement (UE) n° 165/2014 (tachygraphes) en relèvent.'),
  ('directive_ue', 'Directive de l''Union européenne', 2, false,
   'Lie l''État quant au résultat. Ne s''applique pas directement : c''est le texte de transposition qui régit la relation de travail. Sert à interpréter le droit national, et à en révéler les manques.'),
  ('loi', 'Loi et Code du travail', 3, false,
   'Le droit national. Sauf disposition impérative, une norme inférieure plus favorable au salarié l''emporte.'),
  ('rgd', 'Règlement grand-ducal', 4, false,
   'Pris en exécution d''une loi, dont il ne peut pas excéder l''habilitation.'),
  ('convention', 'Convention collective de travail', 5, false,
   'Ne peut pas être moins favorable que la loi. Peut l''être davantage, et c''est alors elle qui s''applique.'),
  ('contrat', 'Contrat de travail', 6, false,
   'Le dernier étage. Ne peut être moins favorable ni que la loi, ni que la convention applicable.');

alter table ref_rang_norme enable row level security;
create policy rang_norme_lecture on ref_rang_norme for select to authenticated using (true);

-- --------------------------------------------- le rang porté par chaque paramètre
alter table parametres_legaux
  add column rang_norme text not null default 'loi' references ref_rang_norme(code);

comment on column parametres_legaux.rang_norme is
  'Étage de la hiérarchie dont ce paramètre relève. Par défaut « loi » : le référentiel est né du Code du travail. Un paramètre issu d''un règlement de l''Union porte « reglement_ue » et prime sur son équivalent national.';

-- --------------------------------------------- détection des conflits de rang
create or replace function fn_conflits_de_norme(p_on date default current_date)
returns table (
  cle_parametre    text,
  rang_retenu      text,
  valeur_retenue   numeric,
  rang_ecarte      text,
  valeur_ecartee   numeric,
  imperatif        boolean,
  commentaire      text
)
language sql
stable
as $$
  -- Deux normes de rangs différents fixant la même clé à la même date. On rend
  -- la plus haute et celle qu'elle écarte : la décision se lit, elle ne se
  -- devine pas.
  with en_vigueur as (
    select p.cle_parametre, p.valeur_num, p.rang_norme, r.rang, r.imperatif
    from parametres_legaux p
    join ref_rang_norme r on r.code = p.rang_norme
    where p.debut_validite <= p_on and p.fin_validite > p_on
  )
  select haut.cle_parametre,
         haut.rang_norme, haut.valeur_num,
         bas.rang_norme,  bas.valeur_num,
         haut.imperatif,
         case
           when haut.imperatif then
             'Norme impérative : le principe de faveur ne joue pas, la valeur du rang supérieur s''impose.'
           when bas.valeur_num is not null and haut.valeur_num is not null
                and bas.valeur_num > haut.valeur_num then
             'La norme inférieure est plus élevée. Si la grandeur est favorable au salarié, c''est elle qui s''applique — à trancher.'
           else
             'La norme supérieure l''emporte.'
         end
  from en_vigueur haut
  join en_vigueur bas
    on bas.cle_parametre = haut.cle_parametre
   and bas.rang > haut.rang
  order by haut.cle_parametre, haut.rang;
$$;

comment on function fn_conflits_de_norme(date) is
  'Rend les clés fixées à la fois par deux étages différents de la hiérarchie, avec la valeur de chacun. Signale sans trancher : un arbitrage silencieux serait impossible à contester. Une norme impérative écarte le principe de faveur.';

revoke execute on function fn_conflits_de_norme(date) from public;
grant execute on function fn_conflits_de_norme(date) to authenticated;
