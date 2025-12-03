WITH club_target AS (SELECT club_id, club_name, sum(branch_target) as branch_target, sum(club_target) as club_target
                     FROM muktadul.livelihood_club_target
                     GROUP BY club_id, club_name),

     club_wise_member AS (SELECT la.id,
                                 COALESCE(la.club_id, lct.club_id)                                       as club_id,
                                 unnest(string_to_array(la.enterprise_assignment_eligible_members, ',')) as assigned_member_id
                          FROM livelihood_assignment la
                                   LEFT JOIN livelihood_club_target lct ON la.item_id = lct.id),

     club_details AS (SELECT la.id,
                             cwm.club_id,
                             ct.club_name,
                             ct.branch_target,
                             ct.club_target,
                             cwm.assigned_member_id,
                             hhm.member_name,
                             hhm.age,
                             hhm.gender,
                             hhm.house_hold_id,
                             la.create_time,
                             cu.name as created_by,
                             la.last_modified_time,
                             mu.name as last_modified_by,
                             la.catchment_id,
                             ca.name as catchment_name,
                             la.office_id,
                             opmh.office_name,
                             opmh.head_office_name,
                             opmh.divisional_office_name,
                             opmh.regional_office_name,
                             opmh.area_office_name,
                             opmh.country_id,
                             opmh.country_name,
                             la.fiscal_year_id,
                             fy.name as fiscal_year_name,
                             la.project_id,
                             p.name  as project_name

                      FROM livelihood_assignment la
                               JOIN club_wise_member cwm ON la.id = cwm.id
                               JOIN house_hold_member hhm ON hhm.id = cwm.assigned_member_id
                               JOIN club_target ct ON ct.club_id = cwm.club_id
                               LEFT JOIN fiscal_year fy ON fy.id = la.fiscal_year_id
                               LEFT JOIN public.project p on p.id = la.project_id
                               LEFT JOIN catchment ca ON ca.id = la.catchment_id
                               LEFT JOIN "user" cu ON cu.id = la.created_by
                               LEFT JOIN "user" mu ON mu.id = la.last_modified_by
                               LEFT JOIN muktadul.office_project_mapping_hierarchy opmh ON la.office_id = opmh.office_id
                      order by la.create_time desc)

SELECT * FROM club_details;