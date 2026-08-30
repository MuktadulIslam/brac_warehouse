-- ==========================================================================================================================================================================
--     Table Structure
-- ==========================================================================================================================================================================
-- create table house_hold_member_catchment_migrations_list
-- (
--     hhm_id,
--     current_catchment_id,
--     new_catchment_id,
--     new_club_id
-- );
--
-- create table house_hold_catchment_migrations_list
-- (
--     hh_id,
--     current_catchment_id,
--     new_catchment_id
-- );

-- $$$$$$$$$$$ For Cohort-4 Those 8 table need to update $$$$$$$$$$$
-- 1. house_hold
-- 2. house_hold_member
-- 3. aim_c4_hh_survey
-- 4. aim_c4_hhm_survey
-- 5. aim_c4_enrollment
-- 6. aim_c4_hhm_correction
-- 7. participant_group_member
-- 8. participant_group_exit


-- ==========================================================================================================================================================================
--     Instructions
-- ==========================================================================================================================================================================
-- 1. First create a catchment in that name in 'catchment' table    (If not already created)
-- 2. Then add the new catchment in 'catchment_community_type_mapping' table    (If not already created)
-- 4. Finally map the new catchment with 'branch_office_village_mapping' table  (If not already created)


-- ==========================================================================================================================================================================
--     1. House Hold Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    hh.id,
    hh.house_hold_serial_number,
    hh.catchment_id       AS current_catchment_id_actual,
    m.current_catchment_id AS current_catchment_id_expected,
    m.new_catchment_id,
    hh.answer::jsonb ? 'catchment_id'  AS has_catchment_id_key,
    hh.answer::jsonb ? '_catchment_id' AS has_underscore_catchment_id_key
FROM house_hold hh
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = hh.id
ORDER BY hh.house_hold_serial_number;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.house_hold_backup_catchment_migration_20_08_2026_muktadul AS
SELECT hh.*
FROM house_hold hh
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = hh.id;

SELECT * FROM bak.house_hold_backup_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE house_hold hh
SET catchment_id = m.new_catchment_id,
    answer = CASE
        WHEN hh.answer::jsonb ? 'catchment_id' THEN
            jsonb_set(
                hh.answer::jsonb,
                '{catchment_id}',
                to_jsonb(m.new_catchment_id::text),
                true
            )::text

        WHEN hh.answer::jsonb ? '_catchment_id' THEN
            jsonb_set(
                hh.answer::jsonb,
                '{_catchment_id}',
                to_jsonb(m.new_catchment_id::text),
                true
            )::text

        ELSE hh.answer
    END,
    last_modified_time = now(),
    last_modified_by = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_catchment_migrations_list m
WHERE m.hh_id = hh.id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT hh.id,
       hh.house_hold_serial_number,
       hh.catchment_id,
       hh.answer::jsonb->>'catchment_id'  AS answer_catchment_id,
       hh.answer::jsonb->>'_catchment_id' AS answer_underscore_catchment_id,
       m.new_catchment_id,
       hh.last_modified_time,
       hh.last_modified_by
FROM house_hold hh
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = hh.id;
-- WHERE hh.catchment_id IS DISTINCT FROM m.new_catchment_id;



-- ==========================================================================================================================================================================
--     2. House Hold Member Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    hhm.id,
    hhm.member_name,
    hhm.catchment_id       AS current_catchment_id_actual,
    m.current_catchment_id AS current_catchment_id_expected,
    m.new_catchment_id,
    m.new_club_id,
    hhm.answer::jsonb ? 'catchment_id'  AS has_catchment_id_key,
    hhm.answer::jsonb ? '_catchment_id' AS has_underscore_catchment_id_key
FROM house_hold_member hhm
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = hhm.id
ORDER BY hhm.member_name;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.house_hold_member_catchment_migration_20_08_2026_muktadul AS
SELECT hhm.*
FROM house_hold_member hhm
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = hhm.id;

