WITH asset_enterprise_data AS (SELECT a.id                       as                                           asset_id,
                                      a.asset_name,
                                      e.id                       as                                           enterprise_id,
                                      e.enterprise_name,
                                      lo.id                      as                                           livelihood_option_id,
                                      lo.livelihood_option_name,
                                      CASE
                                          WHEN
                                              lo.id = '432313e2-5df5-465d-acb5-76a5c969bae8' THEN 'TVET'
                                          ELSE 'Regular'
                                          END                    as                                           regular_or_tvet_transfer,
                                      CASE
                                          WHEN
                                              ea.enterprise_asset_type = '0' THEN 'Main'
                                          ELSE 'Secondary'
                                          END                    as                                           enterprise_asset_type,
                                      ea.enterprise_asset_quantity,
                                      eges.enterprise_group_type as                                           enterprise_group_type_id,
                                      pgt.name                   as                                           enterprise_group_type,
                                      fy.*,
                                      row_number() over (PARTITION BY a.id, e.id, eges.enterprise_group_type) r

                               FROM asset a
                                        LEFT JOIN enterprise_enterprise_assets ea ON a.id = ea.enterprise_asset_name
                                        LEFT JOIN enterprise e ON e.id = ea.master_id
                                        LEFT JOIN livelihood_option lo ON lo.id = e.enterprise_livelihood_option
                                        LEFT JOIN enterprise_group_type_and_economic_status eges ON e.id = eges.master_id
                                        LEFT JOIN participant_group_type pgt ON pgt.id = eges.enterprise_group_type
                                        LEFT JOIN muktadul.dim_fiscal_year fy
                                                  ON fy.country_id = e.country_id AND
                                                     fy.project_id = e.project_id AND
                                                     fy.fiscal_year_id = e.fiscal_year_id


                               WHERE a.asset_name IS NOT NULL),

     asset_enterprise_data_with_non_duplicate AS (SELECT asset_id,
                                                         asset_name,
                                                         enterprise_id,
                                                         enterprise_name,
                                                         livelihood_option_id,
                                                         livelihood_option_name,
                                                         regular_or_tvet_transfer,
                                                         enterprise_asset_type,
                                                         enterprise_asset_quantity,
                                                         enterprise_group_type_id,
                                                         enterprise_group_type,
                                                         project_id,
                                                         project_name,
                                                         country_id,
                                                         country,
                                                         fiscal_year_id,
                                                         fiscal_year_name
                                                  FROM asset_enterprise_data
                                                  WHERE r = 1)
SELECT *
-- INTO muktadul.asset_enterprise_data
FROM asset_enterprise_data_with_non_duplicate;