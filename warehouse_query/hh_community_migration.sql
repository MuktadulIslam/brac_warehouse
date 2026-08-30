SELECT hh.*
INTO bak.house_hold_C4_full_data_18_06_2026
FROM house_hold hh
         JOIN fiscal_year fy ON hh.fiscal_year_id = fy.id
WHERE fy.name = 'Cohort 4';

SELECT *
FROM aim_c4_enrollment;
SELECT *
FROM aim_c4_hhm_survey_verification;
SELECT *
FROM aim_c4_hh_survey_verification;
SELECT *
FROM aim_c4_hhm_information;
SELECT *
FROM aim_c4_hhm_correction;

SELECT *
FROM catchment
where id = 'ffdf175d-e712-4e47-ad62-6af90f4849cc';

-- ════════════════════════════════════════════════════════════════════════════
-- ── 1. Backup
-- ════════════════════════════════════════════════════════════════════════════
SELECT hh.*
-- INTO bak.house_hold_18_06_2026_bracjira_2508
FROM house_hold hh
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON hh.id = m.household_id;

SELECT hhm.*
-- INTO bak.house_hold_member_18_06_2026_bracjira_2508
FROM house_hold_member hhm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = hhm.id;

SELECT s.*
-- INTO bak.aim_c4_hh_survey_18_06_2026_bracjira_2508
FROM aim_c4_hh_survey s
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON m.household_id = s.id;

SELECT s.*
-- INTO bak.aim_c4_hhm_survey_18_06_2026_bracjira_2508
FROM aim_c4_hhm_survey s
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = s.id;

SELECT pgm.*
-- INTO bak.participant_group_member_18_06_2026_bracjira_2508
FROM participant_group_member pgm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pgm.member_id;


SELECT hhm.*
-- INTO bak.aim_c4_enrollment_18_06_2026_bracjira_2508
FROM aim_c4_enrollment hhm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON hhm.item_id = m.member_id;

SELECT hhm.*
-- INTO bak.aim_c4_hhm_survey_verification_18_06_2026_bracjira_2508
FROM aim_c4_hhm_survey_verification hhm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON hhm.item_id = m.member_id;

SELECT hh.*
-- INTO bak.aim_c4_hh_survey_verification_18_06_2026_bracjira_2508
FROM aim_c4_hh_survey_verification hh
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON hh.item_id = m.household_id;

SELECT hhm.*
-- INTO bak.aim_c4_hhm_correction_18_06_2026_bracjira_2508
FROM aim_c4_hhm_correction hhm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON hhm.item_id = m.member_id;

WITH migration AS (SELECT member_id AS item_id, new_community_id
                   FROM c4_community_merge.participants_community_migration_unique_hhm
                   UNION ALL
                   SELECT household_id AS item_id, new_community_id
                   FROM c4_community_merge.participants_community_migration_unique_hh)
SELECT s.*
-- INTO bak.survey_18_06_2026_bracjira_2508
FROM migration m
         JOIN survey s ON s.item_id = m.item_id;


-- ════════════════════════════════════════════════════════════════════════════
-- ── 2. PREVIEW
-- ════════════════════════════════════════════════════════════════════════════
SELECT hh.id,
       hh.catchment_id                      AS current_catchment_id,
       m.new_community_id                   AS new_catchment_id,
       hh.answer::jsonb ->> '_catchment_id' AS json_catchment_id_before,
       hh.last_modified_by,
       jsonb_set(
               hh.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
       )::text                              as new_answer
FROM house_hold hh
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON hh.id = m.household_id;

SELECT hhm.id,
       hhm.fiscal_year_id,
       hhm.catchment_id                      AS current_catchment_id,
       m.new_community_id                    AS new_catchment_id,
       hhm.answer::jsonb ->> '_catchment_id' AS json_catchment_id_before,
       hhm.last_modified_by,
       jsonb_set(
               hhm.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
       )::text                               as new_answer
FROM house_hold_member hhm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = hhm.id;

SELECT s.id,
       s.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       s.fiscal_year_id,
       s.last_modified_by
FROM aim_c4_hhm_survey s
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = s.id;

SELECT s.id,
       s.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       s.fiscal_year_id,
       s.last_modified_by
FROM aim_c4_hh_survey s
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON m.household_id = s.id;

SELECT pgm.id,
       pgm.member_id,
       pgm.group_id,
       pgm.fiscal_year_id,
       pgm.member_type,
       pgm.is_deleted
