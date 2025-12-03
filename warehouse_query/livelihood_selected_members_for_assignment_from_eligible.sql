WITH member_selection_for_enterprise_assignment_splitted_data AS (SELECT item_id                                                             as hh_id,
                                                                         UNNEST(STRING_TO_ARRAY(multi_member_selection_for_assignment, ',')) as hhm_id
                                                                  FROM member_Selection_for_enterprise_assignment),

     hh_where_single_memeber_is_eligible AS (SELECT lep.house_hold_id hh_id,
                                                    count(member_id)  hhm_count
                                             FROM customdataset.livelihood_eligibleparticipants lep
                                             GROUP BY lep.house_hold_id
                                             having count(member_id) = 1
                                             UNION
                                             SELECT '' hh_id, 1),

     single_hhm_from_a_single_hh AS (SELECT lep.house_hold_id as hh_id,
                                            lep.member_id     as hhm_id
                                     FROM customdataset.livelihood_eligibleparticipants lep
                                              JOIN hh_where_single_memeber_is_eligible single_hh
                                                   ON lep.house_hold_id = single_hh.hh_id),

     all_member_for_assignmnet AS (SELECT *
                                   FROM member_selection_for_enterprise_assignment_splitted_data
                                   UNION
                                   SELECT *
                                   FROM single_hhm_from_a_single_hh),
     all_member_for_assignmnet_details AS (SELECT *
                                           FROM customdataset.livelihood_eligibleparticipants lep
                                                    JOIN all_member_for_assignmnet amfa ON lep.member_id = amfa.hhm_id)


SELECT *
-- INTO muktadul.livelihood_selected_members_for_assignment_from_eligible
FROM all_member_for_assignmnet_details;