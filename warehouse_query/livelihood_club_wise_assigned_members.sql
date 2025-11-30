with club_target as (select lct.*
                     from muktadul.livelihood_club_target lct
                     where lct.club_target > 0),
     assigned_members as (select distinct item_id,
                                          unnest(string_to_array(enterprise_assignment_eligible_members, ',')) assigned_member_id
                          from livelihood_assignment)
select ct.*,
       am.assigned_member_id
from club_target ct
         left join assigned_members am on am.item_id = ct.id ORDER BY create_time desc ;

SELECT *
FROM livelihood_club_target;