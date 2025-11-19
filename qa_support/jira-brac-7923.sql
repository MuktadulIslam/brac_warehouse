WITH trainer_date AS (SELECT t.id,
                             t.age,
                             t.name,
                             t.gender,
                             'Mentor' as member_type,
                             t.status, -- Active/Inactive
                             c.name   as country,
                             t.project_id,
                             p.name   as project_name,
                             t.catchment_id,
                             ct.name  as catchment_name,
                             o.id     as branch_office_id,
                             o.name   as branch_office_name,
                             fy.name  as fiscal_year
                      FROM trainer t
                               LEFT JOIN country c ON t.country_id = c.id
                               LEFT JOIN project p ON t.project_id = p.id
                               LEFT JOIN catchment ct ON ct.id = t.catchment_id
                               LEFT JOIN fiscal_year fy ON fy.id = t.fiscal_year_id
                               LEFT JOIN branch_office_village_mapping bovm
                                         ON bovm.catchment_id = t.catchment_id AND bovm.project_id = t.project_id AND
                                            bovm.fiscal_year_id = t.fiscal_year_id
                               LEFT JOIN office o ON o.id = bovm.branch_office_id
                      WHERE t.trainer_type_id = '8ec6962deee145c5b7a2fe078db3bc3a'), -- Mentor type

     house_hold_member_data AS (SELECT hhm.id,
                                       hhm.age,
                                       hhm.member_name     as name,
                                       'Female'            as gender,
                                       'House Hold Member' as member_type,
                                       CASE
                                           WHEN hhm.is_deleted THEN 'Is Deleted'
                                           ELSE 'Not Deleted'
                                           END             as status,
                                       c.name              as country,
                                       hhm.project_id,
                                       p.name              as project_name,
                                       hhm.catchment_id,
                                       ct.name             as catchment_name,
                                       o.id                as branch_office_id,
                                       o.name              as branch_office_name,
                                       fy.name             as fiscal_year

                                FROM house_hold_member hhm
                                         JOIN participant_group_member pgm ON hhm.id = pgm.member_id
                                         JOIN participant_group pg
                                              ON pgm.group_id = pg.id AND pg.participant_group_type_id =
                                                                          '696f7b6161db4e35a6411cc7e08db3e6' -- YW group
                                         LEFT JOIN country c ON hhm.country_id = c.id
                                         LEFT JOIN project p ON hhm.project_id = p.id
                                         LEFT JOIN catchment ct ON ct.id = hhm.catchment_id
                                         LEFT JOIN fiscal_year fy ON fy.id = hhm.fiscal_year_id
                                         LEFT JOIN branch_office_village_mapping bovm
                                                   ON bovm.catchment_id = hhm.catchment_id AND
                                                      bovm.project_id = hhm.project_id AND
                                                      bovm.fiscal_year_id = hhm.fiscal_year_id
                                         LEFT JOIN office o ON o.id = bovm.branch_office_id
                                WHERE hhm.gender = '1'),

     all_data AS (SELECT *
                  FROM trainer_date
                  UNION
                  SELECT *
                  FROM house_hold_member_data)

SELECT *
FROM all_data
WHERE fiscal_year IS NOT NULL
ORDER BY fiscal_year DESC, member_type DESC