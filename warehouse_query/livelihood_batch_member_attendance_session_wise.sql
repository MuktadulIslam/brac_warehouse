SELECT * FROM customdataset.c3_livelihood_eligible_participants;
SELECT * FROM session_attendance ORDER BY create_time desc ;


with session_attendance_data as (
select *, unnest(string_to_array(participants,','))   member_id, 'present' attendance, id batch_session_id  from
             session_attendance sa
         )
select * from session_attendance_data;

SELECT id, item_id, batch_participants, create_time FROM livelihood_batch_creation where office_id ='idSL500001';
SELECT name, id, created_by, create_time FROM office where name='Port Loko';


SELECT * FROM custom_dataset;




SELECT data.member_name, data.j26, pg.name group_name
FROM _aim_c3_hhm_information data
JOIN participant_group_member pgm ON pgm.member_id = data.id
JOIN participant_group pg ON pg.id = pgm.group_id
WHERE pg.name = 'AG 3 Walker - 1';