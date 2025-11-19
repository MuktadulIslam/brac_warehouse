SELECT lbd.id                as batch_id,
       lbd.batch_name,
       lbd.country_id,
       lbd.country_name,
       lbd.event_session_id,
       lbd.event_session_name,
       lbd.project_id,
       lbd.project_name,
       lbd.fiscal_year_id,
       lbd.fiscal_year,
       lbd.branch_office_id,
       lbd.branch_office_name,
       lbd.branch_office_name,
       lbd.created_by,
       lbd.created_by_name,
       p.id                  as member_id,
       hhm.member_name,
       hhm.age,
       CASE
           WHEN hhm.gender = '1' THEN 'Female'
           WHEN hhm.gender = '2' THEN 'Male'
           ELSE 'Others' END as gender,
       hhm.house_hold_id

FROM qa_warehouse_muktaul.livelihood_batch_details lbd
         JOIN LATERAL unnest(string_to_array(lbd.participant_ids, ',')) p(id) ON true
         LEFT JOIN house_hold_member hhm ON p.id = hhm.id;
