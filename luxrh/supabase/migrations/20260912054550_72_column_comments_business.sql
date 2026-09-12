-- 72 — Commentaires sur les colonnes métier
--
-- La migration 71 a traité les colonnes structurelles, répétées d'une table à
-- l'autre, par une boucle. Restaient 273 colonnes dont le sens dépend de la table
-- où elles se trouvent : le `code` d'un pays et le `code` d'une convention ne
-- disent pas la même chose, et un texte générique y serait faux.
--
-- Elles sont écrites ici une par une. Le critère retenu pour chaque texte : dire
-- ce que le nom de la colonne ne dit pas. Répéter « identifiant du salarié » sur
-- `employee_id` n'apprend rien ; dire que la ligne survit à l'avenant, si.
--
-- Après cette migration, les 836 colonnes des 76 tables sont commentées.

set search_path = public;

-- ====================================================== absences et congés

comment on column absence_types.code is 'Code stable du type d''absence, utilisé par le moteur et par les deux interfaces. Il ne change jamais : c''est le libellé qui se retouche, pas le code.';
comment on column absence_types.label is 'Libellé affiché du type d''absence, en français. Destiné à l''écran, jamais à une comparaison.';

comment on column absence_entitlements.absence_type_id is 'Type d''absence auquel ce droit se rapporte. Le droit est daté : un même type peut ouvrir un nombre de jours différent selon la période.';
comment on column absence_entitlements.note is 'Précision sur l''origine du droit : disposition conventionnelle, usage d''entreprise, circonstance particulière. Lue par un humain, jamais par le moteur.';

comment on column absences.absence_type_id is 'Type d''absence demandé. Détermine les pièces exigées, le délai de certificat et l''imputation sur les compteurs.';
comment on column absences.start_date is 'Premier jour d''absence, inclus. Jour entier : une absence d''une demi-journée se compte par days_count, pas par les bornes.';
comment on column absences.end_date is 'Dernier jour d''absence, INCLUS — contrairement aux bornes de validité du référentiel, qui sont exclusives. Une absence d''un seul jour porte la même date en début et en fin.';
comment on column absences.status is 'Où en est la demande : proposé, en attente, validé, refusé, annulé. Un refus n''est jamais un point final — il doit s''accompagner d''une contre-proposition, chaînée par absence_parente_id.';
comment on column absences.comment is 'Motif ou précision donnée par le demandeur. Visible du salarié comme du gestionnaire : ce n''est pas une note interne.';
comment on column absences.certificate_received_at is 'Date de réception du certificat, original ou copie. C''est elle qui arrête le décompte du délai CCSS, pas la date d''émission du certificat.';
comment on column absences.certificate_original_received_at is 'Date de réception de l''ORIGINAL papier. Distincte de la copie : la CCSS exige l''original, et seule cette date solde l''obligation.';
comment on column absences.certificate_document_id is 'Pièce justificative rattachée. Sans clé étrangère stricte vers un document supprimé : l''absence reste lisible même si la pièce a été purgée.';
comment on column absences.requested_by is 'Compte à l''origine de la demande. Peut différer du salarié : un gestionnaire saisit pour un salarié sans accès, et il faut savoir qui a saisi.';
comment on column absences.decided_at is 'Horodatage de la décision. Avec decided_by, répond à « qui a tranché, et quand » — une validation d''absence est un acte opposable.';

-- ====================================================== adresses

comment on column adresses_salarie.type_adresse is 'Nature de l''adresse, parmi ref_type_adresse : domicile légal, résidence effective, correspondance, facturation. Les quatre doivent être couvertes sans trou depuis la candidature jusqu''après le départ — une erreur de salaire découverte plus tard doit pouvoir être notifiée.';
comment on column adresses_salarie.ligne is 'Rue et numéro. Une seule ligne : le découpage varie trop d''un pays à l''autre pour être imposé.';
comment on column adresses_salarie.code_postal is 'Code postal. Confronté au référentiel des localités : un code incohérent est signalé, jamais corrigé d''office.';
comment on column adresses_salarie.localite is 'Localité, telle qu''elle doit figurer sur un courrier.';
comment on column adresses_salarie.latitude is 'Latitude en degrés décimaux, obtenue par géocodage. Sert au calcul des distances de tournée et à l''indemnité kilométrique ; nulle tant que l''adresse n''a pas été géocodée.';
comment on column adresses_salarie.longitude is 'Longitude en degrés décimaux. Voir latitude : le couple n''a de sens que complet.';
comment on column adresses_salarie.note is 'Précision de livraison ou de contact : étage, digicode, « chez ». Jamais une donnée de calcul.';

