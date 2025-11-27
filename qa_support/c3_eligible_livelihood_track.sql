{{
    config(
        materialized='materialized_view'
    )
}}

--------------------------------------------Eligible Participant Member--------------------------------------------------
WITH hhm_with_non_duplicate_group AS MATERIALIZED (SELECT hhm.id as member_id,
                                                          pg.participant_group_type_id,
                                                          pgm.fiscal_year_id
                                                   FROM house_hold_member hhm
                                                            JOIN participant_group_member pgm ON pgm.member_id = hhm.id
                                                            JOIN participant_group pg ON pg.id = pgm.group_id
                                                   GROUP BY hhm.id, pg.participant_group_type_id, pgm.fiscal_year_id
                                                   having count(*) = 1),

     hhm_details AS MATERIALIZED (SELECT hhm.id       AS member_id,
                                         hhm.member_name,
                                         pgm.group_id,
                                         pg.service_point_id,
                                         pg.catchment_id,
                                         pg.participant_group_type_id,
                                         pg.office_id,
                                         pg.fiscal_year_id,
                                         hhm.gender,
                                         hhm.age,
                                         pgm.member_type,
                                         pgm.member_serial,
                                         pg.project_id,
                                         pg.country_id,
                                         hhm.house_hold_id,
                                         pg.name         group_name,
                                         pgt.name        group_type_name,
                                         hhm_data.j33 as pwd,
                                         hhm_data.j26 as member_support_track

                                  FROM house_hold_member hhm
                                           JOIN hhm_with_non_duplicate_group non_d ON non_d.member_id = hhm.id
                                           JOIN participant_group_member pgm ON pgm.member_id = hhm.id
                                           JOIN participant_group pg
                                                ON pg.id = pgm.group_id AND non_d.participant_group_type_id =
                                                                            pg.participant_group_type_id AND
                                                   non_d.fiscal_year_id = pg.fiscal_year_id
                                           JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                           JOIN _aim_c3_hhm_information hhm_data ON hhm.id = hhm_data.id), -- we will only consider the Cohort-3

     ea_yw_with_livelihood_support AS (SELECT *
                                       FROM hhm_details
                                       WHERE group_type_name IN ('YW', 'EA')
                                         AND member_support_track = '4'),

     ea_yw_with_ls_and_vsla_or_plwd AS (SELECT eywls.*,
                                               CASE
                                                   WHEN vsla_pwd.group_type_name ILIKE '%VSLA%' AND vsla_pwd.pwd != ',,,,,'
                                                       THEN 'Both VSLA & PWD'
                                                   WHEN vsla_pwd.group_type_name ILIKE '%VSLA%' THEN 'VSLA'
                                                   WHEN vsla_pwd.pwd != ',,,,,' THEN 'PWD'
                                                   ELSE 'None'
                                                   END as eligible_from
                                        FROM ea_yw_with_livelihood_support eywls
                                                 JOIN (SELECT member_id, group_type_name, pwd
                                                       FROM hhm_details
                                                       WHERE group_type_name ILIKE '%VSLA%'
                                                          OR pwd != ',,,,,'
                                                       GROUP BY member_id, group_type_name, pwd) vsla_pwd
                                                      on eywls.member_id = vsla_pwd.member_id),

     ag_with_livelihood_support AS (SELECT *, -- direct eligible for support
                                           'Direct Livelihood' as eligible_from
                                    FROM hhm_details
                                    WHERE group_type_name IN ('AG')
                                      AND member_support_track = '4'),

     ag_with_educational_support AS (SELECT *
                                     FROM hhm_details
                                     WHERE group_type_name IN ('AG')
                                       AND member_support_track in ('1', '2', '3')),

     aim_education_census_app_details AS (SELECT pgm_id, member_id, c1, c8, c9
                                          FROM (SELECT app.item_id AS                                                        pgm_id,
                                                       hhm.id      AS                                                        member_id,
                                                       app.c1,
                                                       app.c8,
                                                       app.c9,
                                                       row_number() over (PARTITION BY hhm.id ORDER BY app.create_time DESC) rn
                                                FROM aim_education_census app
                                                         LEFT JOIN participant_group_member pgm ON pgm.id = app.item_id
                                                         LEFT JOIN house_hold_member hhm ON hhm.id = pgm.member_id) x
                                          WHERE rn = 1),

     ag_edu_support_with_census_app_details_c1_0_c8_1to11 AS ( -- direct support eligible
         SELECT es.*,
                'j26=(1,2,3) & c0=0 & c8=(1-11)' as eligible_from
         FROM ag_with_educational_support es
                  JOIN aim_education_census_app_details ec ON es.member_id = ec.member_id
         WHERE ec.c1 = '0'
           AND c8 IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11')),

     ag_edu_support_with_census_app_details_c1_0_c8_12to13_c9_0 AS (SELECT es.*
                                                                    FROM ag_with_educational_support es
                                                                             JOIN aim_education_census_app_details ec ON es.member_id = ec.member_id
                                                                    WHERE ec.c1 = '0'
                                                                      AND c8 IN ('12', '13')
                                                                      AND ec.c9 = '0'),

     education_census_eligable_member_ids AS (SELECT p.id
                                              FROM aim_support_for_special_ag_participants asfsap
                                                       LEFT JOIN LATERAL unnest(string_to_array(asfsap.participant_selection, ',')) p(id)
                                                                 ON true
                                              GROUP BY p.id),

     ag_with_education_census AS (SELECT hhm.*, -- direct support eligible
                                         'j26=(1,2,3) & c0=0 & c8=(12,13) & c9=0 & education_census_eligible' as eligible_from
                                  FROM hhm_details hhm
                                           JOIN ag_edu_support_with_census_app_details_c1_0_c8_12to13_c9_0 edu_2
                                                ON edu_2.member_id = hhm.member_id
                                           JOIN education_census_eligable_member_ids ecemi ON ecemi.id = hhm.member_id
                                  WHERE hhm.group_type_name ilike '%AG%'),

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
                                                                     pwd,
                                                                     eligible_from
                                                              FROM (SELECT *
                                                                    FROM ea_yw_with_ls_and_vsla_or_plwd
                                                                    UNION
                                                                    SELECT *
                                                                    FROM final_eligible_ag_without_attendenc) x),

