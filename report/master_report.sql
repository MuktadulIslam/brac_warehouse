-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- hhm participant group member data
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
WITH cohort3_fiscal_year AS MATERIALIZED (SELECT *
                                          FROM fiscal_year
                                          WHERE name ilike 'Cohort 3'),

     c3_participant_group_member AS (SELECT pgm.*
                                     FROM participant_group_member pgm
                                              JOIN cohort3_fiscal_year fy ON fy.id = pgm.fiscal_year_id),

     c3_participant_group_exit AS (SELECT pge.*
                                   FROM participant_group_exit pge
                                            JOIN cohort3_fiscal_year fy ON fy.id = pge.fiscal_year_id),

     vsla_participant AS (SELECT pgm.member_id
                          FROM c3_participant_group_member pgm
                                   JOIN participant_group pg ON pg.id = pgm.group_id
                                   JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                          WHERE pgt.name ILIKE '%VSLA%'
                          GROUP BY pgm.member_id),

     group_member_with_exit_data AS (SELECT id,
                                            member_id,
                                            group_id,
                                            member_serial,
                                            member_type,
                                            'no'                    dropped_out,
                                            member_addition_date as enrollment_or_exit_date,
                                            member_addition_date as enrolment_date,
                                            null                 as exit_date,
                                            ''                   as exit_status,
                                            ''                   as exit_reason,
                                            approval_status
                                     FROM c3_participant_group_member
                                     UNION
                                     SELECT e.id,
                                            e.member_id,
                                            group_id,
                                            hmp.member_serial,
                                            hmp.member_type,
                                            'yes'                   dropped_out,
                                            exit_time            as enrollment_or_exit_date,
                                            CASE
                                                WHEN coalesce(participant_group_member_data, '') != '' then
                                                    (participant_group_member_data::jsonb ->> 'member_addition_date'):: timestamp
                                                else null
                                                END              as enrolment_date,
                                            exit_time::timestamp as exit_date,
                                            exit_status,
                                            reason               as exit_reason,
                                            ''                   as approval_status
                                     FROM c3_participant_group_exit e
                                              JOIN group_member_participant hmp ON e.member_id = hmp.id
                                              LEFT JOIN exit_reason er ON e.exit_reason_id = er.id),

     participant_group_type_with_vsla_tag AS (SELECT *,
                                                     CASE
                                                         WHEN name ILIKE '%vsla%' THEN 'yes'
                                                         ELSE 'no'
                                                         END as is_vsla_group_type
                                              FROM participant_group_type),

     prticipant_group_member_with_exit_multiple AS (SELECT a.*,
                                                           pg.name                      as                                                        group_name,
                                                           pg.participant_group_type_id as                                                        group_type_id,
                                                           pgt.name                     as                                                        group_type_name,
                                                           pg.service_point_id,
                                                           sp.name                      as                                                        service_point_name,
                                                           row_number()
                                                           OVER (PARTITION BY a.member_id ORDER BY a.dropped_out ASC, pgt.is_vsla_group_type ASC) r
                                                    FROM group_member_with_exit_data a
                                                             JOIN participant_group pg on pg.id = a.group_id
                                                             JOIN participant_group_type_with_vsla_tag pgt
                                                                  ON pgt.id = pg.participant_group_type_id
                                                             LEFT JOIN service_point sp ON sp.id = pg.service_point_id),

     prticipant_group_member_with_exit as (SELECT gmwem.*,
                                                  CASE
                                                      WHEN vp.member_id IS NOT NULL
                                                          THEN 'Yes'
                                                      ELSE 'No'
                                                      END
                                                      is_vsla_participant
                                           FROM prticipant_group_member_with_exit_multiple gmwem
                                                    LEFT JOIN vsla_participant vp
                                                              on vp.member_id = gmwem.member_id
                                           WHERE r = 1),

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- hhm livelihood data
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
     livelihood_assignment_data AS (SELECT member_id,
                                           project_id,
                                           count(package_id)             as total_number_of_assigned_packages,
                                           count(package_id) > 1         as got_multiple_packages,
                                           string_agg(package_id, ',')   as package_id,
                                           string_agg(package_name, ',') as package_name

                                    FROM (SELECT unnest(string_to_array(la.enterprise_assignment_eligible_members, ',')) as member_id,
                                                 la.project_id,
                                                 la.item_id                                                              as package_id,
                                                 e.enterprise_name                                                       as package_name
                                          FROM livelihood_assignment la
                                                   JOIN enterprise e ON la.item_id = e.id) x
                                    GROUP BY project_id, member_id),

     member_final_pathway_with_livelihood_eligibility AS (SELECT hc3fp.member_id,
                                                                 hc3fp.initial_pathway,
                                                                 hc3fp.final_pathway,
                                                                 hc3fp.education_census_applicable_ag,
                                                                 hc3fp.education_census_completed_ag,
                                                                 hc3fp.bm_decision_for_ag,
                                                                 count(hc3fp.member_id)            member_duplicate_group_count,
                                                                 string_agg(c3lep.group_name, ',') group_name,
                                                                 CASE
                                                                     WHEN c3lep.member_id IS NOT NULL THEN 'yes'
                                                                     ELSE 'no'
                                                                     END as                        eligible_for_livelihood
                                                          FROM dm_schema.hhm_c3_final_pathway hc3fp
                                                                   LEFT JOIN dm_schema.c3_livelihood_eligible_participants c3lep
                                                                             ON hc3fp.member_id = c3lep.member_id
                                                          GROUP BY hc3fp.member_id, hc3fp.initial_pathway,
                                                                   hc3fp.final_pathway,
                                                                   hc3fp.education_census_applicable_ag,
                                                                   hc3fp.education_census_completed_ag,
                                                                   hc3fp.bm_decision_for_ag,
                                                                   c3lep.member_id),

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Curriculum session attendance data
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
     cohort3_curriculum_based_event AS (SELECT e.*
                                        FROM event e
                                                 JOIN cohort3_fiscal_year fy ON fy.id = e.fiscal_year_id
                                        WHERE e.event_name ILIKE '%Curriculum%'),

     groups_executed_ep AS (SELECT *, unnest(string_to_array(group_ids, ',')) AS group_id
                            FROM event_plan
                            WHERE is_executed = TRUE),

     groups_total_executed_session AS (SELECT group_id,
                                              es.event_id,
                                              count(distinct es.id) as total_executed_session
                                       FROM groups_executed_ep ep
                                                JOIN event_session_for_user esfu ON ep.event_session_for_user_id = esfu.id
                                                JOIN event_session es ON esfu.event_session_id = es.id
                                                JOIN cohort3_curriculum_based_event e ON e.id = es.event_id
                                       GROUP BY es.event_id, group_id),

