-- ============================================================================
-- STEP 1: VALIDATION
-- ============================================================================

SELECT x.batch_id,
       btrim(x.member_id)                                                       AS member_id,
       btrim(x.final_package_id)                                                AS final_package_id,
       (lbc.id IS NULL)                                                         AS batch_not_found,
       lbc.batch_participants ILIKE '%' || member_id || '%'                     AS present_in_column,
       lbc.answer::jsonb ->> 'batch_participants' ILIKE '%' || member_id || '%' AS present_in_answer
FROM temporary.member_attendance_update x
         LEFT JOIN livelihood_batch_creation lbc ON lbc.id = x.current_batch_id
ORDER BY x.batch_id, btrim(x.member_id);

-- ============================================================================
-- STEP 2: BACKUP
-- ============================================================================

SELECT lbc.*
INTO bak.livelihood_batch_creation_removal_30_07_2026_bracjira_3152
FROM livelihood_batch_creation lbc
WHERE lbc.id IN (SELECT DISTINCT batch_id FROM temporary.member_attendance_update);

-- SELECT * FROM bak.livelihood_batch_creation_removal_30_07_2026_bracjira_3152;
-- SELECT * FROM livelihood_batch_creation where id in ('d7af4a0d7217467e99011e924c8cbc11', 'a8760235c6c242378cdc58097ba7ea09', 'e34f91812d95449b9b81009e4c65210f');


-- ============================================================================
-- STEP 3: UPDATE — remove participants
-- ============================================================================

BEGIN;

WITH to_remove AS (SELECT lbc.id,
                          array_agg(DISTINCT x.member_id::text) AS remove_ids
                   FROM temporary.member_attendance_update x
                            JOIN livelihood_batch_creation lbc
                                 ON lbc.id = x.current_batch_id
                                     AND x.member_id::text = ANY
                                         (string_to_array(lbc.batch_participants, ','))
                   GROUP BY lbc.id),
     recomputed AS (SELECT lbc.id,
                           lbc.batch_participants              AS old_participants,
                           (SELECT array_agg(elem ORDER BY ord)
                            FROM unnest(string_to_array(lbc.batch_participants, ','))
                                     WITH ORDINALITY AS u(elem, ord)
                            WHERE elem <> ''
                              AND elem <> ALL (tr.remove_ids)) AS remaining
                    FROM livelihood_batch_creation lbc
                             JOIN to_remove tr ON tr.id = lbc.id)

-- Preview: comment out the UPDATE and run this instead.
-- SELECT id, old_participants, array_to_string(remaining, ',') AS new_participants
-- FROM recomputed ORDER BY id;

UPDATE livelihood_batch_creation lbc
SET batch_participants = COALESCE(array_to_string(r.remaining, ','), ''),
    answer             = jsonb_set(
            COALESCE(lbc.answer, '{}')::jsonb,
            '{batch_participants}',
            to_jsonb(COALESCE(array_to_string(r.remaining, ','), ''))
                         )::text, -- drop ::text if `answer` is a jsonb column
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh'
FROM recomputed r
WHERE lbc.id = r.id;


-- Validating
SELECT x.batch_id,
       btrim(x.member_id)                                                       AS member_id,
       btrim(x.final_package_id)                                                AS final_package_id,
       (lbc.id IS NULL)                                                         AS batch_not_found,
       lbc.batch_participants ILIKE '%' || member_id || '%'                     AS present_in_column,
       lbc.answer::jsonb ->> 'batch_participants' ILIKE '%' || member_id || '%' AS present_in_answer
FROM temporary.member_attendance_update x
         LEFT JOIN livelihood_batch_creation lbc ON lbc.id = x.current_batch_id
ORDER BY x.batch_id, btrim(x.member_id);

-- COMMIT;
-- ROLLBACK;


-- ============================================================================
-- ============================================================================
-- UPDATE — remove data from session attendance
-- ============================================================================
-- ============================================================================

