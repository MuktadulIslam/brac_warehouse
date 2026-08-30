-- SELECT uuid_generate_v1();

INSERT INTO _aim_c2_branch_office_gps
(
    id,
    item_id,
    operational_period_id,
    create_time,
    reporting_date,
    last_modified_time,
    is_deleted,
    created_by,
    last_modified_by,
    country_id,
    project_id,
    catchment_id,
    fiscal_year_id,
    office_id,
    process_data,
    b1,
    gps,
    photo_1,
    last_sync_time,
    version,
    modified_version,
    submission_status,
    meta_data,
    survey_meta_data
)
SELECT
    b.new_id,                     -- new id
    item_id,
    operational_period_id,
    now(),                                    -- create_time
    now(),
    now(),                                    -- last_modified_time
    false,
    'stream_fresh',                           -- created_by
    'stream_fresh',                           -- last_modified_by
    country_id,
    project_id,
    catchment_id,
    '23fb89223504405a88b81946cd04586d',       -- new fiscal_year_id
    office_id,
    process_data,
    b1,
    gps,
    photo_1,
    NULL,                                      -- last_sync_time
    version,
    modified_version,
    submission_status,
    meta_data,
    survey_meta_data
FROM _aim_c2_branch_office_gps s
JOIN bak._aim_c2_branch_office_gps_new_ids b ON s.id = b.id
WHERE fiscal_year_id = 'b7bafa62563646978b22d498b8525212' AND office_id not in ('idSL500002', 'idSL500024');

SELECT * FROM _aim_c2_branch_office_gps where fiscal_year_id='23fb89223504405a88b81946cd04586d';


INSERT INTO survey
(
    id,
    survey_form_id,
    answer,
    name,
    location,
    item_id,
    operational_period_id,
    catchment_id,
    status,
    required_missing,
    create_time,
    last_modified_time,
    is_deleted,
    created_by,
    last_modified_by,
    country_id,
    project_id,
    version,
    fiscal_year_id,
    office_id,
    meta_data,
    process_data,
    last_sync_time,
    modified_version,
    submission_status,
    survey_meta_data
)
SELECT
    b.new_id,                                          -- SAME id (safe: PK is id + fiscal_year_id)
    survey_form_id,
    CASE
        WHEN answer IS NOT NULL THEN
            jsonb_set(
                answer::jsonb,
                '{_fiscal_year_id}',
                to_jsonb('23fb89223504405a88b81946cd04586d'::text),
                true                              -- create key if missing
            )::text
        ELSE answer
    END                                            AS answer,
    name,
    location,
    item_id,
    operational_period_id,
    catchment_id,
    status,
    required_missing,
    now(),                                        -- create_time
    now(),                                        -- last_modified_time
    false,
    'stream_fresh',                               -- created_by
    'stream_fresh',                               -- last_modified_by
    country_id,
    project_id,
    9,
    '23fb89223504405a88b81946cd04586d',           -- new fiscal_year_id
    office_id,
    meta_data,
    process_data,
    NULL,                                          -- last_sync_time
    9,
    submission_status,
    survey_meta_data
FROM survey s
JOIN bak._aim_c2_branch_office_gps_new_ids  b ON b.id = s.id
WHERE survey_form_id = '6359c684b5e941188806a257489e7f44'
  AND fiscal_year_id = 'b7bafa62563646978b22d498b8525212' AND office_id not in ('idSL500002', 'idSL500024');


DROP table bak._aim_c2_branch_office_gps_new_ids;

SELECT * FROM survey WHERE survey_form_id = '6359c684b5e941188806a257489e7f44'
  AND fiscal_year_id = '23fb89223504405a88b81946cd04586d';

SELECT id, gen_random_uuid() as new_id INTO bak._aim_c2_branch_office_gps_new_ids FROM _aim_c2_branch_office_gps
WHERE fiscal_year_id = 'b7bafa62563646978b22d498b8525212' AND office_id not in ('idSL500002', 'idSL500024');

SELECT * FROM country;
SELECT distinct fiscal_year_id FROM _aim_c2_branch_office_gps WHERE country_id = '2';
SELECT * FROM _aim_c2_branch_office_gps WHERE country_id = '2';
SELECT * FROM fiscal_year where id in ('b7bafa62563646978b22d498b8525212', '1ad966043b9a4eda8f71710ae05c77b4', '23fb89223504405a88b81946cd04586d');


