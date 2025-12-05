select p.id    project_id,
       p.name  project_name,
       c.id    country_id,
       c.name  country,
       fy.id   fiscal_year_id,
       fy.name fiscal_year_name
-- INTO muktadul.dim_fiscal_year
from project p
         left join fiscal_year fy on p.id = fy.project_id
         left join country c on p.country_id = c.id and fy.country_id = c.id