FROM participant_group_member pgm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pgm.member_id;

SELECT pgm.id,
       pgm.group_id,
       pgm.member_id,
       now(),                              -- exit_time
       now(),                              -- create_time
       now(),                              -- last_modified_time
       null,                               -- is_deleted
       'bb694b7fce3a4183a249f02382dbd962', -- exit_reason_id
       'stream_fresh_community_migration', -- created_by
       'stream_fresh_community_migration', -- last_modified_by
       pgm.member_type,
       'UnEnrolment',                      -- exit_status
       row_to_json(pgm.*)::text,           -- full pgm row snapshot as JSON
       null,                               -- linked_group_id
       pgm.fiscal_year_id,
       null,                               -- last_sync_time
       null,                               -- rule_ids
       null                                -- rules
FROM participant_group_member pgm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pgm.member_id;


SELECT e.id,
       e.item_id,
       e.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       e.fiscal_year_id,
       e.last_modified_by
FROM aim_c4_enrollment e
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = e.item_id;

SELECT sv.id,
       sv.item_id,
       sv.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       sv.fiscal_year_id,
       sv.last_modified_by
FROM aim_c4_hhm_survey_verification sv
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = sv.item_id;

SELECT hv.id,
       hv.item_id,
       hv.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       hv.fiscal_year_id,
       hv.last_modified_by
FROM aim_c4_hh_survey_verification hv
         JOIN c4_community_merge.participants_community_migration_unique_hh m
              ON m.household_id = hv.item_id;

SELECT hc.id,
       hc.item_id,
       hc.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       hc.fiscal_year_id,
       hc.last_modified_by
FROM aim_c4_hhm_correction hc
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = hc.item_id;

WITH migration AS (SELECT member_id AS item_id, new_community_id
                   FROM c4_community_merge.participants_community_migration_unique_hhm
                   UNION ALL
                   SELECT household_id AS item_id, new_community_id
                   FROM c4_community_merge.participants_community_migration_unique_hh)
SELECT s.id,
       s.item_id,
       s.catchment_id,
    m.new_community_id,
       jsonb_set(
               s.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
                )::text as new_answer
FROM migration m
         JOIN survey s ON s.item_id = m.item_id;


