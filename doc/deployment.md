# Deployment notes

## To wipe the production database completely:

```sql
DO $$
DECLARE
    table_record record;
BEGIN
    FOR table_record IN
        SELECT nspname || '.' || relname AS full_rel_name
        FROM pg_class, pg_namespace
        WHERE relnamespace = pg_namespace.oid
        AND nspname = 'public'
        AND relkind = 'r'
    LOOP
        EXECUTE 'DROP TABLE ' || table_record.full_rel_name || ' CASCADE';
    END LOOP;
END $$;
```