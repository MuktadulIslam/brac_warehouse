SELECT * FROM session_attendance ORDER BY create_time DESC;
SELECT * FROM customdataset.batchcreationsessionlist ORDER BY create_time DESC;
SELECT * FROM office where name ilike '%Port Loko%';
SELECT o.name, o.id FROM livelihood_batch_creation lbc JOIN office o ON lbc.office_id = o.id GROUP BY o.name, o.id; -- idSL500001
SELECT * FROM livelihood_batch_creation lbc where office_id='idSL500001'; -- idSL500001

SELECT * FROM "user" where username = '3500983';