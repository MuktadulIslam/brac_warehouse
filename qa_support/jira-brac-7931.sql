----------------------------YDC group------------------------------
SELECT pg.id    as group_id,
       pg.name  as group_name,
       pgt.name as group_type,
       pg.catchment_id,
       ct.name  as catchment_name,
       o.name   as branch_office_name,
       c.name   as country_name,
       p.name   as project_name,
       fy.name  as fiscal_year,
       pg.fiscal_year_id,
       pg.group_serial,
       pg.create_time,
       pg.last_modified_time,
       uc.id    as created_by,
       um.id    as last_modified_by

FROM participant_group pg
         JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
         LEFT JOIN catchment ct ON pg.catchment_id = ct.id
         LEFT JOIN office o ON pg.office_id = o.id
         LEFT JOIN country c ON pg.country_id = c.id
         LEFT JOIN project p ON pg.project_id = p.id
         LEFT JOIN fiscal_year fy ON pg.fiscal_year_id = fy.id
         LEFT JOIN "user" uc ON uc.id = ct.created_by
         LEFT JOIN "user" um ON um.id = ct.last_modified_by
WHERE pgt.name ilike '%YDC%'
  AND fy.name ilike '%Cohort 3%';


----------------------------YDC session------------------------------
WITH event_session_group_type AS (SELECT es.id,
                                         string_agg(pgt.name, ' ; ')::text AS group_types
                                  FROM event_session es
                                           JOIN LATERAL unnest(string_to_array(es.group_type_id, ',')) as gt(id) ON true
                                           LEFT JOIN participant_group_type pgt ON pgt.id = gt.id
                                  GROUP BY es.id),
     ydc_sessions AS
         (SELECT es.id            as session_id,
                 es.name          as session_name,
                 e.id             as event_id,
                 e.event_name,
                 es.session_data,
                 es.is_session_data_mandatory,
                 es.is_session_member_data_mandatory,
                 es.service_point_type_id,
                 spt.name         as service_point_type,
                 es.need_budget,
                 es.need_scoring,
                 es.need_authorization,
                 es.sort_order_in_event,
                 es.trainer_type_id,
                 tt.name          as trainer_type,
                 es.group_type_id as group_type_ids,
                 esgt.group_types,
                 es.mob_spec_permission,
                 es.is_absent_member_data_mandatory,
                 es.create_time,
                 es.last_modified_time,
                 es.event_theme_session_id,
                 ets.name         as event_theme_session,
                 e.project_id,
                 p.name           as project_name,
                 e.fiscal_year_id,
                 fy.name          as fiscal_year

          FROM event_session es
                   JOIN event e ON e.id = es.event_id
                   LEFT JOIN service_point_type spt ON es.service_point_type_id = spt.id
                   LEFT JOIN trainer_type tt ON tt.id = es.trainer_type_id
                   LEFT JOIN event_session_group_type esgt ON es.id = esgt.id
                   LEFT JOIN event_theme_session ets ON ets.id = es.event_theme_session_id
                   LEFT JOIN project p ON e.project_id = p.id
                   LEFT JOIN fiscal_year fy ON e.fiscal_year_id = fy.id
          WHERE fy.name ilike '%Cohort 3%'
            AND e.event_type_id = '8140b5261a5943ccb24804a6447eca03'    -- Non club based
            AND esgt.group_types ilike '%YDC%'
            AND spt.name = 'None'
--             AND e.event_name ilike '%YDC%'
--             AND es.name ilike '%YDC%'
          )

SELECT * FROM ydc_sessions;