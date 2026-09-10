
-- search_path figé sur les fonctions restantes
alter function fn_easter_sunday(int)              set search_path = public;
alter function fn_luhn_check_digit(text)          set search_path = public;
alter function fn_verhoeff_check_digit(text)      set search_path = public;
alter function fn_valid_national_id(text)         set search_path = public;
alter function fn_shift_start_ts(date, time)      set search_path = public;
alter function fn_shift_end_ts(date, time, time)  set search_path = public;
alter function fn_shift_hours(time, time, int)    set search_path = public;
alter function fn_arbitrate(text, numeric, text, numeric, text, numeric, boolean) set search_path = public;
alter function fn_fmt(numeric)                    set search_path = public;
alter function fn_trim_param_scale()              set search_path = public;
alter function fn_check_cba_not_worse()           set search_path = public;
alter function fn_make_national_id(date, int)     set search_path = public;

-- Rien n'est appelable sans être connecté ; le moteur reste ouvert aux
-- utilisateurs authentifiés, qui passent tous par un contrôle d'accès interne.
revoke execute on all functions in schema public from anon, public;
grant  execute on all functions in schema public to authenticated;

-- Primitives de chiffrement et fonctions de déclencheur : jamais exposées en RPC.
revoke execute on function fn_encrypt_field(text)                        from authenticated, anon, public;
revoke execute on function fn_decrypt_field(bytea)                       from authenticated, anon, public;
revoke execute on function fn_audit()                                    from authenticated, anon, public;
revoke execute on function handle_new_user()                             from authenticated, anon, public;
revoke execute on function fn_trim_param_scale()                         from authenticated, anon, public;
revoke execute on function fn_check_cba_not_worse()                      from authenticated, anon, public;

-- Génération des jours fériés : administration du référentiel uniquement.
revoke execute on function fn_generate_public_holidays(int)              from authenticated, anon, public;

alter default privileges in schema public revoke execute on functions from anon, public;