SELECT * FROM bak.house_hold_member_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE house_hold_member hhm
SET catchment_id = m.new_catchment_id,
    answer = CASE
        WHEN hhm.answer::jsonb ? 'catchment_id' THEN
            jsonb_set(
                hhm.answer::jsonb,
                '{catchment_id}',
                to_jsonb(m.new_catchment_id::text),
                true
            )::text

        WHEN hhm.answer::jsonb ? '_catchment_id' THEN
            jsonb_set(
                hhm.answer::jsonb,
                '{_catchment_id}',
                to_jsonb(m.new_catchment_id::text),
                true
            )::text

        ELSE hhm.answer
    END,
    last_modified_time = now(),
    last_modified_by = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_member_catchment_migrations_list m
WHERE m.hhm_id = hhm.id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT hhm.id,
       hhm.member_name,
       hhm.catchment_id,
       hhm.answer::jsonb->>'catchment_id'  AS answer_catchment_id,
       hhm.answer::jsonb->>'_catchment_id' AS answer_underscore_catchment_id,
       m.new_catchment_id,
       hhm.last_modified_time,
       hhm.last_modified_by
FROM house_hold_member hhm
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = hhm.id;
-- WHERE hhm.catchment_id IS DISTINCT FROM m.new_catchment_id;


-- ==========================================================================================================================================================================
--    3. aim_c4_hh_survey Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    ahs.id,
    ahs.catchment_id       AS current_catchment_id_actual,
    m.current_catchment_id AS current_catchment_id_expected,
    m.new_catchment_id
FROM aim_c4_hh_survey ahs
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = ahs.id
ORDER BY ahs.id;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.aim_c4_hh_survey_catchment_migration_20_08_2026_muktadul AS
SELECT ahs.*
FROM aim_c4_hh_survey ahs
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = ahs.id;

SELECT * FROM bak.aim_c4_hh_survey_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE aim_c4_hh_survey ahs
SET catchment_id       = m.new_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_catchment_migrations_list m
WHERE m.hh_id = ahs.id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT ahs.id,
       ahs.catchment_id,
       m.new_catchment_id,
       ahs.last_modified_time,
       ahs.last_modified_by
FROM aim_c4_hh_survey ahs
JOIN temporary.house_hold_catchment_migrations_list m ON m.hh_id = ahs.id;
-- WHERE ahs.catchment_id IS DISTINCT FROM m.new_catchment_id;




-- ==========================================================================================================================================================================
--    4. aim_c4_hhm_survey Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    ahs.id,
    ahs.catchment_id       AS current_catchment_id_actual,
    m.current_catchment_id AS current_catchment_id_expected,
    m.new_catchment_id,
    m.new_club_id
FROM aim_c4_hhm_survey ahs
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahs.id
ORDER BY ahs.id;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.aim_c4_hhm_survey_catchment_migration_20_08_2026_muktadul AS
SELECT ahs.*
FROM aim_c4_hhm_survey ahs
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahs.id;

SELECT * FROM bak.aim_c4_hhm_survey_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE aim_c4_hhm_survey ahs
SET catchment_id       = m.new_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_member_catchment_migrations_list m
WHERE m.hhm_id = ahs.id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT ahs.id,
       ahs.catchment_id,
       m.new_catchment_id,
       ahs.last_modified_time,
       ahs.last_modified_by
FROM aim_c4_hhm_survey ahs
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahs.id;
-- WHERE ahs.catchment_id IS DISTINCT FROM m.new_catchment_id;




-- ==========================================================================================================================================================================
--    5. aim_c4_enrollment Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    ae.id,
    ae.item_id,
    ae.catchment_id         AS current_catchment_id_actual,
    m.current_catchment_id  AS current_catchment_id_expected,
    m.new_catchment_id
FROM aim_c4_enrollment ae
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ae.item_id
ORDER BY ae.item_id;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.aim_c4_enrollment_catchment_migration_20_08_2026_muktadul AS
SELECT ae.*
FROM aim_c4_enrollment ae
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ae.item_id;

