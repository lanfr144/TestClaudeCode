-- 46 — Durcissement des droits d'exécution après les migrations 40 à 45e
--
-- Note de numérotation
-- --------------------
-- Cette migration porte le numéro 46 et non 45 : la base déployée compte déjà
-- des migrations nommées `45`, `45b`, `45c`, `45d` et `45e` — cinq correctifs de
-- la portabilité appliqués directement, sans fichier correspondant dans le dépôt
-- jusqu'à leur reconstitution. Voir `docs/ecarts-a-corriger.md`.
--
-- Constat
-- -------
-- La migration 16 avait révoqué `execute` pour `anon` et `public` sur toutes les
-- fonctions *existant à cette date*, puis posé un `alter default privileges`.
-- Ce garde-fou n'a pas tenu : PostgreSQL accorde `execute` à PUBLIC à la création
-- de toute fonction, et le `alter default privileges` ne vaut que pour le rôle qui
-- l'a émis — or les fonctions appartiennent à `postgres`.
--
-- Conséquence observée sur le déploiement : seize fonctions créées par les
-- migrations 40 à 45e portaient `=X/postgres` dans leur ACL, c'est-à-dire
-- **execute pour PUBLIC**, dont `anon` hérite. Parmi elles les six points d'entrée
-- de la portabilité, tous en `security definer` :
--
--   fn_export_self, fn_export_employee, fn_export_company,
--   fn_export_organization, fn_export_referential, fn_import_referential
--
-- Ces six-là contrôlent l'accès dans leur corps (`auth.uid()`, `has_company_access`,
-- `is_org_admin`) et échouent donc en position fermée pour un appelant anonyme : la
-- porte n'était pas ouverte. Mais elle ne tenait plus que par un seul verrou, alors
-- que l'architecture en suppose deux — le droit d'appeler, puis le contrôle interne.
-- C'est cette seconde barrière que la présente migration rétablit.
--
-- Trois fonctions de déclencheur (`fn_child_privacy`, `fn_document_expiry`,
-- `fn_sync_part_time`) et un utilitaire interne (`fn_payload_rows`) étaient
-- également appelables en RPC : elles ne le sont plus par personne.

-- ---------------------------------------------------------------------------
-- 1. Remise à plat : personne, sauf les comptes authentifiés
-- ---------------------------------------------------------------------------

revoke execute on all functions in schema public from public, anon;
grant  execute on all functions in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Ce que même un compte authentifié ne doit jamais appeler directement
-- ---------------------------------------------------------------------------

-- Primitives de chiffrement : seules les fonctions du moteur les invoquent.
revoke execute on function fn_encrypt_field(text)  from authenticated, anon, public;
revoke execute on function fn_decrypt_field(bytea) from authenticated, anon, public;

-- Fonctions de déclencheur : appelées par PostgreSQL, jamais par l'API.
revoke execute on function fn_audit()               from authenticated, anon, public;
revoke execute on function handle_new_user()        from authenticated, anon, public;
revoke execute on function fn_trim_param_scale()    from authenticated, anon, public;
revoke execute on function fn_check_cba_not_worse() from authenticated, anon, public;
revoke execute on function fn_child_privacy()       from authenticated, anon, public;
revoke execute on function fn_document_expiry()     from authenticated, anon, public;
revoke execute on function fn_sync_part_time()      from authenticated, anon, public;

-- Administration du référentiel : hors API applicative.
revoke execute on function fn_generate_public_holidays(int) from authenticated, anon, public;

-- Utilitaires internes de la portabilité : la migration 44 en révoquait deux,
-- le troisième avait été oublié.
revoke execute on function fn_rows_json(text, text, uuid) from authenticated, anon, public;
revoke execute on function fn_cba_by_code(text, uuid)     from authenticated, anon, public;
revoke execute on function fn_payload_rows(jsonb)         from authenticated, anon, public;

-- ---------------------------------------------------------------------------
-- 3. `search_path` figé partout où il manquait
-- ---------------------------------------------------------------------------
-- Un `search_path` mutable laisse un appelant détourner la résolution des noms.
-- Sans conséquence sur une fonction `security invoker`, mais la règle vaut pour
-- toutes : elle ne souffre pas d'exception à retenir.

alter function fn_payload_rows(jsonb)   set search_path = public;
alter function fn_child_privacy()       set search_path = public;
alter function fn_document_expiry()     set search_path = public;
alter function fn_sync_part_time()      set search_path = public;

-- ---------------------------------------------------------------------------
-- 4. Que la prochaine migration n'ait plus à y penser
-- ---------------------------------------------------------------------------
-- Émis pour le rôle propriétaire des objets, faute de quoi la règle ne s'applique
-- pas — c'est précisément l'erreur qui a produit le constat ci-dessus.

alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon;

-- ---------------------------------------------------------------------------
-- 5. `app_secrets` : RLS sans politique, et c'est voulu
-- ---------------------------------------------------------------------------
-- L'analyseur Supabase signale « RLS enabled, no policy ». L'absence de politique
-- est ici la protection : aucune ligne n'est lisible par l'API, et seules les
-- fonctions `security definer` du moteur atteignent la clé de chiffrement.

comment on table app_secrets is
  'Clés de chiffrement du moteur. RLS active et VOLONTAIREMENT sans aucune '
  'politique : aucune ligne n''est donc accessible par l''API REST. Seules les '
  'fonctions security definer fn_encrypt_field et fn_decrypt_field y accèdent, '
  'et ces deux fonctions ne sont exécutables par personne hors du moteur.';
