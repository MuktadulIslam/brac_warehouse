WITH batch_member_attendance AS (SELECT batch_id,
                                        member_id,
                                        SUM(is_present) * 100 / count(member_id) as attendance_percentage
                                 FROM muktadul.livelihood_batch_session_wise_member_attendance
                                 WHERE status = 'submitted'
                                 GROUP BY batch_id, member_id)

SELECT bma.member_id,
       hhm.member_name,
       hhm.age,
       hhm.gender,
       ex.partition_status,
       bma.attendance_percentage,
       CASE
           WHEN ex.partition_status IS NOT NULL THEN ex.partition_status
           ELSE
               CASE
                   WHEN bma.attendance_percentage = 100 then 'Include'
                   ELSE 'Exclude'
                   END
           END  final_eligible_status,
       cat.name member_village,
       cat.id   member_village_id,
       bma.batch_id,
       lbd.batch_name,
       lbd.country_id,
       lbd.country_name,
       lbd.project_id,
       lbd.project_name,
       lbd.fiscal_year_id,
       lbd.fiscal_year,
       lbd.branch_office_id,
       lbd.branch_office_name

-- INTO muktadul.livelihood_regular_distribution_eligible_participants
FROM batch_member_attendance bma
         JOIN house_hold_member hhm ON hhm.id = bma.member_id
         LEFT JOIN catchment cat ON cat.id = hhm.catchment_id
         LEFT JOIN muktadul.livelihood_batch_details lbd ON lbd.id = bma.batch_id
         LEFT JOIN muktadul.livelihood_distribution_member_exclude_include_data ex ON ex.item_id = bma.member_id;