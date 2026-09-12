-- 89 — Les trois paramètres qui ne demandent pas de source légale
--
-- `fn_referential_gaps` signalait six clés sans aucune version chargée. Trois
-- d'entre elles ne sont pas des valeurs légales et n'avaient donc aucune raison
-- d'attendre une publication officielle :
--
--   ccss_alerte_info_jours / ccss_alerte_warning_jours
--       Sept jours et deux jours. Ce sont les seuils que vous avez spécifiés le
--       12 septembre 2026 ; la source est la spécification du projet, pas un
--       texte de loi. Sans eux, `fn_recalculer_severites` ne pouvait pas
--       distinguer une échéance proche d'une échéance lointaine.
--
--   absence_max_contre_propositions
--       Nombre de contre-propositions successives admises avant qu'un refus
--       d'absence soit définitif. Paramétrage applicatif : aucun texte ne le
--       fixe, et il doit rester modifiable sans migration.
--
-- LES TROIS QUI RESTENT, ET CE QU'IL LEUR FAUT
-- =============================================
--   accident_class_rates              — barème des classes de risque de
--                                       l'Association d'assurance accident.
--   mileage_allowance_eur_per_km      — barème kilométrique.
--   sanction_notification_deadline_days — délai de notification d'une sanction.
--
-- Ce sont des valeurs légales. La règle 7 du projet interdit d'en inventer une
-- faute de source : elles restent absentes et signalées par
-- `fn_referential_gaps`, ce qui est le comportement voulu. Un chiffre plausible
-- mais faux se recopierait dans une paie.

set search_path = public;

insert into parametres_legaux
  (cle_parametre, libelle, famille, valeur_num, debut_validite, fin_validite,
   source, reference_legale, note)
values
  ('ccss_alerte_info_jours', 'Alerte CCSS — seuil « information »', 'ccss',
   7, date '1970-01-01', date '2037-12-31',
   'Spécification LuxRH du 12 septembre 2026',
   null,
   'Nombre de jours avant l''échéance à partir duquel une alerte CCSS passe en sévérité « info ». Seuil de conduite interne, pas une obligation légale : il se règle sans migration.'),

  ('ccss_alerte_warning_jours', 'Alerte CCSS — seuil « avertissement »', 'ccss',
   2, date '1970-01-01', date '2037-12-31',
   'Spécification LuxRH du 12 septembre 2026',
   null,
   'Nombre de jours avant l''échéance à partir duquel une alerte CCSS passe en sévérité « avertissement ». Au-delà de l''échéance, la sévérité devient « probleme ». Seuil de conduite interne.'),

  ('absence_max_contre_propositions', 'Contre-propositions successives admises', 'conges',
   3, date '1970-01-01', date '2037-12-31',
   'Paramétrage applicatif LuxRH',
   null,
   'Nombre de contre-propositions enchaînées avant qu''un refus d''absence soit considéré comme définitif. Aucun texte ne le fixe : c''est une règle de conduite interne, volontairement paramétrable.')
on conflict do nothing;

do $controle$
declare v_manquantes text;
begin
  select string_agg(cle_parametre, ', ' order by cle_parametre) into v_manquantes
  from fn_referential_gaps() where versions = 0;
  raise notice 'Cles encore sans version : %', coalesce(v_manquantes, '(aucune)');
end $controle$;
