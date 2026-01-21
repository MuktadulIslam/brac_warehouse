WITH member_attendance_data AS (SELECT esfu.event_session_id                                                                       as session_id,
                                       epm.member_id,
                                       epm.fiscal_year_id,
                                       'Cohort 3'                                                                                  as fiscal_year_name, -- cohort3_event_plan_member_view table has only cohort 3 data
                                       epm.group_id,
                                       ep.is_executed                                                                              as plan_executed,
                                       min(TRIM(BOTH FROM epm.attendance_date_wise ->> 'date'::text)::timestamp without time zone) AS event_date,
                                       max(CASE
                                               WHEN (epm.attendance_date_wise ->> 'isPresent')::boolean = true
                                                   THEN 1
                                               ELSE 0
                                           END)                                                                                    AS ispresent
                                FROM (SELECT jsonb_array_elements(attendance::jsonb) AS attendance_date_wise,
                                             member_id,
                                             event_plan_id,
                                             group_id,
                                             fiscal_year_id
                                      FROM cohort3_event_plan_member_view) epm
                                         JOIN event_plan ep ON epm.event_plan_id = ep.id
                                         JOIN event_session_for_user esfu
                                              ON esfu.id = ep.event_session_for_user_id
                                GROUP BY esfu.event_session_id, epm.member_id, epm.member_id, epm.event_plan_id,
                                         epm.fiscal_year_id,
                                         epm.group_id,
                                         ep.is_executed),

     member_attendance_data_with_details AS (SELECT mad.*,
                                                    pg.participant_group_type_id as group_type_id,
                                                    es.name                      as session_name
                                             FROM member_attendance_data mad
                                                      JOIN event_session es ON es.id = mad.session_id
                                                      JOIN participant_group pg ON pg.id = mad.group_id)

SELECT *
FROM member_attendance_data_with_detailsW

UNION ALL

SELECT * FROM staging.fact_session_wise_member_attendance_c1_c2_part