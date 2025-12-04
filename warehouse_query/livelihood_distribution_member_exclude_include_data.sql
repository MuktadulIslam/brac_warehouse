with exclude as (select 'Exclude' as partition_status,
                        id,
                        item_id,
                        last_modified_time,
                        catchment_id,
                        office_id,
                        project_id,
                        fiscal_year_id,
                        remarks
                 from exclusion_form),

     include as (select 'Include' as partition_status,
                        id,
                        item_id,
                        last_modified_time,
                        catchment_id,
                        office_id,
                        project_id,
                        fiscal_year_id,
                        remarks
                 from inclusion_form),
     participant_exclude_include_data as (select *
                                          from exclude
                                          union
                                          select *
                                          from include),
     data as (select ROW_NUMBER() OVER (PARTITION BY item_id
         ORDER BY last_modified_time desc

         ) as row_number,
                     *
              from participant_exclude_include_data)
select *, item_id member_id
-- INTO muktadul.livelihood_distribution_member_exclude_include_data
from data
where row_number = 1 -- without this where condition , you can find history of exclude include