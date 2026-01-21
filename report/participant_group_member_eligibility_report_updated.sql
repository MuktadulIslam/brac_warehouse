WITH education_census_date AS (SELECT member_id,
                                      group_id,
                                      CASE
                                          WHEN c1 IS NULL THEN 'Not Found'
                                          WHEN c1 = '1' THEN 'yes'
                                          ELSE 'no'
                                          END as c1,
                                      CASE
                                          WHEN c8 IS NULL THEN 'Not Found'
                                          WHEN c8 = '1' THEN '2013'
                                          WHEN c8 = '2' THEN '2014'
                                          WHEN c8 = '3' THEN '2015'
                                          WHEN c8 = '4' THEN '2016'
                                          WHEN c8 = '5' THEN '2017'
                                          WHEN c8 = '6' THEN '2018'
                                          WHEN c8 = '7' THEN '2019'
                                          WHEN c8 = '8' THEN '2020'
                                          WHEN c8 = '9' THEN '2021'
                                          WHEN c8 = '10' THEN '2022'
                                          WHEN c8 = '11' THEN '2023'
                                          WHEN c8 = '12' THEN '2024'
                                          WHEN c8 = '13' THEN '2025'
                                          ELSE 'Cannot recall'
                                          END as c8,
                                      CASE
                                          WHEN c9 IS NULL THEN 'Not Found'
                                          WHEN c9 = '1' THEN 'yes'
                                          WHEN c9 = '0' THEN 'no'
                                          ELSE 'Refused to answer'
                                          END as c9

                               FROM (SELECT *,
                                            row_number() over (partition by member_id order by create_time desc) r
                                     FROM (SELECT pgm.member_id,
                                                  pgm.group_id,
                                                  app.c1,
                                                  app.c8,
                                                  app.c9,
                                                  app.create_time
                                           FROM aim_education_census app
                                                    JOIN participant_group_member pgm ON pgm.id = app.item_id

                                           UNION ALL

                                           SELECT pgm.member_id,
                                                  pgm.group_id,
                                                  web.c1,
                                                  web.c8,
                                                  web.c9,
                                                  web.create_time
                                           FROM aim_education_census_web_survey web
                                                    JOIN participant_group_member pgm ON pgm.id = web.participant_selection) x) x
                               WHERE r = 1),

     special_ag_participants_for_aim_support AS (SELECT p.id as member_id
                                                 FROM aim_support_for_special_ag_participants asfsap
                                                          LEFT JOIN LATERAL unnest(string_to_array(asfsap.participant_selection, ',')) p(id)
                                                                    ON true
                                                 GROUP BY p.id),

     multi_member_house_holds AS (SELECT house_hold_id,
                                         unnest(string_to_array(member_ids, ',')) as member_id
                                  FROM (SELECT house_hold_id,
                                               string_agg(member_id, ',') as member_ids
                                        FROM dm_schema.livelihood_eligible_participants
                                        WHERE participant_type = 'HouseHoldMember'
                                        GROUP BY house_hold_id
                                        HAVING count(member_id) > 1) x),
     multi_member_selection_for_assignment AS (SELECT *
                                               FROM (SELECT unnest(string_to_array(multi_member_selection_for_assignment, ',')) as member_id
                                                     FROM member_selection_for_enterprise_assignment) x
                                               GROUP BY member_id),

     final_eligibility_multi_eligible_hhm AS (SELECT multi_hhm.member_id,
                                                     CASE
                                                         WHEN final.member_id IS NOT NULL THEN 'Yes'
                                                         WHEN assignment_happened.item_id IS NOT NULL THEN 'No'
                                                         ELSE 'Still Not Assigned'
                                                         END as member_assignment_status
                                              FROM multi_member_house_holds multi_hhm
                                                       LEFT JOIN multi_member_selection_for_assignment final
                                                                 ON multi_hhm.member_id = final.member_id
                                                       LEFT JOIN member_selection_for_enterprise_assignment assignment_happened
                                                                 ON assignment_happened.item_id = multi_hhm.house_hold_id),

     cohort3_participant_group_member AS (SELECT pgm.*,
                                                 hhm_data.j33             as member_disability,
                                                 CASE
                                                     WHEN hhm_data.j33 IS NULL THEN 'Not Found'
                                                     WHEN hhm_data.j33 ILIKE '%1%' OR
                                                          hhm_data.j33 ILIKE '%2%' OR
                                                          hhm_data.j33 ILIKE '%3%' OR
                                                          hhm_data.j33 ILIKE '%4%' OR
                                                          hhm_data.j33 ILIKE '%5%' OR
                                                          hhm_data.j33 ILIKE '%6%' THEN 'yes'
                                                     ELSE 'no'
                                                     END                     plwd_status,
                                                 ca.parent_catchment_name as parent_of_village,
                                                 ca.parent_catchment_id   as parent_id_of_village,
                                                 hhm_data.j26             as member_support_track,
                                                 CASE
                                                     WHEN hhm_data.j26 IS NULL THEN 'Not Found'
                                                     WHEN hhm_data.j26 = '1' THEN 'AIM Education: Financial Support'
                                                     WHEN hhm_data.j26 = '2'
                                                         THEN 'AIM Education: Return & Financial Support'
                                                     WHEN hhm_data.j26 = '3'
                                                         THEN 'AIM Education:  Alternative Education Opportunities'
                                                     WHEN hhm_data.j26 = '4' THEN 'Livelihood'
                                                     WHEN hhm_data.j26 = '5' THEN 'None'
                                                     ELSE hhm_data.j26
                                                     END                  as initial_pathway
                                          FROM (SELECT *
                                                FROM dm_schema.participant_group_member
                                                WHERE fiscal_year_name = 'Cohort 3') pgm
                                                   LEFT JOIN _aim_c3_hhm_information hhm_data ON pgm.member_id = hhm_data.id
                                                   LEFT JOIN dm_schema.dim_catchment ca ON ca.catchment_id = pgm.catchment_id),

     c3_pgm_with_attendance AS (SELECT c3pgm.*,
                                       att.event_id,
                                       coalesce(att.first_session_no, 0)                          first_session_no,
                                       coalesce(att.total_attendance_in_event_session, 0)         total_attendance_in_event_session,
                                       coalesce(att.total_present_in_event_sessions, 0)           total_present_in_event_sessions,
                                       coalesce(att.overall_percentage_in_group, 0)               overall_percentage_in_group,
                                       coalesce(att.total_session_record_for_first_12_session, 0) total_session_record_for_first_12_session,
                                       coalesce(att.present_session_in_first_12_session, 0)       present_session_in_first_12_session,
                                       coalesce(att.percentage_in_first_12_session, 0)            percentage_in_first_12_session

                                FROM cohort3_participant_group_member c3pgm
                                         LEFT JOIN dm_schema.overall_curriculum_delivery_attendance_details att
                                                   ON att.member_id = c3pgm.member_id AND
                                                      att.group_type_id = c3pgm.group_type_id),
     abc AS (SELECT pgm_att.*,
                    CASE
                        WHEN pgm_att.group_type_name IN ('AG', 'VYA') THEN 'yes'
                        ELSE 'no'
                        END                        as education_census_applicable_ag,
                    CASE
                        WHEN pgm_att.group_type_name NOT IN ('AG', 'VYA') THEN 'Not Applicable'
                        WHEN ecd.member_id IS NULL THEN 'no'
                        ELSE 'yes'
                        END                        as education_census_completed_ag,
                    ecd.c1                         as "corrently_enrolled_in_school_ag (C1)",
                    ecd.c1,
                    ecd.c8                         as "last_attend_school_ag (C8)",
                    ecd.c9                         as "interested_in_returning_to_ school_ag (C9)",
                    CASE
                        WHEN sapfas.member_id IS NOT NULL THEN 'Yes'
                        WHEN pgm_att.group_type_name = 'AG' THEN 'No'
                        ELSE 'Not Applicable'
                        END                        as bm_decision_for_ag,
                    CASE
                        WHEN c3lep.member_id IS NOT NULL THEN 'Yes'
                        else 'No'
                        END                        as eligibility,
                    CASE
                        WHEN femeh.member_id IS NOT NULL THEN 'Yes'
                        ELSE 'No'
                        END                        as multiple_household_member,
                    femeh.member_assignment_status as unique_eligibility

             FROM c3_pgm_with_attendance pgm_att
                      LEFT JOIN education_census_date ecd
                                ON pgm_att.member_id = ecd.member_id AND pgm_att.group_id = ecd.group_id

                      LEFT JOIN special_ag_participants_for_aim_support sapfas
                                ON sapfas.member_id = pgm_att.member_id AND pgm_att.group_type_name = 'AG'
                      LEFT JOIN dm_schema.c3_livelihood_eligible_participants c3lep
                                ON c3lep.member_id = pgm_att.member_id AND c3lep.group_id = pgm_att.group_id
                      LEFT JOIN final_eligibility_multi_eligible_hhm femeh ON femeh.member_id = pgm_att.member_id)

SELECT *
FROM abc
WHERE c1 is not null limit 400000; -- 91708

SELECT count(*)
FROM aim_education_census; -- 92564
SELECT count(*)
FROM aim_education_census_web_survey; -- 645


SELECT count(*)
FROM dm_schema.participant_group_member
where fiscal_year_name = 'Cohort 3'; -- 284814

SELECT *
FROM reporting_schema.participant_group_member_eligibility_report;