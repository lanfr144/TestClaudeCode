-- 59c — Retrait d'une variable de brouillon restée dans fn_sanction_check
--
-- `procedure_noop boolean;` était déclarée et jamais utilisée. Sans effet sur le
-- comportement, mais une variable morte dans une fonction livrée est une
-- question de plus pour le prochain lecteur.
--
-- Migration d'une ligne, assumée : une migration appliquée ne se réécrit pas,
-- on la corrige par la suivante. C'est la convention du projet, y compris —
-- surtout — quand ce qu'elle corrige est une négligence de rédaction.

do $corr$
declare v_src text;
begin
  v_src := pg_get_functiondef('fn_sanction_check(uuid)'::regprocedure);
  v_src := replace(v_src, E'\n  procedure_noop boolean;\n', E'\n');
  if position('procedure_noop' in v_src) > 0 then
    raise exception 'Le retrait n''a pas eu lieu : le corps de la fonction a changé.';
  end if;
  execute v_src;
end $corr$;
