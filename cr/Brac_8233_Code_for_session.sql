SELECT event_name,
       session_id,
       session_name,
       sort_order_in_event,
       group_type_id,
       group_type_name,
       fiscal_year_name,
       CASE
           WHEN group_code IS NULL THEN NULL
           ELSE CONCAT(event_code, group_code, session_code)
           END as session_code

FROM (SELECT e.event_name,
             es.name                                    as session_name,
             es.id                                      as session_id,
             es.sort_order_in_event,
             es.group_type_id,
             pgt.name                                   as group_type_name,
             fy.name                                    as fiscal_year_name,
             -- Prefix based on event name (CB for Curriculum-Based, NCB for Non-Curriculum-Based)
             CASE
                 WHEN e.event_type_id = 'ed1b4bbe5461443698b2e1793ffb326e' THEN 'CB'
                 ELSE 'NCB'
                 END                                    as event_code,
             -- Group type code (01-05 based on group type)
             CASE
                 WHEN pgt.name = 'VYA' THEN '01'
                 WHEN pgt.name = 'AG' THEN '02'
                 WHEN pgt.name = 'YW' THEN '03'
                 WHEN pgt.name = 'EA' THEN '04'
                 WHEN e.event_name ILIKE '%family%' THEN '05'
                 WHEN pgt.name = 'YDC' THEN '01'
                 ELSE null -- Default for unmapped types
                 END                                    as group_code,
             -- Sort order (padded to 2 digits)
             LPAD(es.sort_order_in_event::TEXT, 2, '0') as session_code
      FROM event_session es
               JOIN event e ON es.event_id = e.id
               JOIN fiscal_year fy ON fy.id = e.fiscal_year_id
               LEFT JOIN participant_group_type pgt ON pgt.id = es.group_type_id) x;

------------------ Cohort-2 event name
-- TZ - Cross Gender session
-- SL - Cross Gender session
-- UG - Cross Gender session
-- LB - Cross Gender session
-- RW - Cross Gender session
-- UG-C2-Livelihood_trainng
-- need to delete

------------------ Cohort-1 event name
-- Training

-- AB (group)