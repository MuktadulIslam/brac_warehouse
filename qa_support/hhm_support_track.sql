SELECT hhm.id       as member_id,
       hhm.member_name,
       hhm.age,
       hhm.house_hold_id,
       ct.name      as comminity_name,
       pg.name      as group_name,
       CASE
           WHEN hhm_data.j26 = '1' THEN 'AIM Education: Financial Support'
           WHEN hhm_data.j26 = '2' THEN 'AIM Education: Return & Financial Support'
           WHEN hhm_data.j26 = '3' THEN 'AIM Education:  Alternative Education Opportunities'
           WHEN hhm_data.j26 = '4' THEN 'Livelihood'
           ELSE 'None'
           END      as support_track_name,
       hhm_data.j26 as support_track_id
FROM house_hold_member hhm
         JOIN _aim_c3_hhm_information hhm_data ON hhm.id = hhm_data.id
         LEFT JOIN catchment ct ON ct.id = hhm.catchment_id
         LEFT JOIN participant_group_member pgt ON pgt.member_id = hhm.id
         LEFT JOIN participant_group pg ON pg.id = pgt.group_id
WHERE pg.name in ('AG 2 Gbere - 1', 'AG 2 Gbere - 2');
