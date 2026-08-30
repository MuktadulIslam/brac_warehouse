-- ******************************************* Creating a catchment map table *******************************************
-- DROP TABLE IF EXISTS c4_community_merge.catchment_merge_map;
-- SELECT * FROM c4_community_merge.catchment_merge_map;
SELECT * FROM c4_community_merge.rwanda_merge_request_12_6_26;

CREATE TABLE c4_community_merge.catchment_merge_map AS
WITH src_tgt AS (
  SELECT c1_id AS src_staged, merged_id AS tgt_staged, c1_community AS src_name
  FROM c4_community_merge.rwanda_merge_request_12_6_26
  UNION ALL
  SELECT c2_id, merged_id, c2_community
  FROM c4_community_merge.rwanda_merge_request_12_6_26
)
SELECT
  src.id   AS src_catchment_id,     -- native (undashed) format
  tgt.id   AS tgt_catchment_id,
  st.src_name
FROM src_tgt st
JOIN catchment src ON replace(src.id,'-','') = replace(st.src_staged,'-','')
JOIN catchment tgt ON replace(tgt.id,'-','') = replace(st.tgt_staged,'-','');


-- ******************************************* Backup *******************************************
-- ============================================================
-- BACKUP — C4 Community Merge Catchments (14-06-2026)
-- Target Schema : c4_community_merge
-- Fiscal Year   : e9d5edf630f34068bd0924d23546c82b
-- ============================================================


-- ╔══════════════════════════════════════╗
-- ║  SURVEY TABLES                       ║
-- ╚══════════════════════════════════════╝

-- 1. aim_c4_hhm_correction
SELECT t.*
INTO c4_community_merge.aim_c4_hhm_correction_14_06_2026
FROM aim_c4_hhm_correction t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 2. aim_c4_enrollment
SELECT t.*
INTO c4_community_merge.aim_c4_enrollment_14_06_2026
FROM aim_c4_enrollment t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 3. aim_c4_hh_survey_verification
SELECT t.*
INTO c4_community_merge.aim_c4_hh_survey_verification_14_06_2026
FROM aim_c4_hh_survey_verification t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 4. aim_c4_hhm_survey_verification
SELECT t.*
INTO c4_community_merge.aim_c4_hhm_survey_verification_14_06_2026
FROM aim_c4_hhm_survey_verification t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 5. community_level_inception_meeting
SELECT t.*
-- INTO c4_community_merge.community_level_inception_meeting_14_06_2026
FROM community_level_inception_meeting t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 6. survey
SELECT t.*
INTO c4_community_merge.survey_14_06_2026
FROM survey t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';


-- ╔══════════════════════════════════════╗
-- ║  NORMAL TABLES                       ║
-- ╚══════════════════════════════════════╝
-- 6. aim_c4_hh_survey
SELECT t.*
INTO c4_community_merge.aim_c4_hh_survey_14_06_2026
FROM aim_c4_hh_survey t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 7. aim_c4_hhm_survey
SELECT t.*
INTO c4_community_merge.aim_c4_hhm_survey_14_06_2026
FROM aim_c4_hhm_survey t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 8. participant_group
SELECT t.*
INTO c4_community_merge.participant_group_14_06_2026
FROM participant_group t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 9. service_point
SELECT t.*
-- INTO c4_community_merge.service_point_14_06_2026
FROM service_point t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 10. staff_village_mapping
-- SELECT t.*
-- INTO c4_community_merge.staff_village_mapping_14_06_2026
-- FROM staff_village_mapping t
-- JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 11. house_hold_member  (With Answer)
SELECT t.*
INTO c4_community_merge.house_hold_member_14_06_2026
FROM house_hold_member t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 12. house_hold  (With Answer)
SELECT t.*
INTO c4_community_merge.house_hold_14_06_2026
FROM house_hold t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 13. stakeholder
SELECT t.*
INTO c4_community_merge.stakeholder_14_06_2026
FROM stakeholder t JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- 14. trainer
SELECT t.*
INTO c4_community_merge.trainer_14_06_2026
FROM trainer t
JOIN c4_community_merge.catchment_merge_map m ON m.src_catchment_id = t.catchment_id WHERE t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';





