SELECT ppc.id      as ppc_id,
       ppc.item_id,
       pgm.member_id,
       pgm.member_serial,
       pgm.member_type,
       hhm.member_name,
       hhm.age,
       hhm.gender,
       ppc.country_id,
       ppc.country as country_name,
       ppc.group_id,
       pg.name     as group_name,
       pgt.name    as group_type_id,
       disability_status,
       pg.service_point_id,
       sp.name     as service_point_name,
       ppc.catchment_id,
       cat.name    as catchment_name,
       photo_1,
       ppc.create_time,
       ppc.created_by,
       ppc.reporting_date,
       ppc.last_modified_by,
       ppc.last_modified_time,
       ppc.is_deleted,
       ppc.project_id


FROM lr_c3_participant_photo_collection_for_pid ppc
         LEFT JOIN participant_group_member pgm ON pgm.id = ppc.item_id
         LEFT JOIN house_hold_member hhm ON hhm.id = pgm.member_id
         LEFT JOIN participant_group pg ON pg.id = ppc.group_id
         LEFT JOIN participant_group_type pgt ON pgt.id = pg.participant_group_type_id
         LEFT JOIN service_point sp ON sp.id = pg.service_point_id
         LEFT JOIN catchment cat ON cat.id = ppc.catchment_id