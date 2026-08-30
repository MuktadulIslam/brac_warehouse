-------------------------------------******** Data Preparation ********-------------------------------------
ALTER TABLE temporary.package_change_bracjira_3113
    ADD COLUMN member_id TEXT,
    ADD COLUMN old_package_id TEXT,
    ADD COLUMN new_package_id TEXT,
    ADD COLUMN club_id TEXT;

UPDATE temporary.package_change_bracjira_3113 wp
SET member_id = gmp.id
FROM group_member_participant gmp
WHERE wp.participant_id = gmp.member_serial;

UPDATE temporary.package_change_bracjira_3113 wp
SET club_id = pgm.club_id
FROM (SELECT distinct member_id, service_point_id as club_id  FROM participant_group_member pgm JOIN participant_group pg ON pg.id = pgm.group_id) pgm
WHERE pgm.member_id = wp.member_id;

UPDATE temporary.package_change_bracjira_3113
SET stl_remarks = 'Package is already transferred. So we can not update the package'
FROM asset_transfer at WHERE at.item_id = member_id AND stl_remarks IS NULL;

UPDATE temporary.package_change_bracjira_3113 wp
    SET stl_remarks = 'New package is already assigned'
FROM livelihood_assignment la WHERE la.enterprise_assignment_eligible_members ILIKE '%' || member_id || '%' AND wp.new_package_id = la.item_id;


DELETE FROM temporary.package_change_bracjira_3113 where  participant_id in ('PT00479369', 'PT00413791', 'PT00401707');

-- DROP TABLE temporary.package_change_bracjira_3113;
CREATE TABLE temporary.package_change_bracjira_3204 AS
SELECT *
FROM (
    VALUES
        ('79ca969c65cb49e4b64e7dcbc140f005','Salama Issa Kayamba',          'PT00454245', 'KILAKALA BY',   'Kitwiru A club','08214af7-0109-4034-8b52-5fedb2168e74',    '15A: Small business (Only for urban) with petty trade', '5b48f049-1e72-4bd9-82c2-8fcea4e25f6f',                         '11A: Small business (Only for urban) with petty trade', 'a024f2c011af4ca8882cbec2b13b549c')
) AS t(member_id,member_name, participant_id, catchment_name, club_name,old_package_id, old_package_name,new_package_id,  final_package_name, club_id);



SELECT * FROM temporary.package_change_bracjira_3113;
SELECT distinct right_assigned_package FROM temporary.package_change_bracjira_3113;
SELECT id, enterprise_name FROM enterprise where fiscal_year_id = '48494271233d49c184873d4d321f07ee';

SELECT distinct fiscal_year_id FROM temporary.package_change_bracjira_3113 a LEFT JOIN house_hold_member hhm ON hhm.id = a.member_id;


-- 1A:2female Goat
-- 10 B:Small business with petty trade
-- 3A: 2 goats(female) with petty trade
-- 10 C: Small business
-- 12 A:Small business with 1female Goat
-- 3A:2female goat with petty trade
-- 11 C: Small business
-- 4D: 2 Pigs with petty trade
-- 7A:1 month cross breed chicken with petty trade
-- 10B:Small business with petty trade
-- 11A:Small business with petty trade
-- 10 C :Small Business


-- 1021b602-5924-4bca-959b-024738e4e1d6,    1 A: 2 Goats ( Female 6-8 months)
-- befbd710-a824-4e81-b7fa-7bdbc7a669c6,    10 C: Small business
-- cc4fcf2a-ae7f-428b-91cc-363a12e2ca2e,    10B: Small business with petty trade
-- 5b48f049-1e72-4bd9-82c2-8fcea4e25f6f,    11 A: Small business  with petty trade
-- 21e9ebf6-4343-4395-8d6d-3874e550e18a,    12 A:	Small business with 1 female goat
-- ada2623c-5280-447a-9191-09f1d8d59d72,    3A: 2 Goats (Female) with petty trade
-- ff7766c3-dc7e-49b1-97f8-99a743eb1bb9,    4 D: 2 Pigs (1 Male and 1 Female) with petty trade
-- 314cfbd8-2e1a-4f91-9533-6b22f4774891,    7 A: 1 Month cross-breed chickens (30 SASSO/Kroiler Breed) with petty trade

SELECT mpu.member_id, mpu.participant_id, mpu.old_package, mpu.new_package, e.enterprise_name as current_package FROM temporary.member_package_update mpu
LEFT JOIN livelihood_assignment la ON la.enterprise_assignment_eligible_members ILIKE '%' || member_id || '%'
LEFT JOIN enterprise e ON e.id = la.item_id;

SELECT distinct member_id, participant_id FROM temporary.member_package_update  mpu
JOIN asset_transfer at ON at.item_id = mpu.member_id

-------------------------------------******** Validation Before Update ********-------------------------------------
SELECT * FROM temporary.package_change_bracjira_3113 wp
JOIN asset_transfer at ON at.item_id = wp.member_id;    -- PT00450198

-- SELECT participant_id, member_name, total_fisrt_asset_given, total_second_asset_given, total_input_asset_given
-- FROM reporting_schema.livelihood_member_wise_asset_distribution_report
-- where
--     participant_id in ('PT00479369', 'PT00413791', 'PT00401707');

