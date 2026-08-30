WITH cohort3_fiscal_year AS MATERIALIZED (SELECT * FROM fiscal_year WHERE name = 'Cohort 3'),

     c3_enterprise AS (SELECT e.*,
                              CASE
                                  WHEN e.is_cost_sharing_applicable = '0' THEN 0
                                  ELSE e.cost_sharing_amount END AS package_cost_sharing_amount,
                              e.total_asset_value                AS package_price
                       FROM enterprise e
                                JOIN cohort3_fiscal_year cfy ON cfy.id = e.fiscal_year_id),

     package_asset_details AS (SELECT e.id                                                     AS package_id,
                                      e.fiscal_year_id,
                                      a.id                                                     AS asset_id,
                                      a.asset_name,
                                      ea.enterprise_asset_type,
                                      ea.enterprise_asset_quantity                             AS package_asset_quantity

                               FROM enterprise_enterprise_assets ea
                                        JOIN c3_enterprise e ON e.id = ea.master_id
                                        JOIN asset a ON a.id = ea.enterprise_asset_name),

    package_asset_type_details AS (SELECT package_id,
                                      COALESCE(STRING_AGG(CASE WHEN enterprise_asset_type = '0' THEN asset_name END, ', ' ORDER BY asset_name), 'N/A')          AS first_asset_name,
                                      COALESCE(STRING_AGG(CASE WHEN enterprise_asset_type = '1' THEN asset_name END, ', ' ORDER BY asset_name), 'N/A')          AS second_asset_name,
                                      COALESCE(STRING_AGG(CASE WHEN enterprise_asset_type = '2' THEN asset_name END, ', ' ORDER BY asset_name), 'N/A')          AS input_asset_name,
                                      SUM(CASE WHEN enterprise_asset_type = '0' THEN COALESCE(package_asset_quantity, 0) END)                                   AS fisrt_asset_quantity,
                                      SUM(CASE WHEN enterprise_asset_type = '1' THEN COALESCE(package_asset_quantity, 0) END)                                   AS second_asset_quantity,
                                      SUM(CASE WHEN enterprise_asset_type = '2' THEN COALESCE(package_asset_quantity, 0) END)                                   AS input_asset_quantity
                               FROM package_asset_details
                               GROUP BY package_id)
-- SELECT * FROM package_asset_details;    -- 1158
        ,
     asset_list AS (SELECT at.item_id,
                           at.asset,
                           at.enterprise,
                           at.number_of_asset,
                           at.transfer_date
                    FROM asset_transfer at
                             JOIN cohort3_fiscal_year c3fy ON c3fy.id = at.fiscal_year_id
                    WHERE at.action = '1'),

     asset_transfer_data AS MATERIALIZED (SELECT item_id                                                       as member_id,
                                                 enterprise                                                    as package_id,
                                                 MAX(at.transfer_date) as transfer_date,
                                                 SUM(CASE WHEN pad.enterprise_asset_type = '0' THEN COALESCE(at.number_of_asset, 0) END)       AS number_of_fisrt_asset_transfer,
                                                 SUM(CASE WHEN pad.enterprise_asset_type = '1' THEN COALESCE(at.number_of_asset, 0) END)       AS number_of_second_asset_transfer,
                                                 SUM(CASE WHEN pad.enterprise_asset_type = '2' THEN COALESCE(at.number_of_asset, 0) END)       AS number_of_inout_asset_transfer
                                          FROM asset_list at
                                                   JOIN package_asset_details pad ON pad.asset_id = at.asset AND at.enterprise = pad.package_id
                                          GROUP BY at.item_id, at.enterprise),

     member_asset_status AS (SELECT atd.member_id,
                                    atd.package_id,
                                    atd.transfer_date,
                                    patd.first_asset_name,
                                    patd.fisrt_asset_quantity,
                                    atd.number_of_fisrt_asset_transfer,
                                    CASE
                                        WHEN first_asset_name = 'N/A' THEN 'N/A'
                                        WHEN number_of_fisrt_asset_transfer = 0 THEN 'Not Yet'
                                        WHEN number_of_fisrt_asset_transfer < fisrt_asset_quantity THEN 'Partial'
                                        WHEN number_of_fisrt_asset_transfer >= fisrt_asset_quantity THEN 'Full'
                                        END first_asset_status,

                                    patd.second_asset_name,
                                    patd.second_asset_quantity,
                                    atd.number_of_second_asset_transfer,
                                    CASE
                                        WHEN second_asset_name = 'N/A' THEN 'N/A'
                                        WHEN number_of_second_asset_transfer = 0 THEN 'Not Yet'
                                        WHEN number_of_second_asset_transfer < second_asset_quantity THEN 'Partial'
                                        WHEN number_of_second_asset_transfer >= second_asset_quantity THEN 'Full'
                                        END second_asset_status,

                                    patd.input_asset_name,
                                    patd.input_asset_quantity,
                                    atd.number_of_inout_asset_transfer,
                                    CASE
                                        WHEN input_asset_name = 'N/A' THEN 'N/A'
                                        WHEN number_of_inout_asset_transfer = 0 THEN 'Not Yet'
                                        WHEN number_of_inout_asset_transfer < input_asset_quantity THEN 'Partial'
                                        WHEN number_of_inout_asset_transfer >= input_asset_quantity THEN 'Full'
                                        END input_asset_status

                             FROM asset_transfer_data atd
                             JOIN package_asset_type_details patd ON patd.package_id = atd.package_id)
