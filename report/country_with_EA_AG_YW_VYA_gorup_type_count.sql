WITH service_point_groups AS (SELECT sp.id,
                                     c.name AS country_name,
                                     c.short_name,
                                     SUM(
                                             CASE
                                                 WHEN pgt.name = 'EA' THEN 1
                                                 ELSE 0
                                                 END
                                     )      AS EA_group_count,
                                     SUM(
                                             CASE
                                                 WHEN pgt.name IN ('VYA', 'AG', 'YW') THEN 1
                                                 ELSE 0
                                                 END
                                     )      AS VYA_AG_YW_group_count
                              FROM service_point sp
                                       JOIN country c ON c.id = sp.country_id
                                       JOIN participant_group pg ON pg.service_point_id = sp.id
                                       JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                              WHERE pgt.name IN ('EA', 'VYA', 'AG', 'YW')
                              GROUP BY sp.id, c.name, c.short_name)
SELECT country_name,
       short_name,
       SUM(
               CASE
                   WHEN EA_group_count > 1 THEN 1
                   ELSE 0
                   END
       ) AS sp_with_gratter_than_1_EA_group,
       SUM(
               CASE
                   WHEN VYA_AG_YW_group_count > 3 THEN 1
                   ELSE 0
                   END
       ) AS sp_with_gratter_than_3_VYA_AG_YW_group
FROM service_point_groups
GROUP BY country_name, short_name;