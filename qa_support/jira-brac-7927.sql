WITH aim_education_census_web_details AS (SELECT web.id,
                                                 web.participant_selection as participant_id,
                                                 hhm.id                    as member_id,
                                                 pgm.member_serial,
                                                 hhm.member_name,
                                                 CASE
                                                     WHEN hhm.gender = '1' THEN 'Female'
                                                     WHEN hhm.gender = '2' THEN 'Male'
                                                     ELSE 'Others' END     as gender,
                                                 hhm.house_hold_id,
                                                 web.group_selection       as group_id,
                                                 pg.name                   as group_name,
                                                 web.club_selection        as club_id,
                                                 sp.name                   as club_name,
                                                 web.catchment_id,
                                                 ct.name                   as catchment_name,
                                                 web.country_id,
                                                 o.name                    as country_name,
                                                 web.project_id,
                                                 p.name                    as project_name,
                                                 web.fiscal_year_id,
                                                 fy.name                   as fiscal_year_name,
                                                 web.office_id             as branch_office_id,
                                                 o.name                    as branch_office_name,
                                                 'Web Survey'              as survey_type,
                                                 CASE
                                                     WHEN web.c1 = '0' THEN 'No'
                                                     ELSE 'Yes'
                                                     END                   as currently_enrolled_in_school,
                                                 CASE
                                                     WHEN web.c1 = '0' THEN 'No'
                                                     WHEN web.c1 = '1' THEN 'Yes'
                                                     ELSE 'Refused to answer'
                                                     END                   as interested_in_returning_to_school,
                                                 CASE
                                                     WHEN web.c8 = '-96' THEN 'Cannot recall'
                                                     ELSE (web.c8::numeric + 2012)::text
                                                     END                   as last_attend_school_year
                                          FROM aim_education_census_web_survey web
                                                   LEFT JOIN country c ON web.country_id = c.id
                                                   LEFT JOIN project p ON web.project_id = p.id
                                                   LEFT JOIN catchment ct ON ct.id = web.catchment_id
                                                   LEFT JOIN fiscal_year fy ON fy.id = web.fiscal_year_id
                                                   LEFT JOIN office o ON o.id = web.office_id
                                                   LEFT JOIN service_point sp ON sp.id = web.club_selection
                                                   LEFT JOIN participant_group pg ON pg.id = web.group_selection
                                                   LEFT JOIN participant_group_member pgm ON pgm.id = web.participant_selection
                                                   LEFT JOIN house_hold_member hhm ON hhm.id = pgm.member_id
                                          WHERE web.c9 = '0'
                                            AND web.c1 = '0'
                                            AND web.c8 IN ('12', '13')),

     aim_education_census_app_details AS (SELECT app.id,
                                                 app.item_id           as participant_id,
                                                 hhm.id                as member_id,
                                                 pgm.member_serial,
                                                 hhm.member_name,
                                                 CASE
                                                     WHEN hhm.gender = '1' THEN 'Female'
                                                     WHEN hhm.gender = '2' THEN 'Male'
                                                     ELSE 'Others' END as gender,
                                                 hhm.house_hold_id,
                                                 pgm.group_id,
                                                 pg.name               as group_name,
                                                 pg.service_point_id   as club_id,
                                                 sp.name               as club_name,
                                                 app.catchment_id,
                                                 ct.name               as catchment_name,
                                                 app.country_id,
                                                 o.name                as country_name,
                                                 app.project_id,
                                                 p.name                as project_name,
                                                 app.fiscal_year_id,
                                                 fy.name               as fiscal_year_name,
                                                 app.office_id         as branch_office_id,
                                                 o.name                as branch_office_name,
                                                 'App Survey'          as survey_type,
                                                 CASE
                                                     WHEN app.c1 = '0' THEN 'No'
                                                     ELSE 'Yes'
                                                     END               as currently_enrolled_in_school,
                                                 CASE
                                                     WHEN app.c1 = '0' THEN 'No'
                                                     WHEN app.c1 = '1' THEN 'Yes'
                                                     ELSE 'Refused to answer'
                                                     END               as interested_in_returning_to_school,
                                                 CASE
                                                     WHEN app.c8 = '-96' THEN 'Cannot recall'
                                                     ELSE (app.c8::numeric + 2012)::text
                                                     END               as last_attend_school_year
                                          FROM aim_education_census app
                                                   LEFT JOIN participant_group_member pgm ON pgm.id = app.item_id
                                                   LEFT JOIN participant_group pg ON pg.id = pgm.group_id
                                                   LEFT JOIN house_hold_member hhm ON hhm.id = pgm.member_id
                                                   LEFT JOIN country c ON app.country_id = c.id
                                                   LEFT JOIN project p ON app.project_id = p.id
                                                   LEFT JOIN catchment ct ON ct.id = app.catchment_id
                                                   LEFT JOIN fiscal_year fy ON fy.id = app.fiscal_year_id
                                                   LEFT JOIN office o ON o.id = app.office_id
                                                   LEFT JOIN service_point sp ON sp.id = pg.service_point_id
                                          WHERE app.c9 = '0'
                                            AND app.c1 = '0'
                                            AND app.c8 IN ('12', '13')),

     all_data AS (SELECT *
                  FROM aim_education_census_web_details
                  UNION
                  SELECT *
                  FROM aim_education_census_app_details)

SELECT * FROM all_data