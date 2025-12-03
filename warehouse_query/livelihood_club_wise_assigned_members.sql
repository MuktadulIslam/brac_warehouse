WITH club_wise_member_details AS (SELECT la.id   as la_table_id,
                                         la.item_id,
                                         assigned_member_id,
                                         hhm.member_name,
                                         hhm.age,
                                         hhm.gender,
                                         hhm.house_hold_id,
                                         la.create_time,
                                         cu.name as created_by,
                                         la.last_modified_time,
                                         mu.name as last_modified_by

                                  FROM livelihood_assignment la
                                           JOIN LATERAL unnest(string_to_array(la.enterprise_assignment_eligible_members, ',')) as assigned_member_id
                                                ON true
                                           JOIN house_hold_member hhm ON hhm.id = assigned_member_id
                                           LEFT JOIN "user" cu ON cu.id = la.created_by
                                           LEFT JOIN "user" mu ON mu.id = la.last_modified_by),

     livelihood_club_wise_assigned_members AS (SELECT lct.club_id,
                                                      lct.club_name,
                                                      lct.group_type_id,
                                                      lct.group_type_name,
                                                      lct.branch_target,
                                                      lct.club_target,
                                                      cwmd.*,
                                                      lct.office_id,
                                                      lct.office_name,
                                                      lct.parent_office_id,
                                                      lct.country_id,
                                                      lct.country_name,
                                                      lct.head_office_name,
                                                      lct.divisional_office_name,
                                                      lct.area_office_name,
                                                      lct.project_id,
                                                      lct.project_name,
                                                      lct.fiscal_year_id,
                                                      lct.fiscal_year_name,
                                                      lct.catchment_id,
                                                      lct.catchment_name,
                                                      lct.package_id,
                                                      lct.package_name
                                               FROM club_wise_member_details cwmd
                                                        LEFT JOIN muktadul.livelihood_club_target lct ON cwmd.item_id = lct.id)

SELECT *
-- INTO muktadul.livelihood_club_wise_assigned_members
FROM livelihood_club_wise_assigned_members;