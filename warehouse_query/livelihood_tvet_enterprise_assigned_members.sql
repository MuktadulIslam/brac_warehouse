SELECT lcam.*
-- INTO muktadul.livelihood_tvet_assigned_members
FROM muktadul.livelihood_club_wise_assigned_members lcam
         JOIN muktadul.livelihood_tvet_enterprise te
              ON lcam.package_id = te.id;