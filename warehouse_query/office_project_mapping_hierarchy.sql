WITH RECURSIVE
    office_hierarchy AS (
        -- Base case: start with each office
        SELECT opm.office_id,
               opm.office_name,
               opm.parent_office_id,
               o.office_type_id,
               os.name       as office_type,
               opm.office_id as original_office_id,
               opm.project_id,
               opm.country_id
        FROM office_project_mapping opm
                 JOIN office o ON opm.office_id = o.id
                 LEFT JOIN office_structure os ON o.office_type_id = os.id
        UNION ALL

        -- Recursive case: traverse up the hierarchy    (p means parent)
        SELECT p.office_id,
               p.office_name,
               p.parent_office_id,
               o.office_type_id,
               ps.name as office_type,
               oh.original_office_id,
               oh.project_id,
               oh.country_id
        FROM office_hierarchy oh
                 JOIN office_project_mapping p ON oh.parent_office_id = p.office_id and oh.project_id = p.project_id
                 JOIN office o ON p.office_id = o.id
                 LEFT JOIN office_structure ps ON o.office_type_id = ps.id
        WHERE oh.parent_office_id IS NOT NULL),

    office_pivot AS (SELECT original_office_id,
                            project_id,
                            country_id,
                            MAX(CASE WHEN office_type = 'Head Office' THEN office_name END)       as head_office_name,
                            MAX(CASE WHEN office_type = 'Divisional Office' THEN office_name END) as divisional_office_name,
                            MAX(CASE WHEN office_type = 'Regional Office' THEN office_name END)   as regional_office_name,
                            MAX(CASE WHEN office_type = 'Area Office' THEN office_name END)       as area_office_name,
                            MAX(CASE WHEN office_type = 'Branch Office' THEN office_name END)     as branch_office_name
                     FROM office_hierarchy
                     GROUP BY original_office_id, project_id, country_id),

    office_pivot_with_details AS (SELECT opm.id,
                                         op.project_id,
                                         p.name                AS project_name,
                                         op.original_office_id AS office_id,
                                         o.name                AS office_name,
                                         o.office_type_id,
                                         os.name               AS office_type,
                                         opm.parent_office_id,
                                         op.country_id,
                                         c.name                AS country_name,
                                         op.head_office_name,
                                         op.divisional_office_name,
                                         op.regional_office_name,
                                         op.area_office_name,
                                         op.branch_office_name,
                                         o.latitude,
                                         o.longitude,
                                         opm.create_time,
                                         opm.last_modified_time,
                                         opm.is_deleted,
                                         opm.created_by,
                                         opm.last_modified_by,
                                         opm.last_sync_time
                                  FROM office_pivot op
                                           LEFT JOIN office_project_mapping opm
                                                     ON op.original_office_id = opm.office_id AND
                                                        op.project_id = opm.project_id AND
                                                        op.country_id = opm.country_id
                                           LEFT JOIN office o ON op.original_office_id = o.id
                                           LEFT JOIN office_structure os ON o.office_type_id = os.id
                                           LEFT JOIN country c ON op.country_id = c.id
                                           LEFT JOIN project p ON op.project_id = p.id)
SELECT *
-- INTO muktadul.office_project_mapping_hierarchy
FROM office_pivot_with_details;