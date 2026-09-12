-- 68 — Consentements, fiche santé, et indicateurs de secours
--
-- Le principe qui gouverne tout ce fichier
-- -----------------------------------------
-- La donnée médicale brute — pathologie, allergie, médecin traitant — est une
-- donnée de santé au sens de l'article 9 du RGPD. **Le dispatching n'y a jamais
-- accès.** Il ne voit que des indicateurs dérivés, booléens, qui disent ce qu'il
-- faut faire sans dire pourquoi :
--
--   « ne pas envoyer dans un lieu signalant des chats »  et non  « allergique aux chats »
--   « porte de l'adrénaline »                            et non  « allergique aux guêpes »
--
-- Les indicateurs sont une table de référence, pas des colonnes booléennes.
-- La mèche de cautérisation, l'adrénaline, les antihistaminiques ne sont que des
-- exemples : la liste s'allonge par DML, sans migration.
--
-- Qui voit quoi
-- -------------
--   la personne             sa propre fiche, en entier
--   médecine du travail     la donnée brute de tous
--   RH d'urgence            la donnée brute, pour les secours
--   gestionnaire RH         les indicateurs, pas la donnée brute
--   dispatching / planning  les indicateurs seuls
--
-- Les rôles « médecine du travail » et « RH d'urgence » n'existent pas encore
-- dans `app_role` : ils sont ajoutés ici, et la migration suivante posera les
-- politiques qui s'en servent — une valeur d'énumération ne s'utilise pas dans
-- la transaction qui l'ajoute.

alter type app_role add value if not exists 'medecine_travail';
alter type app_role add value if not exists 'rh_urgence';
alter type app_role add value if not exists 'dispatching';
