---------------------------------------Same member but different age group------------------------------------
WITH c3 AS (SELECT * FROM fiscal_year WHERE name = 'Cohort 4'),

     epm AS (SELECT epm.*
             FROM event_plan_member epm
                      JOIN c3 ON c3.id = epm.fiscal_year_id),

     epm_details AS (SELECT epm.id                                                   AS epm_id,
                            epm.member_id,
                            pg.name                                                  AS epm_group_name,
                            pg.participant_group_type_id,
                            pgt.name                                                 AS epm_group_type_name,
                            ep.is_executed,
                            es.name                                                  AS session_name,
                            es.group_type_id,
                            gts.ids                                                  AS session_group_type_ids,
                            NOT (pg.participant_group_type_id::text = ANY (gts.ids)) AS false_data,
                            (SELECT string_agg(t.name, ', ' ORDER BY gt.ord)
                             FROM unnest(gts.ids) WITH ORDINALITY AS gt(id, ord)
                                      JOIN participant_group_type t ON t.id = gt.id) AS session_group_type_names,
                            e.event_name,
                            es.event_id,
                     es.id as session_id
                     FROM epm
                              JOIN event_plan ep ON ep.id = epm.event_plan_id
                              JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
                              JOIN event_session es ON es.id = esfu.event_session_id
                              JOIN event e ON e.id = es.event_id
                              JOIN participant_group pg ON pg.id = epm.group_id
                              JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                              CROSS JOIN LATERAL (
                         SELECT string_to_array(
                                        nullif(regexp_replace(coalesce(es.group_type_id, ''), '\s', '', 'g'), ''),
                                        ','
                                ) AS ids
                         ) gts)
SELECT *
FROM epm_details
WHERE false_data;

---------------------------------------Same member, same age group but different event------------------------------------
WITH c3 AS (SELECT * FROM fiscal_year WHERE name = 'Cohort 4'),

     epm AS (SELECT epm.*
             FROM event_plan_member epm
                      JOIN c3 ON c3.id = epm.fiscal_year_id),

     epm_details AS (SELECT epm.member_id,
                            e.event_name,
                            es.event_id,
                            string_agg(es.id,',') session_ids,
                            string_agg(es.name,',') session_names
                     FROM epm
                              JOIN event_plan ep ON ep.id = epm.event_plan_id
                              JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
                              JOIN event_session es ON es.id = esfu.event_session_id
                              JOIN event e ON e.id = es.event_id
                     WHERE e.event_name ILIKE '%Curriculum%'
                     GROUP BY epm.member_id, e.event_name, es.event_id),

     member_event_counts AS (SELECT member_id, COUNT(DISTINCT event_id) AS event_count
                              FROM epm_details
                              GROUP BY member_id
                              HAVING COUNT(DISTINCT event_id) > 1)

SELECT ed.*
FROM epm_details ed
JOIN member_event_counts mec ON mec.member_id = ed.member_id
ORDER BY ed.member_id;




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Step-0:  Identifying false group type in event session
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH event_with_group_type AS (SELECT e.id, e.event_name, es.group_type_id, pgt.name as group_type
                               FROM event e
                                        JOIN event_session es ON e.id = es.event_id
                                        JOIN participant_group_type pgt ON pgt.id = es.group_type_id
                                        JOIN fiscal_year fy ON e.fiscal_year_id = fy.id
                               WHERE e.event_name ILIKE '%Curriculum%'
                                 AND fy.name = 'Cohort 4'
                               GROUP BY e.id, es.group_type_id, e.event_name, pgt.name)

SELECT * FROM event_with_group_type; --having count(distinct group_type_id)>1;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Step-1:  Identifying all duplicate member list
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH c3 AS (SELECT * FROM fiscal_year WHERE name = 'Cohort 4'),

     epm AS (SELECT epm.*
             FROM event_plan_member epm
                      JOIN c3 ON c3.id = epm.fiscal_year_id
             WHERE group_id IS NOT NULL),

     epm_details AS (SELECT epm.member_id,
                            e.event_name,
                            es.event_id,
                            string_agg(es.id,',') session_ids,
                            string_agg(es.name,',') session_names
                     FROM epm
                              JOIN event_plan ep ON ep.id = epm.event_plan_id
                              JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
                              JOIN event_session es ON es.id = esfu.event_session_id
                              JOIN event e ON e.id = es.event_id
                     WHERE e.event_name ILIKE '%Curriculum%'
                     GROUP BY epm.member_id, e.event_name, es.event_id),

     member_event_counts AS (SELECT member_id, COUNT(DISTINCT event_id) AS event_count
                              FROM epm_details
                              GROUP BY member_id
                              HAVING COUNT(DISTINCT event_id) > 1)

