-- Check what create_appointment functions exist in the database

-- List all create_appointment functions
SELECT 
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as parameters,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'create_appointment'
  AND n.nspname = 'public';

-- Also check the actual parameter types
SELECT 
  p.proname as function_name,
  format_type(t.oid, NULL) as param_type,
  p.proargnames as param_names
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
CROSS JOIN LATERAL unnest(p.proargtypes) WITH ORDINALITY AS t(oid, num)
WHERE p.proname = 'create_appointment'
  AND n.nspname = 'public'
ORDER BY t.num;
