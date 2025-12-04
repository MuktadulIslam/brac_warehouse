WITH livelihood_distribution_eligible_participants AS (SELECT member_id, final_eligible_status
                                                       FROM muktadul.livelihood_regular_distribution_eligible_participants reg
                                                       UNION
                                                       SELECT assigned_member_id AS member_id, 'Include' final_eligible_status
                                                       FROM muktadul.livelihood_tvet_assigned_members
                                                       WHERE assigned_member_id IS NOT NULL)

SELECT *
INTO muktadul.livelihood_distribution_eligible_participants
FROM livelihood_distribution_eligible_participants;