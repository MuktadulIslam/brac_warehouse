WITH batch_and_session AS (SELECT b.id    batch_id,
                                  b.batch_name,
                                  s.id    session_id,
                                  s.training_name,
                                  s.date  training_date,
                                  CASE
                                      WHEN s.status IS NOT NULL THEN s.status
                                      ELSE 'not submitted'
                                      END status
                           FROM livelihood_batch_creation b
                                    JOIN session_attendance s ON b.id = s.batch
                           GROUP BY 1, 2, 3, 4, 5, 6)
SELECT *
-- INTO muktadul.livelihood_batch_wise_session
FROM batch_and_session;