SELECT * FROM bak.aim_c4_enrollment_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE aim_c4_enrollment ae
SET catchment_id       = m.new_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_member_catchment_migrations_list m
WHERE m.hhm_id = ae.item_id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT ae.id,
       ae.item_id,
       ae.catchment_id,
       m.new_catchment_id,
       ae.last_modified_time,
       ae.last_modified_by
FROM aim_c4_enrollment ae
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ae.item_id;
-- WHERE ae.catchment_id IS DISTINCT FROM m.new_catchment_id;





-- ==========================================================================================================================================================================
--    6. aim_c4_hhm_correction Table Update
-- ==========================================================================================================================================================================
-- 1. PREVIEW — check what will change before touching anything
SELECT
    ahc.id,
    ahc.item_id,
    ahc.catchment_id        AS current_catchment_id_actual,
    m.current_catchment_id  AS current_catchment_id_expected,
    m.new_catchment_id
FROM aim_c4_hhm_correction ahc
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahc.item_id
ORDER BY ahc.item_id;


-- 2. BACKUP — snapshot affected rows before mutating
CREATE TABLE bak.aim_c4_hhm_correction_catchment_migration_20_08_2026_muktadul AS
SELECT ahc.*
FROM aim_c4_hhm_correction ahc
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahc.item_id;

SELECT * FROM bak.aim_c4_hhm_correction_catchment_migration_20_08_2026_muktadul;


-- 3. UPDATE
BEGIN;

UPDATE aim_c4_hhm_correction ahc
SET catchment_id       = m.new_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_catchment_migrations'
FROM temporary.house_hold_member_catchment_migrations_list m
WHERE m.hhm_id = ahc.item_id;

-- review the affected row count reported by the UPDATE before committing
-- COMMIT;   -- uncomment once verified
-- ROLLBACK; -- use instead if something looks wrong

-- 4. VALIDATION — run after COMMIT
SELECT ahc.id,
       ahc.item_id,
       ahc.catchment_id,
       m.new_catchment_id,
       ahc.last_modified_time,
       ahc.last_modified_by
FROM aim_c4_hhm_correction ahc
JOIN temporary.house_hold_member_catchment_migrations_list m ON m.hhm_id = ahc.item_id;
-- WHERE ahc.catchment_id IS DISTINCT FROM m.new_catchment_id;



-- ==========================================================================================================================================================================
--     7. Participant Group Member +  8. Participant Group Exit
-- ==========================================================================================================================================================================
-------------------------------------------------------------------- Step 1: Build the temp table of members needing a group change --------------------------------------------------------------------
DROP TABLE IF EXISTS temporary.pgm_members_needing_group_change;

CREATE TABLE temporary.pgm_members_needing_group_change AS
SELECT pgm.id  AS pgm_id,
       pgm.member_id,
       pgm.type as pgm_type,
       pgm.member_type as pgm_member_type,
       pgm.member_serial,
       pg.participant_group_type_id,
       pg.id   AS old_group_id,
       pg.name as old_group_name,
       a.new_club_id,
       a.new_catchment_id,
       a.current_catchment_id
FROM temporary.house_hold_member_catchment_migrations_list a
         JOIN participant_group_member pgm ON pgm.member_id = a.hhm_id
         JOIN participant_group pg ON pg.id = pgm.group_id
WHERE pg.catchment_id <> a.new_catchment_id
  AND pgm.is_deleted IS NOT TRUE
  AND pg.is_deleted IS NOT TRUE;

SELECT * FROM temporary.pgm_members_needing_group_change;


-------------------------------------------------------------------- Step 2: Find the matching destination group, with priority ranking --------------------------------------------------------------------
DROP TABLE IF EXISTS temporary.pgm_destination_group_resolved;

