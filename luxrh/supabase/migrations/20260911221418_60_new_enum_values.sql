-- 60 — Nouvelles valeurs d'énumération, et rien d'autre
--
-- Migration volontairement réduite à des `alter type` : une valeur d'énumération
-- ne peut pas être utilisée dans la transaction qui l'ajoute. C'est le piège qui
-- a déjà justifié les migrations 20 et 28, d'une seule instruction chacune. Tout
-- ce qui s'appuie sur ces valeurs vit dans les migrations suivantes.
--
--   absence_status  + proposed   Le statut « proposé » : une contre-proposition
--                                de l'employeur, en attente de réponse du
--                                salarié. Distinct de `pending`, qui désigne une
--                                demande du salarié en attente de l'employeur.
--                                Sans cette distinction, on ne saurait pas de
--                                quel côté la balle se trouve.
--
--   severity_kind   + problem    Le délai d'envoi est dépassé. `blocking` est
--                                conservé : les deux ne disent pas la même
--                                chose — `problem` constate un retard, tandis
--                                que `blocking` empêche une opération. Une
--                                échéance CCSS dépassée est un problème, elle
--                                n'interdit pas de publier un planning.
--
--   residency_kind  + ISO 3166-1 alpha-3 : frontalier_fra, frontalier_bel,
--                   frontalier_deu. Les valeurs à deux lettres RESTENT en place
--                   et seront datées par la table de domaine : les retirer ici
--                   casserait les deux fronts, qui les portent dans leurs types
--                   TypeScript et Python. La migration des domaines les marquera
--                   comme échues, ce qu'une énumération ne sait pas faire.

alter type absence_status  add value if not exists 'proposed';
alter type severity_kind   add value if not exists 'problem';
alter type residency_kind  add value if not exists 'frontalier_fra';
alter type residency_kind  add value if not exists 'frontalier_bel';
alter type residency_kind  add value if not exists 'frontalier_deu';
