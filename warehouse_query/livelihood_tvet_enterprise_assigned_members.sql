select lcam.*
--into dm_schema.livelihood_tvet_assigned_members
from
muktadul.livelihood_club_wise_assigned_members  lcam
--  {{ ref('livelihood_club_wise_assigned_members') }}  lcam
join muktadul.livelihood_tvet_enterprise te
-- join {{ ref('livelihood_tvet_enterprise') }} te
on lcam.package_id = te.id;
