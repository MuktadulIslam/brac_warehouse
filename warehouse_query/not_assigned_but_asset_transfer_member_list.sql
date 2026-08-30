DROP table temporary.not_assigned_but_asset_transfer_member_list;
Create table temporary.not_assigned_but_asset_transfer_member_list AS;
WITH member_package AS (SELECT member_id,
                               enterprice_id,
                               max(create_time)        as create_time,
                               max(last_modified_time) as last_modified_time
                        FROM (SELECT item_id                     as member_id,
                                     enterprise                  as enterprice_id,
                                     at.create_time::date        as create_time,
                                     at.last_modified_time::date as last_modified_time
                              FROM asset_transfer at
                                       JOIN fiscal_year fy ON at.fiscal_year_id = fy.id
                              WHERE fy.name = 'Cohort 3') x
                        group by member_id, enterprice_id)


SELECT mp.* FROM member_package mp
LEFT JOIN livelihood_assignment la ON la.item_id = mp.enterprice_id AND la.enterprise_assignment_eligible_members ILIKE '%' || member_id || '%'
WHERE la.item_id IS NULL;

SELECT at.* FROM asset_transfer at
         JOIN fiscal_year fy ON at.fiscal_year_id = fy.id
WHERE fy.name = 'Cohort 3' AND enterprise is null;




ALTER TABLE temporary.not_assigned_but_asset_transfer_member_list
    ADD COLUMN club_id TEXT;

SELECT * FROM temporary.not_assigned_but_asset_transfer_member_list; -- 659
SELECT * FROM temporary.not_assigned_but_asset_transfer_member_list wp
    JOIN (SELECT * FROM (SELECT distinct member_id, service_point_id as club_id,
                          row_number() over (partition by member_id order by  pgm.create_time desc ) r
                          FROM participant_group_member pgm JOIN participant_group pg ON pg.id = pgm.group_id)x where r=1) pgm ON pgm.member_id = wp.member_id;

UPDATE temporary.not_assigned_but_asset_transfer_member_list wp
SET club_id = pgm.club_id
FROM ((SELECT * FROM (SELECT distinct member_id, service_point_id as club_id,
                          row_number() over (partition by member_id order by  pgm.create_time desc ) r
                          FROM participant_group_member pgm JOIN participant_group pg ON pg.id = pgm.group_id)x where r=1)) pgm
WHERE pgm.member_id = wp.member_id;



----------------------------------------Update----------------------------------------------

-------------------------------------******** Preview ********-------------------------------------
DROP TABLE bak.tmp_orphan_groups_06_07_2026;
CREATE TABLE bak.tmp_orphan_groups_06_07_2026 AS
WITH orphans AS (SELECT a.member_id::text AS member_id, a.club_id, a.enterprice_id as new_package_id
                 FROM temporary.not_assigned_but_asset_transfer_member_list a
                          LEFT JOIN livelihood_assignment la
                                    ON la.enterprise_assignment_eligible_members ILIKE '%' || a.member_id::text || '%'
                                        AND a.enterprice_id = la.item_id
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

COMMIT;

DROP TABLE IF EXISTS bak.tmp_orphan_groups_06_07_2026;