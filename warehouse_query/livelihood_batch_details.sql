WITH batch_enterprice_names AS (SELECT lbc.id,
                                       string_agg(e.enterprise_name, ',') AS enterprise_names
                                FROM livelihood_batch_creation lbc
                                         JOIN LATERAL unnest(string_to_array(lbc.enterprises, ',')) as enterprises(id)
                                              ON true
                                         JOIN enterprise e ON e.id = enterprises.id
                                GROUP BY lbc.id),

     batch_participant_names AS (SELECT lbc.id,
                                        string_agg(pn.member_name, ',') AS participant_names
                                 FROM livelihood_batch_creation lbc
                                          JOIN LATERAL unnest(string_to_array(lbc.batch_participants, ',')) as bp(id)
                                               ON true
                                          JOIN LATERAL (
                                     SELECT member_name
                                     FROM house_hold_member hhm
                                     WHERE id::text = bp.id

                                     UNION

                                     SELECT name as member_name
                                     FROM trainer t
                                     WHERE id::text = bp.id
                                     ) pn ON true
                                 GROUP BY lbc.id),

     livelihood_batch_details AS (SELECT lbc.id,
                                         lbc.item_id,
                                         lbc.batch_name,
                                         lbc.country_id,
                                         c.name                 as country_name,
                                         lbc.project_id,
                                         p.name                 as project_name,
                                         lbc.fiscal_year_id,
                                         fy.name                as fiscal_year,
                                         lbc.office_id          as branch_office_id,
                                         o.name                 as branch_office_name,
                                         lbc.enterprises        as enterprise_ids,
                                         ben.enterprise_names,
                                         lbc.batch_participants as participant_ids,
                                         bpn.participant_names,
                                         lbc.created_by         as created_by_id,
                                         u.name                 as created_by_name,
                                         lbc.session            as event_session_id,
                                         es.name as event_session_name,
                                         lbc.create_time,
                                         lbc.last_sync_time,
                                         lbc.reporting_date,
                                         lbc.created_by,
                                         lbc.last_modified_by,
                                         lbc.answer,
                                         lbc.process_data

                                  FROM livelihood_batch_creation lbc
                                           LEFT JOIN country c ON c.id = lbc.country_id
                                           LEFT JOIN project p ON p.id = lbc.project_id
                                           LEFT JOIN fiscal_year fy ON lbc.fiscal_year_id = fy.id
                                           LEFT JOIN office o ON o.id = lbc.office_id
                                           LEFT JOIN batch_enterprice_names ben ON ben.id = lbc.id
                                           LEFT JOIN batch_participant_names bpn ON bpn.id = lbc.id
                                           LEFT JOIN "user" u ON u.id = lbc.created_by
                                           LEFT JOIN event_session es ON lbc.session = es.id
                                  ORDER BY fy.name DESC, lbc.create_time DESC)

-- SELECT * INTO muktadul.livelihood_batch_details FROM livelihood_batch_details;
SELECT * FROM livelihood_batch_details;