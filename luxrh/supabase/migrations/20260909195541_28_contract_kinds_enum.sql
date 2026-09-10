
-- Types de contrat supplémentaires. Isolés : une valeur d'enum ne peut être
-- utilisée dans la transaction qui l'ajoute.
alter type contract_kind add value if not exists 'seasonal';
alter type contract_kind add value if not exists 'apprenticeship';
alter type contract_kind add value if not exists 'interim';
