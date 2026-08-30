WITH field_info AS (
    SELECT
        det.type AS det_type,
        is_multiple,
        regexp_replace(de.id, '.*:(.*)', '\1') AS var_id,
        de.data_element_column_name AS var_name,
        de.display_text,
        deo.value AS option_value,
        deo.name AS option_name
    FROM public.survey_data_element_member sdem
    LEFT JOIN public.data_element de ON de.id = sdem.data_element_id
    LEFT JOIN public.data_element_option deo ON de.id = deo.data_element_id
    LEFT JOIN data_element_type det ON de.data_element_type_id = det.id
    WHERE sdem.survey_form_id = '1adee15e9458454982ae14fecb8885d1'
),
distinct_fields AS (
    SELECT DISTINCT var_name, display_text, det_type, COALESCE(is_multiple, false) AS is_multiple
    FROM field_info
    ORDER BY var_name
),
jsonb_record_fields AS (
    SELECT string_agg('      ' || var_name || ' text', ',' || chr(10) ORDER BY var_name) AS fields_list
    FROM distinct_fields
),
fields_with_options AS (
    SELECT
        var_name,
        is_multiple,
        string_agg(
            '    WHEN a.' || var_name || ' = ''' || replace(option_value, '''', '''''') || ''' THEN ''' || replace(option_name, '''', '''''') || '''',
            chr(10)
        ) AS case_whens,
        string_agg(
            'when value = ''' || replace(option_value, '''', '''''') || ''' then ''' || replace(option_name, '''', '''''') || '''',
            ' '
        ) AS inline_case_whens
    FROM field_info
    WHERE option_value IS NOT NULL
    GROUP BY var_name, is_multiple
),
final_select_clauses AS (
    SELECT
        df.var_name,
        CASE
            -- Multi-select field with options
            WHEN fwo.case_whens IS NOT NULL AND df.is_multiple THEN
                chr(10) || '  -- ' || df.var_name || chr(10) ||
                '  a.' || df.var_name || ',' || chr(10) ||
                '  (SELECT string_agg(CASE ' || fwo.inline_case_whens || ' END, '','') ' ||
                'FROM regexp_split_to_table(a.' || df.var_name || ', '','') AS value) AS ' || df.var_name || '_text,' || chr(10) ||
                '  (SELECT string_agg(CASE ' || fwo.inline_case_whens || ' END, '','') ' ||
                'FROM regexp_split_to_table(a.' || df.var_name || ', '','') AS value) AS "' || replace(df.display_text, '"', '""') || '"'
            -- Single-select field with options
            WHEN fwo.case_whens IS NOT NULL AND NOT df.is_multiple THEN
                chr(10) || '  -- ' || df.var_name || chr(10) ||
                '  a.' || df.var_name || ',' || chr(10) ||
                '  CASE' || chr(10) ||
                fwo.case_whens || chr(10) ||
                '  END AS ' || df.var_name || '_text,' || chr(10) ||
                '  CASE' || chr(10) ||
                fwo.case_whens || chr(10) ||
                '  END AS "' || replace(df.display_text, '"', '""') || '"'
            -- Geolocation field: extract 4 JSON sub-fields
            WHEN df.det_type = 'geolocation' THEN
                chr(10) || '  -- ' || df.var_name || ' (geolocation)' || chr(10) ||
                '  a.' || df.var_name || ',' || chr(10) ||
                '  a.' || df.var_name || '::jsonb -> ''answer'' ->> ''alt''       AS ' || df.var_name || '_alt,' || chr(10) ||
                '  a.' || df.var_name || '::jsonb -> ''answer'' ->> ''lat''       AS ' || df.var_name || '_lat,' || chr(10) ||
                '  a.' || df.var_name || '::jsonb -> ''answer'' ->> ''long''      AS ' || df.var_name || '_long,' || chr(10) ||
                '  a.' || df.var_name || '::jsonb -> ''answer'' ->> ''precision'' AS ' || df.var_name || '_precision,' || chr(10) ||
                '  a.' || df.var_name || ' AS "' || replace(df.display_text, '"', '""') || '"'
            -- Plain field (text, date, number, etc.)
            ELSE
                chr(10) || '  -- ' || df.var_name || chr(10) ||
                '  a.' || df.var_name || ',' || chr(10) ||
                '  a.' || df.var_name || ' AS "' || replace(df.display_text, '"', '""') || '"'
        END AS select_clause
    FROM distinct_fields df
    LEFT JOIN fields_with_options fwo ON df.var_name = fwo.var_name
)
SELECT
'WITH s AS (
  SELECT
    id, item_id, create_time, last_modified_time, catchment_id, survey_meta_data,
    created_by, last_modified_by, country_id, project_id,
    fiscal_year_id, office_id, process_data, answer
  FROM
    survey
  WHERE survey_form_id = ''1adee15e9458454982ae14fecb8885d1''
),
a AS (
  SELECT
    s.*,
    (s.survey_meta_data::jsonb ->> ''StartTime'')::timestamptz as intake_start_date,
    (s.survey_meta_data::jsonb ->> ''EndTime'')::timestamptz as intake_end_date,
    r.*
  FROM
    s
  CROSS JOIN LATERAL jsonb_to_record(s.answer::jsonb) AS r(
' || (SELECT fields_list FROM jsonb_record_fields) || '
  )
)
SELECT
  a.id, a.item_id, a.create_time, a.last_modified_time, a.catchment_id,
  a.created_by, a.last_modified_by, a.country_id, a.project_id,
  a.fiscal_year_id, a.office_id, a.process_data,

  a.intake_start_date,
  a.intake_end_date,

' || (SELECT string_agg(select_clause, ',' || chr(10) ORDER BY var_name) FROM final_select_clauses) || '
FROM
  a';