-- ============================================================================
-- STEP 1: VALIDATION / PREVIEW
-- ============================================================================

DROP TABLE IF EXISTS temporary.session_attendance_presence_check;

CREATE TABLE temporary.session_attendance_presence_check AS
SELECT mb.member_id,
       lbc.id                                           AS batch_id,
       sa.id                                            AS session_attendance_id,
       sa.session,
       sa.training_name,
       sa.participants                                  AS current_participants,
       sa.status                                        AS current_status,
       sa.participants ILIKE '%' || mb.member_id || '%' AS is_present
FROM temporary.member_attendance_update mb
         JOIN livelihood_batch_creation lbc ON lbc.batch_participants ILIKE '%' || mb.member_id || '%'
         JOIN session_attendance sa ON sa.batch = lbc.id;

-- Preview: everyone, present and absent
SELECT *
FROM temporary.session_attendance_presence_check;

-- ============================================================================
-- STEP 2: BACKUP
-- Back up every session_attendance row that will be touched, i.e. every
-- non-deleted session whose batch matches a batch_id resolved in Step 1.
-- ============================================================================

CREATE TABLE bak.session_attendance_30_07_2026_bracjira_3040 AS
-- INSERT INTO bak.session_attendance_30_07_2026_bracjira_3262
SELECT sa.*
FROM session_attendance sa
WHERE sa.id IN (SELECT DISTINCT session_attendance_id
                FROM temporary.session_attendance_presence_check
                WHERE is_present IS NOT TRUE);

SELECT *
FROM bak.session_attendance_7_26_2026_bracjira_2763;

-- ============================================================================
-- STEP 3: UPDATE
-- ============================================================================

BEGIN;

WITH
--     member_batches AS (SELECT DISTINCT d4.member_id,
--                                         d3.batch_id
--                         FROM temporary.member_attendance_update d4
--                                  JOIN temporary.batch_member_data3 d3
--                                       ON d3.member_id = d4.member_id),
-- one row per batch_id: de-duplicated, comma-separated member_ids to add
     batch_additions AS (SELECT batch_id,
                                string_agg(DISTINCT member_id, ',') AS new_member_ids
                         FROM temporary.session_attendance_presence_check
                         WHERE is_present IS NOT TRUE
                         GROUP BY batch_id),
     merged AS (SELECT sa.id,
                       sa.participants,
                       ba.new_member_ids,
                       (SELECT string_agg(DISTINCT v, ',')
                        FROM unnest(
                                     string_to_array(COALESCE(sa.participants, ''), ',')
                                         || string_to_array(ba.new_member_ids, ',')
                             ) AS v
                        WHERE v IS NOT NULL
                          AND btrim(v) <> '') AS merged_participants

                FROM session_attendance sa
                         JOIN batch_additions ba ON ba.batch_id = sa.batch
                WHERE sa.is_deleted IS NOT TRUE)

-- SELECT * FROM merged;

UPDATE session_attendance sa
SET participants       = m.merged_participants,
    status             = 'submitted',
    answer             = (
        (COALESCE(sa.answer, '{}')::jsonb
             || jsonb_build_object('participants', m.merged_participants)
            || jsonb_build_object('status', 'submitted')
            )::text
        ),
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh'
FROM merged m
WHERE sa.id = m.id;


-- ============================================================================
-- STEP 4: VERIFICATION
-- ============================================================================
SELECT lbc.id                                                   as batch_id,
       mb.member_id,
       sa.id                                                    AS session_attendance_id,
       sa.participants,
       (sa.answer::jsonb ->> 'participants')                                     AS answer_participants,
       (participants IS NOT DISTINCT FROM (sa.answer::jsonb ->> 'participants')) AS participants_match,
       (sa.participants ~ ('(^|,)' || mb.member_id || '(,|$)')) AS participant_present,
       sa.status,
       (sa.answer::jsonb ->> 'status')                                           AS answer_status,
       sa.last_modified_by,
       sa.last_modified_time
FROM temporary.member_attendance_update mb
         JOIN livelihood_batch_creation lbc ON lbc.batch_participants ILIKE '%' || mb.member_id || '%'
         JOIN session_attendance sa ON sa.batch = lbc.id;

COMMIT;   -- once the review above looks correct
-- ROLLBACK; -- if not