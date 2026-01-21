WITH non_duplicate_pgm_name_update AS (SELECT *
                                       FROM (SELECT member_id,
                                                    correct_name,
                                                    row_number()
                                                    over (PARTITION BY member_id ORDER BY pnu.correct_name desc) r
                                             FROM pgm_name_update pnu
                                                      JOIN participant_group_member pgm ON pnu.item_id = pgm.id
                                                      JOIN _aim_c3_hhm_information hhm ON pgm.member_id = hhm.id) x
                                       where r = 1),

     hhm_new_name AS (SELECT member_id,
                             new_full_name,
                             CASE
                                 WHEN word_count > 1 THEN
                                     ARRAY_TO_STRING(words[1:word_count - 1], ' ')
                                 ELSE
                                     ''
                                 END           AS new_first_name,
                             words[word_count] AS new_last_name
                      FROM (SELECT member_id,
                                   TRIM(correct_name)                                        AS new_full_name,
                                   STRING_TO_ARRAY(TRIM(correct_name), ' ')                  AS words,
                                   ARRAY_LENGTH(STRING_TO_ARRAY(TRIM(correct_name), ' '), 1) AS word_count
                            FROM non_duplicate_pgm_name_update) sub),

     hhm_name_versions AS MATERIALIZED (SELECT hhm_new.*,
                                               hhm.j2a_member_first_name as old_first_name,
                                               hhm.j2a_member_last_name  as old_last_name,
                                               hhm.member_name           as old_fullname
                                        FROM hhm_new_name hhm_new
                                                 JOIN _aim_c3_hhm_information hhm ON hhm_new.member_id = hhm.id)

SELECT * INTO bak.member_id_name_update FROM hhm_name_versions;
-- SELECT * FROM bak.member_id_name_update;

SELECT count(a.*)
INTO bak._aim_c3_hhm_information_before_name_update_11_12_25

FROM _aim_c3_hhm_information a
JOIN bak.member_id_name_update b ON a.id = b.member_id;

SELECT a.*
INTO bak.house_hold_member_before_name_update_11_12_25

FROM house_hold_member a
         JOIN bak.member_id_name_update b ON a.id = b.member_id;

DROP TABLE bak.member_id_name_update;

SELECT hhm.id,
    hhm.member_name,
       hhm.answer,
       bak.new_first_name,
       bak.new_last_name,
       bak.new_full_name
FROM house_hold_member  hhm
JOIN bak.member_id_name_update bak ON hhm.id = bak.member_id
WHERE hhm.member_name != bak.new_full_name;



UPDATE house_hold_member hhm
SET
    last_modified_time = now()
FROM bak.member_id_name_update bak
WHERE hhm.id = bak.member_id;





SELECT hhm.id,
       hhm.member_name,
       hhm.j2a_member_first_name,
       hhm.j2a_member_last_name,
       bak.new_first_name,
       bak.new_last_name,
       bak.new_full_name
FROM _aim_c3_hhm_information  hhm
         JOIN bak.member_id_name_update bak ON hhm.id = bak.member_id
WHERE hhm.member_name != bak.new_full_name;

UPDATE _aim_c3_hhm_information hhm
SET
    member_name = bak.new_full_name,
    j2a_member_first_name = bak.new_first_name,
    j2a_member_last_name = bak.new_last_name,
    last_modified_time = now()

FROM bak.member_id_name_update bak
WHERE hhm.id = bak.member_id;
SELECT
