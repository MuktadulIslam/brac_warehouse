--------------------------------------------Eligible Participant Member--------------------------------------------------
WITH cohort3_fiscal_year AS MATERIALIZED (SELECT *
                                          FROM fiscal_year
                                          WHERE name ilike 'Cohort 3'),

     hhm_with_non_duplicate_group AS MATERIALIZED (SELECT hhm.id as member_id,
                                                          pg.participant_group_type_id,
                                                          pg.fiscal_year_id
                                                   FROM house_hold_member hhm
                                                            JOIN participant_group_member pgm ON pgm.member_id = hhm.id
                                                            JOIN participant_group pg ON pg.id = pgm.group_id
                                                            JOIN cohort3_fiscal_year fy ON fy.id = pg.fiscal_year_id
                                                   GROUP BY hhm.id,
                                                            pg.participant_group_type_id,
                                                            pg.fiscal_year_id
                                                   HAVING count(*) = 1),

     hhm_details AS MATERIALIZED (SELECT non_hhm.member_id,
                                         hhm_data.member_name,
                                         pgm.id       as pgm_id,
                                         pgm.group_id,
                                         pg.service_point_id,
                                         pg.catchment_id,
                                         pg.participant_group_type_id,
                                         pg.office_id,
                                         pg.fiscal_year_id,
                                         hhm_data.gender,
                                         hhm_data.age,
                                         pgm.member_type,
                                         pgm.member_serial,
                                         pg.project_id,
                                         pg.country_id,
                                         hhm.house_hold_id,
                                         pg.name      as group_name,
                                         pgt.name     as group_type_name,
                                         hhm_data.j33 as pwd,
                                         hhm_data.j26 as member_support_track
                                  FROM hhm_with_non_duplicate_group non_hhm
                                           JOIN _aim_c3_hhm_information hhm_data ON non_hhm.member_id = hhm_data.id
                                           JOIN participant_group_member pgm ON pgm.member_id = non_hhm.member_id
                                           JOIN participant_group pg
                                                ON pg.id = pgm.group_id
                                                    AND non_hhm.participant_group_type_id = pg.participant_group_type_id
                                                    AND non_hhm.fiscal_year_id = pg.fiscal_year_id
                                           JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                           JOIN house_hold_member hhm ON hhm.id = non_hhm.member_id),

     ea_yw_with_livelihood_support AS (SELECT *
                                       FROM hhm_details
                                       WHERE member_support_track = '4'
                                         AND group_type_name IN ('YW', 'EA')),

     ea_yw_with_ls_and_vsla_or_plwd AS (SELECT eywls.*
                                        FROM ea_yw_with_livelihood_support eywls
                                                 JOIN (SELECT member_id
                                                       FROM hhm_details
                                                       WHERE pwd != ',,,,,'
                                                          OR group_type_name ILIKE '%VSLA%'
                                                       GROUP BY member_id) vsla_pwd
                                                      ON eywls.member_id = vsla_pwd.member_id),

     ag_with_livelihood_support AS (SELECT *
                                    FROM hhm_details
                                    WHERE group_type_name IN ('AG')
                                      AND member_support_track = '4'),

     ag_with_educational_support AS MATERIALIZED (SELECT *
                                                  FROM hhm_details
                                                  WHERE group_type_name IN ('AG')
                                                    AND member_support_track in ('1', '2', '3')),

     aim_education_census_app_details AS MATERIALIZED (SELECT pgm_id,
                                                              member_id,
                                                              c1,
                                                              c8,
                                                              c9
                                                       FROM (SELECT app.item_id                                                     AS pgm_id,
                                                                    hhm.member_id,
                                                                    app.c1,
                                                                    app.c8,
                                                                    app.c9,
                                                                    row_number()
                                                                    over (PARTITION BY hhm.member_id ORDER BY app.create_time DESC) as rn
                                                             FROM aim_education_census app
                                                                      JOIN hhm_details hhm ON hhm.pgm_id = app.item_id) x
                                                       WHERE rn = 1),

     ag_edu_support_with_census_app_details_c1_0_c8_1to11 AS (SELECT es.*
                                                              FROM ag_with_educational_support es
                                                                       JOIN aim_education_census_app_details ec ON es.member_id = ec.member_id
                                                              WHERE ec.c1 = '0'
                                                                AND c8 IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '-99')),

     ag_edu_support_with_census_app_details_c1_0_c8_12to13_c9_0 AS (SELECT es.*
                                                                    FROM ag_with_educational_support es
                                                                             JOIN aim_education_census_app_details ec ON es.member_id = ec.member_id
                                                                    WHERE ec.c1 = '0'
                                                                      AND ec.c9 = '0'
                                                                      AND ec.c8 IN ('12', '13')),

     education_census_eligable_member_ids AS (SELECT p.id
                                              FROM aim_support_for_special_ag_participants asfsap
                                                       LEFT JOIN LATERAL unnest(string_to_array(asfsap.participant_selection, ',')) p(id)
                                                                 ON true
                                              GROUP BY p.id),

     ag_with_education_census AS (SELECT hhm.*
                                  FROM (SELECT *
                                        FROM hhm_details
                                        WHERE group_type_name = 'AG') hhm
                                           JOIN education_census_eligable_member_ids ecemi ON ecemi.id = hhm.member_id
                                           JOIN ag_edu_support_with_census_app_details_c1_0_c8_12to13_c9_0 edu_2
                                                ON edu_2.member_id = hhm.member_id),

     final_eligible_ag_without_attendenc AS (SELECT *
                                             FROM ag_with_livelihood_support
                                             UNION
                                             SELECT *
                                             FROM ag_edu_support_with_census_app_details_c1_0_c8_1to11
                                             UNION
                                             SELECT *
                                             FROM ag_with_education_census),

     all_eligible_member_without_attendence_considaration AS (SELECT member_id,
                                                                     member_name,
                                                                     group_id,
                                                                     service_point_id,
                                                                     catchment_id,
                                                                     participant_group_type_id,
                                                                     office_id,
                                                                     fiscal_year_id,
                                                                     gender,
                                                                     age,
                                                                     member_type,
                                                                     member_serial,
                                                                     project_id,
                                                                     country_id,
                                                                     house_hold_id,
                                                                     group_name,
                                                                     group_type_name,
                                                                     pwd
                                                              FROM (SELECT *
                                                                    FROM ea_yw_with_ls_and_vsla_or_plwd
                                                                    UNION
                                                                    SELECT *
                                                                    FROM final_eligible_ag_without_attendenc) x),

