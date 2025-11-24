WITH branch_target AS (SELECT string_agg(lbt.item_id, ',')                                              as id,
                              string_agg(lbt.item_id, ',')                                              as item_id,
                              lbt.country_id,
                              lbt.fiscal_year_id,
                              lbt.project_id,
                              lbt.office_id,
                              lbt.package_id,
                              lbt.group_type_id,
                              sum(coalesce(lbt.livelihood_branch_target, 0))                            AS branch_target,
                              string_agg(DISTINCT lbt.created_by, ',')                                  as created_by,
                              max(lbt.create_time)                                                         create_time,
                              max(lbt.last_modified_time)                                                  last_modified_time,
                              (ARRAY_AGG(lbt.last_modified_by ORDER BY lbt.last_modified_time DESC))[1] as last_modified_by

                       FROM livelihood_branch_target lbt
                       GROUP BY lbt.country_id, lbt.fiscal_year_id, lbt.project_id, lbt.office_id, lbt.package_id,
                                lbt.group_type_id),

     livelihood_branch_target AS (SELECT lbt.id,
                                         lbt.item_id,
                                         lbt.office_id,
                                         opmh.office_name,
                                         opmh.parent_office_id,
                                         lbt.country_id,
                                         opmh.country_name,
                                         opmh.head_office_name,
                                         opmh.divisional_office_name,
                                         opmh.area_office_name,
                                         opmh.regional_office_name,
                                         lbt.project_id,
                                         opmh.project_name,
                                         lbt.fiscal_year_id,
                                         fy.name           AS fiscal_year_name,
                                         lbt.package_id,
                                         e.enterprise_name AS package_name,
                                         lbt.group_type_id,
                                         pgt.name          AS group_type_name,
                                         lbt.branch_target,
                                         lbt.created_by,
                                         lbt.create_time,
                                         lbt.last_modified_by,
                                         lbt.last_modified_time

                                  FROM branch_target lbt
                                           LEFT JOIN muktadul.office_project_mapping_hierarchy opmh
                                                     ON opmh.office_id = lbt.office_id AND
                                                        opmh.project_id = lbt.project_id AND
                                                        lbt.country_id = opmh.country_id
                                           LEFT JOIN fiscal_year fy ON lbt.fiscal_year_id = fy.id
                                           LEFT JOIN enterprise e ON lbt.package_id = e.id
                                           LEFT JOIN participant_group_type pgt ON lbt.group_type_id = pgt.id
                                  ORDER BY lbt.create_time DESC)
SELECT *
-- INTO muktadul.livelihood_branch_target
FROM livelihood_branch_target;