
-- Convention transversale, applicable en plus de la convention sectorielle.
insert into collective_agreements
  (organization_id, code, name, sector, scope, valid_from, valid_to, is_active)
values (null,'HARC-2024','Accord national harcèlement et violence au travail',
        'Interprofessionnel','harassment','2024-01-01', null, true)
on conflict do nothing;

insert into cba_rules (collective_agreement_id, block, rules, is_complete)
select id, 'premiums',
  '{"prevention_referent_required": true, "annual_information_session": true}'::jsonb, true
from collective_agreements where code = 'HARC-2024'
on conflict do nothing;

create or replace function fn_seed_demo()
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare
  v_org uuid; horeca uuid; sas uuid; gard uuid; harc uuid;
  bg uuid; cs uuid; gl uuid; mt uuid;
  dep_salle uuid; dep_cuisine uuid; agency uuid;
  sched uuid; t_midi uuid; t_soir uuid; t_cuisine uuid; t_bar uuid; t_accueil uuid;
  e_marta uuid; e_jonas uuid; e_aicha uuid; e_tomas uuid; e_lena uuid; e_paulo uuid;
  c_aicha uuid; c_tmp uuid; e_tmp uuid;
  at_leave uuid; at_sick uuid; at_birth uuid;
  dt_medical uuid; dt_record uuid;
  wk date := date '2026-10-12';
  i int; nm text;
  first_names text[] := array['Ana','Luc','Marie','Pedro','Sarah','Tom','Nina','Yves','Clara','Hugo','Léa','Marc','Julia','Paul','Emma','Nico','Rita','Sven','Alice','Bruno'];
  last_names  text[] := array['Muller','Schmit','Weber','Hoffmann','Wagner','Klein','Reuter','Thill','Kremer','Braun','Faber','Simon','Meyer','Jung','Diederich','Kieffer','Origer','Steffen','Pauly','Zimmer'];
