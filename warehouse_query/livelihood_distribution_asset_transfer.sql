WITH distribution_asset_transfer_data AS (SELECT item_id as                    member_id,
                                                 country_id,
                                                 project_id,
                                                 fiscal_year_id,
                                                 office_id,
                                                 enterprise,
                                                 asset,
                                                 distribution_type,
                                                 sum(coalesce(number_of_asset,0))          asset_given,
                                                 sum(coalesce(number_of_asset_replaced,0)) asset_replaced
                                          FROM asset_transfer
                                          GROUP BY item_id, country_id, project_id, fiscal_year_id, office_id,
                                                   enterprise, asset, distribution_type),

     distribution_asset_transfer_data_wid_details AS (SELECT datd.member_id,
                                                             hhm.member_name,
                                                             hhm.age,
                                                             hhm.gender,
                                                             hhm.house_hold_id,
                                                             hhm.catchment_id,
                                                             ct.name         as catchment_name,
                                                             datd.office_id,
                                                             o.name          as office_name,
                                                             datd.country_id,
                                                             c.name          as country_name,
                                                             datd.fiscal_year_id,
                                                             fy.name         as fiscal_year,
                                                             datd.enterprise as enterprise_id,
                                                             e.enterprise_name,
                                                             datd.asset      as asset_id,
                                                             a.asset_name,
                                                             datd.distribution_type,
                                                             datd.asset_given,
                                                             datd.asset_replaced

                                                      FROM distribution_asset_transfer_data datd
                                                               JOIN house_hold_member hhm ON hhm.id = datd.member_id
                                                               LEFT JOIN catchment ct ON ct.id = hhm.catchment_id
                                                               LEFT JOIN office o ON o.id = datd.office_id
                                                               LEFT JOIN country c ON c.id = datd.country_id
                                                               LEFT JOIN fiscal_year fy ON fy.id = datd.fiscal_year_id
                                                               LEFT JOIN enterprise e ON e.id = datd.enterprise
                                                               LEFT JOIN asset a ON a.id = datd.asset)

SELECT *
-- INTO muktadul.livelihood_distribution_asset_transfer
FROM distribution_asset_transfer_data_wid_details;