# API serveur — les fonctions RPC

Ce document est le **contrat d'API** entre les fronts et le moteur. Il s'adresse aux développeurs
des deux applications : ce qu'on peut appeler, avec quels arguments, ce qui revient, qui l'appelle
aujourd'hui, et dans quelle migration la fonction est née.

Les fonctions sont appelées en HTTP `POST /rest/v1/rpc/<nom>`, avec le corps JSON des arguments
nommés. Côté React par `callEngine()` (`luxrh/src/lib/supabase.ts`), côté Python par `db.call()` —
mis en cache 60 secondes — ou `db.engine()` pour les écritures (`luxrh-py/luxrh/client.py`).

---

## Règles générales

**Toutes** les fonctions du moteur :

- vérifient l'accès de l'appelant avant de calculer (`has_company_access` ou `can_manage_company`) ;
- prennent une **date de référence** quand le résultat en dépend, avec `current_date` par défaut —
  un calcul daté du 15 mai 2026 lit les paramètres en vigueur au 15 mai 2026 ;
- sont `security definer` avec un `search_path` figé ;
- sont exécutables par le rôle `authenticated` et **par personne d'autre**. La migration 16 révoque
  `execute` pour `anon` et `public` sur tout le schéma, et fixe le privilège par défaut.

**Non exposées**, révoquées explicitement : `fn_encrypt_field`, `fn_decrypt_field`, `fn_audit`,
`handle_new_user`, `fn_trim_param_scale`, `fn_check_cba_not_worse`, `fn_generate_public_holidays`.

Sauf mention contraire, une fonction qui retourne `jsonb` retourne un objet, jamais un tableau nu.