begin
  select organization_id into v_org from profiles where id = auth.uid();
  if v_org is null then raise exception 'Aucun espace de travail'; end if;
  if not is_org_admin() then raise exception 'Réservé à l''administrateur de l''espace'; end if;
  if exists (select 1 from companies where organization_id = v_org) then
    raise exception 'Des sociétés existent déjà dans cet espace : le jeu de démonstration ne peut pas être chargé.';
  end if;

  update organizations set name = 'Fiduciaire Weiland & Associés', kind = 'fiduciary' where id = v_org;

  select id into horeca from collective_agreements where code = 'HORECA-2025';
  select id into sas    from collective_agreements where code = 'SAS-2025';
  select id into gard   from collective_agreements where code = 'GARD-2025';
  select id into harc   from collective_agreements where code = 'HARC-2024';
  select id into at_leave from absence_types where code = 'annual_leave';
  select id into at_sick  from absence_types where code = 'sick';
  select id into at_birth from absence_types where code = 'birth';
  select id into dt_medical from document_types where code = 'medical_periodic';
  select id into dt_record  from document_types where code = 'criminal_record';

  -- ---------------- Sociétés ----------------
  insert into companies(organization_id, legal_name, legal_form, rcs_number, ccss_matricule,
      address_line, postal_code, city, nace_code, sector, reference_period_months)
  values (v_org,'Brasserie du Glacis Sàrl','Sàrl','B 214 887','2019241588312',
      '12 rue du Glacis','L-1628','Luxembourg','56.10','HORECA',4) returning id into bg;
  insert into companies(organization_id, legal_name, legal_form, rcs_number, ccss_matricule,
      address_line, postal_code, city, nace_code, sector, reference_period_months)
  values (v_org,'Clinique Sainte-Anne asbl','asbl','F 4 512','2004118872104',
      '5 rue Sainte-Anne','L-1424','Luxembourg','86.10','Aides et soins',4) returning id into cs;
  insert into companies(organization_id, legal_name, legal_form, rcs_number, ccss_matricule,
      address_line, postal_code, city, nace_code, sector, reference_period_months)
  values (v_org,'Guardian Lux SA','SA','B 178 043','2011339915607',
      '77 route d''Esch','L-1470','Luxembourg','80.10','Gardiennage',4) returning id into gl;
  insert into companies(organization_id, legal_name, legal_form, rcs_number, ccss_matricule,
      address_line, postal_code, city, nace_code, sector, reference_period_months)
  values (v_org,'Menuiserie Thill Sàrl','Sàrl','B 96 220','1998220043918',
      '3 Am Bongert','L-6971','Grevenmacher','16.23','Artisanat',4) returning id into mt;

  -- Taux historisés, avec un changement de classe pour montrer l'historique.
  insert into company_rate_periods(company_id, mutuality_class, accident_factor, activity_class, valid_from, valid_to)
  values (bg, 3, 1.00, 'HORECA', date '2019-01-01', date '2024-01-01');
  insert into company_rate_periods(company_id, mutuality_class, accident_factor, activity_class, valid_from, note)
  values (bg, 2, 1.00, 'HORECA', date '2024-01-01',
          'Reclassement en classe 2 après amélioration de l''absentéisme.');
  insert into company_rate_periods(company_id, mutuality_class, accident_factor, activity_class, valid_from)
  values (cs, 3, 1.10, 'Santé', date '2019-01-01'),
         (gl, 2, 1.35, 'Gardiennage', date '2019-01-01'),
         (mt, 1, 1.00, 'Artisanat', date '2019-01-01');

  -- Conventions applicables : sectorielle + accord harcèlement transversal.
  insert into company_collective_agreements(company_id, collective_agreement_id, valid_from) values
    (bg, horeca, date '2025-01-01'), (bg, harc, date '2024-01-01'),
    (cs, sas,    date '2025-01-01'), (cs, harc, date '2024-01-01'),
    (gl, gard,   date '2025-01-01');

  insert into departments(company_id, name, min_evening_coverage) values (bg,'Salle',2) returning id into dep_salle;
  insert into departments(company_id, name) values (bg,'Cuisine') returning id into dep_cuisine;

  insert into reference_periods(company_id, label, start_date, end_date, months)
  values (bg,'PRL 4 mois · sept → déc','2026-09-01','2026-12-31',4);

  insert into interim_agencies(organization_id, name, ccss_matricule, city)
  values (v_org, 'Randstad Luxembourg', '2001445566778', 'Luxembourg') returning id into agency;

  -- ---------------- Employés ----------------
  insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification,
      address_line, postal_code, city, country, email, department_id, career_start_date, profession)
  values
   (bg,'Marta','Ferreira','1988-04-12','female','resident','qualified','4 rue de Hollerich','L-1740','Luxembourg','LU','marta.ferreira@example.lu',dep_salle,'2008-09-01','Service en salle'),
   (bg,'Jonas','Klein','1999-11-03','male','resident','unqualified','9 rue de Bonnevoie','L-1260','Luxembourg','LU','jonas.klein@example.lu',dep_cuisine,'2021-01-01','Cuisine'),
   (bg,'Aïcha','Diallo','1994-03-18','female','frontalier_fr','qualified','21 rue de Metz','F-57100','Thionville','FR','aicha.diallo@example.fr',dep_salle,'2016-06-01','Réception'),
   (bg,'Tomás','Rocha','1991-07-26','male','resident','qualified','2 rue du Fort','L-1524','Luxembourg','LU','tomas.rocha@example.lu',dep_salle,'2013-03-01','Bar'),
   (bg,'Lena','Weber','1985-01-09','female','resident','qualified','14 Grand-Rue','L-6730','Grevenmacher','LU','lena.weber@example.lu',dep_cuisine,'2006-09-01','Cuisine'),
   (bg,'Paulo','Martins','1996-09-30','male','frontalier_fr','unqualified','7 rue Nationale','F-57970','Yutz','FR','paulo.martins@example.fr',dep_cuisine,'2019-05-01','Plonge'),
   (bg,'Sofia','Almeida','1993-05-14','female','resident','qualified','11 rue Michel Rodange','L-2430','Luxembourg','LU',null,dep_salle,'2014-02-01','Service en salle'),
   (bg,'Michel','Kremer','1979-12-02','male','resident','qualified','30 rue de Mamer','L-8081','Bertrange','LU',null,dep_cuisine,'2000-09-01','Cuisine'),
   (bg,'Elena','Petrova','1997-02-21','female','frontalier_be','qualified','5 rue de l''Étoile','B-6700','Arlon','BE',null,dep_salle,'2018-03-01','Service en salle'),
   (bg,'Karim','Benali','1995-08-08','male','frontalier_fr','unqualified','18 avenue Foch','F-57000','Metz','FR',null,dep_cuisine,'2013-01-01','Cuisine'),
   (bg,'Ana','Silva','1990-06-17','female','resident','unqualified','6 rue du Canal','L-4051','Esch-sur-Alzette','LU',null,dep_cuisine,'2011-04-01','Cuisine'),
   (bg,'Dragan','Ilic','1987-10-25','male','resident','qualified','23 rue de Neudorf','L-2222','Luxembourg','LU',null,dep_salle,'2009-02-01','Bar'),
   (bg,'Julie','Hoffmann','1998-03-05','female','frontalier_de','unqualified','9 Trierer Str.','D-54294','Trier','DE',null,dep_salle,'2020-07-01','Accueil'),
   (bg,'Ricardo','Costa','1992-11-19','male','resident','qualified','1 rue de Strasbourg','L-2560','Luxembourg','LU',null,dep_salle,'2012-09-01','Service en salle');

  update employees e set
    national_id_enc  = fn_encrypt_field(fn_make_national_id(e.birth_date, abs(hashtext(e.id::text)) % 1000, e.sex)),
    national_id_hint = right(fn_make_national_id(e.birth_date, abs(hashtext(e.id::text)) % 1000, e.sex), 4),
    iban_enc = fn_encrypt_field('LU28 0019 4006 4475 0000')
  where e.company_id = bg;

  update employees set is_management = true where company_id = bg and last_name = 'Kremer';

  select id into e_marta from employees where company_id = bg and last_name = 'Ferreira';
  select id into e_jonas from employees where company_id = bg and last_name = 'Klein';
  select id into e_aicha from employees where company_id = bg and last_name = 'Diallo';
  select id into e_tomas from employees where company_id = bg and last_name = 'Rocha';
  select id into e_lena  from employees where company_id = bg and last_name = 'Weber';
  select id into e_paulo from employees where company_id = bg and last_name = 'Martins';

  insert into contracts(company_id, employee_id, kind, status, job_title, job_description, work_place,
      category, start_date, end_date, cdd_reason, renewal_count, monthly_gross, index_ref,
      weekly_hours, days_per_week, work_distribution, reference_period_months, night_work,
      annual_leave_days, break_minutes, non_compete_clause, probation_length, probation_unit, signed_at)
  select bg, e.id, v.kind::contract_kind, 'active', v.job, v.descr, '12 rue du Glacis, L-1628 Luxembourg',
      v.cat, v.startd, v.endd, v.reason, v.renew, v.gross, 992.24,
      v.hours, 5, '5 jours sur 7, horaires variables', 4, v.night, 28, 30, false, v.plen, v.punit, v.startd
  from employees e
  join (values
    ('Ferreira','cdi','Cheffe de rang','Encadrement du service en salle','B',date '2021-03-01',null::date,null::text,0,3650.00,40.0,true,3,'months'),
    ('Klein','cdd','Commis de cuisine','Préparation et mise en place','A',date '2025-04-01',date '2026-10-31','Accroissement temporaire d''activité',2,3350.00,40.0,false,null,null),
    ('Diallo','cdi','Réceptionniste','Accueil de la clientèle et réservations','B',date '2026-07-01',null,null,0,3400.00,40.0,false,3,'months'),
    ('Rocha','cdi','Barman','Service au bar','A',date '2022-06-01',null,null,0,3450.00,40.0,true,3,'months'),
    ('Weber','cdi','Sous-cheffe de cuisine','Second de cuisine','C',date '2019-09-01',null,null,0,3950.00,40.0,false,3,'months'),
    ('Martins','cdi','Plongeur','Plonge et entretien','A',date '2023-02-01',null,null,0,1750.00,20.0,false,3,'months'),
    ('Almeida','cdi','Serveuse','Service en salle','A',date '2022-01-10',null,null,0,3480.00,40.0,true,3,'months'),
    ('Kremer','cdi','Chef de cuisine','Direction de la cuisine','C',date '2018-05-01',null,null,0,4250.00,40.0,false,3,'months'),
    ('Petrova','cdi','Serveuse','Service en salle','A',date '2024-03-01',null,null,0,2600.00,30.0,true,3,'months'),
    ('Benali','cdi','Commis de cuisine','Préparation','A',date '2023-11-01',null,null,0,3420.00,40.0,false,3,'months'),
    ('Silva','cdi','Aide de cuisine','Aide à la préparation','A',date '2021-08-01',null,null,0,3520.00,40.0,false,3,'months'),
    ('Ilic','cdi','Barman','Service au bar','A',date '2020-02-01',null,null,0,3550.00,40.0,true,3,'months'),
    ('Hoffmann','cdi','Hôtesse d''accueil','Accueil','A',date '2024-07-01',null,null,0,2100.00,24.0,false,3,'months'),
    ('Costa','cdi','Serveur','Service en salle','A',date '2022-09-01',null,null,0,3450.00,40.0,true,3,'months')
  ) as v(lname,kind,job,descr,cat,startd,endd,reason,renew,gross,hours,night,plen,punit)
    on v.lname = e.last_name
  where e.company_id = bg;

  select id into c_aicha from contracts where employee_id = e_aicha;

  insert into employee_tax_cards(employee_id, company_id, tax_class, monthly_allowance, valid_from, credits, commute_distance_km)
  select e.id, bg, case when e.residency = 'resident' then '1a' else '1' end::tax_class, 0, '2026-01-01',
         '["CIS"]'::jsonb, case when e.residency = 'resident' then 8 else 35 end
  from employees e where e.company_id = bg;

  -- Statuts protégés et documents, pour illustrer la vigilance.
  insert into employee_statuses(company_id, employee_id, kind, start_date, expected_birth_date, declared_on)
  values (bg, e_lena, 'pregnancy', date '2026-08-20', date '2027-02-14', date '2026-08-20');

  insert into documents(company_id, employee_id, name, storage_path, document_type_id, issued_on)
  values (bg, e_tomas, 'Visite médicale périodique', bg::text || '/' || e_tomas::text || '/medical.pdf',
          dt_medical, date '2024-10-01'),
         (bg, e_aicha, 'Extrait de casier judiciaire', bg::text || '/' || e_aicha::text || '/casier.pdf',
          dt_record, date '2026-05-01');

  -- Part variable de rémunération.
  insert into contract_pay_components(contract_id, company_id, kind, code, label, amount, basis,
      in_salary_reference, valid_from)
  select c.id, bg, 'variable', 'service_share', 'Part de service', 180.00,
         'pourcentage du service encaissé', true, c.start_date
  from contracts c where c.employee_id = e_marta;

  -- ---------------- Absences ----------------
  insert into absences(company_id, employee_id, absence_type_id, start_date, end_date, days_count,
      status, certificate_received, certificate_received_at, certificate_original_received)
  values (bg, e_aicha, at_sick, '2026-08-12','2026-08-15',4,'approved',true,'2026-08-13',true);
  insert into probation_extensions(contract_id, from_date, to_date, days_added)
  values (c_aicha,'2026-08-12','2026-08-15',4);

  insert into absences(company_id, employee_id, absence_type_id, start_date, end_date, days_count, status, decided_at)
  values (bg, e_aicha, at_leave,'2026-10-13','2026-10-14',2,'approved', now());

  insert into absences(company_id, employee_id, absence_type_id, start_date, end_date, days_count,
      status, certificate_received, declared_by_employee)
  values (bg, e_tomas, at_sick,'2026-09-01','2026-09-20',15,'approved',false,true);

  insert into absences(company_id, employee_id, absence_type_id, start_date, end_date, days_count, status, comment)
  values (bg, e_lena,  at_leave,'2026-10-19','2026-10-20',2,'pending','Vacances scolaires'),
         (bg, e_paulo, at_birth,'2026-10-05','2026-10-16',10,'pending','Naissance'),
         (bg, e_jonas, at_leave,'2026-12-24','2026-12-31',6,'pending','Fêtes de fin d''année');

  -- ---------------- Modèles de shifts ----------------
  insert into shift_templates(company_id, name, start_time, end_time, break_minutes, color, department_id)
  values (bg,'Service midi','11:00','15:00',0,'#017E84',dep_salle) returning id into t_midi;
  insert into shift_templates(company_id, name, start_time, end_time, break_minutes, color, department_id)
  values (bg,'Service soir','17:00','23:00',0,'#714B67',dep_salle) returning id into t_soir;
  insert into shift_templates(company_id, name, start_time, end_time, break_minutes, color, department_id)
  values (bg,'Cuisine','09:00','18:00',60,'#B7791F',dep_cuisine) returning id into t_cuisine;
  insert into shift_templates(company_id, name, start_time, end_time, break_minutes, color, department_id)
  values (bg,'Bar','16:00','24:00',30,'#5C3D54',dep_salle) returning id into t_bar;
  insert into shift_templates(company_id, name, start_time, end_time, break_minutes, color, department_id)
  values (bg,'Accueil','08:00','16:00',30,'#017E84',dep_salle) returning id into t_accueil;

  insert into schedules(company_id, department_id, week_start, label, status)
  values (bg, null, wk, 'Semaine 42 · 12 – 18 octobre 2026','draft') returning id into sched;

  insert into shifts(schedule_id, company_id, employee_id, shift_date, start_time, end_time, break_minutes, label, template_id)
  values
   (sched,bg,e_marta,wk+0,'11:00','15:00',0,'Service midi',t_midi),
   (sched,bg,e_marta,wk+0,'17:00','23:00',0,'Service soir',t_soir),
   (sched,bg,e_marta,wk+1,'17:00','23:30',0,'Service soir',t_soir),
   (sched,bg,e_marta,wk+2,'17:00','23:30',0,'Service soir',t_soir),
   (sched,bg,e_marta,wk+3,'07:00','15:00',30,'Service midi',t_midi),
   (sched,bg,e_marta,wk+4,'17:00','23:00',0,'Service soir',t_soir),
   (sched,bg,e_jonas,wk+0,'09:00','18:00',60,'Cuisine',t_cuisine),
   (sched,bg,e_jonas,wk+1,'09:00','18:00',60,'Cuisine',t_cuisine),
   (sched,bg,e_jonas,wk+2,'08:00','19:00',0,'Cuisine',t_cuisine),
   (sched,bg,e_jonas,wk+3,'09:00','18:00',60,'Cuisine',t_cuisine),
   (sched,bg,e_jonas,wk+4,'09:00','18:00',60,'Cuisine',t_cuisine),
   (sched,bg,e_aicha,wk+0,'08:00','16:00',30,'Accueil',t_accueil),
   (sched,bg,e_aicha,wk+3,'08:00','16:00',30,'Accueil',t_accueil),
   (sched,bg,e_aicha,wk+4,'08:00','16:00',30,'Accueil',t_accueil),
   (sched,bg,e_aicha,wk+5,'08:00','16:00',30,'Accueil',t_accueil),
   (sched,bg,e_tomas,wk+2,'16:00','24:00',30,'Bar',t_bar),
   (sched,bg,e_tomas,wk+3,'16:00','24:00',30,'Bar',t_bar),
   (sched,bg,e_tomas,wk+4,'16:00','24:00',30,'Bar',t_bar),
   (sched,bg,e_tomas,wk+5,'16:00','24:00',30,'Bar',t_bar),
   (sched,bg,e_tomas,wk+6,'16:00','24:00',30,'Bar',t_bar);

  -- ---------------- Licenciements pour motif non inhérent ----------------
  for i in 1..3 loop
    insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification)
    values (bg, (array['Bruno','Nathalie','Ali'])[i], (array['Marques','Roth','Yilmaz'])[i],
            date '1990-01-01' + i*37,
            (array['male','female','male'])[i]::sex_kind, 'resident','unqualified')
    returning id into e_tmp;
    insert into contracts(company_id, employee_id, kind, status, job_title, work_place, category,
        start_date, end_date, monthly_gross, index_ref, weekly_hours, annual_leave_days)
    values (bg, e_tmp,'cdi','ended','Serveur','12 rue du Glacis, L-1628 Luxembourg','A',
            date '2023-01-01', (array[date '2026-11-30', date '2026-12-31', date '2026-08-31'])[i],
            3450.00, 992.24, 40, 28)
    returning id into c_tmp;
    insert into contract_terminations(contract_id, company_id, reason, is_personal_ground, notified_on, notice_start, notice_end)
    values (c_tmp, bg,'licenciement_motif_economique', false,
            (array[date '2026-09-02', date '2026-09-05', date '2026-06-16'])[i],
            (array[date '2026-09-15', date '2026-10-01', date '2026-07-01'])[i],
            (array[date '2026-11-14', date '2026-11-30', date '2026-08-31'])[i]);
  end loop;

  -- ---------------- Autres dossiers ----------------
  for i in 1..84 loop
    nm := first_names[1 + (i % 20)];
    insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification)
    values (cs, nm, last_names[1 + ((i*7) % 20)], date '1980-01-01' + (i*97),
            (array['female','male'])[1 + (i % 2)]::sex_kind,
            (array['resident','frontalier_fr','frontalier_be','frontalier_de'])[1 + (i % 4)]::residency_kind,'qualified')
    returning id into e_tmp;
    insert into contracts(company_id, employee_id, kind, status, job_title, work_place, category,
        start_date, monthly_gross, index_ref, weekly_hours, annual_leave_days, night_work)
    values (cs, e_tmp,'cdi','active','Aide-soignant(e)','5 rue Sainte-Anne, L-1424 Luxembourg','C1',
            date '2020-01-01' + (i*11), 3600.00, 992.24, 40, 26, i % 3 = 0);
  end loop;

  for i in 1..212 loop
    nm := first_names[1 + (i % 20)];
    insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification)
    values (gl, nm, last_names[1 + ((i*13) % 20)], date '1978-01-01' + (i*61),
            (array['male','female'])[1 + (i % 2)]::sex_kind,
            (array['resident','frontalier_fr','frontalier_be','frontalier_de'])[1 + (i % 4)]::residency_kind,'unqualified')
    returning id into e_tmp;
    insert into contracts(company_id, employee_id, kind, status, job_title, work_place, category,
        start_date, monthly_gross, index_ref, weekly_hours, annual_leave_days, night_work)
    values (gl, e_tmp,'cdi','active','Agent de sécurité','77 route d''Esch, L-1470 Luxembourg','Agent',
            date '2019-01-01' + (i*7), 3000.00, 992.24, 40, 26, i % 2 = 0);
  end loop;

  for i in 1..9 loop
    nm := first_names[1 + (i % 20)];
    insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification)
    values (mt, nm, last_names[1 + ((i*3) % 20)], date '1985-01-01' + (i*151),
            (array['male','female'])[1 + (i % 2)]::sex_kind, 'resident','qualified')
    returning id into e_tmp;
    insert into contracts(company_id, employee_id, kind, status, job_title, work_place,
        start_date, monthly_gross, index_ref, weekly_hours, annual_leave_days)
    values (mt, e_tmp,'cdi','active','Menuisier','3 Am Bongert, L-6971 Grevenmacher',
            date '2018-01-01' + (i*211), 3600.00, 992.24, 40, 26);
  end loop;

  -- Un contrat de mission, chez le client gardiennage.
  insert into employees(company_id, first_name, last_name, birth_date, sex, residency, qualification)
  values (gl,'Diogo','Ferreira', date '1995-04-04','male','frontalier_fr','unqualified')
  returning id into e_tmp;
  insert into contracts(company_id, employee_id, kind, status, job_title, work_place, category,
      start_date, end_date, monthly_gross, index_ref, weekly_hours, annual_leave_days,
      interim_agency_id, user_company_name, mission_reason)
  values (gl, e_tmp,'interim','active','Agent de sécurité','77 route d''Esch, L-1470 Luxembourg','Agent',
          date '2026-09-01', date '2026-12-31', 3050.00, 992.24, 40, 26,
          agency, 'Guardian Lux SA', 'Remplacement d''un salarié absent');

  return jsonb_build_object(
    'organization_id', v_org,
    'companies', jsonb_build_array(bg, cs, gl, mt),
    'schedule_id', sched,
    'message','Jeu de démonstration chargé : 4 dossiers, 323 salariés, conventions multiples, '
      || 'taux historisés, statuts protégés et un contrat de mission.');
end $$;

grant execute on function fn_seed_demo() to authenticated;
