
-- numeric(14,4) figeait 4 décimales : « 15.0000 salariés » dans les messages.
-- On garde la précision utile (0,3333) sans traîner de zéros.
alter table legal_parameters alter column value_num type numeric;
update legal_parameters set value_num = trim_scale(value_num) where value_num is not null;

-- Même traitement pour les valeurs saisies plus tard
create or replace function fn_trim_param_scale()
returns trigger language plpgsql as $$
begin
  if new.value_num is not null then new.value_num := trim_scale(new.value_num); end if;
  return new;
end $$;

create trigger legal_parameters_trim before insert or update on legal_parameters
  for each row execute function fn_trim_param_scale();
