-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--     Step-1: Identify the member ids
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH hhm_data_need_to_update AS (SELECT hhm.id                                    AS hhm_id,
       ace.id                                    AS enrollment_id,
       -- Combined Mismatch Description Flag --
       CASE
           WHEN ahs.age IS DISTINCT FROM ace.c4a_participant_age
               AND ahs.j3c IS DISTINCT FROM ace.c4b_age_group
               THEN 'Age and Age Group Mismatched'
           WHEN ahs.age IS DISTINCT FROM ace.c4a_participant_age
               THEN 'Age Mismatched'
           WHEN ahs.j3c IS DISTINCT FROM ace.c4b_age_group
               THEN 'Age Group Mismatched'
           ELSE 'Matched'
           END                                   AS mismatch_status,
       ahs.is_member_enrolled                    AS is_member_enrolled,

       hhm.census_update_record::jsonb ->> 'age' AS age_before_enrolment,
       ace.c4a_participant_age                   AS enrolment_age,
       hhm.census_update_record::jsonb ->> 'j3c' AS age_group_before_enrolment,
       ace.c4b_age_group                         AS enrolment_age_group
FROM house_hold_member hhm
         JOIN aim_c4_hhm_survey ahs ON ahs.id = hhm.id
         JOIN (SELECT DISTINCT ON (item_id) * FROM aim_c4_enrollment ORDER BY item_id, last_modified_time DESC) ace ON ace.item_id = hhm.id

WHERE (ahs.j3c IS NOT DISTINCT FROM ace.c4b_age_group and ahs.age IS DISTINCT FROM ace.c4a_participant_age)
  AND ahs.is_member_enrolled = '1')

SELECT *
INTO bak.orpahan_table_of_hhm_age_update
FROM hhm_data_need_to_update;

SELECT * FROM bak.orpahan_table_of_hhm_age_update;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--     Update house_hold_member table
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.answer,
       hhm.answer::jsonb ->> 'j3c',
       hhm.answer::jsonb ->> 'age',
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM house_hold_member hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id;


----------backup
CREATE TABLE enrolment_freature.house_hold_member_27_08_2026 AS
SELECT hhm.*
FROM house_hold_member hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id;
SELECT * FROM enrolment_freature.house_hold_member_27_08_2026;


----------update
BEGIN;
UPDATE house_hold_member hhm
SET age                = hhm_up.enrolment_age,
    answer             = (
                            COALESCE(NULLIF(hhm.answer, '')::jsonb, '{}'::jsonb)
                            || jsonb_build_object(
                                   'age', hhm_up.enrolment_age,
                                   'j3c', hhm_up.enrolment_age_group::text
                               )
                         )::text,
    last_modified_by   = 'stream_fresh',
    last_modified_time = now()
FROM bak.orpahan_table_of_hhm_age_update hhm_up
WHERE hhm.id = hhm_up.hhm_id;

----------verify
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.answer,
       hhm.answer::jsonb ->> 'j3c',
       hhm.answer::jsonb ->> 'age',
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM house_hold_member hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id
WHERE hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR
      hhm.answer::jsonb ->> 'age' IS DISTINCT FROM hhm_up.enrolment_age::text OR
      hhm.answer::jsonb ->> 'j3c' IS DISTINCT FROM hhm_up.enrolment_age_group::text;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--     Update aim_c4_hhm_survey table
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.j3c,
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM aim_c4_hhm_survey hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id;


----------backup
CREATE TABLE enrolment_freature.aim_c4_hhm_survey_27_08_2026 AS
SELECT hhm.*
FROM house_hold_member hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id;
SELECT * FROM enrolment_freature.aim_c4_hhm_survey_27_08_2026;


----------update
BEGIN;
UPDATE aim_c4_hhm_survey hhm
SET age                = hhm_up.enrolment_age,
    j3c = hhm_up.enrolment_age_group,
    last_modified_by   = 'stream_fresh',
    last_modified_time = now()
FROM bak.orpahan_table_of_hhm_age_update hhm_up
WHERE hhm.id = hhm_up.hhm_id;

----------verify
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.j3c,
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM aim_c4_hhm_survey hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.id = hhm_up.hhm_id
WHERE hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR
      hhm.j3c IS DISTINCT FROM hhm_up.enrolment_age_group::text;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--     Update aim_c4_hhm_correction table
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.j3c,
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM aim_c4_hhm_correction hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.item_id = hhm_up.hhm_id
WHERE (hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR hhm.j3c IS DISTINCT FROM hhm_up.enrolment_age_group::text);


