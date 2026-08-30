-------------------------------------******** Preview ********-------------------------------------
WITH to_remove AS (SELECT la.id, array_agg(DISTINCT a.member_id::text) AS remove_ids
                   FROM temporary.package_removal_data a
                            JOIN livelihood_assignment la
                                 ON a.member_id::text = ANY
                                    (string_to_array(la.enterprise_assignment_eligible_members, ','))
                   WHERE a.new_package_id <> la.item_id
                   GROUP BY la.id)
SELECT la.id,
       la.enterprise_assignment_eligible_members AS before_members,
       array_to_string(ARRAY(
                               SELECT elem
                               FROM unnest(string_to_array(la.enterprise_assignment_eligible_members, ',')) WITH ORDINALITY AS u(elem, ord)
                               WHERE elem <> ALL (tr.remove_ids)
                               ORDER BY ord
                       ), ',')                   AS after_members,
       tr.remove_ids
FROM livelihood_assignment la
         JOIN to_remove tr ON tr.id = la.id;

SELECT * FROM livelihood_assignment where id in ('16563e94e9b645d7b319712b8d9414c8', '1446c86acf364f47b17441f5b6a4a377', '19321add254d477086648f1aa9801af7');


-------------------------------------******** Back-Up ********-------------------------------------
-- INSERT INTO bak.livelihood_assignment_29_07_2026_BRACJira_3113
WITH to_remove AS (SELECT la.id, array_agg(DISTINCT a.member_id::text) AS remove_ids
                   FROM temporary.package_removal_data a
                            JOIN livelihood_assignment la
                                 ON a.member_id::text = ANY
                                    (string_to_array(la.enterprise_assignment_eligible_members, ','))
                   WHERE a.new_package_id <> la.item_id
                   GROUP BY la.id)
SELECT la.*
INTO bak.livelihood_assignment_31_07_2026_BRACJira_2514
FROM livelihood_assignment la
         JOIN to_remove tr ON tr.id = la.id;


-------------------------------------******** Update/Delete ********-------------------------------------
WITH to_remove AS (SELECT la.id,
                          array_agg(DISTINCT a.member_id::text) AS remove_ids
                   FROM temporary.package_removal_data a
                            JOIN livelihood_assignment la
                                 ON a.member_id::text = ANY
                                    (string_to_array(la.enterprise_assignment_eligible_members, ','))
                   WHERE a.new_package_id <> la.item_id
                   GROUP BY la.id),
     recomputed AS (SELECT la.id,
                           (SELECT array_agg(elem ORDER BY ord)
                            FROM unnest(string_to_array(la.enterprise_assignment_eligible_members, ','))
                                     WITH ORDINALITY AS u(elem, ord)
                            WHERE elem <> ALL (tr.remove_ids)) AS remaining
                    FROM livelihood_assignment la
                             JOIN to_remove tr ON tr.id = la.id),
     del AS (
         -- Row would be left empty (single value == member_id, or all members flagged) -> delete
         DELETE FROM livelihood_assignment la
             USING recomputed r
             WHERE la.id = r.id
                 AND (r.remaining IS NULL OR cardinality(r.remaining) = 0)
             RETURNING la.id)

UPDATE livelihood_assignment la
SET enterprise_assignment_eligible_members = array_to_string(r.remaining, ','),
    answer                                 = jsonb_set(
            la.answer::jsonb,
            '{enterprise_assignment_eligible_members}',
            to_jsonb(array_to_string(r.remaining, ','))
                                             ), -- append ::text or ::json if `answer` is not a jsonb column
    last_modified_time                     = now(),
    last_modified_by                       = 'stream_fresh'
FROM recomputed r
WHERE la.id = r.id
  AND r.remaining IS NOT NULL
  AND cardinality(r.remaining) > 0;

