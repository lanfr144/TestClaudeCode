-- 77c — Le corps de est_admin_organisation lisait encore l'ancienne colonne
--
-- Suite directe de 77b, et correction d'une erreur de ma part.
--
-- La migration 77 avait produit **deux** fonctions : l'ancienne `is_org_admin()`,
-- au corps inchangé, et une nouvelle `est_admin_organisation()` portant le corps
-- corrigé. En 77b j'ai supprimé la nouvelle et renommé l'ancienne — c'est-à-dire
-- que j'ai gardé le corps périmé. Il lisait `profils.is_org_admin`, colonne
-- renommée en `profils.est_admin_organisation`.
--
-- Conséquence visible : cinq vérifications de la suite « portabilité » en échec,
-- avec `column "is_org_admin" does not exist`. Ce sont elles qui l'ont attrapé —
-- ni la compilation TypeScript, ni le renommage lui-même ne pouvaient le voir.
--
-- Le choix de 77b restait le bon : c'est l'ancienne fonction que quarante-quatre
-- politiques RLS référencent par identifiant interne, et la renommer les fait
-- suivre. Seul le corps était à reprendre.
--
-- La colonne et la fonction portent maintenant le même nom. PostgreSQL les
-- distingue sans peine, mais on qualifie la colonne pour que le lecteur aussi.

set search_path = public;

create or replace function public.est_admin_organisation()
returns boolean language sql stable security definer set search_path to 'public'
as $fn$
  select coalesce(
    (select p.est_admin_organisation from profils p where p.id = auth.uid()),
    false);
$fn$;

revoke execute on function public.est_admin_organisation() from public, anon;
grant  execute on function public.est_admin_organisation() to authenticated;
