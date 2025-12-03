SELECT e.id  enterprise_id,
       e.enterprise_name,
       e.country_id,
       e.project_id,
       e.fiscal_year_id,
       e.enterprise_distribution_type,
       lo.id livelihood_option_id,
       lo.livelihood_option_name,
       livelihood_option_code
FROM enterprise e
         LEFT JOIN livelihood_option lo ON lo.id = e.enterprise_livelihood_option
