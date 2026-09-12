-- 71 — Commentaires sur les colonnes structurelles
--
-- Où en était la couverture
-- --------------------------
-- 836 colonnes, 317 commentées : **38 %**. Les 76 tables portaient toutes un
-- commentaire, mais près de deux colonnes sur trois n'en avaient aucun. C'est la
-- remarque faite deux fois sur ce projet, et elle était fondée.
--
-- Ce que cette migration traite, et ce qu'elle laisse
-- ---------------------------------------------------
-- Environ 350 des 519 colonnes non commentées sont des colonnes **structurelles**,
-- répétées à l'identique d'une table à l'autre : `id`, `created_at`,
-- `organization_id`, `employee_id`, `debut_validite`… Leur sens ne dépend pas de
-- la table. Les commenter une par une à la main produirait 350 variations d'un
-- même texte, avec la certitude que certaines finiraient par diverger.
--
-- Elles sont donc commentées par une boucle, avec un texte unique par nom de
-- colonne. Ce n'est pas du remplissage : chacun de ces textes dit une chose que
-- le nom ne dit pas — pourquoi un UUID et non une séquence, pourquoi la
-- suppression est logique, quelle borne est inclusive.
--
-- Les colonnes dont le sens dépend de la table — `code`, `label`, `name`,
-- `reason`, `start_date`, `note` — ne sont **pas** traitées ici. Un texte
-- générique y serait faux : le `code` d'un pays et le `code` d'une convention ne
-- disent pas la même chose. Elles font l'objet de la migration 72, écrite à la main.
--
-- Règle de non-écrasement
-- ------------------------
-- La boucle ne pose un commentaire que là où il n'y en a aucun. Un commentaire
-- déjà écrit — souvent plus précis, parce qu'il a été pensé pour sa table — est
-- toujours conservé.

set search_path = public;

do $$
declare
  v_textes constant jsonb := jsonb_build_object(

  'id',
  'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir '
  'être exporté, réimporté et fusionné entre deux bases sans lien de base à base et '
  'sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, '
  'jamais utilisé comme clé de rapprochement dans un export — ce sont les clés '
  'naturelles qui servent à cela.',

  'created_at',
  'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date '
  'métier : la date à laquelle un fait est survenu est portée par une colonne qui '
  'le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.',

  'updated_at',
  'Horodatage de la dernière modification, tenu par un déclencheur. Comme '
  'created_at, c''est une donnée d''audit et non une date métier.',

  'deleted_at',
  'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue '
  'de l''application et exclue par les politiques RLS ; elle reste en base pour que '
  'l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit '
  'pouvoir encore nommer le salarié qu''elle a payé.',

  'deleted_by',
  'Compte ayant prononcé la suppression logique. Une suppression est une décision : '
  'elle a un auteur, qui doit rester connu après coup.',

  'created_by',
  'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le '
  'client — une identité déclarée par l''appelant ne prouve rien.',

  'organization_id',
  'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques '
  'RLS la comparent à celle du demandeur, et aucune requête ne franchit cette '
  'frontière. L''isolation est imposée en base, jamais dans l''interface.',

  'company_id',
  'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau '
  'employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux '
  'sociétés de son périmètre.',

  'employee_id',
  'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un '
  'avenant, à un changement de société au sein du groupe, et à la fin du contrat.',

  'contract_id',
  'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul '
  'en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. '
  'Ce qui se rattache ici vaut pour cette version-là du contrat.',

  'department_id',
  'Service de rattachement. Sert au périmètre de dispatching et à la résolution des '
  'conventions collectives, qui peuvent s''appliquer par service.',

  'collective_agreement_id',
  'Convention collective visée. Le rattachement peut se faire au niveau de la '
  'société, du service ou du contrat ; fn_applicable_cbas résout les trois.',

  'debut_validite',
  'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une '
  'validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.',

  'fin_validite',
  'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une '
  'validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour '
  'clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis '
  'insérer la suivante à cette même date.',

  'ordre',
  'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans '
  'un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.',

  'legal_ref',
  'Référence du texte qui fonde la valeur : article du Code du travail, article de '
  'convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du '
  'projet interdit d''inventer une valeur légale.',

  'postal_code',
  'Code postal de l''adresse. Confronté au référentiel des localités par '
  'fn_check_address : un code qui ne correspond pas à la localité est signalé, non '
  'corrigé d''office.',

  'city',
  'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.',

  'address_line',
  'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à '
  'l''autre pour être imposé ici.',

  'entity_id',
  'Identifiant de la ligne visée par l''événement, dans la table que nomme la '
  'colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à '
  'la suppression de ce qu''il relate.'

  );
  v_col     text;
  v_rec     record;
  v_poses   integer := 0;
begin
  for v_col in select jsonb_object_keys(v_textes) loop
    for v_rec in
      select c.relname as tbl
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
      join pg_attribute a on a.attrelid = c.oid and a.attname = v_col
                         and a.attnum > 0 and not a.attisdropped
      where c.relkind = 'r'
        and col_description(c.oid, a.attnum) is null   -- jamais d'écrasement
    loop
      execute format('comment on column %I.%I is %L',
                     v_rec.tbl, v_col, v_textes ->> v_col);
      v_poses := v_poses + 1;
    end loop;
  end loop;

  raise notice '% commentaire(s) de colonne posé(s).', v_poses;
end $$;
