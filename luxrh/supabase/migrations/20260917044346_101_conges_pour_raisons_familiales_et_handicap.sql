-- 101 — Congé pour raisons familiales, et congé du salarié handicapé
--
-- Les cinq clés restées vides en tête du classeur reçoivent leur valeur. Trois
-- écarts entre la spécification reçue et le texte du Code du travail sont
-- consignés ici plutôt que résolus en silence.
--
-- ### Les tranches d'âge
--
-- Art. L. 234-52 : « La durée du congé pour raisons familiales dépend de l'âge de
-- l'enfant et s'établit comme suit : douze jours par enfant si l'enfant est âgé
-- de zéro à moins de quatre ans accomplis ; dix-huit jours par enfant si l'enfant
-- est âgé de quatre ans accomplis à moins de treize ans accomplis ; cinq jours
-- par enfant si l'enfant est âgé de treize ans accomplis jusqu'à l'âge de
-- dix-huit ans accomplis et hospitalisé. »
--
-- | Clé du classeur | Tranche annoncée | Tranche de l'art. L. 234-52 |
-- |---|---|---|
-- | `Enfant_Jours_5`  | 0 à 5 ans inclus   | **0 à moins de 4 ans accomplis** |
-- | `Enfant_Jours_13` | 6 à 12 ans inclus  | 4 ans accomplis à moins de 13 |
-- | `Enfant_Jours_18` | 13 à 17 ans inclus | 13 ans jusqu'à 18 ans, **et hospitalisé** |
--
-- La première tranche ne coïncide pas, et le nom de la clé porte « 5 » là où la
-- loi s'arrête à quatre ans. Les valeurs chargées sont **celles de la loi** ; la
-- clé garde le nom du classeur, conformément à la règle qui fait de `Abrege`
-- l'identifiant canonique. La note de chaque paramètre énonce la borne réelle,
-- pour qu'un lecteur ne se fie pas au nom.
--
-- ### L'enfant handicapé
--
-- Art. L. 234-51, dernier alinéa : « La limite d'âge de dix-huit ans ne
-- s'applique pas aux enfants qui bénéficient de l'allocation spéciale
-- supplémentaire au sens de l'article 274 du Code de la Sécurité sociale. »
--
-- Ce n'est **pas** une majoration ni un doublement des jours, comme la
-- spécification l'indiquait : c'est la levée d'une condition d'âge. Le paramètre
-- est donc un drapeau, pas un nombre de jours.
--
-- ### Les six jours du salarié handicapé
--
-- La valeur de six jours est retenue telle qu'elle a été transmise, mais **sans
-- référence légale** : le seul « congé supplémentaire de six jours ouvrables »
-- que le Code du travail atteste dans le corpus est celui de l'art. L. 231-11,
-- accordé aux salariés dont le service ne permet pas le repos ininterrompu de
-- quarante-quatre heures. C'est un tout autre droit.
--
-- `fn_referential_gaps` signalera l'absence de référence jusqu'à ce que la base
-- légale soit versée au corpus. Une référence plausible mais fausse se recopie et
-- ne se détecte plus.

insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, reference_legale, note)
values
  ('conges', 'Enfant_Jours_5',
   'Congé pour raisons familiales — enfant de moins de 4 ans accomplis',
   12, 'jours', date '1970-01-01', date '2037-12-31', 'Legilux', 'art. L.234-52',
   'La loi borne à « moins de quatre ans accomplis ». Le nom de la clé porte « 5 » : ne pas s''y fier, la borne est 4.'),

  ('conges', 'Enfant_Jours_13',
   'Congé pour raisons familiales — enfant de 4 à moins de 13 ans accomplis',
   18, 'jours', date '1970-01-01', date '2037-12-31', 'Legilux', 'art. L.234-52',
   'De quatre ans accomplis à moins de treize ans accomplis.'),

  ('conges', 'Enfant_Jours_18',
   'Congé pour raisons familiales — enfant de 13 à 18 ans accomplis et hospitalisé',
   5, 'jours', date '1970-01-01', date '2037-12-31', 'Legilux', 'art. L.234-52',
   'L''hospitalisation est une condition, pas une circonstance : sans elle, le droit ne s''ouvre pas pour cette tranche.'),

  ('conges', 'Enfant_Handicape',
   'Congé pour raisons familiales — levée de la limite d''âge, enfant bénéficiaire de l''allocation spéciale supplémentaire',
   1, 'booléen', date '1970-01-01', date '2037-12-31', 'Legilux', 'art. L.234-51',
   'Drapeau, et non un nombre de jours : la limite d''âge de dix-huit ans ne s''applique pas. Voir l''art. 274 du Code de la sécurité sociale pour l''allocation spéciale supplémentaire.'),

  ('conges', 'Adulte_Handicap',
   'Congé supplémentaire du salarié handicapé ou reclassé',
   6, 'jours ouvrables', date '1970-01-01', date '2037-12-31',
   'Spécification transmise le 17 septembre 2026', null,
   'Référence légale à établir. Le seul congé supplémentaire de six jours ouvrables attesté par le Code du travail au corpus est celui de l''art. L.231-11, accordé lorsque le repos hebdomadaire de quarante-quatre heures n''est pas respecté : c''est un autre droit, et la confusion serait coûteuse.')
on conflict do nothing;

-- Ces clés sont désormais lues par le moteur des congés : `fn_referential_gaps`
-- doit savoir les réclamer si elles venaient à disparaître.
insert into parametres_attendus (cle_parametre, lu_par, note) values
  ('Enfant_Jours_5',   'fn_annual_leave_rule', 'Congé pour raisons familiales, art. L.234-52.'),
  ('Enfant_Jours_13',  'fn_annual_leave_rule', 'Congé pour raisons familiales, art. L.234-52.'),
  ('Enfant_Jours_18',  'fn_annual_leave_rule', 'Congé pour raisons familiales, art. L.234-52.'),
  ('Enfant_Handicape', 'fn_annual_leave_rule', 'Levée de la limite d''âge, art. L.234-51.'),
  ('Adulte_Handicap',  'fn_annual_leave_rule', 'Congé supplémentaire du salarié handicapé — référence à établir.')
on conflict (cle_parametre) do nothing;