-- ****************************************** Updating ******************************************
UPDATE aim_c4_hhm_correction t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE aim_c4_enrollment t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE aim_c4_hh_survey_verification t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE aim_c4_hhm_survey_verification t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE community_level_inception_meeting t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE aim_c4_hh_survey t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE aim_c4_hhm_survey t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE participant_group t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh_community_merge'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

UPDATE service_point t
SET catchment_id = m.tgt_catchment_id, last_modified_time = now(), last_modified_by = 'stream_fresh'
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';




select catchment_id, answer from c4_community_merge.house_hold_member_14_06_2026 where id='9b738c3cb41c4ad29cfad253c9bc5f0f';   -- f83ec048-8589-47a1-a32e-3b0d71d7ed59
select catchment_id, answer from house_hold_member where id='9b738c3cb41c4ad29cfad253c9bc5f0f';     -- 3a2e3eee-6ebb-4083-ace2-cc57e107d8f6, "3a2e3eee-6ebb-4083-ace2-cc57e107d8f6",
SELECT * FROM c4_community_merge.catchment_merge_map where src_catchment_id ='f83ec048-8589-47a1-a32e-3b0d71d7ed59'

-- =========================================================
-- STEP 1 — house_hold_member: audit + JSON only, via house_hold.
--          MUST precede the house_hold catchment flip.
-- =========================================================
UPDATE house_hold_member t
SET last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_merge',
    catchment_id = m.tgt_catchment_id,
    answer = CASE WHEN t.answer ~ '^\s*\{'
                  THEN jsonb_set(t.answer::jsonb, '{_catchment_id}',
                                 to_jsonb(m.tgt_catchment_id), false)::text
                  ELSE t.answer END
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id   = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- =========================================================
-- house_hold (owns catchment_id + answer)
-- =========================================================
UPDATE house_hold t
SET catchment_id       = m.tgt_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_merge',
    answer = CASE WHEN t.answer ~ '^\s*\{'
                  THEN jsonb_set(t.answer::jsonb, '{_catchment_id}',
                                 to_jsonb(m.tgt_catchment_id), false)::text
                  ELSE t.answer END
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id   = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- =========================================================
-- survey (partitioned; owns catchment_id + answer)
-- =========================================================
UPDATE survey t
SET catchment_id       = m.tgt_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_merge',
    answer = CASE WHEN t.answer ~ '^\s*\{'
                  THEN jsonb_set(t.answer::jsonb, '{_catchment_id}',
                                 to_jsonb(m.tgt_catchment_id), false)::text
                  ELSE t.answer END
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id   = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- =========================================================
-- stakeholder (owns catchment_id + answer)
-- =========================================================
UPDATE stakeholder t
SET catchment_id       = m.tgt_catchment_id,
    last_modified_time = now(),
last_modified_by   = 'stream_fresh_community_merge',
    answer = CASE WHEN t.answer ~ '^\s*\{'
                  THEN jsonb_set(t.answer::jsonb, '{_catchment_id}',
                                 to_jsonb(m.tgt_catchment_id), false)::text
                  ELSE t.answer END
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id   = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';

-- =========================================================
-- trainer (owns catchment_id + answer)
-- =========================================================
SELECT * FROM c4_community_merge.trainer_14_06_2026;
UPDATE trainer t
SET catchment_id       = m.tgt_catchment_id,
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh_community_merge',
    answer = CASE WHEN t.answer ~ '^\s*\{'
                  THEN jsonb_set(t.answer::jsonb, '{_catchment_id}',
                                 to_jsonb(m.tgt_catchment_id), false)::text
                  ELSE t.answer END
FROM c4_community_merge.catchment_merge_map m
WHERE t.catchment_id   = m.src_catchment_id AND t.fiscal_year_id = 'e9d5edf630f34068bd0924d23546c82b';