--------------------------------------------Calculating Participant Members the Attendance--------------------------------------------------
     curriculum_events AS (SELECT e.*
                           FROM event e
                                    JOIN fiscal_year fy
                                         ON e.fiscal_year_id = fy.id
                           WHERE event_name ilike '%Curriculum%'
                             AND fy.name = 'Cohort 3'
                           ORDER BY event_name),

     fist_12_session_event_plan_member_data AS (SELECT a.member_id,
                                                       a.event_id,
                                                       a.event_session_id,
                                                       a.sort_order_in_event,
                                                       -- Here it's calculating the attendance prioritizing present on  "same session" for "same group" or "different group"
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
                                                      FROM event_plan_member epm
                                                               JOIN fiscal_year fy ON epm.fiscal_year_id = fy.id
                                                               JOIN event_plan ep ON epm.event_plan_id = ep.id
                                                               JOIN event_session_for_user esfu ON ep.event_session_for_user_id = esfu.id
                                                               JOIN event_session es ON esfu.event_session_id = es.id
                                                               JOIN curriculum_events ce ON ce.id = es.event_id
                                                      WHERE fy.name = 'Cohort 3'
                                                        AND es.sort_order_in_event <= 12
                                                        AND ep.is_executed = true) a
                                                GROUP BY a.event_session_id, a.member_id, a.sort_order_in_event,
                                                         a.event_id
                                                ORDER BY member_id, sort_order_in_event),

     participant_members_attendance_data AS (SELECT epm.event_id, -- 5(1), 8(0), 9(1) 1+0+1 = 2, 10-5 + 1
                                                    epm.member_id,
                                                    count(epm.event_session_id)             AS total_session,
                                                    sum(epm.ispresent)                      AS present_session,
                                                    min(epm.sort_order_in_event)            AS session_start_from,
                                                    sum(epm.ispresent) * 100 /
                                                    (12 - min(epm.sort_order_in_event) + 1) AS percentage
                                             FROM fist_12_session_event_plan_member_data epm
                                             GROUP BY epm.event_id, epm.member_id),                        -- 552


     all_eligible_member_with_above_75_attendence AS (SELECT aemwac.*,
                                                             pmad.percentage,
                                                             pmad.total_session,
                                                             pmad.present_session
                                                      FROM all_eligible_member_without_attendence_considaration aemwac
                                                               JOIN participant_members_attendance_data pmad
                                                                    ON aemwac.member_id = pmad.member_id
                                                      WHERE pmad.percentage >= 75),                        -- 3824
-- SELECT count(*) FROM all_eligible_member_with_above_75_attendence;       -- 155


--------------------------------------------Eligible Mentor--------------------------------------------------
     trainer_with_non_duplicate_group AS MATERIALIZED (SELECT t.id as member_id,
                                                              pg.participant_group_type_id,
                                                              pgm.fiscal_year_id
                                                       FROM trainer t
                                                                JOIN participant_group_member pgm ON pgm.member_id = t.id
                                                                JOIN participant_group pg ON pg.id = pgm.group_id
                                                       GROUP BY t.id, pg.participant_group_type_id, pgm.fiscal_year_id
                                                       having count(*) = 1)
