-- 84 — `ref_pays` reçoit la norme ISO 3166-1 complète
--
-- La table ne portait que quatre pays : Luxembourg et les trois frontaliers.
-- Toute autre nationalité, toute adresse étrangère, tout site client hors zone
-- était donc impossible à saisir — la clé étrangère les refusait.
--
-- ISO 3166-1 n'est pas une valeur légale luxembourgeoise : c'est une norme
-- internationale stable, publiée et vérifiable. La règle 7 du projet — ne jamais
-- inventer une valeur légale faute de source — ne s'y oppose donc pas, et il n'y
-- avait aucune raison de laisser la table incomplète.
--
-- `frontalier` reste vrai pour les trois seuls pays qui ouvrent ce régime au
-- Luxembourg : Belgique, France, Allemagne. Le remplir pour d'autres serait,
-- lui, inventer une règle.
--
-- Les noms sont en français, comme tous les libellés du projet.

set search_path = public;

insert into ref_pays (alpha3, alpha2, nom, frontalier) values
('AFG','AF','Afghanistan',false),('ZAF','ZA','Afrique du Sud',false),
('ALB','AL','Albanie',false),('DZA','DZ','Algérie',false),
('DEU','DE','Allemagne',true),('AND','AD','Andorre',false),
('AGO','AO','Angola',false),('AIA','AI','Anguilla',false),
('ATA','AQ','Antarctique',false),('ATG','AG','Antigua-et-Barbuda',false),
('SAU','SA','Arabie saoudite',false),('ARG','AR','Argentine',false),
('ARM','AM','Arménie',false),('ABW','AW','Aruba',false),
('AUS','AU','Australie',false),('AUT','AT','Autriche',false),
('AZE','AZ','Azerbaïdjan',false),('BHS','BS','Bahamas',false),
('BHR','BH','Bahreïn',false),('BGD','BD','Bangladesh',false),
('BRB','BB','Barbade',false),('BEL','BE','Belgique',true),
('BLZ','BZ','Belize',false),('BEN','BJ','Bénin',false),
('BMU','BM','Bermudes',false),('BTN','BT','Bhoutan',false),
('BLR','BY','Biélorussie',false),('BOL','BO','Bolivie',false),
('BIH','BA','Bosnie-Herzégovine',false),('BWA','BW','Botswana',false),
('BRA','BR','Brésil',false),('BRN','BN','Brunei',false),
('BGR','BG','Bulgarie',false),('BFA','BF','Burkina Faso',false),
('BDI','BI','Burundi',false),('CYM','KY','Îles Caïmans',false),
('KHM','KH','Cambodge',false),('CMR','CM','Cameroun',false),
('CAN','CA','Canada',false),('CPV','CV','Cap-Vert',false),
('CAF','CF','République centrafricaine',false),('CHL','CL','Chili',false),
('CHN','CN','Chine',false),('CYP','CY','Chypre',false),
('COL','CO','Colombie',false),('COM','KM','Comores',false),
('COG','CG','Congo',false),('COD','CD','République démocratique du Congo',false),
('PRK','KP','Corée du Nord',false),('KOR','KR','Corée du Sud',false),
('CRI','CR','Costa Rica',false),('CIV','CI','Côte d''Ivoire',false),
('HRV','HR','Croatie',false),('CUB','CU','Cuba',false),
('CUW','CW','Curaçao',false),('DNK','DK','Danemark',false),
('DJI','DJ','Djibouti',false),('DMA','DM','Dominique',false),
('EGY','EG','Égypte',false),('SLV','SV','Salvador',false),
('ARE','AE','Émirats arabes unis',false),('ECU','EC','Équateur',false),
('ERI','ER','Érythrée',false),('ESP','ES','Espagne',false),
('EST','EE','Estonie',false),('SWZ','SZ','Eswatini',false),
('USA','US','États-Unis',false),('ETH','ET','Éthiopie',false),
('FJI','FJ','Fidji',false),('FIN','FI','Finlande',false),
('FRA','FR','France',true),('GAB','GA','Gabon',false),
('GMB','GM','Gambie',false),('GEO','GE','Géorgie',false),
('GHA','GH','Ghana',false),('GIB','GI','Gibraltar',false),
('GRC','GR','Grèce',false),('GRD','GD','Grenade',false),
('GRL','GL','Groenland',false),('GLP','GP','Guadeloupe',false),
('GUM','GU','Guam',false),('GTM','GT','Guatemala',false),
('GGY','GG','Guernesey',false),('GIN','GN','Guinée',false),
('GNB','GW','Guinée-Bissau',false),('GNQ','GQ','Guinée équatoriale',false),
('GUY','GY','Guyana',false),('GUF','GF','Guyane française',false),
('HTI','HT','Haïti',false),('HND','HN','Honduras',false),
('HKG','HK','Hong Kong',false),('HUN','HU','Hongrie',false),
('IMN','IM','Île de Man',false),('CXR','CX','Île Christmas',false),
('IND','IN','Inde',false),('IDN','ID','Indonésie',false),
('IRQ','IQ','Irak',false),('IRN','IR','Iran',false),
('IRL','IE','Irlande',false),('ISL','IS','Islande',false),
('ISR','IL','Israël',false),('ITA','IT','Italie',false),
('JAM','JM','Jamaïque',false),('JPN','JP','Japon',false),
('JEY','JE','Jersey',false),('JOR','JO','Jordanie',false),
('KAZ','KZ','Kazakhstan',false),('KEN','KE','Kenya',false),
('KGZ','KG','Kirghizistan',false),('KIR','KI','Kiribati',false),
('KWT','KW','Koweït',false),('LAO','LA','Laos',false),
('LSO','LS','Lesotho',false),('LVA','LV','Lettonie',false),
('LBN','LB','Liban',false),('LBR','LR','Liberia',false),
('LBY','LY','Libye',false),('LIE','LI','Liechtenstein',false),
('LTU','LT','Lituanie',false),('LUX','LU','Luxembourg',false),
('MAC','MO','Macao',false),('MKD','MK','Macédoine du Nord',false),
('MDG','MG','Madagascar',false),('MYS','MY','Malaisie',false),
('MWI','MW','Malawi',false),('MDV','MV','Maldives',false),
('MLI','ML','Mali',false),('MLT','MT','Malte',false),
('MAR','MA','Maroc',false),('MTQ','MQ','Martinique',false),
('MUS','MU','Maurice',false),('MRT','MR','Mauritanie',false),
('MYT','YT','Mayotte',false),('MEX','MX','Mexique',false),
('FSM','FM','Micronésie',false),('MDA','MD','Moldavie',false),
('MCO','MC','Monaco',false),('MNG','MN','Mongolie',false),
('MNE','ME','Monténégro',false),('MSR','MS','Montserrat',false),
('MOZ','MZ','Mozambique',false),('MMR','MM','Birmanie',false),
('NAM','NA','Namibie',false),('NRU','NR','Nauru',false),
('NPL','NP','Népal',false),('NIC','NI','Nicaragua',false),
('NER','NE','Niger',false),('NGA','NG','Nigeria',false),
('NIU','NU','Niue',false),('NOR','NO','Norvège',false),
('NCL','NC','Nouvelle-Calédonie',false),('NZL','NZ','Nouvelle-Zélande',false),
('OMN','OM','Oman',false),('UGA','UG','Ouganda',false),
('UZB','UZ','Ouzbékistan',false),('PAK','PK','Pakistan',false),
('PLW','PW','Palaos',false),('PSE','PS','Palestine',false),
('PAN','PA','Panama',false),('PNG','PG','Papouasie-Nouvelle-Guinée',false),
('PRY','PY','Paraguay',false),('NLD','NL','Pays-Bas',false),
('PER','PE','Pérou',false),('PHL','PH','Philippines',false),
('POL','PL','Pologne',false),('PYF','PF','Polynésie française',false),
('PRI','PR','Porto Rico',false),('PRT','PT','Portugal',false),
('QAT','QA','Qatar',false),('REU','RE','La Réunion',false),
('ROU','RO','Roumanie',false),('GBR','GB','Royaume-Uni',false),
('RUS','RU','Russie',false),('RWA','RW','Rwanda',false),
('ESH','EH','Sahara occidental',false),('BLM','BL','Saint-Barthélemy',false),
('KNA','KN','Saint-Christophe-et-Niévès',false),('SMR','SM','Saint-Marin',false),
('MAF','MF','Saint-Martin',false),('SXM','SX','Saint-Martin (Pays-Bas)',false),
('SPM','PM','Saint-Pierre-et-Miquelon',false),('VAT','VA','Saint-Siège',false),
('VCT','VC','Saint-Vincent-et-les-Grenadines',false),('LCA','LC','Sainte-Lucie',false),
('SHN','SH','Sainte-Hélène',false),('SLB','SB','Îles Salomon',false),
('WSM','WS','Samoa',false),('ASM','AS','Samoa américaines',false),
('STP','ST','Sao Tomé-et-Principe',false),('SEN','SN','Sénégal',false),
('SRB','RS','Serbie',false),('SYC','SC','Seychelles',false),
('SLE','SL','Sierra Leone',false),('SGP','SG','Singapour',false),
('SVK','SK','Slovaquie',false),('SVN','SI','Slovénie',false),
('SOM','SO','Somalie',false),('SDN','SD','Soudan',false),
('SSD','SS','Soudan du Sud',false),('LKA','LK','Sri Lanka',false),
('SWE','SE','Suède',false),('CHE','CH','Suisse',false),
('SUR','SR','Suriname',false),('SJM','SJ','Svalbard et Jan Mayen',false),
('SYR','SY','Syrie',false),('TJK','TJ','Tadjikistan',false),
('TWN','TW','Taïwan',false),('TZA','TZ','Tanzanie',false),
('TCD','TD','Tchad',false),('CZE','CZ','Tchéquie',false),
('THA','TH','Thaïlande',false),('TLS','TL','Timor oriental',false),
('TGO','TG','Togo',false),('TKL','TK','Tokelau',false),
('TON','TO','Tonga',false),('TTO','TT','Trinité-et-Tobago',false),
('TUN','TN','Tunisie',false),('TKM','TM','Turkménistan',false),
('TUR','TR','Turquie',false),('TCA','TC','Îles Turques-et-Caïques',false),
('TUV','TV','Tuvalu',false),('UKR','UA','Ukraine',false),
('URY','UY','Uruguay',false),('VUT','VU','Vanuatu',false),
('VEN','VE','Venezuela',false),('VNM','VN','Viêt Nam',false),
('VGB','VG','Îles Vierges britanniques',false),('VIR','VI','Îles Vierges américaines',false),
('WLF','WF','Wallis-et-Futuna',false),('YEM','YE','Yémen',false),
('ZMB','ZM','Zambie',false),('ZWE','ZW','Zimbabwe',false),
('ALA','AX','Îles Åland',false),('BES','BQ','Pays-Bas caribéens',false),
('BVT','BV','Île Bouvet',false),('CCK','CC','Îles Cocos',false),
('COK','CK','Îles Cook',false),('FLK','FK','Îles Malouines',false),
('FRO','FO','Îles Féroé',false),('HMD','HM','Îles Heard-et-MacDonald',false),
('MHL','MH','Îles Marshall',false),('MNP','MP','Îles Mariannes du Nord',false),
('NFK','NF','Île Norfolk',false),('PCN','PN','Îles Pitcairn',false),
('SGS','GS','Géorgie du Sud-et-les Îles Sandwich du Sud',false),
('ATF','TF','Terres australes françaises',false),
('IOT','IO','Territoire britannique de l''océan Indien',false),
('UMI','UM','Îles mineures éloignées des États-Unis',false)
on conflict (alpha3) do update
  set alpha2 = excluded.alpha2, nom = excluded.nom;

do $controle$
declare v_n int; v_f int;
begin
  select count(*), count(*) filter (where frontalier) into v_n, v_f from ref_pays;
  raise notice '% pays charges, dont % frontaliers.', v_n, v_f;
  if v_f <> 3 then
    raise exception 'Le regime frontalier ne concerne que BEL, FRA et DEU : % trouve(s).', v_f;
  end if;
end $controle$;
