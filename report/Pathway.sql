WITH AG_EA_YW_member_details as (SELECT hhm.id                       as member_id,
                                        hhm.member_name,
                                        hhm.age,
                                        hhm.gender,
                                        hhm.j33                      as plwd,
                                        CASE
                                            WHEN hhm.j33 IS NULL THEN 'Not Found'
                                            WHEN hhm.j33 ILIKE '%1%' OR
                                                 hhm.j33 ILIKE '%2%' OR
                                                 hhm.j33 ILIKE '%3%' OR
                                                 hhm.j33 ILIKE '%4%' OR
                                                 hhm.j33 ILIKE '%5%' OR
                                                 hhm.j33 ILIKE '%6%' THEN 'yes'
                                            ELSE 'no'
                                            END                         plwd_status,
                                        hhm.j26                      as initial_pathway_number,
                                        CASE
                                            WHEN hhm.j26 IS NULL THEN 'Not Found'
                                            WHEN hhm.j26 = '1' THEN 'AIM Education: Financial Support'
                                            WHEN hhm.j26 = '2'
                                                THEN 'AIM Education: Return & Financial Support'
                                            WHEN hhm.j26 = '3'
                                                THEN 'AIM Education:  Alternative Education Opportunities'
                                            WHEN hhm.j26 = '4' THEN 'Livelihood'
                                            WHEN hhm.j26 = '5' THEN 'None'
                                            ELSE hhm.j26
                                            END                      as initial_pathway,
                                        pgm.id                       as pgm_id,
                                        pgm.member_serial,
                                        pgm.group_id,
                                        pg.name                      as group_name,
                                        pg.participant_group_type_id as group_type_id,
                                        pgt.name                     as group_type_name
                                 FROM participant_group_member pgm
                                          JOIN _aim_c3_hhm_information hhm ON hhm.id = pgm.member_id
                                          JOIN participant_group pg ON pg.id = pgm.group_id
                                          JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                 WHERE pgt.name IN ('AG', 'EA', 'YW')),

     education_census_data AS (SELECT member_id,
                                      c1,
                                      CASE
                                          WHEN c1 IS NULL THEN NULL
                                          WHEN c1 = '1' THEN 'Yes'
                                          ELSE 'No'
                                          END as c1_text,
                                      c8,
                                      CASE
                                          WHEN c8 IS NULL THEN NULL
                                          WHEN c8 = '1' THEN '2013'
                                          WHEN c8 = '2' THEN '2014'
                                          WHEN c8 = '3' THEN '2015'
                                          WHEN c8 = '4' THEN '2016'
                                          WHEN c8 = '5' THEN '2017'
                                          WHEN c8 = '6' THEN '2018'
                                          WHEN c8 = '7' THEN '2019'
                                          WHEN c8 = '8' THEN '2020'
                                          WHEN c8 = '9' THEN '2021'
                                          WHEN c8 = '10' THEN '2022'
                                          WHEN c8 = '11' THEN '2023'
                                          WHEN c8 = '12' THEN '2024'
                                          WHEN c8 = '13' THEN '2025'
                                          ELSE 'Cannot recall'
                                          END as c8_text,
                                      c9,
                                      CASE
                                          WHEN c9 IS NULL THEN NULL
                                          WHEN c9 = '1' THEN 'Yes'
                                          WHEN c9 = '0' THEN 'No'
                                          ELSE 'Refused to answer'
                                          END as c9_text

                               FROM (SELECT *,
                                            row_number() over (partition by member_id order by create_time desc) r
                                     FROM (SELECT pgm.member_id,
                                                  app.c1,
                                                  app.c8,
                                                  app.c9,
                                                  app.create_time
                                           FROM aim_education_census app
                                                    JOIN participant_group_member pgm ON pgm.id = app.item_id

                                           UNION ALL

                                           SELECT pgm.member_id,
                                                  web.c1,
                                                  web.c8,
                                                  web.c9,
                                                  web.create_time
                                           FROM aim_education_census_web_survey web
                                                    JOIN participant_group_member pgm ON pgm.id = web.participant_selection) x) x
                               WHERE r = 1),

     special_ag_participants_for_aim_support AS (SELECT member_id
                                                 FROM aim_support_for_special_ag_participants asfsap
                                                          LEFT JOIN LATERAL unnest(string_to_array(asfsap.participant_selection, ',')) member_id
                                                                    ON true
                                                 GROUP BY member_id),

     AG_EA_YW_member_with_AG_details AS (SELECT hhm.*,
                                                CASE
                                                    WHEN hhm.group_type_name in ('AG', 'VYA') THEN 'yes'
                                                    ELSE 'no'
                                                    END as education_census_applicable_ag,
                                                CASE
                                                    WHEN ecd.member_id IS NOT NULL then 'yes'
                                                    WHEN hhm.group_type_name NOT IN ('AG', 'VYA') THEN 'Not Applicable'
                                                    ELSE 'no'
                                                    END as education_census_completed_ag,
                                                ecd.c1,
                                                ecd.c1_text,
                                                ecd.c8,
                                                ecd.c8_text,
                                                ecd.c9,
                                                ecd.c9_text,
                                                CASE
                                                    WHEN sapfas.member_id IS NOT NULL THEN 'yes'
                                                    WHEN hhm.group_type_name = 'AG' THEN 'no'
                                                    ELSE 'Not Applicable'
                                                    END as bm_decision_for_ag

                                         FROM AG_EA_YW_member_details hhm
                                                  LEFT JOIN education_census_data ecd ON hhm.member_id = ecd.member_id
                                                  LEFT JOIN special_ag_participants_for_aim_support sapfas
                                                            ON sapfas.member_id = hhm.member_id),

     hhm_details_with_final_pathway AS (SELECT *,
                                               CASE
                                                   WHEN c1 = '0' AND c8 IN
                                                                     ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
                                                                      '11', '-96') THEN 'Livelihood'
                                                   WHEN c1 = '0' AND c9 = '1' AND c8 IN ('12', '13') THEN 'Undecided'
                                                   WHEN c1 = '0' AND c9 = '0' AND c8 IN ('12', '13') AND bm_decision_for_ag = 'yes'
                                                       THEN 'Livelihood'
                                                   ELSE initial_pathway
                                                   END as final_pathway
                                        FROM AG_EA_YW_member_with_AG_details)

SELECT * FROM hhm_details_with_final_pathway;