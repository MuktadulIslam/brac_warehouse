-- ============================================================================
-- Livelihood Batch Participant Update Workflow
-- Table under update: livelihood_batch_creation
-- Staging table:       temporary.member_data_for_batch
-- ============================================================================


-- ============================================================================
-- STEP 1: VALIDATION
-- Find member_data_for_batch rows whose member_id is NOT already assigned to
-- any livelihood package. These are the members you must NOT add (or must
-- remove from staging before proceeding).
-- ============================================================================

SELECT x.*, la.id AS existing_assignment_id
FROM temporary.member_data_for_batch x
         LEFT JOIN livelihood_assignment la
                   ON la.enterprise_assignment_eligible_members ILIKE '%' || x.member_id || '%'
WHERE la.id IS NULL;

-- Review this result set manually. Every member_id returned here is
-- unassigned to a package and should be removed from staging (Step 2)
-- before you build the update payload.


-- ============================================================================
-- STEP 2: REMOVE UNASSIGNED MEMBERS FROM STAGING
-- Deletes exactly the rows identified in Step 1 from member_data_for_batch.
-- Uses the same join/predicate so it can't drift from what you reviewed.
-- ============================================================================

BEGIN;

DELETE
FROM temporary.member_data_for_batch x
WHERE NOT EXISTS (SELECT 1
                  FROM livelihood_assignment la
                  WHERE la.enterprise_assignment_eligible_members ILIKE '%' || x.member_id || '%');

-- Sanity check: every remaining staging row should now have a package match
SELECT x.*
FROM temporary.member_data_for_batch x
         LEFT JOIN livelihood_assignment la
                   ON la.enterprise_assignment_eligible_members ILIKE '%' || x.member_id || '%'
WHERE la.id IS NULL;
-- ^ expect 0 rows before you COMMIT

-- COMMIT;   -- uncomment once the sanity check above returns 0 rows
-- ROLLBACK; -- if it doesn't


-- ============================================================================
-- STEP 3: BACKUP
-- ============================================================================

SELECT lbc.*
INTO bak.livelihood_batch_creation_26_07_2026_bracjira_2589
FROM livelihood_batch_creation lbc
WHERE lbc.id IN (SELECT DISTINCT batch_id FROM temporary.member_data_for_batch);

COMMIT;

-- ============================================================================
-- STEP 4: UPDATE
-- ============================================================================

BEGIN;

WITH batch_additions AS (SELECT batch_id,
                                -- de-duplicated, comma-separated list of member_ids to add for this batch
                                string_agg(DISTINCT member_id, ',')         AS new_member_ids,
                                -- de-duplicated, comma-separated list of package ids to add for this batch
                                string_agg(DISTINCT final_package_id, ',')
                                FILTER (WHERE final_package_id IS NOT NULL) AS new_package_ids
                         FROM temporary.member_data_for_batch
                         GROUP BY batch_id),
     merged AS (SELECT lbc.id,
                       lbc.batch_participants,
                       lbc.enterprises,
                       lbc.answer,
                       ba.new_member_ids,
                       ba.new_package_ids,

                       -- merge + de-dup batch_participants
                       (SELECT string_agg(DISTINCT v, ',')
                        FROM unnest(
                                     string_to_array(COALESCE(lbc.batch_participants, ''), ',')
                                         || string_to_array(ba.new_member_ids, ',')
                             ) AS v
                        WHERE v IS NOT NULL
                          AND btrim(v) <> '') AS merged_participants,

                       -- merge + de-dup enterprises (only add package ids not already present)
                       CASE
                           WHEN lbc.enterprises IS NULL THEN lbc.enterprises
                           ELSE
                               (SELECT string_agg(DISTINCT v, ',')
                                FROM unnest(
                                             string_to_array(COALESCE(lbc.enterprises, ''), ',')
                                                 || string_to_array(COALESCE(ba.new_package_ids, ''), ',')
                                     ) AS v
                                WHERE v IS NOT NULL
                                  AND btrim(v) <> '')
                           END                AS merged_enterprises
                FROM livelihood_batch_creation lbc
                         JOIN batch_additions ba ON ba.batch_id = lbc.id)

-- SELECT * FROM merged;

UPDATE livelihood_batch_creation lbc
SET batch_participants = m.merged_participants,
    enterprises        = m.merged_enterprises,
    answer             = (
        (COALESCE(lbc.answer, '{}')::jsonb
             || jsonb_build_object('batch_participants', m.merged_participants)
            || jsonb_build_object('enterprises', m.merged_enterprises)
            )::text
        ),
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh'
FROM merged m
WHERE lbc.id = m.id;


-- ============================================================================
-- STEP 5: VERIFICATION
-- ============================================================================

-- 5a. Every member_id from staging should now appear in the batch's
--     batch_participants column, for the correct batch_id.
SELECT x.batch_id,
       x.member_id,
       lbc.batch_participants,
       lbc.answer::jsonb ->> 'batch_participants' as batch_participants_in_answer,
       (lbc.batch_participants ~ ('(^|,)' || x.member_id || '(,|$)'))       AS participant_present,
       (lbc.answer::jsonb ->> 'batch_participants' ~ ('(^|,)' || x.member_id || '(,|$)'))       AS participant_present_in_answer,
       x.final_package_id,
       lbc.enterprises,
       lbc.answer::jsonb ->> 'enterprises' as enterprises_in_answer,
       (x.final_package_id IS NULL OR lbc.enterprises ~ ('(^|,)' || x.final_package_id || '(,|$)')) AS package_present,
       (x.final_package_id IS NULL OR lbc.answer::jsonb ->> 'enterprises' ~ ('(^|,)' || x.final_package_id || '(,|$)')) AS package_present_in_answer

FROM temporary.member_data_for_batch x
         JOIN livelihood_batch_creation lbc ON lbc.id = x.batch_id
ORDER BY x.batch_id, x.member_id;

COMMIT;   -- once the review above looks correct
-- ROLLBACK; -- if not