-- ════════════════════════════════════════════════════════════════════════════
-- ── 3. UPDATE
-- ════════════════════════════════════════════════════════════════════════════
UPDATE house_hold hh
SET catchment_id       = m.new_community_id,
    answer             = jsonb_set(
            hh.answer::jsonb,
            '{_catchment_id}',
            to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hh m
WHERE hh.id = m.household_id;

UPDATE house_hold_member hhm
SET catchment_id       = m.new_community_id,
    answer             = jsonb_set(
            hhm.answer::jsonb,
            '{_catchment_id}',
            to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hhm m
WHERE hhm.id = m.member_id;

UPDATE aim_c4_hhm_survey s
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hhm m
WHERE s.id = m.member_id;

UPDATE aim_c4_hh_survey s
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hh m
WHERE s.id = m.household_id;

UPDATE aim_c4_enrollment e
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hhm m
WHERE e.item_id = m.member_id;

UPDATE aim_c4_hhm_survey_verification sv
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hhm m
WHERE sv.item_id = m.member_id;

UPDATE aim_c4_hh_survey_verification hv
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hh m
WHERE hv.item_id = m.household_id;

UPDATE aim_c4_hhm_correction hc
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM c4_community_merge.participants_community_migration_unique_hhm m
WHERE hc.item_id = m.member_id;


WITH migration AS (
    SELECT member_id    AS item_id, new_community_id
    FROM   c4_community_merge.participants_community_migration_unique_hhm
    UNION ALL
    SELECT household_id AS item_id, new_community_id
    FROM   c4_community_merge.participants_community_migration_unique_hh
)
UPDATE survey s
SET
    catchment_id       = m.new_community_id,
    answer             = jsonb_set(
                             s.answer::jsonb,
                             '{_catchment_id}',
                             to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
        last_modified_by   = 'stream_fresh_community_migration'
FROM migration m
WHERE s.item_id      = m.item_id;


INSERT INTO participant_group_exit (id,
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
                                    rules)
SELECT pgm.id,
       pgm.group_id,
       pgm.member_id,
       now(),                              -- exit_time
       now(),                              -- create_time
       now(),                              -- last_modified_time
       null,                               -- is_deleted
       '0c418d2fdc6243f798053ca7296e46f4', -- exit_reason_id
       'stream_fresh_community_migration', -- created_by
       'stream_fresh_community_migration', -- last_modified_by
       pgm.member_type,
       'UnEnrolment',                      -- exit_status
       row_to_json(pgm.*)::text,           -- full pgm row snapshot as JSON
       null,                               -- linked_group_id
       pgm.fiscal_year_id,
       null,                               -- last_sync_time
       null,                               -- rule_ids
       null                                -- rules
FROM participant_group_member pgm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pgm.member_id
ON CONFLICT (id) DO NOTHING;
-- safe re-run: skip already-exited rows


-- ── Step 2: Verify INSERT before deleting ───────────────────────────────────
SELECT pge.id,
       pge.member_id,
       pge.group_id,
       pge.fiscal_year_id,
       pge.exit_status,
       pge.exit_reason_id,
       pge.created_by,
       pge.create_time,
       pge.is_deleted
FROM participant_group_exit pge
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pge.member_id
WHERE pge.created_by = 'stream_fresh_community_migration'
ORDER BY pge.member_id;

SELECT *
FROM exit_reason
where id = '0c418d2fdc6243f798053ca7296e46f4';


-- ── Step 4: DELETE from participant_group_member (hard delete) ───────────────
DELETE
FROM participant_group_member pgm
    USING c4_community_merge.participants_community_migration_unique_hhm m
WHERE pgm.member_id = m.member_id;


-- ── Step 5: Verify DELETE ────────────────────────────────────────────────────
-- Should return 0 rows
SELECT COUNT(*) AS remaining_pgm_rows
FROM participant_group_member pgm
         JOIN c4_community_merge.participants_community_migration_unique_hhm m
              ON m.member_id = pgm.member_id;




--#############################################################################################################################
--#############################################################################################################################
--#############################################################################################################################
--#############################################################################################################################
--#############################################################################################################################
--#############################################################################################################################
--#############################################################################################################################


SELECT * FROM community_split_brac_jira_1954.participants_transfer_with_id_18_06_26;
DROP TABLE community_split_brac_jira_1954.participants_transfer_unique_hh;
SELECT DISTINCT member_id,
    current_community_id,
    move_community_id as new_community_id
       INTO community_split_brac_jira_1954.participants_transfer_unique_hhm
       FROM community_split_brac_jira_1954.participants_transfer_with_id_18_06_26;

SELECT DISTINCT house_hold_id,
    current_community_id,
    move_community_id as new_community_id
       INTO community_split_brac_jira_1954.participants_transfer_unique_hh
       FROM community_split_brac_jira_1954.participants_transfer_with_id_18_06_26;

SELECT * FROM community_split_brac_jira_1954.participants_transfer_unique_hh;   -- 187
SELECT * FROM community_split_brac_jira_1954.participants_transfer_unique_hhm;   -- 209
-- bcda2257-c5f6-4d86-9591-d34da11b00c9

-- ════════════════════════════════════════════════════════════════════════════
-- ── 1. Backup
-- ════════════════════════════════════════════════════════════════════════════
SELECT hh.*
-- INTO bak.house_hold_18_06_2026_bracjira_1954
FROM house_hold hh
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON hh.id = m.house_hold_id;

SELECT hhm.*
-- INTO bak.house_hold_member_18_06_2026_bracjira_1954
FROM house_hold_member hhm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = hhm.id;

SELECT s.*
-- INTO bak.aim_c4_hh_survey_18_06_2026_bracjira_1954
FROM aim_c4_hh_survey s
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON m.house_hold_id = s.id;

SELECT s.*
-- INTO bak.aim_c4_hhm_survey_18_06_2026_bracjira_1954
FROM aim_c4_hhm_survey s
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = s.id;

SELECT pgm.*
-- INTO bak.participant_group_member_18_06_2026_bracjira_1954
FROM participant_group_member pgm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pgm.member_id;


SELECT hhm.*
-- INTO bak.aim_c4_enrollment_18_06_2026_bracjira_1954
FROM aim_c4_enrollment hhm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON hhm.item_id = m.member_id;

SELECT hhm.*
-- INTO bak.aim_c4_hhm_survey_verification_18_06_2026_bracjira_1954
FROM aim_c4_hhm_survey_verification hhm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON hhm.item_id = m.member_id;

SELECT hh.*
-- INTO bak.aim_c4_hh_survey_verification_18_06_2026_bracjira_1954
FROM aim_c4_hh_survey_verification hh
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON hh.item_id = m.house_hold_id;

SELECT hhm.*
-- INTO bak.aim_c4_hhm_correction_18_06_2026_bracjira_1954
FROM aim_c4_hhm_correction hhm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON hhm.item_id = m.member_id;

WITH migration AS (SELECT member_id AS item_id, new_community_id
                   FROM community_split_brac_jira_1954.participants_transfer_unique_hhm
                   UNION ALL
                   SELECT house_hold_id AS item_id, new_community_id
                   FROM community_split_brac_jira_1954.participants_transfer_unique_hh)
SELECT s.*
-- INTO bak.survey_18_06_2026_bracjira_1954
FROM migration m
         JOIN survey s ON s.item_id = m.item_id;


-- ════════════════════════════════════════════════════════════════════════════
-- ── 2. PREVIEW
-- ════════════════════════════════════════════════════════════════════════════
SELECT hh.id,
       hh.catchment_id                      AS current_catchment_id,
       m.new_community_id                   AS new_catchment_id,
       hh.answer::jsonb ->> '_catchment_id' AS json_catchment_id_before,
       hh.last_modified_by,
       jsonb_set(
               hh.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
       )::text                              as new_answer
FROM house_hold hh
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON hh.id = m.house_hold_id;

SELECT hhm.id,
       hhm.fiscal_year_id,
       hhm.catchment_id                      AS current_catchment_id,
       m.new_community_id                    AS new_catchment_id,
       hhm.answer::jsonb ->> '_catchment_id' AS json_catchment_id_before,
       hhm.last_modified_by,
       jsonb_set(
               hhm.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
       )::text                               as new_answer
FROM house_hold_member hhm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = hhm.id;

SELECT s.id,
       s.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       s.fiscal_year_id,
       s.last_modified_by
FROM aim_c4_hhm_survey s
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = s.id;

SELECT s.id,
       s.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       s.fiscal_year_id,
       s.last_modified_by
FROM aim_c4_hh_survey s
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON m.house_hold_id = s.id;

SELECT pgm.id,
       pgm.member_id,
       pgm.group_id,
       pgm.fiscal_year_id,
       pgm.member_type,
       pgm.is_deleted
FROM participant_group_member pgm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pgm.member_id;

SELECT pgm.id,
       pgm.group_id,
       pgm.member_id,
       now(),                              -- exit_time
       now(),                              -- create_time
       now(),                              -- last_modified_time
       null,                               -- is_deleted
       'bb694b7fce3a4183a249f02382dbd962', -- exit_reason_id
       'stream_fresh_community_migration', -- created_by
       'stream_fresh_community_migration', -- last_modified_by
       pgm.member_type,
       'UnEnrolment',                      -- exit_status
       row_to_json(pgm.*)::text,           -- full pgm row snapshot as JSON
       null,                               -- linked_group_id
       pgm.fiscal_year_id,
       null,                               -- last_sync_time
       null,                               -- rule_ids
       null                                -- rules
FROM participant_group_member pgm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pgm.member_id;


SELECT e.id,
       e.item_id,
       e.catchment_id     AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       e.fiscal_year_id,
       e.last_modified_by
FROM aim_c4_enrollment e
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = e.item_id;

SELECT sv.id,
       sv.item_id,
       sv.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       sv.fiscal_year_id,
       sv.last_modified_by
FROM aim_c4_hhm_survey_verification sv
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = sv.item_id;

SELECT hv.id,
       hv.item_id,
       hv.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       hv.fiscal_year_id,
       hv.last_modified_by
FROM aim_c4_hh_survey_verification hv
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hh m
              ON m.house_hold_id = hv.item_id;

SELECT hc.id,
       hc.item_id,
       hc.catchment_id    AS current_catchment_id,
       m.new_community_id AS new_catchment_id,
       hc.fiscal_year_id,
       hc.last_modified_by
FROM aim_c4_hhm_correction hc
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = hc.item_id;

WITH migration AS (SELECT member_id AS item_id, new_community_id
                   FROM community_split_brac_jira_1954.participants_transfer_unique_hhm
                   UNION ALL
                   SELECT house_hold_id AS item_id, new_community_id
                   FROM community_split_brac_jira_1954.participants_transfer_unique_hh)
SELECT s.id,
       s.item_id,
       s.catchment_id,
    m.new_community_id,
       jsonb_set(
               s.answer::jsonb,
               '{_catchment_id}',
               to_jsonb(m.new_community_id)
                )::text as new_answer
FROM migration m
         JOIN survey s ON s.item_id = m.item_id;


-- ════════════════════════════════════════════════════════════════════════════
-- ── 3. UPDATE
-- ════════════════════════════════════════════════════════════════════════════
UPDATE house_hold hh
SET catchment_id       = m.new_community_id,
    answer             = jsonb_set(
            hh.answer::jsonb,
            '{_catchment_id}',
            to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hh m
WHERE hh.id = m.house_hold_id;

UPDATE house_hold_member hhm
SET catchment_id       = m.new_community_id,
    answer             = jsonb_set(
            hhm.answer::jsonb,
            '{_catchment_id}',
            to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE hhm.id = m.member_id;

UPDATE aim_c4_hhm_survey s
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE s.id = m.member_id;

UPDATE aim_c4_hh_survey s
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hh m
WHERE s.id = m.house_hold_id;

UPDATE aim_c4_enrollment e
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE e.item_id = m.member_id;

UPDATE aim_c4_hhm_survey_verification sv
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE sv.item_id = m.member_id;

UPDATE aim_c4_hh_survey_verification hv
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hh m
WHERE hv.item_id = m.house_hold_id;

UPDATE aim_c4_hhm_correction hc
SET catchment_id       = m.new_community_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_migration'
FROM community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE hc.item_id = m.member_id;


WITH migration AS (
    SELECT member_id    AS item_id, new_community_id
    FROM   community_split_brac_jira_1954.participants_transfer_unique_hhm
    UNION ALL
    SELECT house_hold_id AS item_id, new_community_id
    FROM   community_split_brac_jira_1954.participants_transfer_unique_hh
)
UPDATE survey s
SET
    catchment_id       = m.new_community_id,
    answer             = jsonb_set(
                             s.answer::jsonb,
                             '{_catchment_id}',
                             to_jsonb(m.new_community_id)
                         )::text,
    last_modified_time = now(),
        last_modified_by   = 'stream_fresh_community_migration'
FROM migration m
WHERE s.item_id      = m.item_id;


INSERT INTO participant_group_exit (id,
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
                                    rules)
SELECT pgm.id,
       pgm.group_id,
       pgm.member_id,
       now(),                              -- exit_time
       now(),                              -- create_time
       now(),                              -- last_modified_time
       null,                               -- is_deleted
       '0c418d2fdc6243f798053ca7296e46f4', -- exit_reason_id
       'stream_fresh_community_migration', -- created_by
       'stream_fresh_community_migration', -- last_modified_by
       pgm.member_type,
       'UnEnrolment',                      -- exit_status
       row_to_json(pgm.*)::text,           -- full pgm row snapshot as JSON
       null,                               -- linked_group_id
       pgm.fiscal_year_id,
       null,                               -- last_sync_time
       null,                               -- rule_ids
       null                                -- rules
FROM participant_group_member pgm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pgm.member_id
ON CONFLICT (id) DO NOTHING;
-- safe re-run: skip already-exited rows


-- ── Step 2: Verify INSERT before deleting ───────────────────────────────────
SELECT pge.id,
       pge.member_id,
       pge.group_id,
       pge.fiscal_year_id,
       pge.exit_status,
       pge.exit_reason_id,
       pge.created_by,
       pge.create_time,
       pge.is_deleted
FROM participant_group_exit pge
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pge.member_id
WHERE pge.created_by = 'stream_fresh_community_migration'
ORDER BY pge.member_id;

SELECT *
FROM exit_reason
where id = '0c418d2fdc6243f798053ca7296e46f4';


-- ── Step 4: DELETE from participant_group_member (hard delete) ───────────────
DELETE
FROM participant_group_member pgm
    USING community_split_brac_jira_1954.participants_transfer_unique_hhm m
WHERE pgm.member_id = m.member_id;


-- ── Step 5: Verify DELETE ────────────────────────────────────────────────────
-- Should return 0 rows
SELECT COUNT(*) AS remaining_pgm_rows
FROM participant_group_member pgm
         JOIN community_split_brac_jira_1954.participants_transfer_unique_hhm m
              ON m.member_id = pgm.member_id;