----------backup
CREATE TABLE enrolment_freature.aim_c4_hhm_correction_27_08_2026 AS
SELECT hhm.*
FROM aim_c4_hhm_correction hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.item_id = hhm_up.hhm_id
WHERE (hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR hhm.j3c IS DISTINCT FROM hhm_up.enrolment_age_group::text);
SELECT * FROM enrolment_freature.aim_c4_hhm_correction_27_08_2026;


----------update
BEGIN;
UPDATE aim_c4_hhm_correction hhm
SET age                = hhm_up.enrolment_age,
    j3c = hhm_up.enrolment_age_group,
    last_modified_by   = 'stream_fresh',
    last_modified_time = now()
FROM bak.orpahan_table_of_hhm_age_update hhm_up
WHERE hhm.item_id = hhm_up.hhm_id AND
      (hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR
      hhm.j3c IS DISTINCT FROM hhm_up.enrolment_age_group::text);

COMMIT;
----------verify
SELECT hhm.age,
       hhm_up.enrolment_age,
       hhm.j3c,
       hhm_up.enrolment_age_group,
       last_modified_by,
       last_modified_time
FROM aim_c4_hhm_correction hhm
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON hhm.item_id = hhm_up.hhm_id
WHERE hhm.age IS DISTINCT FROM hhm_up.enrolment_age OR
      hhm.j3c IS DISTINCT FROM hhm_up.enrolment_age_group::text;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--     Update survey.answer (form 7296f18ee5ae46289b23ac64f775cf9f) — age / j3c
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------preview
SELECT s.id,
       s.item_id,
       s.answer::jsonb ->> 'age'              AS current_age,
       hhm_up.enrolment_age                   AS new_age,
       s.answer::jsonb ->> 'j3c'              AS current_j3c,
       hhm_up.enrolment_age_group             AS new_j3c,
       jsonb_typeof(s.answer::jsonb -> 'age') AS age_json_type,
       jsonb_typeof(s.answer::jsonb -> 'j3c') AS j3c_json_type,
       s.last_modified_by,
       s.last_modified_time
FROM survey s
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON s.item_id = hhm_up.hhm_id
WHERE s.survey_form_id = '7296f18ee5ae46289b23ac64f775cf9f'
  AND (s.answer::jsonb ->> 'age' IS DISTINCT FROM hhm_up.enrolment_age::text OR
       s.answer::jsonb ->> 'j3c' IS DISTINCT FROM hhm_up.enrolment_age_group::text);

----------backup
CREATE TABLE enrolment_freature.survey_hhm_age_27_08_2026 AS
SELECT s.*
FROM survey s
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON s.item_id = hhm_up.hhm_id
WHERE s.survey_form_id = '7296f18ee5ae46289b23ac64f775cf9f'
  AND (s.answer::jsonb ->> 'age' IS DISTINCT FROM hhm_up.enrolment_age::text OR
       s.answer::jsonb ->> 'j3c' IS DISTINCT FROM hhm_up.enrolment_age_group::text);

SELECT * FROM enrolment_freature.survey_hhm_age_27_08_2026;

----------update
BEGIN;
UPDATE survey s
SET answer             = (s.answer::jsonb || jsonb_build_object(
                             'age', hhm_up.enrolment_age::text,
                             'j3c', hhm_up.enrolment_age_group::text
                         ))::text,
    last_modified_by   = 'stream_fresh',
    last_modified_time = now()
FROM bak.orpahan_table_of_hhm_age_update hhm_up
WHERE s.survey_form_id = '7296f18ee5ae46289b23ac64f775cf9f'
  AND s.item_id = hhm_up.hhm_id
  AND (s.answer::jsonb ->> 'age' IS DISTINCT FROM hhm_up.enrolment_age::text OR
       s.answer::jsonb ->> 'j3c' IS DISTINCT FROM hhm_up.enrolment_age_group::text);

COMMIT;

----------verify (expect 0 rows)
SELECT s.item_id,
       s.answer::jsonb ->> 'age' AS age,
       hhm_up.enrolment_age,
       s.answer::jsonb ->> 'j3c' AS j3c,
       hhm_up.enrolment_age_group,
       s.last_modified_by,
       s.last_modified_time
FROM survey s
JOIN bak.orpahan_table_of_hhm_age_update hhm_up ON s.item_id = hhm_up.hhm_id
WHERE s.survey_form_id = '7296f18ee5ae46289b23ac64f775cf9f'
  AND (s.answer::jsonb ->> 'age' IS DISTINCT FROM hhm_up.enrolment_age::text OR
       s.answer::jsonb ->> 'j3c' IS DISTINCT FROM hhm_up.enrolment_age_group::text);