CREATE TABLE temporary.pgm_destination_group_resolved AS
SELECT *
FROM (SELECT x.*,
             pg.id AS new_group_id,
             pg.approval_status,
             pg.create_time,

             ROW_NUMBER() OVER (
                 PARTITION BY x.pgm_id
                 ORDER BY
                     CASE pg.approval_status
                         WHEN 'submitted' THEN 1
                         WHEN 'auto_approved' THEN 2
                         ELSE 3
                         END,
                     pg.create_time DESC
                 ) AS rn
      FROM temporary.pgm_members_needing_group_change x
               LEFT JOIN participant_group pg
                    ON pg.service_point_id = x.new_club_id
                        AND pg.catchment_id = x.new_catchment_id
                        AND pg.participant_group_type_id = x.participant_group_type_id
                        AND pg.is_deleted IS NOT TRUE) x
WHERE rn = 1;

SELECT * FROM temporary.pgm_destination_group_resolved;


-------------------------------------------------------------------- Step 3: Chack that if there is any group that doesn't fit. Then we have to mention it to the client --------------------------------------------------------------------
SELECT * FROM temporary.pgm_destination_group_resolved WHERE new_group_id IS NULL;


-------------------------------------------------------------------- Step 4: INSERT the new pgm rows --------------------------------------------------------------------
INSERT INTO participant_group_member (
    id, member_id, group_id, type, member_answers, member_data_id,
    member_serial, member_addition_date, create_time, last_modified_time,
    is_deleted, created_by, last_modified_by, validation_rule_id,
    member_type, linked_group_type_id, linked_group_id, meta_data,
    fiscal_year_id, approval_status, last_sync_time
)
SELECT
    get_guid(),
    member_id,
    new_group_id,
    pgm_type,
    NULL,
    NULL,
    member_serial,
    now(),                                  -- member_addition_date
    now(),                                  -- create_time
    now(),                                  -- last_modified_time
    false,                                  -- is_deleted
    'stream_fresh_catchment_migrations',
    'stream_fresh_catchment_migrations',
    NULL,
    pgm_member_type,
    NULL,
    NULL,
    NULL,
    fiscal_year_id,
    'auto_approved',
    NULL
FROM temporary.pgm_destination_group_resolved  WHERE new_group_id IS NOT NULL;

SELECT
    npgm.id AS new_pgm_id,
    npgm.member_id,
    npgm.group_id,
    pg.catchment_id,
    pg.service_point_id,
    pg.participant_group_type_id,
    npgm.approval_status,
    npgm.create_time
FROM participant_group_member npgm
JOIN temporary.pgm_destination_group_resolved f ON f.member_id = npgm.member_id AND f.new_group_id = npgm.group_id
JOIN participant_group pg ON pg.id = npgm.group_id
WHERE npgm.created_by = 'stream_fresh_catchment_migrations'
ORDER BY npgm.member_id;


-------------------------------------------------------------------- Step 5: INSERT the new pge rows from pgm   --------------------------------------------------------------------
INSERT INTO participant_group_exit (
    id,
    group_id,
    member_id,
    exit_time,
    create_time,
    last_modified_time,
    is_deleted,
    exit_reason_id,
    created_by,
    last_modified_by,
    member_type,
    exit_status,
    participant_group_member_data,
    linked_group_id,
    fiscal_year_id,
    last_sync_time,
    rule_ids,
    rules
)
SELECT
    pgm.id::text,
    pgm.group_id,
    pgm.member_id,
    now(),
    now(),
    now(),
    false,
    '0c418d2fdc6243f798053ca7296e46f4',
    'stream_fresh_catchment_migrations',
    'stream_fresh_catchment_migrations',
    pgm.member_type,
    'DropOut',
    to_jsonb(pgm)::text,
    NULL,
    pgm.fiscal_year_id,
    now(),
    NULL,
    NULL
FROM participant_group_member pgm
JOIN temporary.pgm_destination_group_resolved f ON f.member_id = pgm.member_id AND f.old_group_id = pgm.group_id;

SELECT * FROM participant_group_exit pge
JOIN temporary.pgm_destination_group_resolved f ON f.member_id = pge.member_id AND f.old_group_id = pge.group_id;


--------------------------------------------------------- Step 6: Deleting from the participant_group_member ---------------------------------------------------------
DELETE  FROM participant_group_member
WHERE id IN (
    SELECT pgm_id FROM temporary.pgm_destination_group_resolved
);


