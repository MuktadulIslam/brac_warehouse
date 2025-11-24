WITH livelihood_club_target AS (SELECT lct.id,
                                       lct.item_id,
                                       opmh.office_id,
                                       opmh.office_name,
                                       opmh.parent_office_id,
                                       opmh.country_id,
                                       opmh.country_name,
                                       opmh.head_office_name,
                                       opmh.divisional_office_name,
                                       opmh.area_office_name,
                                       opmh.regional_office_name,
                                       opmh.project_id,
                                       opmh.project_name,
                                       lct.fiscal_year_id,
                                       fy.name                                   AS fiscal_year_name,
                                       lct.package_id,
                                       e.enterprise_name                         AS package_name,
                                       lct.catchment_id,
                                       c.name                                    AS catchment_name,
                                       lct.club_id,
                                       sp.name                                   AS club_name,
                                       lct.group_type_id,
                                       pgt.name                                  AS group_type_name,
                                       lct.profile_id,
                                       CASE
                                           WHEN lbt.livelihood_branch_target IS NULL THEN 0
                                           ELSE lbt.livelihood_branch_target END AS livelihood_branch_target,
                                       CASE
                                           WHEN lct.livelihood_club_target IS NULL THEN 0
                                           ELSE lct.livelihood_club_target END   AS livelihood_club_target
                                FROM livelihood_club_target lct
                                         LEFT JOIN muktadul.office_project_mapping_hierarchy opmh
                                                   ON opmh.office_id = lct.office_id AND
                                                      opmh.project_id = lct.project_id AND
                                                      lct.country_id = opmh.country_id
                                         LEFT JOIN fiscal_year fy ON lct.fiscal_year_id = fy.id
                                         LEFT JOIN enterprise e ON lct.package_id = e.id
                                         LEFT JOIN catchment c ON c.id = lct.catchment_id
                                         LEFT JOIN service_point sp ON sp.id = lct.club_id
                                         LEFT JOIN participant_group_type pgt on lct.group_type_id = pgt.id
                                         LEFT JOIN livelihood_branch_target lbt ON lct.office_id = lbt.office_id AND
                                                                                   lct.project_id = lbt.project_id AND
                                                                                   lct.fiscal_year_id =
                                                                                   lbt.fiscal_year_id AND
                                                                                   lct.package_id = lbt.package_id AND
                                                                                   lct.group_type_id =
                                                                                   lbt.group_type_id AND
                                                                                   lct.profile_id = lbt.profile_id)
SELECT *
-- INTO muktadul.livelihood_club_target
FROM livelihood_club_target;


WITH club_target AS (SELECT string_agg(lct.item_id, ',')                                              as id,
                            string_agg(lct.item_id, ',')                                              as item_id,
                            lct.country_id,
                            lct.fiscal_year_id,
                            lct.project_id,
                            lct.office_id,
                            lct.package_id,
                            lct.group_type_id,
                            lct.catchment_id,
                            lct.club_id,
                            sum(coalesce(lct.livelihood_club_target, 0))                              AS club_target,
                            string_agg(DISTINCT lct.created_by, ',')                                  as created_by,
                            max(lct.create_time)                                                         create_time,
                            max(lct.last_modified_time)                                                  last_modified_time,
                            (ARRAY_AGG(lct.last_modified_by ORDER BY lct.last_modified_time DESC))[1] as last_modified_by

                     FROM livelihood_club_target lct
                     GROUP BY lct.country_id, lct.fiscal_year_id, lct.project_id, lct.office_id, lct.package_id,
                              lct.group_type_id, lct.catchment_id, lct.club_id),

     livelihood_club_target AS (SELECT lct.id,
                                       lct.item_id,
                                       opmh.office_id,
                                       opmh.office_name,
                                       opmh.parent_office_id,
                                       opmh.country_id,
                                       opmh.country_name,
                                       opmh.head_office_name,
                                       opmh.divisional_office_name,
                                       opmh.area_office_name,
                                       opmh.regional_office_name,
                                       opmh.project_id,
                                       opmh.project_name,
                                       lct.fiscal_year_id,
                                       fy.name           AS fiscal_year_name,
                                       lct.catchment_id,
                                       c.name            AS catchment_name,
                                       lct.package_id,
                                       e.enterprise_name AS package_name,
                                       lct.club_id,
                                       sp.name           AS club_name,
                                       lct.group_type_id,
                                       pgt.name          AS group_type_name,
                                       lbt.branch_target,
                                       lct.club_target,
                                       lct.created_by,
                                       lct.create_time,
                                       lct.last_modified_by,
                                       lct.last_modified_time

                                FROM club_target lct
                                         LEFT JOIN muktadul.office_project_mapping_hierarchy opmh
                                                   ON opmh.office_id = lct.office_id AND
                                                      opmh.project_id = lct.project_id AND
                                                      lct.country_id = opmh.country_id
                                         LEFT JOIN fiscal_year fy ON lct.fiscal_year_id = fy.id
                                         LEFT JOIN enterprise e ON lct.package_id = e.id
                                         LEFT JOIN catchment c ON c.id = lct.catchment_id
                                         LEFT JOIN service_point sp ON sp.id = lct.club_id
                                         LEFT JOIN participant_group_type pgt on lct.group_type_id = pgt.id
                                         LEFT JOIN muktadul.livelihood_branch_target lbt
                                                   ON lct.office_id = lbt.office_id AND
                                                      lct.project_id = lbt.project_id AND
                                                      lct.fiscal_year_id =
                                                      lbt.fiscal_year_id AND
                                                      lct.package_id = lbt.package_id AND
                                                      lct.group_type_id =
                                                      lbt.group_type_id AND
                                                      lct.country_id = lbt.country_id
                                ORDER BY lct.create_time DESC)
SELECT *
-- INTO muktadul.livelihood_club_target
FROM livelihood_club_target;