SELECT * FROM customdataset.c3_livelihood_eligible_participants;
SELECT * FROM session_attendance ORDER BY create_time desc ;


with session_attendance_data as (
select *, unnest(string_to_array(participants,','))   member_id, 'present' attendance, id batch_session_id  from
             session_attendance sa
         )
select * from session_attendance_data;

SELECT id, item_id, batch_participants, create_time FROM livelihood_batch_creation where office_id ='idSL500001';
SELECT name, id, created_by, create_time FROM office where name='Port Loko';