--------------------------------------------Calculating Participant Members the Attendance--------------------------------------------------
     curriculum_events AS (SELECT e.*
                           FROM event e
                                    JOIN cohort3_fiscal_year fy ON e.fiscal_year_id = fy.id
                           WHERE event_name ilike '%Curriculum%'
                           ORDER BY event_name),
     fist_12_session_event_plan_member_data AS (SELECT a.member_id,
                                                       a.event_id,
                                                       a.event_session_id,
                                                       a.sort_order_in_event,
                                                       max(
                                                               CASE
                                                                   WHEN (a.attendance_date_wise ->> 'isPresent'::text) = 'true'::text
                                                                       THEN 1
                                                                   ELSE 0
                                                                   END
                                                       ) AS ispresent
                                                FROM (SELECT jsonb_array_elements(epm.attendance::jsonb) AS attendance_date_wise,
                                                             epm.member_id,
                                                             ce.id                                       as event_id,
                                                             es.id                                       as event_session_id,
                                                             es.sort_order_in_event
                                                      FROM (SELECT * FROM event_plan_member) epm
                                                               JOIN event_plan ep ON epm.event_plan_id = ep.id
                                                               JOIN event_session_for_user esfu ON ep.event_session_for_user_id = esfu.id
                                                               JOIN event_session es ON esfu.event_session_id = es.id
                                                               JOIN curriculum_events ce ON ce.id = es.event_id
                                                      WHERE es.sort_order_in_event <= 12
                                                        AND ep.is_executed = true) a
                                                GROUP BY a.event_session_id, a.member_id, a.sort_order_in_event,
                                                         a.event_id
                                                ORDER BY member_id, sort_order_in_event),

     participant_members_attendance_data AS (SELECT epm.event_id,
                                                    epm.member_id,
                                                    count(epm.event_session_id)             AS total_session,
                                                    sum(epm.ispresent)                      AS present_session,
                                                    min(epm.sort_order_in_event)            AS session_start_from,
                                                    sum(epm.ispresent) * 100 /
                                                    (12 - min(epm.sort_order_in_event) + 1) AS percentage
                                             FROM fist_12_session_event_plan_member_data epm
                                             GROUP BY epm.event_id, epm.member_id),

     participant_members_attendance_data_with_non_duplicate_event AS (SELECT x.*
                                                                      FROM (SELECT *,
                                                                                   row_number() over (partition by member_id order by percentage desc) r
                                                                            FROM participant_members_attendance_data) x
                                                                      WHERE x.r = 1),

     all_eligible_member_with_above_75_attendence AS (SELECT aemwac.*,
                                                             pmad.percentage,
                                                             pmad.total_session,
                                                             pmad.present_session
                                                      FROM all_eligible_member_without_attendence_considaration aemwac
                                                               JOIN participant_members_attendance_data_with_non_duplicate_event pmad
                                                                    ON aemwac.member_id = pmad.member_id
                                                      WHERE pmad.percentage >= 75),

