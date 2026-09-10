
-- Nouvelle famille de paramètres. Isolée dans sa propre migration : PostgreSQL
-- interdit d'utiliser une valeur d'enum dans la transaction qui l'ajoute.
alter type param_family add value if not exists 'ccss';
