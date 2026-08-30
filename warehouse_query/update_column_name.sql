DO $$
DECLARE
    old_names text[] := ARRAY['c1','c2','c3','c4','c5','c6','c7','c8'];
    new_names text[] := ARRAY[
        'Branch',
        'community',
        'Participant Name',
        'Participant ID',
        'Age group',
        'club',
        'In case she is assigned to a wrong package',
        'New package'
    ];
    schema_name text := 'temporary';
    tbl_name text := 'wrong_packages';
    i int;
BEGIN
    FOR i IN 1 .. array_length(old_names, 1) LOOP
        EXECUTE format(
            'ALTER TABLE %I.%I RENAME COLUMN %I TO %I',
            schema_name, tbl_name, old_names[i], new_names[i]
        );
    END LOOP;
END $$;