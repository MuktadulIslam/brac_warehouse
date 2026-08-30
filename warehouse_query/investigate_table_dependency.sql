SELECT dependent_ns.nspname AS view_schema,
       dependent_view.relname AS view_name
FROM pg_depend
JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.oid
JOIN pg_namespace dependent_ns ON dependent_view.relnamespace = dependent_ns.oid
WHERE pg_depend.refobjid = 'public.branch_office_village_mapping'::regclass
  AND dependent_view.relkind = 'v'
  AND dependent_view.oid != pg_depend.refobjid;



-- See all the view
SELECT schemaname, viewname, viewowner
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, viewname;