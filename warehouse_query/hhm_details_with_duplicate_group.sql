WITH hhm_with_duplicate_group AS (SELECT hhm.id,
                                         hhm.participant_group_type_id,
                                         hhm.fiscal_year_id,
                                         string_agg(hhm.group_name, ',')    as group_names,
                                         string_agg(hhm.group_id, ',')      as group_ids,
                                         string_agg(hhm.created_by_id, ',') as group_created_by_ids,
                                         string_agg(hhm.created_by, ',')    as group_created_by_names,
                                         string_agg(hhm.imei, ',')          as imei_numbers
                                  FROM (SELECT hhm.id,
                                               pg.participant_group_type_id,
                                               pgm.fiscal_year_id,
                                               pg.name                                          as group_name,
                                               pg.id                                            as group_id,
                                               pgm.created_by                                   as created_by_id,
                                               u.name                                           as created_by,
                                               pgm.meta_data::jsonb -> 'device_info' ->> 'IMEI' AS imei
                                        FROM house_hold_member hhm
                                                 JOIN participant_group_member pgm ON pgm.member_id = hhm.id
                                                 JOIN participant_group pg ON pg.id = pgm.group_id
                                                 LEFT JOIN fiscal_year fy ON fy.id = pgm.fiscal_year_id
                                                 LEFT JOIN "user" u ON u.id = pgm.created_by
                                        WHERE fy.name ilike '%Cohort 3%') hhm
                                  GROUP BY hhm.id, hhm.participant_group_type_id, hhm.fiscal_year_id
                                  having count(*) > 1),

     hhm_details_with_duplicate_group AS (SELECT hhm.id,
                                                 hhm.house_hold_id,
                                                 hhm.member_name,
                                                 hhm.age,
                                                 CASE
                                                     WHEN hhm.gender = '1' THEN 'Female'
                                                     WHEN hhm.gender = '2' THEN 'Male'
                                                     ELSE 'Others'
                                                     END as gender,
                                                 hhm2.participant_group_type_id,
                                                 hhm2.group_ids,
                                                 hhm2.group_names,
                                                 hhm2.group_created_by_ids,
                                                 hhm2.group_created_by_names,
                                                 hhm2.imei_numbers,
                                                 hhm.catchment_id,
                                                 ct.name AS catchment_name,
                                                 hhm.is_synced,
                                                 hhm.status,
                                                 hhm.required_missing,
                                                 hhm.is_deleted,
                                                 hhm.create_time,
                                                 u.name  as created_by,
                                                 hhm.last_modified_time,
                                                 u2.name as last_modified_by,
                                                 hhm.country_id,
                                                 c.name  as country,
                                                 hhm.fiscal_year_id,
                                                 fy.name,
                                                 hhm.project_id,
                                                 p.name  as project_name,
                                                 hhm.office_id,
                                                 o.name  as office_name
                                          FROM house_hold_member hhm
                                                   JOIN hhm_with_duplicate_group hhm2 ON hhm2.id = hhm.id
                                                   LEFT JOIN catchment ct ON ct.id = hhm.catchment_id
                                                   LEFT JOIN "user" u ON u.id = hhm.created_by
                                                   LEFT JOIN "user" u2 ON u2.id = hhm.last_modified_by
                                                   LEFT JOIN public.country c on hhm.country_id = c.id
                                                   LEFT JOIN project p ON hhm.project_id = p.id
                                                   LEFT JOIN office o ON o.id = hhm.office_id
                                                   LEFT JOIN fiscal_year fy ON fy.id = hhm2.fiscal_year_id)

SELECT * FROM hhm_details_with_duplicate_group;