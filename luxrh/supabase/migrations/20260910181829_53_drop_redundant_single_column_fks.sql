-- 53 — Retrait des clés étrangères simples devenues redondantes
--
-- Régression introduite par la migration 48, attrapée par la suite de tests dès
-- son application : 4 vérifications sur 154 seulement passaient.
--
-- En ajoutant des clés composites `(employee_id, company_id)` à côté des clés
-- simples `(employee_id)` déjà présentes, la migration 48 a créé **deux relations
-- PostgREST** entre les mêmes couples de tables. L'imbrication devient alors
-- ambiguë et la requête échoue :
--
--   employees?select=*,departments(name),contracts(...)
--   → {"code":"PGRST201", "details":[{"cardinality":"one-to-many",
--       "embedding":"employees with contracts",
--       "relationship":"contract_belongs_to_employees_company …"}, …]}
--
-- La clé composite **subsume strictement** la simple : mêmes colonnes plus
-- `company_id`, même `on delete cascade`. Retirer la simple ne perd donc aucune
-- intégrité référentielle — `(employee_id, company_id)` vers `(id, company_id)`
-- implique `employee_id` vers `employees.id` — et ne laisse qu'une seule relation
-- par couple, ce qui lève l'ambiguïté.
--
-- La leçon vaut d'être écrite : sur PostgREST, une clé étrangère n'est pas
-- seulement une contrainte d'intégrité, c'est une **arête du graphe de relations
-- exposé par l'API**. En ajouter une sans retirer l'ancienne change le contrat
-- d'interface sans toucher une ligne de front.

alter table absences              drop constraint absences_employee_id_fkey;
alter table contracts             drop constraint contracts_employee_id_fkey;
alter table employee_children     drop constraint employee_children_employee_id_fkey;
alter table employee_disabilities drop constraint employee_disabilities_employee_id_fkey;
alter table employee_statuses     drop constraint employee_statuses_employee_id_fkey;
alter table meal_voucher_grants   drop constraint meal_voucher_grants_employee_id_fkey;
alter table overtime_requests     drop constraint overtime_requests_employee_id_fkey;
alter table premiums              drop constraint premiums_employee_id_fkey;
alter table shifts                drop constraint shifts_employee_id_fkey;
alter table shifts                drop constraint shifts_schedule_id_fkey;
alter table time_entries          drop constraint time_entries_employee_id_fkey;

-- Contrôle : une seule relation par couple de tables, et l'imbrication repasse.
--
--   with composites as (
--     select conrelid, confrelid, conkey from pg_constraint
--     where connamespace = 'public'::regnamespace and contype = 'f'
--       and array_length(conkey, 1) = 2)
--   select s.conrelid::regclass, s.conname
--   from pg_constraint s join composites c
--     on c.conrelid = s.conrelid and c.confrelid = s.confrelid and s.conkey <@ c.conkey
--   where s.contype = 'f' and array_length(s.conkey, 1) = 1;
--   -- doit ne rien renvoyer
