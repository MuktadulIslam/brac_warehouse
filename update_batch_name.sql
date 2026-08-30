SELECT lbc.id, lbc.batch_name, es.name as session_type
FROM livelihood_batch_creation lbc
JOIN event_session es ON es.id = lbc.session
where lbc.id in ('f351aa11cefb4a14a3770f1922bb25c9', '3b60f90b4de14fd0b853dbd223b41b58', '1d0d0e68a494410eba11e9876ce68d11',
             'f1947cbd9d5947e39fe123a6afb70d9a', 'be855f2e665546fd86bef22a799dd02f');

SELECT * INTO bak.livelihood_batch_creation_11_06_2026_Brac_481
FROM livelihood_batch_creation
WHERE id IN ('f351aa11cefb4a14a3770f1922bb25c9', '3b60f90b4de14fd0b853dbd223b41b58', '1d0d0e68a494410eba11e9876ce68d11',
             'f1947cbd9d5947e39fe123a6afb70d9a', 'be855f2e665546fd86bef22a799dd02f');
SELECT * FROM bak.livelihood_batch_creation_11_06_2026_Brac_481;

-- WITH new_names (id, batch_name) AS (
--     VALUES
--         ('f351aa11cefb4a14a3770f1922bb25c9', 'Technical training small business'),
--         ('3b60f90b4de14fd0b853dbd223b41b58', 'Technical training small business'),
--         ('1d0d0e68a494410eba11e9876ce68d11', 'Technical training livestock'),
--         ('f1947cbd9d5947e39fe123a6afb70d9a', 'Entrepreneurship training'),
--         ('be855f2e665546fd86bef22a799dd02f', 'Entrepreneurship training')
-- )
-- UPDATE livelihood_batch_creation lbc
-- SET
--     batch_name         = nn.batch_name,
--     last_modified_time = NOW(),
--     last_modified_by   = 'stream_fresh'
-- FROM new_names nn
-- WHERE lbc.id = nn.id;