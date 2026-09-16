-- Une famille pour les aides à l'emploi et les subventions.
--
-- Le classeur des paramètres porte quatre montants d'aide (SUB_INT_1,
-- SUB_INT_1A_2L, SUB_PRE_1, SUB_PRE_1A_2L) qui ne sont ni une cotisation, ni un
-- seuil de temps de travail, ni un barème fiscal. Les ranger dans « social »
-- les aurait noyés parmi cent autres.
--
-- `add value` est isolé dans sa propre migration : PostgreSQL refuse d'employer
-- une valeur d'énumération dans la transaction qui la crée.
alter type famille_parametre add value if not exists 'aide';