--------------------------------------------Eligible Mentor--------------------------------------------------
     trainer_with_non_duplicate_group AS MATERIALIZED (SELECT t.id as member_id,
                                                              pg.participant_group_type_id,
                                                              pgm.fiscal_year_id
                                                       FROM trainer t
                                                                JOIN participant_group_member pgm ON pgm.member_id = t.id
                                                                JOIN cohort3_fiscal_year fy ON pgm.fiscal_year_id = fy.id
                                                                JOIN participant_group pg ON pg.id = pgm.group_id
                                                       GROUP BY t.id,
                                                                pg.participant_group_type_id,
                                                                pgm.fiscal_year_id
                                                       HAVING count(*) = 1),

     vsla_trainer AS (SELECT t.id          AS member_id,
                             t.name        AS member_name,
                             pgm.group_id,
                             pg.service_point_id,
                             pg.catchment_id,
                             pg.participant_group_type_id,
                             pg.office_id,
                             pg.fiscal_year_id,
                             t.gender,
                             t.age,
                             member_type,
                             member_serial,
                             pg.project_id,
                             pg.country_id,
                             null::text    AS house_hold_id,
                             pg.name       as group_name,
                             pgt.name      as group_type_name,
                             null::text    AS pwd,
                             null::numeric AS percentage,
                             null::bigint  AS total_session,
                             null::bigint  AS present_session
                      FROM trainer t
                               JOIN (SELECT * FROM _aim_c2_economic_survey_c04bc WHERE _mentor_eligibility = '1') a2
                                    on a2.item_id = t.id
                               JOIN participant_group_member pgm ON t.id = pgm.member_id
                               JOIN trainer_with_non_duplicate_group non_d ON non_d.member_id = t.id
                               JOIN participant_group pg ON pg.id = pgm.group_id
                               JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                      WHERE pgt.name ILIKE '%VSLA%'),

     vsla_trainer_with_non_duplicate_vsla_group AS (SELECT member_id,
                                                           member_name,
                                                           group_id,
                                                           service_point_id,
                                                           catchment_id,
                                                           participant_group_type_id,
                                                           office_id,
                                                           fiscal_year_id,
                                                           gender,
                                                           age,
                                                           member_type,
                                                           member_serial,
                                                           project_id,
                                                           country_id,
                                                           house_hold_id,
                                                           group_name,
                                                           group_type_name,
                                                           pwd,
                                                           percentage,
                                                           total_session,
                                                           present_session
                                                    FROM (SELECT *,
                                                                 row_number() over (partition by member_id) r
                                                          FROM vsla_trainer) x
                                                    where r = 1),

--------------------------------------------C3 Livelihood Eligible Participants--------------------------------------------------
     all_members AS (SELECT *
                     FROM all_eligible_member_with_above_75_attendence
                     UNION ALL
                     SELECT *
                     FROM vsla_trainer_with_non_duplicate_vsla_group),
     c3_livelihood_eligible_participants as (SELECT ''                          as id,
                                                    --gen_random_uuid()                  as id,
                                                    member_id,
                                                    member_name,
                                                    gender,
                                                    age,
                                                    a.country_id,
                                                    c.name                      as country,
                                                    a.project_id,
                                                    a.fiscal_year_id,
                                                    fy.name                     as fiscal_year_name,
                                                    a.catchment_id,
                                                    cat.name                    as village,
                                                    a.office_id,
                                                    o.name                      as branch,
                                                    a.house_hold_id,
                                                    house_hold_serial_number,
                                                    a.member_serial,
                                                    a.member_type,
                                                    group_id,
                                                    group_name,
                                                    a.participant_group_type_id as group_type_id,
                                                    group_type_name,
                                                    service_point_id,
                                                    sp.name                     as service_point_name,
                                                    member_type                 as participant_type,
                                                    ''                          AS mf_status,
                                                    ''                          AS ep_member_mf_status,
                                                    ''                          AS ep_hh_mf_status,
                                                    ''                          AS received_livelihood,
                                                    ''                          AS aim_ep_h1a_receivedlivelihood,
                                                    ''                          AS aim_ep_i3_hh_catagory,
                                                    ''                          AS economic_status,
                                                    ''                          AS economic_status_from_entry,
                                                    ''                          AS hh_profile_status,
                                                    ''                          AS school_satus,
                                                    ''                          AS want_to_back_to_school,
                                                    ''                          AS has_support_to_manage_livelihood,
                                                    ''                          AS received_livelihood_text,
                                                    ''                          AS mf_status_info,
                                                    ''                          AS profile_status,
                                                    ''                          AS economic_status_from_entry_label,
                                                    ''                          AS want_to_back_school,
                                                    ''                          AS has_support_manage_livelihood,
                                                    now()                       as last_modified_time,
                                                    a.percentage,
                                                    a.total_session,
                                                    a.present_session,
                                                    pwd,
                                                    case
                                                        when pwd != ',,,,,' then 'yes'
                                                        else 'no'
                                                        end                     as is_pwd
                                             FROM all_members a
                                                      LEFT JOIN country c on c.id = a.country_id
                                                      LEFT JOIN cohort3_fiscal_year fy on a.fiscal_year_id = fy.id
                                                      LEFT JOIN catchment cat on a.catchment_id = cat.id
                                                      LEFT JOIN office o on a.office_id = o.id
                                                      LEFT JOIN service_point sp on a.service_point_id = sp.id
                                                      LEFT JOIN house_hold hh on a.house_hold_id = hh.id)

SELECT *
FROM c3_livelihood_eligible_participants