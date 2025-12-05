WITH livelihood_member_wise_asset_distribution as (SELECT ct.country_id,
                                                          ct.project_id,
                                                          ct.fiscal_year_id,
                                                          ct.office_id,
                                                          ct.member_id,
                                                          ct.package_id as             enterprise_id,
                                                          ae.enterprise_name,
                                                          ae.asset_id,
                                                          ae.asset_name,
                                                          ae.enterprise_group_type_id,
                                                          ae.enterprise_asset_type,
                                                          ae.regular_or_tvet_transfer,
                                                          da.distribution_type,
                                                          da.asset_given,
                                                          da.asset_replaced,
                                                          ae.enterprise_asset_quantity asset_quantity,
                                                          case
                                                              when
                                                                  da.asset_given is null
                                                                  then ae.enterprise_asset_quantity
                                                              else (ae.enterprise_asset_quantity - da.asset_given::int)
                                                              end                      asset_remain

                                                   from muktadul.livelihood_club_wise_assigned_members ct
                                                            join muktadul.asset_enterprise_data ae
                                                                 on ct.package_id = ae.enterprise_id
                                                            left join muktadul.livelihood_distribution_asset_transfer da
                                                                      on da.member_id = ct.member_id
                                                                          and da.enterprise_id = ae.enterprise_id
                                                                          and da.asset_id = ae.asset_id
                                                   )
SELECT *
FROM livelihood_member_wise_asset_distribution; -- 60685    353735