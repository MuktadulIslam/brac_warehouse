WITH duplicate_member AS (SELECT item_id, count(1) duplicate_count FROM aim_c4_enrollment group by item_id having count(1)>1)

SELECT dm.item_id as member_id,
       gmp.member_serial as participant_id,
       ac4e.id as enrollment_survey_id,
       dm.duplicate_count,
       hhm.member_name,
       hhm.j2a_member_first_name as first_name,
       hhm.j2a_member_last_name as last_name,
       hhm.age,
       hh.house_hold_serial_number,
       ac4e.office_id as branch_office_id,
       o.name as branch_office_name,
       ac4e.country_id,
       c.name as country_name,
       ac4e.c3a_first_name as "C3a: First Name of the participant",
       ac4e.c3b_second_name as "C3b: Second Name of the participant",
       ac4e.c4b_age_group as "C4b: AIM Age Group",
       'Delete this record / Keep this record' as remarks


       FROM duplicate_member dm
JOIN aim_c4_enrollment ac4e ON dm.item_id = ac4e.item_id
JOIN group_member_participant gmp ON gmp.id = dm.item_id
JOIN aim_c4_hhm_survey hhm ON hhm.id = dm.item_id
JOIN house_hold_member hhm2 ON hhm.id = hhm2.id
JOIN house_hold hh ON hhm2.house_hold_id = hh.id
JOIN office o ON o.id = ac4e.office_id
JOIN country c ON c.id = ac4e.country_id