comment on column address_checks.entity_table is 'Table de la ligne vérifiée — employees, companies, client_sites. Le contrôle d''adresse est le même pour toutes ; cette colonne dit d''où vient celle-ci.';
comment on column address_checks.status is 'Résultat du contrôle, parmi ref_statut_verification_adresse : vérifiée, incohérente, hors périmètre, non vérifiable. « Non vérifiable » est un résultat, pas un échec : LuxRH ne couvre que le Luxembourg et les zones frontalières déclarées.';
comment on column address_checks.zone_code is 'Zone reconnue pour cette adresse : Luxembourg, ou zone frontalière déclarée. Détermine le régime de frontalier et les barèmes applicables.';
comment on column address_checks.message is 'Explication du résultat, destinée à l''humain qui corrigera. Une adresse rejetée sans motif ne se corrige pas.';
comment on column address_checks.checked_at is 'Date du contrôle. Un référentiel postal évolue : un contrôle ancien ne vaut pas contrôle actuel.';

comment on column address_zones.kind is 'Nature de la zone : pays, région frontalière, plage de codes postaux. Détermine comment les bornes ci-dessous se lisent.';
comment on column address_zones.code is 'Code de la zone, repris par address_checks.zone_code et par les barèmes qui s''y réfèrent.';
comment on column address_zones.label is 'Nom lisible de la zone, pour l''affichage et les messages de contrôle.';
comment on column address_zones.postal_to is 'Borne haute INCLUSE de la plage de codes postaux couverte. Nulle si la zone ne se décrit pas par une plage.';
comment on column address_zones.note is 'Origine de la délimitation : convention, accord frontalier, choix de paramétrage. Ce qui permet de la contester.';

-- ====================================================== comptes et sécurité

comment on column app_secrets.key is 'Nom du secret. La table porte RLS active et VOLONTAIREMENT aucune politique : aucune ligne n''est accessible par l''API REST, seules les fonctions security definer du moteur y accèdent.';
comment on column app_secrets.secret is 'Valeur du secret. Voir la remarque sur la table : elle n''est lisible par personne à travers l''API. Un secret qui vit dans la base qu''il protège reste un compromis assumé et documenté.';

comment on column app_users.email is 'Adresse de connexion et de notification. Unique : c''est elle qui identifie le compte pour la récupération de mot de passe.';
comment on column app_users.full_name is 'Nom affiché du compte. Modifiable par l''intéressé en libre-service, contrairement aux données d''identité du dossier salarié.';
comment on column app_users.updated_by is 'Compte auteur de la dernière modification. Sur une table de comptes, savoir qui a changé quoi n''est pas optionnel.';

comment on column user_roles.user_id is 'Compte auquel le rôle est attribué. Un compte peut porter plusieurs rôles ; c''est le plus permissif qui s''applique, et les politiques RLS lisent cette table, jamais une valeur transmise par le client.';

comment on column profiles.full_name is 'Nom affiché de l''utilisateur dans l''interface. Doublon assumé de app_users.full_name : profiles est la vue applicative, app_users la table de comptes portable vers un autre SGBD.';

-- ====================================================== journaux

comment on column audit_log.occurred_at is 'Horodatage de l''écriture auditée, posé par la base au moment du déclencheur. Ce n''est pas une date saisie : elle ne se retouche pas.';
comment on column audit_log.actor_id is 'Compte auteur de l''écriture. Nul pour une opération de maintenance exécutée hors session applicative — cas rare, qui doit rester visible plutôt que d''être attribué à tort.';
comment on column audit_log.action is 'Nature de l''écriture : insert, update, delete. La suppression enregistrée ici est logique ; une ligne n''est jamais retirée de la base.';

comment on column data_access_log.occurred_at is 'Horodatage de la LECTURE. Ce journal répond au « quand » de l''article 15 du RGPD : à quel moment les données d''une personne ont été consultées.';
comment on column data_access_log.actor_id is 'Compte ayant lu. Répond au « par qui ». Renseigné par le serveur à partir de la session, jamais déclaré par l''appelant.';
comment on column data_access_log.entity_table is 'Table lue. Répond au « quoi », avec la ligne visée et les colonnes effectivement renvoyées.';
comment on column data_access_log.row_count is 'Nombre de lignes effectivement renvoyées à l''appelant. Une consultation qui ne renvoie rien reste une consultation et se journalise.';
comment on column data_access_log.source_ip is 'Adresse IP d''origine, lue dans les en-têtes transmis par la passerelle. Répond au « d''où ».';
comment on column data_access_log.user_agent is 'Agent déclaré par le client. Indicatif seulement : un agent se falsifie, il complète l''IP sans la remplacer.';
comment on column data_access_log.request_id is 'Identifiant de la requête, pour rapprocher une ligne de ce journal des traces de la passerelle lors d''une investigation.';

comment on column export_log.requested_by is 'Compte ayant demandé l''export. Un export de données personnelles est un traitement : il a un demandeur nommé.';
comment on column export_log.subject_id is 'Ligne concernée par l''export, dans la table que désigne subject_kind. Nulle pour un export qui ne vise pas une ligne unique, comme le référentiel.';