-- SELECT * FROM trainer_with_non_duplicate_group;
        ,
     vsla_trainer AS (SELECT t.id                         AS member_id,
                             t.name                       AS member_name,
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
                             null::text                   AS house_hold_id,
                             pg.name                         group_name,
                             pgt.name                        group_type_name,
                             null::text                   AS pwd,
                             'VSLA & _mentor_eligibility' as eligible_from,
                             null::numeric                AS percentage,
                             null::bigint                 AS total_session,
                             null::bigint                 AS present_session
                      FROM trainer t
                               JOIN participant_group_member pgm
                                    ON t.id = pgm.member_id
                               JOIN trainer_with_non_duplicate_group non_d ON non_d.member_id = t.id
                               JOIN participant_group pg ON pg.id = pgm.group_id
                               JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                               join fiscal_year fy on pg.fiscal_year_id = fy.id
                               join _aim_c2_economic_survey_c04bc a2 on a2.item_id = t.id
                      WHERE pgt.name ILIKE '%VSLA%'
                        and fy.name = 'Cohort 3'
                        and a2._mentor_eligibility = '1'),
--       select count(*) from vsla_trainer;        -- 10

     --------------------------------------------C3 Livelihood Eligible Participants--------------------------------------------------
     all_members AS (SELECT *
                     FROM all_eligible_member_with_above_75_attendence
                     UNION ALL
                     SELECT *
                     FROM vsla_trainer),

     c3_livelihood_eligible_participants as (select get_guid()  as              id,
                                                    member_id,
                                                    member_name,
                                                    gender,
                                                    age,
                                                    a.country_id,
                                                    c.name      as              country,
                                                    a.project_id,
                                                    a.fiscal_year_id,
                                                    fy.name                     fiscal_year_name,
                                                    a.catchment_id,
                                                    cat.name                    village,
                                                    a.office_id,
                                                    o.name                      branch,
                                                    a.house_hold_id,
                                                    house_hold_serial_number,
                                                    a.member_serial             participant_id,
                                                    a.member_type,
                                                    group_id,
                                                    group_name,
                                                    a.participant_group_type_id group_type_id,
                                                    group_type_name,
                                                    service_point_id,
                                                    sp.name                     service_point_name,
                                                    member_type as              participant_type,
                                                    ''          AS              mf_status,
                                                    ''          AS              ep_member_mf_status,
                                                    ''          AS              ep_hh_mf_status,
                                                    ''          AS              received_livelihood,
                                                    ''          AS              aim_ep_h1a_receivedlivelihood,
                                                    ''          AS              aim_ep_i3_hh_catagory,
                                                    ''          AS              economic_status,
                                                    ''          AS              economic_status_from_entry,
                                                    ''          AS              hh_profile_status,
                                                    ''          AS              school_satus,
                                                    ''          AS              want_to_back_to_school,
                                                    ''          AS              has_support_to_manage_livelihood,
                                                    ''          AS              received_livelihood_text,
                                                    ''          AS              mf_status_info,
                                                    ''          AS              profile_status,
                                                    ''          AS              economic_status_from_entry_label,
                                                    ''          AS              want_to_back_school,
                                                    ''          AS              has_support_manage_livelihood,
                                                    now()       as              last_modified_time,
                                                    a.percentage,
                                                    a.total_session,
                                                    a.present_session,
                                                    pwd,
                                                    case
                                                        when pwd != ',,,,,' then 'yes'
                                                        else 'no'
                                                        end                     is_pwd,
                                                    eligible_from

                                             from all_members a
                                                      left join country c on c.id = a.country_id
                                                      left join fiscal_year fy on a.fiscal_year_id = fy.id
                                                      left join catchment cat on a.catchment_id = cat.id
                                                      left join office o on a.office_id = o.id
                                                      left join service_point sp on a.service_point_id = sp.id
                                                      left join house_hold hh on a.house_hold_id = hh.id)

SELECT member_id, member_name, member_type, age,branch, village, service_point_name, group_name, group_type_name, total_session, present_session, percentage, eligible_from
FROM c3_livelihood_eligible_participants where catchment_id='a332f8d8-78d5-4ef4-9e74-dbd74cca84a8';

-- DROP MATERIALIZED VIEW customdataset.c3_livelihood_eligible_participants CASCADE;
SELECT *
FROM customdataset.c3_livelihood_eligible_participants;