-------------------------------------******** Preview ********-------------------------------------
CREATE TABLE bak.tmp_orphan_groups_06_07_2026 AS
WITH orphans AS (SELECT a.member_id::text AS member_id, a.club_id, a.new_package_id
                 FROM temporary.package_change_bracjira_3113 a
                          LEFT JOIN livelihood_assignment la
                                    ON la.enterprise_assignment_eligible_members ILIKE '%' || a.member_id::text || '%'
                                        AND a.new_package_id = la.item_id
                 WHERE la.id IS NULL)
SELECT club_id,
       new_package_id,
       string_agg(DISTINCT member_id, ',') AS new_members
FROM orphans
GROUP BY club_id, new_package_id;


SELECT la2.id                                     AS target_id,
       la2.club_id,
       la2.item_id                                as package_id,
       og.new_members,
       la2.enterprise_assignment_eligible_members as old_member_list,
       CASE
           WHEN COALESCE(NULLIF(la2.enterprise_assignment_eligible_members, ''), '') = ''
               THEN og.new_members
           ELSE la2.enterprise_assignment_eligible_members || ',' || og.new_members
           END                                    AS new_member_list
FROM bak.tmp_orphan_groups_06_07_2026 og
         JOIN livelihood_assignment la2
              ON la2.club_id = og.club_id
                  AND la2.item_id = og.new_package_id;

-------------------------------------******** Back-Up ********-------------------------------------
SELECT la2.*
INTO bak.livelihood_assignment_22_07_2026_BRACJira_3113
FROM bak.tmp_orphan_groups_06_07_2026 og
         JOIN livelihood_assignment la2
              ON la2.club_id = og.club_id
                  AND la2.item_id = og.new_package_id;


-------------------------------------******** Update/Delete ********-------------------------------------

BEGIN;

-- 1. BRANCH A — row exists for (club_id, item_id): append members, sync answer JSON
UPDATE livelihood_assignment la
SET enterprise_assignment_eligible_members = nl.new_list,
    answer                                 = jsonb_set(
            COALESCE(la.answer, '{}')::jsonb,
            '{enterprise_assignment_eligible_members}',
            to_jsonb(nl.new_list)
                                             )::text,
    last_modified_time                     = now(),
    last_modified_by                       = 'stream_fresh'
FROM (SELECT la2.id  AS target_id,
             CASE
                 WHEN COALESCE(NULLIF(la2.enterprise_assignment_eligible_members, ''), '') = ''
                     THEN og.new_members
                 ELSE la2.enterprise_assignment_eligible_members || ',' || og.new_members
                 END AS new_list
      FROM bak.tmp_orphan_groups_06_07_2026 og
               JOIN livelihood_assignment la2
                    ON la2.club_id = og.club_id
                        AND la2.item_id = og.new_package_id) nl
WHERE la.id = nl.target_id;

-- 2. BRANCH B — no (club_id, item_id) row: clone one club sibling, then override
INSERT INTO livelihood_assignment (id, item_id, operational_period_id,
                                   create_time, reporting_date, last_modified_time,
                                   is_deleted, catchment_id, created_by, last_modified_by,
                                   country_id, project_id, answer, fiscal_year_id, office_id,
                                   eligible_members_max_limit, enterprise_assignment_eligible_members,
                                   process_data, last_sync_time,
                                   version, modified_version, submission_status,
                                   meta_data, survey_meta_data, club_id)
SELECT uuid_generate_v1()::text, -- new id
       og.new_package_id,      -- item_id  <- user's new_package_id
       NULL,                     -- operational_period_id
       now(),
       now(),
       now(),                    -- create/reporting/last_modified time
       NULL,                     -- is_deleted
       src.catchment_id,
       'stream_fresh',
       'stream_fresh',           -- created_by, last_modified_by
       src.country_id,
       src.project_id,
       jsonb_set( -- answer: patch member list, _itemId, max_limit
               jsonb_set(
                       jsonb_set(
                               COALESCE(src.answer, '{}')::jsonb,
                               '{enterprise_assignment_eligible_members}', to_jsonb(og.new_members)
                       ),
                       '{_itemId}', to_jsonb(og.new_package_id)
               ),
               '{eligible_members_max_limit}', 'null'::jsonb
       )::text,
       src.fiscal_year_id,
       src.office_id,
       NULL,                     -- eligible_members_max_limit
       og.new_members,           -- enterprise_assignment_eligible_members
       NULL,
       NULL,                     -- process_data, last_sync_time
       src.version,
       src.modified_version,
       src.submission_status,
       src.meta_data,
       src.survey_meta_data,
       src.club_id
FROM bak.tmp_orphan_groups_06_07_2026 og
         CROSS JOIN LATERAL (
    SELECT *
    FROM livelihood_assignment l
    WHERE l.club_id = og.club_id
    ORDER BY l.create_time DESC NULLS LAST
    LIMIT 1
    ) src
WHERE NOT EXISTS (SELECT 1
                  FROM livelihood_assignment l2
                  WHERE l2.club_id = og.club_id
                    AND l2.item_id = og.new_package_id);


DROP TABLE IF EXISTS bak.tmp_orphan_groups_06_07_2026;