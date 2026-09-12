-- 57 — Reprise des adresses déjà en base
--
-- Le déclencheur `check_address` posé par la migration 56 ne se déclenche qu'à
-- l'écriture : les lignes déjà présentes n'ont jamais été soumises à la
-- validation. Sans cette reprise, `address_checks` resterait vide et l'on
-- croirait, à tort, n'avoir aucune adresse douteuse — le contraire exact de ce
-- que ce registre est censé montrer.
--
-- La reprise n'écrit que le verdict. Elle ne modifie aucune adresse et ne refuse
-- rien : une adresse hors zone déjà enregistrée est consignée comme telle, à
-- traiter, plutôt que supprimée. Corriger des données existantes est une
-- décision métier, pas un effet de bord de migration.
--
-- Ce que la reprise a révélé
-- --------------------------
--   ok       17  · Luxembourg 13, Moselle 3, province de Luxembourg 1
--   unknown 309  · dont 308 salariés **sans aucun code postal**
--                · et 1 adresse allemande, en attente des bornes postales
--
-- Autrement dit : sur 317 salariés, **9 seulement portent un code postal**. Le
-- reste du jeu de démonstration n'a pas d'adresse du tout. Ce n'est pas un
-- défaut de la validation, c'est ce qu'elle est faite pour rendre visible.

insert into address_checks (entity_table, entity_id, company_id, country,
                            postal_code, status, zone_code, message)
select 'employees', e.id, e.company_id, e.country, e.postal_code,
       v.verdict ->> 'status', v.verdict ->> 'zone', v.verdict ->> 'message'
from employees e
cross join lateral (select fn_validate_address(e.country, e.postal_code, e.city) as verdict) v
where e.country is not null or e.postal_code is not null
on conflict (entity_table, entity_id) do update
  set status = excluded.status, zone_code = excluded.zone_code,
      message = excluded.message, checked_at = now();

insert into address_checks (entity_table, entity_id, company_id, country,
                            postal_code, status, zone_code, message)
select 'companies', c.id, c.id, c.country, c.postal_code,
       v.verdict ->> 'status', v.verdict ->> 'zone', v.verdict ->> 'message'
from companies c
cross join lateral (select fn_validate_address(c.country, c.postal_code, c.city) as verdict) v
where c.country is not null or c.postal_code is not null
on conflict (entity_table, entity_id) do update
  set status = excluded.status, zone_code = excluded.zone_code,
      message = excluded.message, checked_at = now();

insert into address_checks (entity_table, entity_id, company_id, country,
                            postal_code, status, zone_code, message)
select 'client_sites', s.id, s.company_id, s.country, s.postal_code,
       v.verdict ->> 'status', v.verdict ->> 'zone', v.verdict ->> 'message'
from client_sites s
cross join lateral (select fn_validate_address(s.country, s.postal_code, s.city) as verdict) v
where s.country is not null or s.postal_code is not null
on conflict (entity_table, entity_id) do update
  set status = excluded.status, zone_code = excluded.zone_code,
      message = excluded.message, checked_at = now();

-- Contrôle, à rejouer après toute reprise de données :
--   select status, zone_code, count(*) from address_checks group by 1, 2 order by 3 desc;
--   select country, left(message, 60), count(*) from address_checks
--    where status = 'unknown' group by 1, 2 order by 3 desc;
