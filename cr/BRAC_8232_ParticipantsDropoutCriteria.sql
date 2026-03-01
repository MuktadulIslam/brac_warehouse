------------------------------------BRAC-8232: Participants Dropout Criteria------------------------------------------------
WITH duplicate_event_plan_member_data AS (SELECT a.member_id,
                                                 a.event_session_id,
                                                 a.group_id,
                                                 a.fiscal_year_id,
                                                 a.is_executed,
                                                 TRIM(BOTH FROM a.attendance_date_wise ->> 'date'::text)::timestamp without time zone AS event_date,
                                                 CASE
                                                     WHEN (a.attendance_date_wise ->> 'isPresent'::text) = 'true'::text
                                                         THEN 1
                                                     ELSE 0
                                                     END                                                                              AS ispresent
                                          FROM (SELECT jsonb_array_elements(epm.attendance::jsonb) AS attendance_date_wise,
                                                       epm.member_id,
                                                       epm.group_id,
                                                       epm.fiscal_year_id,
                                                       esfu.event_session_id,
                                                       ep.is_executed
                                                FROM cohort3_event_plan_member_view epm
                                                         JOIN event_plan ep ON ep.id = epm.event_plan_id
                                                         JOIN event_session_for_user esfu ON esfu.id = ep.event_session_for_user_id) a),
     event_plan_member_data AS (SELECT *
                                FROM (SELECT *,
                                             row_number()
                                             over (PARTITION BY member_id, event_session_id ORDER BY ispresent DESC, is_executed DESC, event_date DESC) r
                                      FROM duplicate_event_plan_member_data) x
                                WHERE r = 1),

     events_total_session AS (SELECT event_id,
                                     count(1) as total_session
                              FROM event_session
                              GROUP BY event_id),

     groups_total_executed_session AS (SELECT group_id,
                                              es.event_id,
                                              ets.total_session,
                                              fy.name as fiscal_year_name,
                                              es.id   as session_id,
                                              es.name as event_session_name

                                       FROM event_plan ep
                                                JOIN LATERAL unnest(string_to_array(ep.group_ids, ',')) AS group_id
                                                     ON TRUE
                                                JOIN event_session_for_user esfu ON ep.event_session_for_user_id = esfu.id
                                                JOIN event_session es ON esfu.event_session_id = es.id
                                                JOIN event e ON es.event_id = e.id
                                                JOIN events_total_session ets ON es.event_id = ets.event_id
                                                JOIN fiscal_year fy ON fy.id = e.fiscal_year_id
                                                JOIN participant_group pg ON pg.id = group_id
                                       WHERE ep.is_executed IS TRUE
                                         AND fy.name = 'Cohort 3'
                                         AND e.event_name ILIKE '%Curriculum%')
--      SELECT * FROM groups_total_executed_session;
        ,

     cohort3_aged_based_group_members AS (SELECT pgm.*,
                                                 pg.name                      as group_name,
                                                 pg.participant_group_type_id as group_type_id,
                                                 pgt.name                     as group_type_name
                                          FROM participant_group_member pgm
                                                   JOIN participant_group pg ON pg.id = pgm.group_id
                                                   JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                                   JOIN fiscal_year fy ON fy.id = pgm.fiscal_year_id
                                          WHERE pgt.name IN ('VYA', 'AG', 'YW', 'EA')
                                            AND fy.name = 'Cohort 3'),

     aged_based_member_session_data AS (SELECT gtes.event_id,
                                               gtes.total_session,
                                               gtes.session_id,
                                               c3abgm.member_id,
                                               c3abgm.id as pgm_id,
                                               c3abgm.group_id,
                                               c3abgm.group_type_id,
                                               c3abgm.group_type_name,
                                               epmd.ispresent

                                        FROM groups_total_executed_session gtes
                                                 JOIN cohort3_aged_based_group_members c3abgm
                                                      ON gtes.group_id = c3abgm.group_id
                                                 LEFT JOIN event_plan_member_data epmd
                                                           ON epmd.member_id = c3abgm.member_id AND
                                                              epmd.event_session_id = gtes.session_id),

     members_total_absent_count AS (SELECT member_id,
                                           pgm_id,
                                           group_type_name,
                                           count(
                                                   CASE
                                                       WHEN ispresent = 0 OR ispresent IS NULL THEN 1
                                                       ELSE 0
                                                       END
                                           ) total_absent_count
                                    FROM aged_based_member_session_data
                                    where ispresent = 0
                                       OR ispresent IS NULL
                                    GROUP BY member_id, pgm_id, group_type_name),

     droppable_members AS (SELECT *
                           FROM members_total_absent_count
                           WHERE (group_type_name IN ('VYA', 'AG', 'YW') AND total_absent_count > 6)
                              OR (group_type_name = 'EA' AND total_absent_count > 9))

-- SELECT * FROM members_total_absent_count;
SELECT *
FROM droppable_members;