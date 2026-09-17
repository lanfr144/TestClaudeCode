-- 109 — Congés liés au handicap : la référence trouvée, et celle qui manque
--
-- ### `Adulte_Handicap` — la base légale existe, je l'avais manquée
--
-- La migration 101 chargeait ces six jours « sans référence légale », faute
-- d'avoir trouvé le texte. Il est pourtant au corpus, **art. L. 233-4,
-- alinéa 2** :
--
--   « Un congé supplémentaire de six jours ouvrables est accordé aux invalides
--   de guerre, aux accidentés de travail et aux personnes ayant un handicap
--   physique, mental, sensoriel ou psychique, auxquelles a été reconnue la
--   qualité de salarié handicapé conformément au livre V, titre VI relatif à
--   l'emploi de personnes handicapées. L'indemnité journalière du congé
--   supplémentaire est à charge des crédits budgétaires de l'État. »
--
-- Mon motif de recherche cherchait « six jours de congé supplémentaire » ; le
-- texte dit « congé supplémentaire de six jours ouvrables ». L'article était là
-- depuis le début. La mention de l'art. L. 231-11 portée en note était une
-- fausse piste, et elle est retirée.
--
-- L'art. L. 561-1 définit la **qualité** de salarié handicapé ; L. 233-4 ouvre le
-- **droit au congé**. Les deux sont cités.
--
-- ### `Enfant_Handicape` — deux effets, deux paramètres
--
-- Le Code du travail dans sa version du 26 juillet 2026 atteste **un seul**
-- effet, à l'art. L. 234-51, dernier alinéa :
--
--   « La limite d'âge de dix-huit ans ne s'applique pas aux enfants qui
--   bénéficient de l'allocation spéciale supplémentaire au sens de l'article 274
--   du Code de la Sécurité sociale. »
--
-- Le **doublement** de la durée n'y figure pas : aucune occurrence de « double »,
-- « porté au double » ou « deux fois » ne s'y rapporte. Il est retenu sur
-- instruction, et porté par un paramètre distinct plutôt que fondu dans le
-- premier. Ainsi la levée d'âge garde sa référence vérifiable, le doublement
-- porte sa propre provenance, et l'un ne se fait pas passer pour l'autre.

update parametres_legaux
   set reference_legale = 'art. L.233-4, al. 2 ; qualité au sens de l''art. L.561-1',
       source = 'Legilux',
       libelle = 'Congé supplémentaire du salarié handicapé ou en reclassement',
       note = 'Six jours ouvrables par an. L''indemnité journalière est à charge '
              || 'des crédits budgétaires de l''État. Ouvert aux invalides de guerre, '
              || 'aux accidentés du travail et aux personnes reconnues salariés '
              || 'handicapés au titre du livre V, titre VI.'
 where cle_parametre = 'Adulte_Handicap';

-- La levée de limite d'âge garde son nom et sa référence.
update parametres_legaux
   set cle_parametre = 'Enfant_Handicape_Age_Leve',
       libelle = 'Congé pour raisons familiales — levée de la limite d''âge',
       note = 'Drapeau. La limite de dix-huit ans ne s''applique pas à l''enfant '
              || 'bénéficiaire de l''allocation spéciale supplémentaire (art. 274 '
              || 'du Code de la sécurité sociale).'
 where cle_parametre = 'Enfant_Handicape';

-- Le doublement, avec sa provenance déclarée.
insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, reference_legale, note)
values
  ('conges', 'Enfant_Handicape',
   'Congé pour raisons familiales — facteur applicable à l''enfant handicapé',
   2, 'facteur', date '1970-01-01', date '2037-12-31',
   'Spécification transmise le 17 septembre 2026', null,
   'Doublement de la durée des tranches de l''art. L.234-52 pour l''enfant '
   || 'bénéficiaire de l''allocation d''éducation spéciale. Le Code du travail '
   || 'dans sa version du 26 juillet 2026 n''énonce pas ce doublement : il '
   || 'n''atteste que la levée de la limite d''âge, portée par '
   || 'Enfant_Handicape_Age_Leve. Retenu sur instruction ; la référence reste à '
   || 'établir, et fn_referential_gaps continuera de le signaler.')
on conflict do nothing;

insert into parametres_attendus (cle_parametre, lu_par, note) values
  ('Enfant_Handicape_Age_Leve', 'fn_annual_leave_rule',
   'Levée de la limite d''âge, art. L.234-51.')
on conflict (cle_parametre) do nothing;

do $$
declare
  adulte   text;
  facteur  numeric;
  age_leve numeric;
begin
  select reference_legale into adulte from parametres_legaux
   where cle_parametre = 'Adulte_Handicap' limit 1;
  facteur  := fn_param_num('Enfant_Handicape', current_date);
  age_leve := fn_param_num('Enfant_Handicape_Age_Leve', current_date);

  if adulte is null then raise exception 'Adulte_Handicap reste sans référence.'; end if;
  if facteur is distinct from 2 then raise exception 'Facteur enfant = %', facteur; end if;
  if age_leve is distinct from 1 then raise exception 'Levée d''âge = %', age_leve; end if;
  raise notice 'Adulte_Handicap : % · facteur enfant % · levée d''âge %',
               adulte, facteur, age_leve;
end
$$;
