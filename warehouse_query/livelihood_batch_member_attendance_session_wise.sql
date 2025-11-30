WITH session_attendanced_members AS (SELECT sa.id as training_session_id,
                                            p.id  as member_id
                                     FROM session_attendance sa
                                              JOIN LATERAL unnest(string_to_array(sa.participants, ',')) p(id) ON true),

     session_attendanced_members_details AS (SELECT get_guid()          as id,
                                                    sa.id               as training_session_id,
                                                    sa.training_name    as training_session_name,
                                                    lbp.batch_id,
                                                    lbp.batch_name,
                                                    lbp.member_id,
                                                    lbp.member_name,
                                                    lbp.age,
                                                    lbp.gender,
                                                    lbp.house_hold_id,
                                                    CASE
                                                        WHEN sam.member_id IS NOT NULL THEN 1
                                                        ELSE 0
                                                        END             AS is_present,
                                                    lbp.country_id,
                                                    lbp.country_name,
                                                    lbp.event_session_id,
                                                    lbp.event_session_name,
                                                    lbp.project_id,
                                                    lbp.project_name,
                                                    lbp.fiscal_year_id,
                                                    lbp.fiscal_year,
                                                    lbp.branch_office_id,
                                                    lbp.branch_office_name,
                                                    CASE
                                                        WHEN sa.status IS NOT NULL THEN 'submitted'
                                                        ELSE 'not submitted'
                                                        END             AS status,
                                                    sa.create_time,
                                                    sa.created_by       as created_by_id,
                                                    cu.name             as created_by,
                                                    sa.last_modified_time,
                                                    sa.last_modified_by as last_modified_by_id,
                                                    mu.name             as last_modified_by
                                             FROM session_attendance sa
                                                      CROSS JOIN muktadul.livelihood_batch_participants lbp
                                                      LEFT JOIN session_attendanced_members sam
                                                                ON sa.id = sam.training_session_id
                                                                    AND lbp.member_id = sam.member_id
                                                      LEFT JOIN public."user" cu ON sa.created_by = cu.id
                                                      LEFT JOIN public."user" mu ON sa.last_modified_by = mu.id
                                             WHERE sa.batch = lbp.batch_id
                                             ORDER BY sa.create_time DESC)

SELECT *
-- INTO muktadul.livelihood_batch_member_attendance_session_wise
FROM session_attendanced_members_details;