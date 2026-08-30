-- temporary.member_package_change      = non of them got asset
SELECT gmp.id, gmp.member_serial, at.asset FROM group_member_participant gmp
LEFT JOIN asset_transfer at ON at.item_id = gmp.id
WHERE gmp.member_serial IN ('PT00481938', 'PT00479967', 'PT00479987');


-- augustino_william_accumulated_issues_pangani_pongwe_and_korogwe      = all 3 member got asset
SELECT gmp.id,gmp.member_serial, at.asset FROM group_member_participant gmp
LEFT JOIN asset_transfer at ON at.item_id = gmp.id
WHERE gmp.member_serial IN ('PT00473406', 'PT00489924', 'PT00489034');


-- augustino_william_accumulated_issues_lushoto_updated         = one member got asset
SELECT gmp.id, gmp.member_serial, at.asset FROM group_member_participant gmp
LEFT JOIN asset_transfer at ON at.item_id = gmp.id
WHERE gmp.member_serial IN ('PT00473988', 'PT00472912', 'PT00449424', 'PT00443285');






SELECT mpc.participant_id, mpc.member_id, la.item_id, mpc.old_package_id, final_package_id, final_package_id = la.item_id as already_updated FROM temporary.member_package_change_backup mpc
LEFT JOIN livelihood_assignment la ON la.enterprise_assignment_eligible_members ILIKE '%' || mpc.member_id || '%';

SELECT mpc.participant_id, mpc.old_package, e.enterprise_name, mpc.final_package, e2.enterprise_name FROM temporary.member_package_change_backup mpc
LEFT JOIN enterprise e ON e.id = mpc.old_package_id
LEFT JOIN enterprise e2 ON e2.id = mpc.final_package_id;

SELECT * FROM asset_transfer where item_id in ('f68bf819913a47c795e2373235f9b901', '78d91075220b4994b59c535f9892af1a');

SELECT * FROM livelihood_assignment where enterprise_assignment_eligible_members ilike '%93d07cfe463a4749af34f3c7a84270a1%';
SELECT * FROM temporary.member_package_change_with_asset_transfer where member_id = '93d07cfe463a4749af34f3c7a84270a1';
SELECT * FROM livelihood_assignment where item_id = 'c911b5bf-5c57-493e-a16d-89d74e7bc53b' AND club_id='0ea50f8768e8405690486ff4fec51a53';
SELECT * INTO bak.livelihood_assignment_28_07_2026_bracjira_3262_3 FROM livelihood_assignment where id in ('cb922d9906d147afa0b4c6e9f59305e7', '3d686e1c79634c7a8182eb456afdf95a');

SELECT participant_id, member_id, mpc.old_package_id, mpc.final_package_id, e.cost_sharing_amount, e2.cost_sharing_amount FROM temporary.member_package_change_with_asset_transfer mpc
LEFT JOIN enterprise e ON e.id = mpc.old_package_id
LEFT JOIN enterprise e2 ON e2.id = mpc.final_package_id;


-- enterprise_id,                          enterprise_name,                                     enterprise_asset_type,  enterprise_asset_quantity,      asset_id,                               asset_name
-- 21e9ebf6-4343-4395-8d6d-3874e550e18a,   12 A:	Small business with 1 female goat,          First Asset,            1,                              eebad86f-16a5-4684-aa5c-ef7cbcdb0a40,   Small Business
-- 21e9ebf6-4343-4395-8d6d-3874e550e18a,   12 A:	Small business with 1 female goat,          Second Asset,           1,                              67c04d6b-432a-4cd3-b7e6-6917c62158fa,   Goat (Female)
-- c911b5bf-5c57-493e-a16d-89d74e7bc53b,   12 D:	Small business with 10 pullets (3month),    First Asset,            1,                              eebad86f-16a5-4684-aa5c-ef7cbcdb0a40,   Small Business
-- c911b5bf-5c57-493e-a16d-89d74e7bc53b,   12 D:	Small business with 10 pullets (3month),    Second Asset,           10,                             1ec9be7f-f519-4a49-b95e-be9679140431,   Pullets

-- member_id,                           enterprise_id,                          enterprise_name,                            enterprise_asset_type,      asset_name,         asset_id
-- 93d07cfe463a4749af34f3c7a84270a1,    21e9ebf6-4343-4395-8d6d-3874e550e18a,   12 A:	Small business with 1 female goat,  Second Asset,               Goat (Female),      67c04d6b-432a-4cd3-b7e6-6917c62158fa
-- 93d07cfe463a4749af34f3c7a84270a1,    21e9ebf6-4343-4395-8d6d-3874e550e18a,   12 A:	Small business with 1 female goat,  First Asset,                Small Business,     eebad86f-16a5-4684-aa5c-ef7cbcdb0a40


SELECT * FROM asset_transfer where item_id='93d07cfe463a4749af34f3c7a84270a1';
SELECT * INTO bak.asset_transfer_28_07_2026_bracjira_3262 FROM asset_transfer where item_id='93d07cfe463a4749af34f3c7a84270a1';
UPDATE asset_transfer SET
                          last_modified_by = 'stream_fresh',
                          last_modified_time = now()
                          where id in ('72e9b5f735474ac9968e4494da11b551', 'cb2953becee14d06be1a2ad237c207d5');

SELECT * FROM voucher_generation_history where source_type_id='1' AND member_id = '93d07cfe463a4749af34f3c7a84270a1';       -- 97680911
SELECT * FROM voucher_generation_history where source_type_id='2' AND member_id = '93d07cfe463a4749af34f3c7a84270a1';       -- 97680911

-- DELETE FROM voucher_generation_history where source_type_id='1' AND member_id = '93d07cfe463a4749af34f3c7a84270a1';       -- 97680911, 34487253
SELECT * INTO bak.voucher_generation_history_28_07_2026_bracjira_3263 FROM voucher_generation_history where source_type_id='2' AND member_id = '93d07cfe463a4749af34f3c7a84270a1';
INSERT INTO voucher_generation_history
SELECT * FROM bak.voucher_generation_history_28_07_2026_bracjira_3263;
SELECT * FROM grant_recovery_installment where member_id = '93d07cfe463a4749af34f3c7a84270a1';
SELECT * INTO bak.grant_recovery_installment_28_07_2026_bracjira_3262 FROM grant_recovery_installment where member_id = '93d07cfe463a4749af34f3c7a84270a1';
SELECT * FROM grant_recovery_collection where item_id = '93d07cfe463a4749af34f3c7a84270a1';
SELECT * FROM enterprise where id in ('21e9ebf6-4343-4395-8d6d-3874e550e18a', 'c911b5bf-5c57-493e-a16d-89d74e7bc53b');
UPDATE voucher_generation_history SET
--                           last_modified_by = 'stream_fresh',
                          last_modified_time = now(),
                          enterprise_id = 'c911b5bf-5c57-493e-a16d-89d74e7bc53b'
                          where item_id = '56f5aa60-9c20-4f08-9a67-19757e375b5f';

