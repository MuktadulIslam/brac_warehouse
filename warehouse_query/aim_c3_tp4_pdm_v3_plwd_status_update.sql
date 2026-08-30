SELECT s.id, s.item_id, s.created_by, s.create_time, s._plwd, a.j33,
       CASE
           WHEN a.j33 = ',,,,,' THEN 'No'
           ELSE 'Yes'
           END as plw
       FROM aim_c3_tp4_pdm_v3 s
JOIN _aim_c3_hhm_information a ON a.id = s.item_id;

UPDATE aim_c3_tp4_pdm_v3 s
SET _plwd = CASE
    WHEN a.j33 = ',,,,,' THEN 'No'
    ELSE 'Yes'
END
FROM _aim_c3_hhm_information a
WHERE a.id = s.item_id;
