WITH cohort_1_2_club_wise_assigned_members AS (SELECT lct.club_id,
                                                      lct.project_id,
                                                      lct.package_id,
                                                      lct.fiscal_year_id,
                                                      la.office_id,
                                                      sum(lct.livelihood_club_target)                                         as club_target,
                                                      max(la.create_time)                                                     AS create_time,
                                                      (ARRAY_AGG(la.created_by ORDER BY la.create_time DESC))[1]              AS created_by,
                                                      max(la.last_modified_time)                                              AS last_modified_time,
                                                      (ARRAY_AGG(la.last_modified_by ORDER BY la.last_modified_time DESC))[1] AS last_modified_by,
                                                      string_agg(la.enterprise_assignment_eligible_members, ',')              AS assigned_members

                                               FROM livelihood_assignment la
                                                        JOIN livelihood_club_target lct ON la.item_id = lct.id
                                               -- it will give only Cohort-1&2 data as in Cohort-3 the item id indicate the enterprise id
                                               GROUP BY lct.club_id, lct.project_id, lct.package_id,
                                                        lct.fiscal_year_id, la.office_id),

     cohort_3_club_wise_assigned_members AS (SELECT la.club_id,
                                                    la.project_id,
                                                    la.item_id                                                              as package_id,
                                                    la.fiscal_year_id,
                                                    la.office_id,
                                                    sum(coalesce(lct.livelihood_club_target, 0))                            as club_target,
                                                    max(la.create_time)                                                     AS create_time,
                                                    (ARRAY_AGG(la.created_by ORDER BY la.create_time DESC))[1]              AS created_by,
                                                    max(la.last_modified_time)                                              AS last_modified_time,
                                                    (ARRAY_AGG(la.last_modified_by ORDER BY la.last_modified_time DESC))[1] AS last_modified_by,
                                                    string_agg(la.enterprise_assignment_eligible_members, ',')              AS assigned_members

                                             FROM livelihood_assignment la
                                                      JOIN enterprise e ON la.item_id = e.id
                                                      LEFT JOIN livelihood_club_target lct ON la.club_id = lct.club_id
                                             GROUP BY la.club_id, la.project_id, la.fiscal_year_id, la.item_id,
                                                      la.office_id),

     club_wise_assigned_members AS (SELECT *
                                    FROM cohort_1_2_club_wise_assigned_members
                                    UNION ALL
                                    SELECT *
                                    FROM cohort_3_club_wise_assigned_members),

     club_wise_assigned_members_details AS (SELECT cwmd.club_id,
                                                   sp.name           as club_name,
                                                   cwmd.package_id,
                                                   e.enterprise_name as package_name,
                                                   cwmd.club_target,
                                                   hhm.id            as member_id,
                                                   hhm.member_name,
                                                   hhm.age,
                                                   hhm.gender,
                                                   cwmd.office_id,
                                                   opmh.office_name,
                                                   opmh.parent_office_id,
                                                   opmh.country_id,
                                                   opmh.country_name,
                                                   opmh.head_office_name,
                                                   opmh.divisional_office_name,
                                                   opmh.area_office_name,
                                                   cwmd.project_id,
                                                   p.name            as project_name,
                                                   cwmd.fiscal_year_id,
                                                   fy.name           as fiscal_year_name,
                                                   cwmd.create_time,
                                                   cu.name           as created_by,
                                                   cwmd.last_modified_time,
                                                   mu.name           as last_modified_by
                                            FROM club_wise_assigned_members cwmd
                                                     JOIN LATERAL unnest(string_to_array(cwmd.assigned_members, ',')) as assigned_member_id
                                                          ON true
                                                     JOIN house_hold_member hhm ON hhm.id = assigned_member_id
                                                     LEFT JOIN enterprise e ON e.id = cwmd.package_id
                                                     LEFT JOIN "user" cu ON cu.id = cwmd.created_by
                                                     LEFT JOIN "user" mu ON mu.id = cwmd.last_modified_by
                                                     LEFT JOIN service_point sp ON sp.id = cwmd.club_id
                                                     LEFT JOIN muktadul.office_project_mapping_hierarchy opmh
                                                               ON opmh.office_id = cwmd.office_id
                                                     LEFT JOIN project p ON p.id = cwmd.project_id
                                                     LEFT JOIN fiscal_year fy ON fy.id = cwmd.fiscal_year_id)

SELECT *
-- INTO muktadul.livelihood_club_wise_assigned_members
FROM club_wise_assigned_members_details;