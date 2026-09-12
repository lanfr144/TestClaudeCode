-- 77b — Une fonction d'autorisation ne peut pas exister en deux exemplaires
--
-- Défaut introduit par la migration 77, et que la vérification a immédiatement
-- rendu visible : une fonction ouverte au rôle `anon`, alors que la revue de
-- sécurité l'avait ramené à zéro.
--
-- CE QUI S'EST PASSÉ
-- ==================
-- La colonne `profils.is_org_admin` était dans la table de correspondance. Or il
-- existait aussi une **fonction** nommée `is_org_admin()`. La substitution
-- textuelle ne distingue pas les deux : elle a réécrit la définition de la
-- fonction avec le nouveau nom, et `create or replace` a donc créé une **seconde
-- fonction** au lieu de renommer la première.
--
-- Résultat : deux définitions de la même règle d'autorisation. Quinze fonctions
-- appelaient la nouvelle, quarante-quatre politiques RLS appelaient l'ancienne.
-- Le comportement était correct — les corps étaient identiques — mais un tel
-- doublon ne survit pas à la première correction apportée d'un seul côté.
--
-- Et la nouvelle fonction, étant une création et non un remplacement, avait
-- reçu le `grant execute` implicite à PUBLIC. C'est ce qu'a détecté le contrôle.
--
-- LA CORRECTION
-- =============
-- On supprime la nouvelle, puis on **renomme** l'ancienne. Les politiques RLS
-- référencent une fonction par son identifiant interne, pas par son nom : elles
-- suivent le renommage sans être réécrites. Les quarante-quatre pointent donc
-- sur la fonction renommée, et les quinze appels par nom la trouvent.
--
-- LA LEÇON
-- ========
-- Une table de correspondance de noms de colonnes ne doit pas être appliquée à
-- l'aveugle sur des définitions de fonctions : un même mot peut nommer une
-- colonne ici et une fonction là. Le contrôle qui a attrapé cela est
-- `fn_coherence_report`, sur le seul critère « aucune fonction applicative
-- exécutable par anon ».

set search_path = public;

drop function if exists public.est_admin_organisation();

alter function public.is_org_admin() rename to est_admin_organisation;

-- Une ceinture : la fonction renommée conserve ses droits d'origine, mais on
-- réaffirme l'invariant plutôt que de le supposer.
revoke execute on function public.est_admin_organisation() from public, anon;
grant  execute on function public.est_admin_organisation() to authenticated;

comment on function public.est_admin_organisation() is
  'Vrai si le compte connecté est administrateur de son organisation. Appelée par quarante-quatre politiques RLS et par les fonctions du moteur qui réservent une lecture du catalogue système aux administrateurs. Renommée depuis is_org_admin par la migration 77b.';