-- ============================================================================
-- STEP 1: VALIDATION / PREVIEW
-- ============================================================================

DROP TABLE IF EXISTS temporary.session_attendance_removal_check;

CREATE TABLE temporary.session_attendance_removal_check AS
SELECT DISTINCT x.member_id,
                x.current_batch_id,
                sa.id                                                        AS session_attendance_id,
                sa.session,
                sa.training_name,
                sa.participants                                              AS current_participants,
                sa.status                                                    AS current_status,
                (x.member_id::text = ANY (string_to_array(sa.participants, ','))) AS is_present
FROM temporary.member_attendance_update x
         JOIN session_attendance sa ON sa.batch = x.current_batch_id
WHERE sa.is_deleted IS NOT TRUE;

-- Preview: everything resolved, present and absent
SELECT *
FROM temporary.session_attendance_removal_check
ORDER BY current_batch_id, member_id, session_attendance_id;

-- Scope check: how much actually changes
SELECT count(*) FILTER (WHERE is_present)               AS rows_to_change,
       count(*) FILTER (WHERE NOT is_present)           AS already_absent,
       count(DISTINCT session_attendance_id) FILTER (WHERE is_present) AS sessions_touched,
       count(DISTINCT member_id)                        AS members
FROM temporary.session_attendance_removal_check;

-- ============================================================================
-- STEP 2: BACKUP
-- Only sessions that will actually change (is_present = true).
-- ============================================================================
DROP TABLE bak.session_attendance_removal_30_07_2026_bracjira_3152;
CREATE TABLE bak.session_attendance_removal_30_07_2026_bracjira_3152 AS
SELECT sa.*
FROM session_attendance sa
WHERE sa.id IN (SELECT DISTINCT session_attendance_id
                FROM temporary.session_attendance_removal_check
                WHERE is_present);

SELECT * FROM bak.session_attendance_removal_30_07_2026_bracjira_3152;
-- ============================================================================
-- STEP 3: UPDATE
-- ============================================================================

BEGIN;

WITH to_remove AS (SELECT c.session_attendance_id                 AS id,
                          array_agg(DISTINCT c.member_id::text)   AS remove_ids
                   FROM temporary.session_attendance_removal_check c
                   WHERE c.is_present
                   GROUP BY c.session_attendance_id),
     recomputed AS (SELECT sa.id,
                           sa.participants AS old_participants,
                           (SELECT array_agg(elem ORDER BY ord)
                            FROM unnest(string_to_array(sa.participants, ','))
                                     WITH ORDINALITY AS u(elem, ord)
                            WHERE elem <> ''
                              AND elem <> ALL (tr.remove_ids)) AS remaining
                    FROM session_attendance sa
                             JOIN to_remove tr ON tr.id = sa.id
                    WHERE sa.is_deleted IS NOT TRUE)

-- Preview: comment out the UPDATE and run this instead.
-- SELECT id, old_participants, array_to_string(remaining, ',') AS new_participants
-- FROM recomputed ORDER BY id;

UPDATE session_attendance sa
SET participants       = COALESCE(array_to_string(r.remaining, ','), ''),
    answer             = jsonb_set(
            COALESCE(sa.answer, '{}')::jsonb,
            '{participants}',
            to_jsonb(COALESCE(array_to_string(r.remaining, ','), ''))
                         )::text, -- drop ::text if `answer` is a jsonb column
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh'
FROM recomputed r
WHERE sa.id = r.id;

SELECT DISTINCT x.member_id,
                x.current_batch_id,
                sa.id                                                        AS session_attendance_id,
                sa.session,
                sa.training_name,
                sa.participants                                              AS current_participants,
                sa.status                                                    AS current_status,
                (x.member_id::text = ANY (string_to_array(sa.participants, ','))) AS is_present
FROM temporary.member_attendance_update x
         JOIN session_attendance sa ON sa.batch = x.current_batch_id
WHERE sa.is_deleted IS NOT TRUE;

COMMIT;
-- ROLLBACK;

