------------------------------------BRAC-8232: Participants Dropout Criteria------------------------------------------------
WITH events_total_session AS (SELECT event_id,
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
                                         AND e.event_name ILIKE '%Curriculum%'
                                         and group_id = 'ad34764151a14b58b58d0401465fee6d')
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
                                            AND fy.name = 'Cohort 3'
                                            AND group_id = 'ad34764151a14b58b58d0401465fee6d'),

     aged_based_member_session_data AS (SELECT gtes.event_id,
                                               gtes.total_session,
                                               gtes.session_id,
                                               c3abgm.member_id,
                                               c3abgm.id as pgm_id,
                                               c3abgm.group_id,
                                               c3abgm.group_type_id,
                                               c3abgm.group_type_name,
                                               fswma.ispresent

                                        FROM groups_total_executed_session gtes
                                                 JOIN cohort3_aged_based_group_members c3abgm
                                                      ON gtes.group_id = c3abgm.group_id
                                                 LEFT JOIN dm_schema.fact_session_wise_member_attendance fswma
                                                           ON fswma.member_id = c3abgm.member_id AND
                                                              fswma.session_id = gtes.session_id),

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

     droppable_members AS (SELECT * FROM members_total_absent_count
                                    WHERE (group_type_name IN ('VYA','AG','YW') AND total_absent_count > 6) OR
                                          (group_type_name = 'EA' AND total_absent_count > 9)
                                    )

-- SELECT * FROM members_total_absent_count;
SELECT * FROM droppable_members;