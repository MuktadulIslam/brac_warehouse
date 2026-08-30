WITH pgm_all_data AS (SELECT id as pgm_id, 'no' drop_out, member_id, group_id
                      FROM participant_group_member
                      UNION ALL
                      SELECT id as pgm_id, 'yes' drop_out, member_id, group_id
                      FROM participant_group_exit
                      WHERE is_deleted IS NOT TRUE),

     pgm_all_ased_based_group_data AS (SELECT pgm_id,
                                              drop_out,
                                              member_id,
                                              group_id,
                                              pgt.name as group_type,
                                              fy.name  as fiscal_year
                                       FROM pgm_all_data pge
                                                JOIN participant_group pg ON pge.group_id = pg.id
                                                JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                                JOIN fiscal_year fy ON pg.fiscal_year_id = fy.id
                                       WHERE fy.name IN ('Cohort 3', 'Cohort 4')
                                         AND pgt.name IN ('AG', 'EA', 'YW', 'VYA')),

     hhm_aged_group AS (SELECT hhms.id as member_id, hhms.j3c::text as aged_group, hhms.age::text
                        FROM aim_c4_hhm_survey hhms
--                         JOIN house_hold_member hhm ON hhms.id = hhm.id
                        UNION ALL
                        SELECT id as member_id, j3c::text as aged_group, age::text
                        FROM _aim_c3_hhm_information),

    false_pge_member_data_with_tag AS (SELECT pgm_id,
                                               fiscal_year,
                                               member_id,
                                               drop_out,
                                               group_id,
                                               group_type,
                                               aged_based_group,
                                               age,
                                               CASE
                                                   WHEN group_type ILIKE '%VSLA%' THEN 'keep'
                                                   WHEN aged_based_group ILIKE group_type || ' (%' THEN 'keep'
                                                   ELSE 'droppable'
                                                   END AS record_status
                                        FROM (SELECT DISTINCT pge.pgm_id,
                                                              pge.member_id,
                                                              pge.group_id,
                                                              pge.drop_out,
                                                              pgt.name AS group_type,
                                                              CASE hhm.aged_group
                                                                  WHEN '1' THEN 'VYA (12-14)'
                                                                  WHEN '2' THEN 'AG (15-17)'
                                                                  WHEN '3' THEN 'YW (18-24)'
                                                                  WHEN '4' THEN 'EA (25-35)'
                                                                  END  AS aged_based_group,
                                                              hhm.age,
                                                              pge.fiscal_year
                                              FROM pgm_all_ased_based_group_data pge
                                                       JOIN participant_group pg ON pge.group_id = pg.id
                                                       JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
                                                       LEFT JOIN hhm_aged_group hhm ON hhm.member_id = pge.member_id) x)

-- SELECT * INTO bak.member_need_to_dropout FROM false_pge_member_data_with_tag WHERE record_status = 'droppable';
-- SELECT * FROM false_pge_member_data_with_tag WHERE record_status = 'droppable' AND drop_out = 'no';
SELECT * FROM false_pge_member_data_with_tag WHERE record_status = 'droppable';
-- SELECT * FROM duplicate_member;
-- SELECT * FROM bak.member_need_to_dropout;
DROP  TABLE bak.member_need_to_dropout;


-------------------------------------------------------------------- Inserting Into Exit Group --------------------------------------------------------------------
INSERT INTO participant_group_exit (
    id,
    group_id,
    member_id,
    exit_time,
    create_time,
    last_modified_time,
    is_deleted,
    exit_reason_id,
    created_by,
    last_modified_by,
    member_type,
    exit_status,
    participant_group_member_data,
    linked_group_id,
    fiscal_year_id,
    last_sync_time,
    rule_ids,
    rules
)
SELECT
    pgm.id::text,
    pgm.group_id,
    pgm.member_id,
    now(),
    now(),
    now(),
    true,
    '23f22b68bb854ba0940a82a69d1eb3af',
    'stream_fresh',
    'stream_fresh',
    pgm.member_type,
    'UnEnrolment',
    to_jsonb(pgm)::text,
    NULL,
    pgm.fiscal_year_id,
    now(),
    NULL,
    NULL
FROM participant_group_member pgm
WHERE pgm.id IN (
    SELECT pgm_id FROM bak.member_need_to_dropout WHERE record_status = 'droppable'  AND drop_out = 'no'
);


SELECT * FROM participant_group_exit pge
JOIN bak.member_need_to_dropout  mntd ON pge.id = mntd.pgm_id WHERE record_status = 'droppable'  AND drop_out = 'no';


--------------------------------------------------------- Deleting from the participant_group_member ---------------------------------------------------------
DELETE  FROM participant_group_member
WHERE id IN (
    SELECT pgm_id FROM bak.member_need_to_dropout WHERE record_status = 'droppable'  AND drop_out = 'no'
);



--------------------------------------------------------- Updating status in participant_group_exit ---------------------------------------------------------
UPDATE participant_group_exit
SET
    exit_status = 'UnEnrolment',
    last_modified_time =  now(),
    last_modified_by = 'stream_fresh',
    is_deleted =  true,
    exit_reason_id = '23f22b68bb854ba0940a82a69d1eb3af'
FROM bak.member_need_to_dropout WHERE pgm_id = id AND record_status = 'droppable'  AND drop_out = 'yes';




---------------------------------------------------------------------------------------------------------------------------------------------------------------
--     If Cohort-4 hhm does not have any  j3c attribute
---------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE house_hold_member
SET answer = (COALESCE(NULLIF(answer, ''), '{}')::jsonb || '{"j3c":"2"}'::jsonb)::text
--     last_modified_time = now(),
--     last_modified_by   = 'stream_fresh'
WHERE id IN ('98e3174d17fb4df49a56da3a5654f4cb','63b9af569ffb45d6be065f63e71105bc',
             '97799438023945fab04f852a1c937585','076f0d90714346a098d1b967064ed6d6',
             'a5e31f34bcfd4ec3bcd4c1a65b8fcd67');
