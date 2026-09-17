-- Création de l'utilisateur applicatif LuxRH
--
-- Appelé par `00_charger.sh`, qui porte la sentinelle et ne le joue que si le
-- schéma est absent.
-- Le script suivant — `02_schema.sql` — est déposé par `docker/demarrer.sh`
-- depuis `schema/oracle.sql`, lui-même régénéré à partir de PostgreSQL.
--
-- IDEMPOTENT À DESSEIN
-- =====================
-- L'image ne joue ce répertoire qu'à la création de la base. Mais un volume
-- conservé et un conteneur recréé suffiraient à le rejouer : chaque instruction
-- est donc écrite pour ne pas échouer au second passage.
--
-- LE MOT DE PASSE
-- ===============
-- Il vient de `.env`, substitué par `docker/demarrer.sh` avant le montage. Il
-- n'est écrit nulle part dans le dépôt.

set serveroutput on

-- Pas de « alter session set container » : la connexion vise déjà le PDB par
-- son nom de service. La ligne qui figurait ici nommait LUXRHPDB en dur, un PDB
-- qui n'existe pas — l'image `database/free` livre FREEPDB1 et ignore
-- ORACLE_PDB, sa base étant déjà créée. Le script échouait sur sa deuxième
-- ligne, avant d'avoir rien fait.

declare
  v_existe integer;
begin
  select count(*) into v_existe from dba_users where username = 'LUXRH';

  if v_existe = 0 then
    -- Le mot de passe est remplacé au démarrage. S'il ne l'a pas été, la
    -- création échoue franchement plutôt que de poser un compte devinable.
    execute immediate 'create user luxrh identified by "&&LUXRH_DB_PASSWORD"';
    dbms_output.put_line('Utilisateur LUXRH créé.');
  else
    dbms_output.put_line('Utilisateur LUXRH déjà présent — rien à faire.');
  end if;

  -- Droits accordés dans tous les cas : une exécution antérieure a pu créer
  -- l'utilisateur sans aller au bout.
  execute immediate 'grant create session, create table, create view,
                     create sequence, create procedure, create trigger,
                     create type to luxrh';

  -- Quota explicite : sans lui, la première insertion échoue sur ORA-01950,
  -- message qui n'évoque rien pour qui découvre Oracle.
  execute immediate 'alter user luxrh quota unlimited on users';

  dbms_output.put_line('Droits et quota appliqués à LUXRH.');
end;
/

