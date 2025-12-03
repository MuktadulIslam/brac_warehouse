WITH tvet_enterprise AS (SELECT *
                         FROM enterprise
                         WHERE enterprise_livelihood_option = '432313e2-5df5-465d-acb5-76a5c969bae8')
                        -- 432313e2-5df5-465d-acb5-76a5c969bae8 is the ID of TVER in "livelihood_option" table

SELECT *
-- INTO muktadul.livelihood_tvet_enterprise
FROM tvet_enterprise;