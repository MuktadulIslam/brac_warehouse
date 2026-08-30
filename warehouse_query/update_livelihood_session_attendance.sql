-------------------------------------******** Preview ********-------------------------------------
WITH members_to_add AS (SELECT sa.id                                       AS sa_id,
                               sa.participants                             AS current_participants,
                               string_agg(DISTINCT a.member_id::text, ',') AS new_member_ids
                        FROM temporary.member_attendance_update2 a
                                 JOIN livelihood_batch_creation la
                                      ON la.batch_participants ILIKE '%' || a.member_id::text || '%'
                                 JOIN session_attendance sa
                                      ON sa.batch = la.id
                        -- NULL-safe + exact match (old position() dropped NULL participants entirely)
                        WHERE NOT EXISTS (SELECT 1
                                          FROM unnest(string_to_array(COALESCE(sa.participants, ''), ',')) AS p(mid)
                                          WHERE btrim(p.mid) = a.member_id::text)
                        GROUP BY sa.id, sa.participants)

SELECT sa_id,
       new_member_ids,
       current_participants,
       concat_ws(',', NULLIF(btrim(current_participants), ''), new_member_ids) AS updated_participants
FROM members_to_add;

-------------------------------------******** Back-Up ********-------------------------------------
-- INSERT INTO bak.session_attendance_18_08_2026_BRACJira_3526
CREATE TABLE  bak.session_attendance_18_08_2026_BRACJira_3526 AS
WITH members_to_add AS (SELECT sa.id AS sa_id
                        FROM temporary.member_attendance_update2 a
                                 JOIN livelihood_batch_creation la
                                      ON la.batch_participants ILIKE '%' || a.member_id::text || '%'
                                 JOIN session_attendance sa
                                      ON sa.batch = la.id
                        WHERE NOT EXISTS (SELECT 1
                                          FROM unnest(string_to_array(COALESCE(sa.participants, ''), ',')) AS p(mid)
                                          WHERE btrim(p.mid) = a.member_id::text)
                        GROUP BY sa.id)

SELECT st.*
FROM members_to_add a
JOIN session_attendance st ON a.sa_id = st.id;

-------------------------------------******** Update/Delete ********-------------------------------------
BEGIN;
WITH members_to_add AS (SELECT sa.id                                       AS sa_id,
                               sa.participants                             AS current_participants,
                               string_agg(DISTINCT a.member_id::text, ',') AS new_member_ids
                        FROM temporary.member_attendance_update2 a
                                 JOIN livelihood_batch_creation la
                                      ON la.batch_participants ILIKE '%' || a.member_id::text || '%'
                                 JOIN session_attendance sa
                                      ON sa.batch = la.id
                        WHERE NOT EXISTS (SELECT 1
                                          FROM unnest(string_to_array(COALESCE(sa.participants, ''), ',')) AS p(mid)
                                          WHERE btrim(p.mid) = a.member_id::text)
                        GROUP BY sa.id, sa.participants),
     final AS (SELECT sa_id,
                      concat_ws(',', NULLIF(btrim(current_participants), ''), new_member_ids) AS updated_participants
               FROM members_to_add)
UPDATE session_attendance sa
SET participants       = f.updated_participants,
    answer             = jsonb_set(
            COALESCE(sa.answer::jsonb, '{}'::jsonb),   -- jsonb_set(NULL,...) returns NULL and would blank the answer
            '{participants}',
            to_jsonb(f.updated_participants),
            true
                         ),
    last_modified_time = now(),
    last_modified_by   = 'stream_fresh',
    status             = 'submitted'
FROM final f
WHERE sa.id = f.sa_id;
COMMIT;

-------------------------------------******** Checking ********-------------------------------------

SELECT b.member_id, es.name as session_type, sa.id as session_id,
       row_number() over (PARTITION BY member_id, batch, sa.session ORDER BY  sa.create_time ASC) session_no,
       lbc.id as batch_id, sa.participants ilike '%' || b.member_id || '%' as is_present
FROM temporary.member_attendance_update2 b
JOIN livelihood_batch_creation lbc ON lbc.batch_participants ILIKE '%' || b.member_id || '%'
LEFT JOIN session_attendance sa ON sa.batch = lbc.id
LEFT JOIN event_session es ON es.id = sa.session;


WITH session_attendanced_members AS (SELECT sa.id as training_session_id,
                                            sa.batch as batch_id,
                                            p.id  as member_id
                                     FROM session_attendance sa
                                              JOIN LATERAL unnest(string_to_array(sa.participants, ',')) p(id) ON true),

    livelihood_batch_wise_session AS (SELECT b.id                                                        batch_id,
                                  b.batch_name,
                                  s.id                                                        session_id,
                                  b.item_id                                                as session_type_id,
                                  es.name                                                  as session_type_name,
                                  s.training_name,
                                  s.date                                                      training_date,
                                  row_number() over (partition by s.batch order by s.create_time) as session_serial,
                                  s.create_time,
                                  s.created_by,
                                  s.last_modified_time,
                                  s.last_modified_by,
                                  coalesce(s.status, 'not submitted')                         status,
                                  s.fiscal_year_id,
                                  fy.name                                                  as fiscal_year
                           FROM livelihood_batch_creation b
                                    JOIN event_session es ON es.id = b.item_id
                                    JOIN session_attendance s ON b.id = s.batch
                                    LEFT JOIN fiscal_year fy ON s.fiscal_year_id = fy.id),

     session_attendanced_members_details AS (SELECT gen_random_uuid() as id,
                                                    lbws.session_id as training_session_id,
                                                    lbws.training_name as training_session_name,
                                                    lbws.session_type_id as training_session_type_id,
                                                    lbws.session_type_name as training_session_type_name,
                                                    lbws.session_serial,
                                                    lbws.training_date,
                                                    lbws.status,
                                                    lbws.created_by,
                                                    lbws.create_time,
                                                    lbws.last_modified_by,
                                                    lbws.last_modified_time,
                                                    lbp.batch_name,
                                                    lbp.id as batch_id,
                                                    CASE
                                                        WHEN sam.member_id IS NOT NULL THEN 1
                                                        ELSE 0
                                                        END           as is_present,
                                                    CASE
                                                        WHEN sam.member_id IS NOT NULL THEN 'Present'
                                                        ELSE 'Absent'
                                                        END           as attendance_status,
                                                 p.id as member_id
                                             FROM livelihood_batch_creation lbp
         JOIN LATERAL unnest(string_to_array(lbp.batch_participants, ',')) p(id) ON true
                                                      JOIN livelihood_batch_wise_session lbws ON lbp.id = lbws.batch_id
                                                      LEFT JOIN session_attendanced_members sam
                                                                ON sam.training_session_id = lbws.session_id AND
                                                                   sam.member_id = p.id)

SELECT s2.batch_id, s2.batch_name, s2.training_session_id, s2.is_present, s2.member_id  FROM session_attendanced_members_details s2
JOIN  temporary.member_attendance_update2 a ON s2.member_id = a.member_id;