Légende de la colonne **Appelée par** : ⚛️ React · 🐍 Streamlit · — aucun front (disponible et
testée, mais sans écran dédié aujourd'hui).

Légende de la colonne **Mig.** : le numéro de la migration qui a créé la fonction ou, entre
parenthèses, celles qui l'ont ensuite modifiée. Les migrations 46 à 56 sont **appliquées** ;
vérifié par requête sur `pg_proc` (hors extensions, schéma `public`) : **111 fonctions** sur le
projet Supabase à la date de cette page, dont 65 `security definer`.

---

## Référentiel et arbitrage

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_param` | `p_key text, p_on date = current_date` | La ligne `legal_parameters` en vigueur, valeur dérivée résolue | — (socle interne) | 02 |
| `fn_param_num` | `p_key text, p_on date = current_date` | `numeric` — la valeur seule | — (socle interne) | 02 |
| `fn_arbitrate` | `p_label text, p_law numeric, p_law_ref text, p_cba numeric, p_cba_ref text, p_contract numeric, p_higher_is_better boolean = true` | `jsonb` : les trois valeurs, la retenue, sa source et son article | — (appelée par le moteur) | 05 |
| `fn_referential_gaps` | `p_since date = '2019-12-31'` | Table : `family, param_key, label, earliest_covered, latest_covered, versions, covers_since, gap_days, read_by`. La colonne `read_by` et la source `expected_parameters` datent de la migration 50 (jointure `full outer join` : une clé que le moteur lit mais dont **aucune version n'est chargée** sort avec `versions = 0`, en tête de liste — l'ancienne version, qui groupait `legal_parameters`, ne pouvait pas la voir, faute de ligne à grouper) | ⚛️ 🐍 | 21 (50) |
| `fn_referential_holes` | — | Table : `param_key, gap_from, gap_to` | ⚛️ 🐍 | 21 |
| `fn_referential_inconsistencies` | `p_on date = current_date` | Table : `param_key, label, published, derived, difference, tolerance, source_key` | ⚛️ 🐍 | 22 |
| `fn_add_parameter_version` | `p_key text, p_valid_from date, p_value_num numeric, p_value_text text, p_value_json jsonb, p_source text = 'CCSS', p_index_ref numeric, p_note text` | La ligne `legal_parameters` créée. Clôture la précédente. Réservée à l'administrateur | ⚛️ 🐍 | 21 |
| `fn_validate_parameter_version` | `p_id uuid` | La ligne validée. **Refuse** si l'appelant est celui qui a saisi | — | 21 |

## Conventions collectives

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_applicable_cbas` | `p_contract uuid, p_on date = current_date` | Table des conventions applicables, avec leur portée et leur période | ⚛️ | 26 |
| `fn_cba_best_num` | `p_contract uuid, p_block cba_block, p_path text, p_on date, p_higher_is_better boolean = true` | `jsonb` — la meilleure valeur parmi toutes les conventions applicables | — | 26 |
| `fn_cba_value` | `p_cba uuid, p_block cba_block, p_path text` | `jsonb` — lecture brute d'une clause | — | 02 |
| `fn_cba_by_code` | `p_code text, p_org uuid` | `uuid` — résolution d'une CCT par clé naturelle, pour l'import | — (portabilité) | 44 |

## Contrat

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_contract_compliance` | `p_contract uuid, p_on date = current_date` | `jsonb` : contrôles (`code`, `severity`, `detail`, `legal_ref`), mentions obligatoires, arbitrages, `blocking_count`, `can_validate` | ⚛️ 🐍 | 05 (30, 31) |
| `fn_min_salary` | `p_contract uuid, p_on date = current_date` | `jsonb` : SSM applicable selon qualification, âge et grille CCT, prorata temps partiel | — (via `fn_contract_compliance`) | 05 (27) |
| `fn_probation` | `p_contract uuid, p_on date = current_date` | `jsonb` : fin d'essai, prolongation par maladie, **dernier jour utile pour notifier** | — (via `fn_contract_compliance`) | 05 |
| `fn_notice_period` | `p_contract uuid, p_notified_on date, p_by_employer boolean` | `jsonb` : préavis selon l'ancienneté, règle du 15 du mois | — | 05 |
| `fn_annual_leave_rule` | `p_contract uuid, p_on date = current_date` | `jsonb` : droit à congé annuel applicable | — (via le moteur) | 05 (27) |
| `fn_salary_reference` | `p_contract uuid, p_on date = current_date` | `jsonb` : fixe + part variable retenue comme référence salariale | — | 29 |
| `fn_can_terminate` | `p_contract uuid, p_reason text, p_on date = current_date, p_gross_misconduct boolean = false` | `jsonb` : `allowed`, `blockers[]`. Un délégué n'est licenciable que pour faute grave | — | 41 |
| `fn_end_of_contract_documents` | `p_contract uuid` | `jsonb` : ce qui reste à remettre au salarié, `outstanding` | ⚛️ | 34 |
| `fn_amend_contract` | `p_contract uuid, p_effective_date date, p_changes jsonb, p_reason text` | `jsonb` : `previous_contract_id`, `new_contract_id`, `version`, `effective_date`, `applied`, `pay_components_carried`, `collective_agreements_carried`. Clôt le contrat en cours la veille de la prise d'effet et en crée un nouveau — bâti par `to_jsonb(ancien) \|\| changements`, pour qu'aucune colonne ne soit oubliée — qui reprend les éléments de rémunération et les conventions encore en vigueur. Le contrat qui en résulte part **non signé**. Refuse un contrat non `active`, une prise d'effet antérieure ou égale au début du contrat, et un jeu de changements vide. Réservée à `can_manage_company` | — aucun front ne l'appelle encore | 55 |

## Planning et temps de travail

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_validate_schedule` | `p_schedule uuid` | `jsonb` : `violations[]` (gravité, code, titre, détail, article, salarié, date), résumé par salarié, `blocking_count`, `warning_count`, `can_publish` | ⚛️ 🐍 | 06 (11, 13, 38) |
| `fn_publish_schedule` | `p_schedule uuid` | `jsonb` : `published`. **Lève une exception** si une violation bloquante subsiste | ⚛️ 🐍 | 06 |
| `fn_reference_period_status` | `p_company uuid, p_on date = current_date` | `jsonb` : moyenne hebdomadaire sur la période de référence, cible, marge | ⚛️ | 06 |
| `fn_overtime_approve` | `p_request uuid, p_as_hr boolean` | La ligne `overtime_requests`. L'accord n'est acquis qu'après validation RH **et** acceptation du salarié | 🐍 | 41 |
| `fn_overtime_approved_hours` | `p_employee uuid, p_from date, p_to date` | `numeric` — heures couvertes par un accord préalable | — | 41 |
| `fn_overtime_eligibility` | `p_employee uuid, p_on date = current_date` | `jsonb` : mineur, grossesse, prime de réemploi — heures supplémentaires interdites | ⚛️ 🐍 | 32 |

## Congés, maladie, absences

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_leave_balance` | `p_employee uuid, p_on date = current_date` | `jsonb` : solde et détail ligne à ligne, source du droit | ⚛️ 🐍 | 06 (30) |
| `fn_sick_counters` | `p_employee uuid, p_on date = current_date` | `jsonb` : jours dans la fenêtre glissante, limite, fin de protection, certificats | ⚛️ 🐍 | 06 (14) |
| `fn_leave_request_impact` | `p_employee uuid, p_type uuid, p_start date, p_end date` | `jsonb` : impact de la demande avant envoi, droit applicable à la date | ⚛️ 🐍 | 06 (33) |
| `fn_absence_entitlement` | `p_type uuid, p_on date = current_date` | La ligne `absence_entitlements` en vigueur à la date | — | 33 |
| `fn_disability_extra_leave` | `p_employee uuid, p_on date = current_date` | `jsonb` : `applies`, `rate_pct`, `extra_days` | 🐍 | 40 |

## Effectifs, licenciement collectif, vigilance

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_headcount` | `p_company uuid, p_on date = current_date` | `jsonb` : effectif présent et **moyenne sur 12 mois** | — (via `fn_headcount_obligations`) | 07 |
| `fn_headcount_obligations` | `p_company uuid, p_on date = current_date` | `jsonb` : effectif, seuils 15 / 100 / 150 / 250, mode de scrutin | ⚛️ 🐍 | 07 |
| `fn_collective_dismissal_counters` | `p_company uuid, p_on date = current_date` | `jsonb` : compteurs glissants 30 et 90 jours, date de libération | ⚛️ 🐍 | 07 |
| `fn_simulate_collective_dismissal` | `p_company uuid, p_count int, p_date date, p_personal_ground boolean = false` | `jsonb` : verdict, alternatives, chronologie complète de la procédure | ⚛️ 🐍 | 07 |
| `fn_compliance_scan` | `p_company uuid, p_on date = current_date` | `jsonb` : `overdue[]`, `due_soon[]`, `watch[]`, plus `headcount` et `dismissal_counters` | ⚛️ 🐍 | 07 (35, 36) |
| `fn_company_absenteeism` | `p_company uuid, p_year int` | `jsonb` : taux d'absentéisme, classe Mutualité suggérée | ⚛️ | 37 |
| `fn_delegation_eligibility` | `p_employee uuid, p_on date = current_date` | `jsonb` : ancienneté, âge, exclusion du personnel de direction | ⚛️ 🐍 | 32 |
| `fn_dismissal_protections` | `p_employee uuid, p_on date = current_date` | `jsonb` : maladie, grossesse, mandat de délégué, réunies | ⚛️ 🐍 | 32 |

## Société, salarié

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_company_rates` | `p_company uuid, p_on date = current_date` | `jsonb` : classe d'activité, classe Mutualité, facteur accident **à la date**, plus depuis la migration 50 : `accident_rate_source` (`classe` ou `base`), `complete`, `missing_parameters[]` et un `message`. Ne se rabat plus **en silence** sur le taux d'accident de base quand `accident_class_rates` n'est pas chargée — le repli demeure, mais il est désormais nommé, voir [moteur-de-regles.md](moteur-de-regles.md) | ⚛️ 🐍 | 23 (50) |
| `fn_set_company_rates` | `p_company uuid, p_from date, p_mutuality_class smallint, p_accident_factor numeric, p_activity_class text, p_accident_risk_class text, p_note text` | La ligne `company_rate_periods` créée | ⚛️ 🐍 | 23 |
| `fn_employee_sensitive` | `p_employee uuid` | Table `(national_id text, iban text)` — **déchiffrement** contrôlé | ⚛️ 🐍 | 03 |
| `fn_set_employee_sensitive` | `p_employee uuid, p_national_id text, p_iban text` | `void` — chiffre et enregistre. Valide le matricule | ⚛️ | 03 (24) |
| `fn_is_qualified` | `p_employee uuid, p_on date = current_date` | `jsonb` : qualification déclarée **ou** acquise par l'ancienneté de carrière, avec `source` | ⚛️ 🐍 | 27 |
| `fn_employee_age` | `p_employee uuid, p_on date = current_date` | `numeric` | — (via le moteur) | 27 |
| `fn_employee_children` | `p_employee uuid, p_on date = current_date` | `jsonb` : `count`, `gift_eligible_count`, droits associés | 🐍 | 40 |
| `fn_check_national_id` | `p_id text, p_birth date, p_sex sex_kind` | `jsonb` : `errors[]` nommant chaque échec — date encodée, parité du sexe, clés de Luhn et de Verhoeff | — | 24 |

## Rémunération et fiscalité

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_income_tax` | `p_taxable numeric, p_class tax_class, p_on date = current_date, p_periodicity tax_periodicity = 'monthly'` | `jsonb` : tranche, impôt de base, taux sur le dépassement. **`found: false`** tant que `tax_brackets` est vide | — | 37 |
| `fn_commute_allowance` | `p_km numeric, p_on date = current_date` | `jsonb` : barème de frais de déplacement | — | 37 |
| `fn_meal_voucher_check` | `p_grant uuid` | `jsonb` : valeur faciale et participation du salarié face aux plafonds, `warning_count` | 🐍 | 41 |
| `fn_premium_caps` | `p_company uuid, p_year int` | `jsonb` : plafond individuel (30 % du brut annuel), enveloppe (7,5 % du bénéfice N-1), dépassements par salarié | 🐍 | 42 |
| `fn_premium_check` | `p_premium uuid` | `jsonb` : contrôle d'une prime isolée | — | 42 |

## Jours fériés

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_holiday_summary` | `p_year int, p_cba uuid = null` | `jsonb` : `declared`, `distinct_dates`, `recoverable` | — | 25 |
| `fn_is_public_holiday` | `p_date date, p_cba uuid = null` | `boolean` | — (via le moteur) | 02 |
| `fn_generate_public_holidays` | `p_year int` | `setof public_holidays` — 11 fériés, fêtes mobiles, collisions et récupérations. **Non exposée** : administration du référentiel | — | 02 (25) |

## Portabilité — migration 44

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_export_self` | — | `jsonb` — enveloppe `luxrh.export/1`, `kind: employee`. Matricule et IBAN **déchiffrés** : un export illisible ne satisferait pas le droit d'accès | ⚛️ 🐍 | 44 |
| `fn_export_employee` | `p_employee uuid` | Le dossier d'un salarié. Refuse à un salarié qui demande celui d'un collègue | ⚛️ | 44 |
| `fn_export_company` | `p_company uuid` | Le dossier complet d'une société | ⚛️ 🐍 | 44 |
| `fn_export_organization` | — | La fiduciaire entière. Réservée à l'administrateur | ⚛️ 🐍 | 44 |
| `fn_export_referential` | — | Paramètres légaux datés, barèmes, catalogues et CCT, en **clés naturelles** sans identifiant technique | ⚛️ 🐍 | 44 |
| `fn_import_referential` | `p_document jsonb, p_mode text = 'skip_existing'` | `jsonb` : `added`, `replaced`, `skipped`, `rejected[]`, `message`. Refuse un format ou un genre étranger, en le nommant | ⚛️ 🐍 | 44 |

## Traçabilité des accès (RGPD) — migrations 46, 49, 51

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_request_source` | — | `jsonb` : `ip`, `user_agent`, `request_id`, lus dans les en-têtes HTTP exposés par PostgREST. Ne lève jamais d'erreur, renvoie des champs nuls hors contexte HTTP | — (interne, révoquée pour tous les rôles y compris `authenticated`) | 49 |
| `fn_log_access` | `p_subject_employee uuid, p_entity_table text, p_entity_id uuid, p_action text, p_scope text = null, p_row_count integer = null` | `void` — insère une ligne dans `data_access_log`, `action` parmi `READ / DECRYPT / EXPORT / DOWNLOAD` | — (interne, révoquée pour tous les rôles ; appelée par `fn_employee_sensitive` et `fn_set_travel_distance`) | 49 |
| `fn_redact_encrypted` | `p_row jsonb` | `jsonb` — remplace la valeur de toute colonne dont le nom finit par `_enc` par `"[chiffré]"` | — (interne, révoquée pour tous les rôles ; appelée par `fn_audit` avant d'écrire dans `audit_log`) | 49 |
| `fn_person_access_report` | `p_employee uuid, p_from timestamptz = null, p_to timestamptz = null` | Table `(quand, qui, qui_id, quoi, detail, nature, d_ou, agent, requete)` — union de `data_access_log`, `audit_log` et `export_log` pour une personne. Réservée à ses gestionnaires et à elle-même | — aucun front ne l'appelle encore | 49 |
| `fn_log_access_autonomous` | `p_subject_employee uuid, p_company uuid, p_entity_table text, p_entity_id uuid, p_action text, p_scope text = null, p_row_count integer = 1` | `void` — écrit la trace par `dblink`, hors de la transaction appelante (`is_autonomous = true`) ; retombe en écriture dans la transaction courante, en le déclarant (`is_autonomous = false`), si `app_secrets.dblink_conninfo` est absent | — (interne, révoquée pour tous les rôles ; appelée par `fn_employee_rows` et `fn_time_entry_rows`) | 51 |
| `fn_employee_rows` | `p_company uuid = null, p_department uuid = null, p_employee uuid = null, p_search text = null, p_active_on date = null, p_fields text[] = ['first_name','last_name'], p_limit integer = 500` | `setof employee_row` — lecture pipelinée : chaque ligne est contrôlée (accès société, droit renforcé pour `national_id`/`iban`), tracée hors transaction, **puis** émise. Refuse un appel sans `p_company` ni `p_employee` | — aucun front ne l'appelle encore | 51 |
| `fn_time_entry_rows` | `p_employee uuid, p_from date, p_to date, p_only_validated boolean = false, p_limit integer = 1000` | `setof time_entry_row` — même patron que `fn_employee_rows`, borné à une période explicite (`p_from`/`p_to` obligatoires) | — aucun front ne l'appelle encore | 51 |

**Vérifié sur la base déployée** : `data_access_log` porte déjà deux lignes `action = 'DECRYPT'`,
écrites pendant l'exécution de la suite de tests elle-même, sans qu'aucun code applicatif ait été
modifié pour cela. Les deux portent `is_autonomous = false`, faute de `dblink_conninfo` chargée dans
`app_secrets` — la trace survit tant que la transaction appelante n'est pas annulée, pas au-delà.

Aucun front n'appelle encore `fn_person_access_report`, `fn_employee_rows` ni `fn_time_entry_rows` :
c'est un écart réel, pas un défaut d'installation, et la suite de tests ne les couvre pas non plus
spécifiquement aujourd'hui — voir [tests-et-qualite.md](tests-et-qualite.md).

## Lieux d'intervention et distances — migration 52

Aucune de ces fonctions n'est appelée par un écran aujourd'hui. Le paramètre
`mileage_allowance_eur_per_km` qu'elles supposent est déclaré dans `expected_parameters` mais
**aucune valeur n'est chargée** : `fn_shift_travel` et `fn_schedule_travel` renvoient `found: false`
tant qu'il manque.

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_address_of` | `p_ref text` (`employee:<uuid>`, `company:<uuid>` ou `site:<uuid>`) | `jsonb` — adresse résolue sous le contrôle d'accès habituel, ou `found: false` si aucune adresse n'est enregistrée | — aucun front ; appelée par l'Edge Function `travel-distance` | 52 |
| `fn_travel_distance` | `p_origin text, p_destination text` | `jsonb` — distance en cache (symétrique origine/destination), `found: false` si le couple n'a jamais été calculé | — aucun front ; appelée par l'Edge Function `travel-distance` et par `fn_shift_travel` | 52 |
| `fn_set_travel_distance` | `p_origin text, p_destination text, p_km numeric, p_minutes integer, p_source text, p_note text = null` | `jsonb` : `ok`. Exige une source non vide, exige `can_manage_company`, trace la transmission de l'adresse dans `data_access_log` (action `DOWNLOAD`) | — aucun front ; appelée par l'Edge Function `travel-distance` | 52 |
| `fn_shift_travel` | `p_shift uuid` | `jsonb` : distances domicile→site et domicile→siège, excédent aller-retour, montant au tarif `mileage_allowance_eur_per_km`, ou `found: false` nommant ce qui manque | — aucun front ne l'appelle encore | 52 |
| `fn_schedule_travel` | `p_schedule uuid` | `jsonb` : somme des dépassements du planning (`total_amount`), détail par vacation, `incomplete_count` | — aucun front ne l'appelle encore | 52 |

Aucun test ne couvre encore spécifiquement `fn_shift_travel` ni `fn_schedule_travel` — voir
[tests-et-qualite.md](tests-et-qualite.md).

## Adresses — migration 56

Trois fonctions, dont une seule est appelable directement ; la quatrième (`fn_check_address`) est le
corps du déclencheur `check_address`, posé sur `employees`, `companies` et `client_sites` — elle
figure ici pour mémoire, elle n'est pas exposée en RPC.

| Fonction | Arguments | Retour | Appelée par | Mig. |
|---|---|---|---|---|
| `fn_validate_address` | `p_country text, p_postal text, p_city text = null` | `jsonb` : `status` parmi `ok` / `outside` / `unknown`, jamais un booléen. `ok` porte la `zone` et sa `source` ; `outside` porte les zones autorisées du pays ; `unknown` porte un message expliquant pourquoi rien ne peut être conclu | — aucun front ne l'appelle encore ; appelée par `fn_check_address` | 56 |
| `fn_postal_number` | `p_country text, p_postal text` | `integer` — le code postal réduit à son nombre, préfixe pays et séparateurs retirés (`immutable`, sans accès à une table) | — (socle interne, utilisée par `fn_validate_address`) | 56 |
| `fn_check_address()` | — (déclencheur) | `trigger` — valide `new`, refuse un verdict `outside` (exception), enregistre le verdict dans `address_checks`. Ne revalide que si l'adresse a changé par rapport à `old` ; ne regarde jamais une autre ligne que celle écrite. **Non exposée**, révoquée pour tous les rôles y compris `authenticated` | — (interne, posée sur `employees`, `companies`, `client_sites`) | 56 |

Aucun écran, React ou Streamlit, n'appelle `fn_validate_address` directement aujourd'hui : la seule
validation en vigueur passe par le déclencheur, à l'écriture d'une adresse. Aucune suite de tests ne
couvre spécifiquement ces trois fonctions ni la contrainte d'exclusion `one_active_contract_at_a_time`
de la migration 55 — voir [tests-et-qualite.md](tests-et-qualite.md).

## Contrôle d'accès et utilitaires

Ces fonctions sont appelées par le moteur, pas par les fronts. Elles figurent ici parce qu'elles
sont le socle de l'isolation.

| Fonction | Retour | Rôle |
|---|---|---|
| `auth_org_id()` | `uuid` | L'organisation de l'appelant |
| `is_org_admin()` | `boolean` | Administrateur de l'espace |
| `has_role(p_role app_role, p_company uuid)` | `boolean` | Rôle sur une société ou sur tout l'espace |
| `has_company_access(p_company uuid)` | `boolean` | Lecture autorisée |
| `can_manage_company(p_company uuid)` | `boolean` | Écriture autorisée |
| `is_self_employee(p_employee uuid)` | `boolean` | L'appelant est ce salarié |
| `has_shift_in_schedule` · `schedule_is_published` | `boolean` | Évitent la récursion entre politiques `schedules` / `shifts` (migration 18) |
| `fn_seed_demo()` | `jsonb` | Charge le jeu de démonstration. ⚛️ 🐍 |
| `fn_fmt(numeric)` | `text` | Formatage francophone des nombres dans les messages du moteur |
| `fn_rows_json` · `fn_payload_rows` | — | Utilitaires internes de la portabilité |

---

## Écarts relevés entre le moteur et les fronts

Ces fonctions sont exposées et fonctionnelles, mais **aucun écran ne les appelle** aujourd'hui.
Elles sont pour la plupart couvertes par `tests/api.test.mjs`.

`fn_notice_period` · `fn_salary_reference` · `fn_can_terminate` · `fn_income_tax` ·
`fn_commute_allowance` · `fn_holiday_summary` · `fn_check_national_id` ·
`fn_overtime_approved_hours` · `fn_premium_check` · `fn_validate_parameter_version` ·
`fn_absence_entitlement` · `fn_cba_best_num` · `fn_cba_value` · `fn_amend_contract` ·
`fn_validate_address`

Et ces fonctions ne sont appelées que d'un seul côté :

| Fonction | Seulement dans |
|---|---|
| `fn_applicable_cbas`, `fn_company_absenteeism`, `fn_end_of_contract_documents`, `fn_reference_period_status`, `fn_set_employee_sensitive`, `fn_export_employee` | React |
| `fn_disability_extra_leave`, `fn_employee_children`, `fn_meal_voucher_check`, `fn_overtime_approve`, `fn_premium_caps` | Streamlit |

Ce n'est pas un défaut du moteur : les deux interfaces n'ont simplement pas encore le même
périmètre d'écrans. Le point est signalé ici pour qu'il soit choisi, et non subi.

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [moteur-de-regles.md](moteur-de-regles.md) — ce que ces fonctions calculent, et pourquoi
- [architecture.md](architecture.md) — le trajet d'un appel de bout en bout
- [modele-de-donnees.md](modele-de-donnees.md) — les tables que ces fonctions lisent
- [tests-et-qualite.md](tests-et-qualite.md) — comment chaque fonction est vérifiée
- [ecarts-a-corriger.md](ecarts-a-corriger.md) — l'historique de migrations à réparer et les fonctions sans écran
