-- 95 — La première colonne du classeur n'est pas une date d'entrée en vigueur
--
-- Le classeur relève les paramètres à partir du 1er janvier 2020. Chargé tel
-- quel, il faisait commencer à cette date des règles bien antérieures : la durée
-- hebdomadaire de quarante heures, le repos de onze heures, les vingt-six jours
-- de congé. Toute lecture antérieure rendait NULL.
--
-- Ce n'était pas théorique. Cinquante-sept contrats commencent avant 2020, le
-- plus ancien en mai 2018, et `fn_sync_part_time` comparait « 30 heures » à NULL :
-- la comparaison rend NULL, le contrat n'était plus reconnu comme temps partiel,
-- et rien ne le signalait. Le test du cycle de vie l'a arrêté.
--
-- Distinction retenue, mesurable et sans interprétation :
--
--   * une clé dont le relevé ne porte **qu'une seule période** n'a jamais varié
--     sur toute l'étendue du classeur. Sa borne basse recule à la sentinelle
--     `1970-01-01` : le classeur n'affirme pas qu'elle a commencé en 2020, il
--     commence seulement à la relever là ;
--   * une clé qui porte **plusieurs périodes** est une grandeur qui évolue — un
--     montant indexé, un taux de cotisation. Reculer sa borne basse affirmerait
--     que le SSM de 2020 valait déjà celui de 1970. Elle reste au 1er janvier
--     2020, et son absence avant cette date est une absence réelle.

with constantes as (
  select cle_parametre
  from parametres_legaux
  where source = 'paramètres.xlsx'
  group by cle_parametre
  having count(*) = 1
)
update parametres_legaux p
   set debut_validite = date '1970-01-01',
       note = p.note || ' — relevé unique, valable avant le premier relevé du classeur'
  from constantes c
 where p.cle_parametre = c.cle_parametre
   and p.source = 'paramètres.xlsx'
   and p.debut_validite = date '2020-01-01';