SELECT ed.*
-- INTO temporary.duplicate_event_plan_member
FROM epm_details ed
JOIN member_event_counts mec ON mec.member_id = ed.member_id
ORDER BY ed.member_id;
-- DROP TABLE temporary.duplicate_event_plan_member;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Step-2:  Member id's with false event tag
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH non_duplicate_member_id AS (SELECT distinct member_id FROM temporary.duplicate_event_plan_member),

     members_current_group AS (SELECT pgm.member_id, pgt.name as group_type
                               FROM (SELECT member_id, group_id, is_deleted
                                     FROM participant_group_member
                                     UNION ALL
                                     SELECT member_id, group_id, is_deleted
                                     FROM participant_group_exit) pgm
                                        JOIN non_duplicate_member_id depm ON depm.member_id = pgm.member_id
                                        JOIN participant_group pg ON pg.id = pgm.group_id
                                        JOIN participant_group_type pgt ON pg.participant_group_type_id = pgt.id
                               WHERE pgt.name NOT ILIKE '%VSLA%'
                                 AND pgm.is_deleted IS NOT TRUE
                               GROUP BY pgm.member_id, pgt.name),

     member_aged_group_data AS (SELECT mcg.group_type,
                                       depm.member_id,
                                       depm.event_name,
                                       depm.event_id,
                                       depm.session_ids,
                                       array_length(string_to_array(depm.session_ids, ','), 1) AS session_ids_count
                                FROM temporary.duplicate_event_plan_member depm
                                         LEFT JOIN members_current_group mcg ON mcg.member_id = depm.member_id),

    event_tag AS (SELECT member_id,
                         group_type,
                         event_id,
                         event_name,
                         event_name NOT ILIKE '% ' || group_type || ' %' AS is_false_event_name,
                         row_number() over (PARTITION BY member_id ORDER BY session_ids_count DESC) priority_by_session_count,
                         session_ids_count
                         FROM member_aged_group_data magd),

    final_data AS (
        SELECT *,
               CASE WHEN priority_by = 1 THEN 'keep' ELSE 'drop' END final_tag
               FROM (SELECT member_id,
               group_type,
               event_id,
               event_name,
               row_number() over (partition by member_id ORDER BY is_false_event_name, priority_by_session_count) as priority_by
               FROM event_tag) x
    )

-- SELECT * FROM event_tag WHERE is_false_event_name AND priority_by_session_count = 1;
SELECT *
-- INTO temporary.member_events_to_remove
FROM final_data;
SELECT * FROM temporary.member_events_to_remove;
-- DROP TABLE temporary.member_events_to_remove;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Step-3:  Member id's with false event tag
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =====================================================================
-- STEP 0: Materialize your keep/delete event sets from the temp table
-- =====================================================================
-- (Run this first, or substitute directly wherever event_id_to_keep is used)

WITH member_data AS (
    SELECT
        member_id,
        string_agg(DISTINCT CASE WHEN final_tag = 'keep' THEN event_id END, ',') AS event_id_to_keep,
        string_agg(DISTINCT CASE WHEN final_tag <> 'keep' THEN event_id END, ',') AS event_id_to_delete
    FROM temporary.member_events_to_remove
    GROUP BY member_id
)
SELECT * FROM member_data;


-- =====================================================================
-- STEP 1: REVIEW QUERY — sessions per member, ordered by sort_order_in_event,
--         review sessions excluded, restricted to event_id_to_keep
-- =====================================================================
-- Review this output BEFORE running any UPDATE.

WITH member_data AS (
    SELECT
        member_id,
        string_agg(DISTINCT CASE WHEN final_tag = 'keep' THEN event_id END, ',') AS event_id_to_keep
    FROM temporary.member_events_to_remove
    GROUP BY member_id
),
member_keep_events AS (
    -- unnest the comma-joined keep list back into rows for joining
    SELECT
        md.member_id,
        unnest(string_to_array(md.event_id_to_keep, ',')) AS event_id
    FROM member_data md
    WHERE md.event_id_to_keep IS NOT NULL AND md.event_id_to_keep <> ''
)
SELECT
    epm.member_id,
    epm.id                              AS epm_id,
    epm.fiscal_year_id,
    e.id                                AS event_id,
    es.id                                AS event_session_id,
    es.name                              AS session_name,
    es.sort_order_in_event,
    (es.setting::jsonb ->> 'IsReviewSession')::boolean AS is_review_session,
    es.setting::jsonb ->> 'ReviewSessionId'             AS review_session_id,
    epm.attendance
FROM event_plan_member epm
JOIN event_plan ep               ON ep.id  = epm.event_plan_id
JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
JOIN event_session es            ON es.id  = esfu.event_session_id
JOIN event e                     ON e.id  = es.event_id
JOIN member_keep_events mke      ON mke.member_id = epm.member_id
                                  AND mke.event_id  = e.id
WHERE epm.is_deleted = false
  AND COALESCE((es.setting::jsonb ->> 'IsReviewSession')::boolean, false) = false
ORDER BY epm.member_id, es.sort_order_in_event;