--      SELECT * FROM member_asset_status; -- 3,562
     ,

     unique_participant_vsla_group_member AS (SELECT member_id, group_name, group_id
                                              FROM (SELECT pgm.member_id,
                                                           pg.name as group_name,
                                                           pg.id as group_id,
                                                           ROW_NUMBER() OVER (PARTITION BY atum.member_id ORDER BY pg.create_time) AS rn
                                                    FROM asset_transfer_data atum
                                                             JOIN participant_group_member pgm ON atum.member_id = pgm.member_id
                                                             JOIN participant_group pg ON pg.id = pgm.group_id
                                                    WHERE pg.name ILIKE '%VSLA%') ranked
                                              WHERE rn = 1),

     tagged_members AS (SELECT member_id, group_name, group_id
                        FROM (SELECT item_id                                      as member_id,
                                     pg.name as group_name,
                                     vgt.vsla_group_id                            AS group_id,
                                     ROW_NUMBER() OVER (PARTITION BY vgt.item_id) AS rn,
                                     upvgm.member_id                              as vsla_member
                              FROM vsla_group_tagging vgt
                                       JOIN participant_group pg ON pg.id = vgt.vsla_group_id
                                       LEFT JOIN unique_participant_vsla_group_member upvgm
                                                 ON upvgm.member_id = vgt.item_id) ranked
                        WHERE rn = 1
                          AND vsla_member IS NULL),

     eligible_members AS (SELECT * FROM unique_participant_vsla_group_member UNION ALL SELECT * FROM tagged_members),

     existing_voucher_ids AS (SELECT TRIM(unnest(string_to_array(item_id, ',')))::TEXT AS voucher_item_id
                              FROM voucher_generation_history
                              WHERE item_id IS NOT NULL
                                AND source_type_id = '1')

SELECT at.member_id,
       le.member_name,
       le.age,
       le.member_serial as member_code,
       le.group_id,
       le.group_name,
       pgm.group_name as vsla_group_name,
       pgm.group_id as vsla_group_id,
       le.service_point_id,
       le.service_point_name,
       le.office_id as branch_office_id,
       opmh.branch_office_name,
       opmh.regional_office_id,
       opmh.regional_office_name,
       opmh.country_id,
       opmh.country_name,
       opmh.project_id,
       opmh.project_name,
       le.fiscal_year_id,
       le.fiscal_year_name,
       at.package_id,
       e.enterprise_name as package_name,
       e.cost_sharing_amount,
       e.package_price,
       at.transfer_date,
       at.first_asset_name,
       at.first_asset_status,
       at.second_asset_name,
       at.second_asset_status,
       at.input_asset_name,
       at.input_asset_status
--        CASE
--            WHEN at.first_asset_status = 'Full' AND mas.cost_sharing_amount > 0 THEN 'Yes'
--            ELSE 'No' END                                                 AS voucher_eligible,
--        CASE WHEN ev.voucher_item_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS voucher_generated,
--        CASE
--            WHEN ev.voucher_item_id IS NOT NULL THEN 'Generated'
--            WHEN mas.first_asset_status = 'Full' AND mas.cost_sharing_amount > 0 THEN 'Pending Generation'
--            ELSE 'Not Eligible' END                                       AS voucher_pipeline_status
FROM member_asset_status AS at
         LEFT JOIN customdataset.livelihood_eligibleparticipants AS le ON le.member_id = at.member_id
         LEFT JOIN customdataset.office_project_mapping_hierarchy opmh
                   ON opmh.office_id = le.office_id AND opmh.project_id = le.project_id
         LEFT JOIN c3_enterprise e ON e.id = at.package_id
         JOIN eligible_members AS pgm ON pgm.member_id = at.member_id;
--          JOIN member_asset_status mas ON mas.hhm_id = at.item_id AND mas.fiscal_year_id = at.fiscal_year_id
--          LEFT JOIN existing_voucher_ids ev ON ev.voucher_item_id = at.id
-- ORDER BY voucher_pipeline_status, at.transfer_date DESC;