--                  *******************************Member Attendance*********************
     attendance_expanded AS (SELECT jsonb_array_elements(epm.attendance::jsonb) AS attendance_date_wise,
                                    epm.member_id,
                                    ce.id                                       AS event_id,
                                    es.id                                       AS event_session_id,
                                    es.sort_order_in_event
                             FROM cohort3_event_plan_member_view epm
                                      JOIN event_plan ep ON epm.event_plan_id = ep.id
                                      JOIN event_session_for_user esfu ON ep.event_session_for_user_id = esfu.id
                                      JOIN event_session es ON esfu.event_session_id = es.id
                                      JOIN cohort3_curriculum_based_event ce ON ce.id = es.event_id),

     event_plan_member_data AS (SELECT a.member_id,
                                       a.event_id,
                                       a.event_session_id,
                                       a.sort_order_in_event,
                                       MAX(CASE
                                               WHEN a.attendance_date_wise @> '{"isPresent": true}' THEN 1
                                               ELSE 0
                                           END) AS ispresent
                                FROM attendance_expanded a
                                GROUP BY a.event_session_id,
                                         a.member_id,
                                         a.sort_order_in_event,
                                         a.event_id
                                ORDER BY member_id,
                                         sort_order_in_event),

     participant_members_attendance AS (SELECT epm.event_id,
                                               epm.member_id,
                                               sum(epm.ispresent)           AS present_session,
                                               min(epm.sort_order_in_event) AS session_start_from
                                        FROM event_plan_member_data epm
                                        GROUP BY epm.event_id, epm.member_id),

     participant_members_attendance_with_percentage AS (SELECT pma.*,
                                                               gtes.total_executed_session as total_session,
                                                               CASE
                                                                   WHEN gtes.total_executed_session - (session_start_from - 1) <= 0
                                                                       THEN 0
                                                                   ELSE LEAST(
                                                                           pma.present_session * 100.0 /
                                                                           (gtes.total_executed_session - (session_start_from - 1)),
                                                                           100
                                                                        )
                                                                   END                     AS percentage
                                                        FROM participant_members_attendance pma
                                                                 JOIN prticipant_group_member_with_exit AEYmd
                                                                      ON AEYmd.member_id = pma.member_id
                                                                 JOIN groups_total_executed_session gtes
                                                                      ON gtes.group_id = AEYmd.group_id and gtes.event_id = pma.event_id),

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Multi-member eligible from single household data
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
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

     final_eligibility_multi_eligible_hhm AS (SELECT member_id,
                                                     member_assignment_status
                                              FROM (SELECT multi_hhm.member_id,
                                                           CASE
                                                               WHEN final.member_id IS NOT NULL THEN 'Yes'
                                                               WHEN assignment_happened.item_id IS NOT NULL THEN 'No'
                                                               ELSE 'Still Not Assigned'
                                                               END as member_assignment_status
                                                    FROM multi_member_house_holds multi_hhm
                                                             LEFT JOIN multi_member_selection_for_assignment final
                                                                       ON multi_hhm.member_id = final.member_id
                                                             LEFT JOIN member_selection_for_enterprise_assignment assignment_happened
                                                                       ON assignment_happened.item_id = multi_hhm.house_hold_id) x
                                              GROUP BY member_id, member_assignment_status),


     final_data AS (SELECT hhm_data.*,
                           pgm.dropped_out,
                           pgm.group_id,
                           pgm.group_name,
                           pgm.group_type_id,
                           pgm.group_type_name,
                           pgm.service_point_id,
                           pgm.service_point_name,
                           pgm.is_vsla_participant,
                           CASE
                               WHEN pgm.group_type_name ILIKE '%VSLA%' THEN 'yes'
                               ELSE 'no'
                               END                                         as is_just_vsla_member,

                           CASE
                               WHEN pmawp.member_id IS NOT NULL THEN 'yes'
                               ELSE 'no'
                               END                                         as have_attendance_in_curriculum_event,
                           pmawp.event_id,
                           e.event_name,
                           pmawp.session_start_from,
                           pmawp.present_session,
                           pmawp.total_session                             as total_executed_session_in_current_group,
                           pmawp.percentage,


                           mfpwle.initial_pathway,
                           mfpwle.final_pathway,
                           mfpwle.education_census_applicable_ag,
                           mfpwle.education_census_completed_ag,
                           mfpwle.bm_decision_for_ag,
                           coalesce(mfpwle.eligible_for_livelihood, 'N/A') as eligible_for_livelihood,

                           CASE
                               WHEN femeh.member_id IS NOT NULL THEN 'yes'
                               ELSE 'no'
                               END                                         as multiple_household_member,
                           femeh.member_assignment_status                  as unique_eligibility,

                           CASE
                               WHEN mfpwle.eligible_for_livelihood = 'yes' THEN null
                               WHEN trim(mfpwle.final_pathway) != 'Livelihood' THEN 'Final Pathway is not livelihood'
                               WHEN mfpwle.member_duplicate_group_count > 1
                                   THEN 'Member are in duplicate aged based group'
                               WHEN mfpwle.eligible_for_livelihood IS NULL THEN 'N/A'
                               END                                         as reason_for_ineligibility,

                           CASE
                               WHEN lad.total_number_of_assigned_packages IS NOT NULL
                                   THEN lad.total_number_of_assigned_packages::text
                               WHEN mfpwle.eligible_for_livelihood = 'yes' THEN 'Not Assigned Yet'
                               WHEN mfpwle.eligible_for_livelihood = 'no' THEN 'Not Eligible'
                               ELSE 'N/A'
                               END                                         as total_number_of_assigned_packages,

                           CASE
                               WHEN lad.got_multiple_packages IS NOT NULL
                                   THEN lad.got_multiple_packages::text
                               WHEN mfpwle.eligible_for_livelihood = 'yes' THEN 'Not Assigned Yet'
                               WHEN mfpwle.eligible_for_livelihood = 'no' THEN 'Not Eligible'
                               ELSE 'N/A'
                               END                                         as got_multiple_packages,

                           CASE
                               WHEN lad.package_id IS NOT NULL
                                   THEN lad.package_id::text
                               WHEN mfpwle.eligible_for_livelihood = 'yes' THEN 'Not Assigned Yet'
                               WHEN mfpwle.eligible_for_livelihood = 'no' THEN 'Not Eligible'
                               ELSE 'N/A'
                               END                                         as package_id,

                           CASE
                               WHEN lad.package_name IS NOT NULL
                                   THEN lad.package_name
                               WHEN mfpwle.eligible_for_livelihood = 'yes' THEN 'Not Assigned Yet'
                               WHEN mfpwle.eligible_for_livelihood = 'no' THEN 'Not Eligible'
                               ELSE 'N/A'
                               END                                         as package_name

                    FROM reporting_schema.aim_c3_hhm_data_with_hh hhm_data
                             LEFT JOIN prticipant_group_member_with_exit pgm
                                       ON pgm.member_id = hhm_data.house_hold_member_id
                             LEFT JOIN member_final_pathway_with_livelihood_eligibility mfpwle
                                       ON mfpwle.member_id = hhm_data.house_hold_member_id
                             LEFT JOIN participant_members_attendance_with_percentage pmawp
                                       ON pmawp.member_id = hhm_data.house_hold_member_id
                             LEFT JOIN event e ON e.id = pmawp.event_id
                             LEFT JOIN livelihood_assignment_data lad
                                       ON lad.member_id = hhm_data.house_hold_member_id AND
                                          lad.project_id = hhm_data.project_id
                             LEFT JOIN final_eligibility_multi_eligible_hhm femeh ON femeh.member_id = pgm.member_id)

SELECT *
FROM final_data