-- =====================================================================
-- STEP 2: THE OR-MERGE UPDATE
-- =====================================================================
-- Logic: for each epm row in event_id_to_keep, merge each date's isPresent
-- with the isPresent value from the "duplicate" epm row (same member, same
-- date) that is being dropped (event_id_to_delete), via boolean OR.
-- Adjust the "source" join below to match how your duplicate rows are
-- actually related (e.g. matched by date, by group_id, etc.)
BEGIN;
WITH member_data AS (SELECT member_id,
                            string_agg(DISTINCT CASE WHEN final_tag = 'keep' THEN event_id END, ',')  AS event_id_to_keep,
                            string_agg(DISTINCT CASE WHEN final_tag <> 'keep' THEN event_id END, ',') AS event_id_to_delete
                     FROM temporary.member_events_to_remove
                     GROUP BY member_id),

     keep_rows AS (SELECT epm.id, epm.member_id, epm.attendance, e.id AS event_id, es.sort_order_in_event, (es.setting::jsonb ->> 'IsReviewSession')::boolean is_review_session
                   FROM event_plan_member epm
                            JOIN event_plan ep ON ep.id = epm.event_plan_id
                            JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
                            JOIN event_session es ON es.id = esfu.event_session_id
                            JOIN event e ON e.id = es.event_id
                            JOIN member_data md ON md.member_id = epm.member_id
                   WHERE epm.is_deleted = false
                     AND e.id = ANY (string_to_array(md.event_id_to_keep, ','))),

     delete_rows AS (SELECT epm.id, epm.member_id, epm.attendance, e.id AS event_id, es.sort_order_in_event, (es.setting::jsonb ->> 'IsReviewSession')::boolean is_review_session
                     FROM event_plan_member epm
                              JOIN event_plan ep ON ep.id = epm.event_plan_id
                              JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id
                              JOIN event_session es ON es.id = esfu.event_session_id
                              JOIN event e ON e.id = es.event_id
                              JOIN member_data md ON md.member_id = epm.member_id
                     WHERE epm.is_deleted = false
                       AND e.id = ANY (string_to_array(md.event_id_to_delete, ','))),

     epm_to_update AS (SELECT *
                       FROM (SELECT kr.id                                             AS epm_id,
                                    kr.member_id,
                                    sort_order_in_event,
                                    is_review_session,
                                    (attendance::jsonb -> 0 ->> 'isPresent')::boolean AS is_present
                             FROM keep_rows kr) x
                       WHERE NOT is_review_session
                         AND NOT is_present),

     epm_will_use_to_update AS (SELECT *
                                FROM (SELECT dr.id                                             AS epm_id,
                                             dr.member_id,
                                             sort_order_in_event,
                                             is_review_session,
                                             (attendance::jsonb -> 0 ->> 'isPresent')::boolean AS is_present
                                      FROM delete_rows dr) x
                                WHERE NOT is_review_session AND is_present),

     merged AS (SELECT kd.member_id,
                       kd.epm_id                                                  AS epm_id,
                       kd.sort_order_in_event,
                       kd.is_present                                              AS current_is_present,
                       (kd.is_present OR bool_or(dd.is_present)) AS merged_is_present
                FROM epm_to_update kd
                         JOIN epm_will_use_to_update dd ON dd.member_id = kd.member_id AND dd.sort_order_in_event = kd.sort_order_in_event
                GROUP BY kd.member_id, kd.sort_order_in_event, kd.is_present, kd.epm_id),

     rebuilt AS (SELECT m.epm_id,
                        epm.attendance as old_attendance,
                        jsonb_set(
                                epm.attendance::jsonb,
                                '{0,isPresent}',
                                to_jsonb(m.merged_is_present)
                        ) AS new_attendance
                 FROM merged m
                 JOIN event_plan_member epm ON epm.id = m.epm_id)
-- SELECT * FROM merged;
-- SELECT * FROM rebuilt;

----------Update----------
-- UPDATE event_plan_member epm
-- SET attendance         = r.new_attendance::text,
--     last_modified_time = now()
-- FROM rebuilt r
-- WHERE epm.id = r.epm_id;

----------Backup----------
-- SELECT *
-- INTO bak.event_plan_member_false_session_attendance_data_26_08_2026
-- FROM delete_rows;

----------Remove False epm rows----------
DELETE FROM event_plan_member epm WHERE epm.id in (SELECT id FROM delete_rows);

COMMIT;

-----------------------Checking----------------------
SELECT id, create_time, last_modified_time, attendance
FROM event_plan_member
WHERE id in ('659030fedf1f4a568ecdcda68a378c1d', '73974b0a296c49c5bb9b21c900923227', '4f0aeb8dd1284e2ab9aadb82cebb01d6',
             '3d71e4dc76c54232900dff707cf93629', '86906e918d86440b8d780e5b479038c1', 'a91d285da1c140d69369b23381ed1946',
             '2fdc6dfb7e5646cbb9797dc6f7e17a80')
