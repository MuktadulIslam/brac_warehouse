WITH s AS (SELECT id,
                  item_id,
                  create_time,
                  last_modified_time,
                  catchment_id,
                  survey_meta_data,
                  created_by,
                  last_modified_by,
                  country_id,
                  project_id,
                  fiscal_year_id,
                  office_id,
                  process_data,
                  answer
           FROM survey
           WHERE survey_form_id = '9947a7f47a1d470ba740a6f601f655a0'),
     a AS (SELECT s.*,
                  (s.survey_meta_data::jsonb ->> 'StartTime')::timestamptz as intake_start_date,
                  (s.survey_meta_data::jsonb ->> 'EndTime')::timestamptz   as intake_end_date,
                  r.*
           FROM s
                    CROSS JOIN LATERAL jsonb_to_record(s.answer::jsonb) AS r(
                                                                             j27 text,
                                                                             j28 text,
                                                                             j29 text,
                                                                             j30 text,
                                                                             j31 text,
                                                                             j32 text,
                                                                             j33 text
               )),

     final_data AS (SELECT a.id,
                           a.item_id,
                           a.create_time,
                           a.last_modified_time,
                           a.catchment_id,
                           a.created_by,
                           a.last_modified_by,
                           a.country_id,
                           a.project_id,
                           a.fiscal_year_id,
                           a.office_id,
                           a.process_data,

                           a.intake_start_date,
                           a.intake_end_date,


                           -- j27
                           a.j27,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '6' then 'Don’t Know' END, ',')
                            FROM regexp_split_to_table(a.j27, ',') AS value) AS j27_text,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '6' then 'Don’t Know' END, ',')
                            FROM regexp_split_to_table(a.j27, ',') AS value) AS "J27: Does the member have diﬃculty seeing, even when wearing glasses? Would you say …?  ",

                           -- j28
                           a.j28,
                           (SELECT string_agg(CASE
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '5' then 'Refused'
                                                  when value = '2' then 'Some diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j28, ',') AS value) AS j28_text,
                           (SELECT string_agg(CASE
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '5' then 'Refused'
                                                  when value = '2' then 'Some diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j28, ',') AS value) AS "J28: Does the member have diﬃculty hearing even if using a hearing aid? Would you say …?   ",

                           -- j29
                           a.j29,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '1' then 'No diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j29, ',') AS value) AS j29_text,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '1' then 'No diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j29, ',') AS value) AS "J29: Does the member have diﬃculty walking or climbing steps? Would you say …?  ",

                           -- j30
                           a.j30,
                           (SELECT string_agg(CASE
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '5' then 'Refused'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '3' then 'A lot of diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j30, ',') AS value) AS j30_text,
                           (SELECT string_agg(CASE
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '5' then 'Refused'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '3' then 'A lot of diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j30, ',') AS value) AS "J30: Using usual language, does the member have diﬃculty communicating, for example, understanding or being understood? Would you say …?  ",

                           -- j31
                           a.j31,
                           (SELECT string_agg(CASE
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '5' then 'Refused'
                                                  when value = '1' then 'No diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j31, ',') AS value) AS j31_text,
                           (SELECT string_agg(CASE
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '4' then 'Cannot do at all'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '5' then 'Refused'
                                                  when value = '1' then 'No diﬃculty' END, ',')
                            FROM regexp_split_to_table(a.j31, ',') AS value) AS "J31: Does the member have diﬃculty remembering or concentrating? Would you say …?",

                           -- j32
                           a.j32,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '4' then 'Cannot do at all' END, ',')
                            FROM regexp_split_to_table(a.j32, ',') AS value) AS j32_text,
                           (SELECT string_agg(CASE
                                                  when value = '5' then 'Refused'
                                                  when value = '3' then 'A lot of diﬃculty'
                                                  when value = '2' then 'Some diﬃculty'
                                                  when value = '1' then 'No diﬃculty'
                                                  when value = '6' then 'Don’t Know'
                                                  when value = '4' then 'Cannot do at all' END, ',')
                            FROM regexp_split_to_table(a.j32, ',') AS value) AS "J32: Does the member have diﬃculty with self-care such as washing all over or dressing? Would you say …?  ",

                           -- j33
                           a.j33,
                           (SELECT string_agg(CASE
                                                  when value = '3' then 'Mobility'
                                                  when value = '6' then 'Self-Care'
                                                  when value = '5' then 'Cognition/Remembering'
                                                  when value = '4' then 'Communication'
                                                  when value = '1' then 'Vision'
                                                  when value = '2' then 'Hearing' END, ',')
                            FROM regexp_split_to_table(a.j33, ',') AS value) AS j33_text,
                           (SELECT string_agg(CASE
                                                  when value = '3' then 'Mobility'
                                                  when value = '6' then 'Self-Care'
                                                  when value = '5' then 'Cognition/Remembering'
                                                  when value = '4' then 'Communication'
                                                  when value = '1' then 'Vision'
                                                  when value = '2' then 'Hearing' END, ',')
                            FROM regexp_split_to_table(a.j33, ',') AS value) AS "J33: Disability category identified"
                    FROM a)

SELECT fd.id,
       fd.item_id                   as member_id,
       pgm.pgm_id,
       pgm.member_name,
       pgm.house_hold_id,
       pgm.age,
       pgm.participant_id,
       pgm.member_name              as participant_name,
       pgm.group_id,
       pgm.group_name,
       pgm.group_type_id,
       pgm.group_type_name,
       pgm.service_point_id         as club_id,
       pgm.group_service_point_name as club_name,
       fd.catchment_id,
       dc.catchment_name,
       dc.parent_catchment_id,
       dc.parent_catchment_name,
       dc.community_type_id,
       dc.community_type,
       dc.catchment_level_id,
       dc.catchment_level_name,
       opmh.branch_office_id,
       opmh.branch_office_name,
       opmh.area_office_id,
       opmh.area_office_name,
       opmh.regional_office_id,
       opmh.regional_office_name,
       opmh.country_id,
       opmh.country_name,
       opmh.project_id,
       opmh.project_name,
       fd.fiscal_year_id,
       fy.name                      as fiscal_year,
       fd.create_time,
       fd.last_modified_time,

       fd.process_data,
       fd.intake_start_date,
       fd.intake_end_date,

       fd."J27: Does the member have diﬃculty seeing, even when wearing glasses? Would you say …?  ",
       fd."J28: Does the member have diﬃculty hearing even if using a hearing aid? Would you say …?   ",
       fd."J29: Does the member have diﬃculty walking or climbing steps? Would you say …?  ",
       fd."J30: Using usual language, does the member have diﬃculty communicating, for example, understanding or being understood? Would you say …?  ",
       fd."J31: Does the member have diﬃculty remembering or concentrating? Would you say …?",
       fd."J32: Does the member have diﬃculty with self-care such as washing all over or dressing? Would you say …?  ",
       fd."J33: Disability category identified"


FROM final_data fd
         LEFT JOIN dm_schema.participant_group_member pgm ON pgm.pgm_id = fd.item_id
         LEFT JOIN dm_schema.office_project_mapping_hierarchy opmh
                   ON opmh.office_id = fd.office_id AND opmh.project_id = fd.project_id
         LEFT JOIN fiscal_year fy ON fy.id = fd.fiscal_year_id
         LEFT JOIN dm_schema.dim_catchment dc ON dc.catchment_id = fd.catchment_id