WITH RECURSIVE
    office_hierarchy AS (
        -- Base case: start with each office
        SELECT o.id    as office_id,
               o.name  as office_name,
               o.parent_id,
               o.office_type_id,
               os.name as office_type,
               o.id    as original_office_id
        FROM office o
                 LEFT JOIN office_structure os ON o.office_type_id = os.id
        UNION ALL
        -- Recursive case: traverse up the hierarchy    (p means parent)
        SELECT p.id    as office_id,
               p.name  as office_name,
               p.parent_id,
               p.office_type_id,
               ps.name as office_type,
               oh.original_office_id
        FROM office_hierarchy oh
                 INNER JOIN office p ON oh.parent_id = p.id
                 LEFT JOIN office_structure ps ON p.office_type_id = ps.id
        WHERE oh.parent_id IS NOT NULL),

    office_pivot AS (SELECT original_office_id,
                            MAX(CASE WHEN office_type = 'Head Office' THEN office_id END)         as head_office_id,
                            MAX(CASE WHEN office_type = 'Head Office' THEN office_name END)       as head_office_name,
                            MAX(CASE WHEN office_type = 'Divisional Office' THEN office_id END)   as divisional_office_id,
                            MAX(CASE WHEN office_type = 'Divisional Office' THEN office_name END) as divisional_office_name,
                            MAX(CASE WHEN office_type = 'Regional Office' THEN office_id END)     as regional_office_id,
                            MAX(CASE WHEN office_type = 'Regional Office' THEN office_name END)   as regional_office_name,
                            MAX(CASE WHEN office_type = 'Area Office' THEN office_id END)         as area_office_id,
                            MAX(CASE WHEN office_type = 'Area Office' THEN office_name END)       as area_office_name,
                            MAX(CASE WHEN office_type = 'Branch Office' THEN office_id END)       as branch_office_id,
                            MAX(CASE WHEN office_type = 'Branch Office' THEN office_name END)     as branch_office_name
                     FROM office_hierarchy
                     GROUP BY original_office_id),

    office_pivot_with_details AS (SELECT op.original_office_id AS office_id,
                                         o.code,
                                         o.name                AS office_name,
                                         o.office_type_id,
                                         os.name               AS office_type_name,
                                         o.parent_id,
                                         o.country_id,
                                         c.name                as country_name,
                                         op.head_office_id,
                                         op.head_office_name,
                                         op.divisional_office_id,
                                         op.divisional_office_name,
                                         op.regional_office_id,
                                         op.regional_office_name,
                                         op.area_office_id,
                                         op.area_office_name,
                                         op.branch_office_id,
                                         op.branch_office_name,
                                         o.status,
                                         o.latitude,
                                         o.longitude,
                                         o.created_by,
                                         o.is_deleted,
                                         o.settlement_type
                                  FROM office_pivot op
                                           JOIN office o ON op.original_office_id = o.id
                                           LEFT JOIN office_structure os ON o.office_type_id = os.id
                                           LEFT JOIN country c ON c.id = o.country_id)
SELECT * FROM office_pivot_with_details