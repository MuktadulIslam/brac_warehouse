SELECT s.id,
       s.item_id,
       s.catchment_id,
       s.country_id,
       s.project_id,
       s.fiscal_year_id,
       s.office_id,
       s.create_time,
       s.last_modified_time,
       s.created_by,
       s.last_modified_by,
       s.process_data,
       a.approval_status,
       a._3955                                                                              AS code,
       a.community_village_of_school,
       a.district_name_of_school,
       a.doc_upload,
       a._3956                                                                              AS formation_date,
       a._3957                                                                              AS gps_location,
       a._3951                                                                              AS name,
       a.name_of_the_school,
       a.ownership_type_of_the_school,
       CASE
           WHEN a.ownership_type_of_the_school = '4' THEN 'Community owned school'
           WHEN a.ownership_type_of_the_school = '3' THEN 'Private School'
           WHEN a.ownership_type_of_the_school = '2'
               THEN 'Semi-government school (Government-Aided Private School)'
           WHEN a.ownership_type_of_the_school = '1' THEN 'Public (Government) School'
           WHEN a.ownership_type_of_the_school = '5' THEN 'School supported by a non profit organization'
           END                                                                              AS ownership_type_of_the_school_text,
       a.plead_formation_date,
       a.plead_pa_pin,
       a.plead_pin,
       a.region_province_county_name_of_school,
       a._3958                                                                              AS service_point_type_id,
       a.sp_a_fee_status_of_srhr_and_gbv,
       CASE
           WHEN a.sp_a_fee_status_of_srhr_and_gbv = '0' THEN 'No'
           WHEN a.sp_a_fee_status_of_srhr_and_gbv = '1' THEN 'Yes'
           END                                                                              AS sp_a_fee_status_of_srhr_and_gbv_text,
       a.sp_availavble_kits,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Post-Exposure Prophylaxis (PEP)'
                           WHEN '2' THEN 'Emergency contraception'
                           WHEN '3' THEN 'STI medicines'
                           WHEN '4' THEN 'Hepatitis B vaccination'
                           WHEN '5' THEN 'Tetanus vaccination'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_availavble_kits, ',') AS value)                     AS sp_availavble_kits_text,
       a.sp_b_age_groups__activities_serve,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Children'
                           WHEN '2' THEN 'Young adolescents (10-14)'
                           WHEN '3' THEN 'Older adolescents (15-18)'
                           WHEN '4' THEN 'Adult women (18+)'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_b_age_groups__activities_serve, ',') AS value)      AS sp_b_age_groups__activities_serve_text,
       a.sp_b_community_based_gvb_support,
       CASE
           WHEN a.sp_b_community_based_gvb_support = '1' THEN 'Yes'
           WHEN a.sp_b_community_based_gvb_support = '0' THEN 'No'
           END                                                                              AS sp_b_community_based_gvb_support_text,
       a.sp_b_have_safe_space_to_receive_survivors,
       CASE
           WHEN a.sp_b_have_safe_space_to_receive_survivors = '0' THEN 'No'
           WHEN a.sp_b_have_safe_space_to_receive_survivors = '1' THEN 'Yes'
           END                                                                              AS sp_b_have_safe_space_to_receive_survivors_text,
       a.sp_b_is_fee_required,
       CASE
           WHEN a.sp_b_is_fee_required = '0' THEN 'No'
           WHEN a.sp_b_is_fee_required = '1' THEN 'Yes'
           END                                                                              AS sp_b_is_fee_required_text,
       a.sp_b_psychosocial_services_provided_by,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Trained psychologists/ Therapists'
                           WHEN '2' THEN 'Partners (NGO, CBO, etc.)'
                           WHEN '3' THEN 'Staff of your organization'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_b_psychosocial_services_provided_by, ',') AS value) AS sp_b_psychosocial_services_provided_by_text,
       a.sp_b_type_of_service,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Basic emotional support/ Psychological First Aid'
                           WHEN '2' THEN 'Case management / psychosocial support'
                           WHEN '3' THEN 'Group activities'
                           WHEN '99' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_b_type_of_service, ',') AS value)                   AS sp_b_type_of_service_text,
       a.sp_b_type_of_service_others,
       a.sp_c_1_others,
       a.sp_c_fee_for_purpose,
       a.sp_c_fee_status_of_safety_and_protection,
       CASE
           WHEN a.sp_c_fee_status_of_safety_and_protection = '0' THEN 'No'
           WHEN a.sp_c_fee_status_of_safety_and_protection = '1' THEN 'Yes'
           END                                                                              AS sp_c_fee_status_of_safety_and_protection_text,
       a.sp_contact_number,
       a.sp_contact_number_of_the_focal_persion,
       a.sp_c_services_provide,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Safety and security planning for survivors'
                           WHEN '2' THEN 'Safe houses/ Shelter'
                           WHEN '3' THEN 'Patrols'
                           WHEN '4' THEN 'Others'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_c_services_provide, ',') AS value)                  AS sp_c_services_provide_text,
       a.sp_c_specific_age_groups,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Children'
                           WHEN '2' THEN 'Young adolescents (10-14)'
                           WHEN '3' THEN 'Older adolescents (15-18)'
                           WHEN '4' THEN 'Adult women (18+)'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_c_specific_age_groups, ',') AS value)               AS sp_c_specific_age_groups_text,
       a.sp_c_total_fee,
       a.sp_d_1,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Legal awareness and sensitization'
                           WHEN '2' THEN 'Legal counseling services'
                           WHEN '3' THEN 'Legal representation services'
                           WHEN '4' THEN 'Alternative Dispute Resolution'
                           WHEN '5' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_d_1, ',') AS value)                                 AS sp_d_1_text,
       a.sp_d_2_others,
       a.sp_d_disability_support,
       CASE
           WHEN a.sp_d_disability_support = '1' THEN 'Yes'
           WHEN a.sp_d_disability_support = '0' THEN 'No'
           END                                                                              AS sp_d_disability_support_text,
       a.sp_d_disability_support_services,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Ramps for physical accessibility'
                           WHEN '2' THEN 'Psychosocial support services'
                           WHEN '3' THEN 'Assistive technology devices'
                           WHEN '4' THEN 'Occupational Therapy'
                           WHEN '5' THEN 'Speech Therapy'
                           WHEN '6' THEN 'Physical Therapy'
                           WHEN '7' THEN 'Case Management/ Counselling Service'
                           WHEN '8' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_d_disability_support_services, ',') AS value)       AS sp_d_disability_support_services_text,
       a.sp_d_fee,
       a.sp_d_is_free_service,
       CASE
           WHEN a.sp_d_is_free_service = '0' THEN 'No'
           WHEN a.sp_d_is_free_service = '1' THEN 'Yes'
           END                                                                              AS sp_d_is_free_service_text,
       a.sp_d_paid_services,
       a.sp_d_provides_gbv_legal_support,
       CASE
           WHEN a.sp_d_provides_gbv_legal_support = '1' THEN 'Yes'
           WHEN a.sp_d_provides_gbv_legal_support = '0' THEN 'No'
           END                                                                              AS sp_d_provides_gbv_legal_support_text,
       a.sp_e_1_others,
       a.sp_e_disability_support,
       CASE
           WHEN a.sp_e_disability_support = '0' THEN 'No'
           WHEN a.sp_e_disability_support = '1' THEN 'Yes'
           END                                                                              AS sp_e_disability_support_text,
       a.sp_e_disability_support_services,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Assistive devices for vision impairment (e.g., eyeglasses, white cane, etc.)'
                           WHEN '2' THEN 'Hearing impairment devices'
                           WHEN '3'
                               THEN 'Mobility appliance distribution (e.g., artificial limbs, wheelchairs, crutches, etc.)'
                           WHEN '4'
                               THEN 'Special education support (e.g., braille-based, sign language based, intellectual disability support education)'
                           WHEN '5' THEN 'Teaching sign language'
                           WHEN '6'
                               THEN 'Rehabilitation services (e.g., physiotherapy, occupational therapy, speech therapy)'
                           WHEN '7' THEN 'Livelihood support (cash, in-kind and training)'
                           WHEN '8' THEN 'Psychosocial Support Services'
                           WHEN '9' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_e_disability_support_services, ',') AS value)       AS sp_e_disability_support_services_text,
       a.sp_e_is_fee_requir,
       CASE
           WHEN a.sp_e_is_fee_requir = '1' THEN 'Yes'
           WHEN a.sp_e_is_fee_requir = '0' THEN 'No'
           END                                                                              AS sp_e_is_fee_requir_text,
       a.sp_email,
       a.sp_f_1,
       CASE
           WHEN a.sp_f_1 = '0' THEN 'No'
           WHEN a.sp_f_1 = '1' THEN 'Yes'
           END                                                                              AS sp_f_1_text,
       a.sp_f_2,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Sexual and Reproductive Health'
                           WHEN '2' THEN 'Gender Based Violence Prevention'
                           WHEN '3' THEN 'Education'
                           WHEN '4' THEN 'Financial Inclusion'
                           WHEN '5' THEN 'Market Access'
                           WHEN '6' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_f_2, ',') AS value)                                 AS sp_f_2_text,
       a.sp_f_2_othars,
       a.sp_f_3,
       a.sp_family_planning_methods,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Family planning awareness and sensitization'
                           WHEN '2' THEN 'Birth control methods/kits distribution'
                           WHEN '3' THEN 'Male condoms'
                           WHEN '4' THEN 'Female condom'
                           WHEN '5' THEN 'Oral contraceptive pills'
                           WHEN '6' THEN 'Emergency Contraceptive Pills (ECP)'
                           WHEN '7' THEN 'Injections (i.e. Sayana press)'
                           WHEN '8' THEN 'Implant (i.e. Jadelle)'
                           WHEN '9' THEN 'IUD (hormonal, copper)'
                           WHEN '10' THEN 'Tubectomy/ Tubal ligation'
                           WHEN '11' THEN 'Vasectomy'
                           WHEN '12' THEN 'Others'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_family_planning_methods, ',') AS value)             AS sp_family_planning_methods_text,
       a.sp_family_planning_methods_others,
       a.sp_focal_person,
       a.sp_focal_person_phone,
       a.sp_g_1,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Training on Crop and Livestock'
                           WHEN '2' THEN 'Technical Services (treatment of crops and livestock)'
                           WHEN '3' THEN 'Deworming and Vaccination of animals'
                           WHEN '4' THEN 'Safe/distribute the agro-inputs (feed, seed, and medicine)'
                           WHEN '5' THEN 'Visit the household and farm, and provide technical assistance'
                           WHEN '6' THEN 'Support for organizing the farmers group meeting'
                           WHEN '7' THEN 'Seed Distribution Support'
                           WHEN '8' THEN 'Fertilizer support'
                           WHEN '9' THEN 'Market Linkage and Value Chain Development'
                           WHEN '10' THEN 'Liaison with government extension workers'
                           WHEN '11' THEN 'Crop Storage Support'
                           WHEN '12' THEN 'Agro-Food Processing'
                           WHEN '13' THEN 'Agricultural Credit/ Loan'
                           WHEN '14' THEN 'Crop and livestock Insurance'
                           WHEN '15' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_g_1, ',') AS value)                                 AS sp_g_1_text,
       a.sp_g_1_others,
       a.sp_g_2,
       CASE
           WHEN a.sp_g_2 = '0' THEN 'No'
           WHEN a.sp_g_2 = '1' THEN 'Yes'
           END                                                                              AS sp_g_2_text,
       a.sp_h_1,
       CASE
           WHEN a.sp_h_1 = '1' THEN 'Yes'
           WHEN a.sp_h_1 = '0' THEN 'No'
           END                                                                              AS sp_h_1_text,
       a.sp_h__1,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'ECD (i.e., kindergarten, preschool, community-based ECD, daycare, etc.)'
                           WHEN '2' THEN 'Tertiary/University level'
                           WHEN '3' THEN 'Digital Delivery of Education'
                           WHEN '4' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_h__1, ',') AS value)                                AS sp_h__1_text,
       a.sp_h__10,
       CASE
           WHEN a.sp_h__10 = '0' THEN 'No'
           WHEN a.sp_h__10 = '1' THEN 'Yes'
           END                                                                              AS sp_h__10_text,
       a.sp_h__10_1,
       a.sp_h__10_2,
       a.sp_h__11,
       CASE
           WHEN a.sp_h__11 = '1' THEN 'Yes'
           WHEN a.sp_h__11 = '0' THEN 'No'
           END                                                                              AS sp_h__11_text,
       a.sp_h__11_1,
       a.sp_h__1_others,
       a.sp_h_2,
       CASE
           WHEN a.sp_h_2 = '0' THEN 'No'
           WHEN a.sp_h_2 = '1' THEN 'Yes'
           END                                                                              AS sp_h_2_text,
       a.sp_h__2,
       CASE
           WHEN a.sp_h__2 = '1' THEN 'Yes'
           WHEN a.sp_h__2 = '0' THEN 'No'
           END                                                                              AS sp_h__2_text,
       a.sp_h__2_1,
       a.sp_h_3,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'ECD (i.e., kindergarten, preschool, community-based ECD, daycare, etc.)'
                           WHEN '2'
                               THEN 'Alternative Education (AE) for out-of-school adolescents, i.e., Accelerated learning, Remedial Education, Bridging Classes (specify the name of AE they offer) at primary or secondary equivalents'
                           WHEN '3' THEN 'Adult Education (If selected, provide age group and type of service offered)'
                           WHEN '4'
                               THEN 'Life Skills training (If selected, provide information on the service included?)'
                           WHEN '5'
                               THEN 'Vocational/Technical Level (If selected, provide the type of vocational/technical package)?'
                           WHEN '6' THEN 'Tertiary/University level'
                           WHEN '7'
                               THEN 'Providing Scholastic material (If selected, provide information on what is included in this package)'
                           WHEN '8' THEN 'Education stipends (If selected, provide information on the type of stipends)'
                           WHEN '9'
                               THEN 'Scholarships (If selected, provide information on what is included under this package)'
                           WHEN '10' THEN 'Digital Literacy (If selected, what kind of digital tool is used?)'
                           WHEN '11' THEN 'Digital Delivery of Education'
                           WHEN '12' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_h_3, ',') AS value)                                 AS sp_h_3_text,
       a.sp_h__3,
       CASE
           WHEN a.sp_h__3 = '1' THEN 'Yes'
           WHEN a.sp_h__3 = '0' THEN 'No'
           END                                                                              AS sp_h__3_text,
       a.sp_h__3_1,
       a.sp_h_3_others,
       a.sp_h_4,
       CASE
           WHEN a.sp_h_4 = '0' THEN 'No'
           WHEN a.sp_h_4 = '1' THEN 'Yes'
           END                                                                              AS sp_h_4_text,
       a.sp_h__4,
       CASE
           WHEN a.sp_h__4 = '0' THEN 'No'
           WHEN a.sp_h__4 = '1' THEN 'Yes'
           END                                                                              AS sp_h__4_text,
       a.sp_h__4_1,
       a.sp_h_5,
       CASE
           WHEN a.sp_h_5 = '0' THEN 'No'
           WHEN a.sp_h_5 = '1' THEN 'yes'
           END                                                                              AS sp_h_5_text,
       a.sp_h__5,
       CASE
           WHEN a.sp_h__5 = '0' THEN 'No'
           WHEN a.sp_h__5 = '1' THEN 'Yes'
           END                                                                              AS sp_h__5_text,
       a.sp_h__5_1,
       a.sp_h__6,
       CASE
           WHEN a.sp_h__6 = '1' THEN 'Yes'
           WHEN a.sp_h__6 = '0' THEN 'No'
           END                                                                              AS sp_h__6_text,
       a.sp_h__6_1,
       a.sp_h__7,
       CASE
           WHEN a.sp_h__7 = '0' THEN 'No'
           WHEN a.sp_h__7 = '1' THEN 'Yes'
           END                                                                              AS sp_h__7_text,
       a.sp_h__7_1,
       a.sp_h__8,
       CASE
           WHEN a.sp_h__8 = '0' THEN 'No'
           WHEN a.sp_h__8 = '1' THEN 'Yes'
           END                                                                              AS sp_h__8_text,
       a.sp_h__8_1,
       a.sp_h__9,
       CASE
           WHEN a.sp_h__9 = '1' THEN 'Yes'
           WHEN a.sp_h__9 = '0' THEN 'No'
           END                                                                              AS sp_h__9_text,
       a.sp_h__9_1,
       a.sp_have_gbv_focal_points,
       CASE
           WHEN a.sp_have_gbv_focal_points = '1' THEN 'Yes'
           WHEN a.sp_have_gbv_focal_points = '0' THEN 'No'
           END                                                                              AS sp_have_gbv_focal_points_text,
       a.sp_have_post_rape_kits,
       CASE
           WHEN a.sp_have_post_rape_kits = '0' THEN 'No'
           WHEN a.sp_have_post_rape_kits = '1' THEN 'Yes'
           END                                                                              AS sp_have_post_rape_kits_text,
       a.sp_have_space_to_receive_survivors,
       CASE
           WHEN a.sp_have_space_to_receive_survivors = '1' THEN 'Yes'
           WHEN a.sp_have_space_to_receive_survivors = '0' THEN 'No'
           END                                                                              AS sp_have_space_to_receive_survivors_text,
       a.sp_medical_personnel,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Nurses'
                           WHEN '2' THEN 'Doctors'
                           WHEN '3' THEN 'Midwives'
                           WHEN '4' THEN 'Gynaecologists'
                           WHEN '5' THEN 'Surgeons'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_medical_personnel, ',') AS value)                   AS sp_medical_personnel_text,
       a.sp_medical_personnel_received_training,
       CASE
           WHEN a.sp_medical_personnel_received_training = '1' THEN 'Yes'
           WHEN a.sp_medical_personnel_received_training = '0' THEN 'No'
           END                                                                              AS sp_medical_personnel_received_training_text,
       a.sp_name,
       a.sp_name_of_the_ocula_person,
       a.sp_provision_for_child_survivors,
       CASE
           WHEN a.sp_provision_for_child_survivors = '0' THEN 'No'
           WHEN a.sp_provision_for_child_survivors = '1' THEN 'Yes'
           END                                                                              AS sp_provision_for_child_survivors_text,
       a.sp_srhr_other_services,
       a.sp_support_type,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'Sexual and Reproductive Health and GBV Services'
                           WHEN '2' THEN 'Psychosocial Support / Case Management'
                           WHEN '3' THEN 'Legal Assistance Service'
                           WHEN '4' THEN 'Safety and Protection Services'
                           WHEN '5' THEN 'Disability Support Services'
                           WHEN '6' THEN 'Advocacy for AGYW Social and Economic rights'
                           WHEN '7' THEN 'Agricultural Extension'
                           WHEN '8' THEN 'Education'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_support_type, ',') AS value)                        AS sp_support_type_text,
       a.sp_which_srhr_services_you_offer,
       (SELECT string_agg(
                       CASE value
                           WHEN '1' THEN 'SRHR sensitization and awareness'
                           WHEN '2' THEN 'Menstrual hygiene awareness and kit distribution'
                           WHEN '3' THEN 'STI sensitization'
                           WHEN '4' THEN 'STI test (including HIV)'
                           WHEN '5' THEN 'Medical services for STIs'
                           WHEN '6' THEN 'ART services'
                           WHEN '7' THEN 'Family planning advice'
                           WHEN '8' THEN 'Birth control methods/kits distribution'
                           WHEN '9' THEN 'ANC services'
                           WHEN '10' THEN 'PNC services'
                           WHEN '11' THEN 'Vaccination (HPV, MMR, Td/Tdap etc.)'
                           WHEN '12' THEN 'Other'
                           END, ', ')
        FROM regexp_split_to_table(a.sp_which_srhr_services_you_offer, ',') AS value)       AS sp_which_srhr_services_you_offer_text,
       a.type_of_school_based_on_highest_levels_of_education_offered,
       CASE
           WHEN a.type_of_school_based_on_highest_levels_of_education_offered = '1' THEN 'Primary'
           WHEN a.type_of_school_based_on_highest_levels_of_education_offered = '2' THEN 'Lower secondary'
           WHEN a.type_of_school_based_on_highest_levels_of_education_offered = '3' THEN 'Upper secondary'
           WHEN a.type_of_school_based_on_highest_levels_of_education_offered = '4'
               THEN 'Combined (Primary + secondary)'
           END                                                                              AS type_of_school_based_on_highest_levels_of_education_offered_text
FROM (SELECT id,
             name,
             code,
             service_point_type_id,
             NULL AS latitude,                            -- Missing in service_point_office_level
             NULL AS longitude,                           -- Missing in service_point_office_level
             NULL AS catchment_ids,                       -- Missing in service_point_office_level
             NULL AS catchment_coverage,                  -- Missing in service_point_office_level
             catchment_id,
             NULL AS location_ids,                        -- Missing in service_point_office_level
             answer,
             NULL AS serial,                              -- Missing in service_point_office_level
             NULL AS unique_id,                           -- Missing in service_point_office_level
             NULL AS assigned_staff_id,                   -- Missing in service_point_office_level
             formation_date,
             NULL AS image_name,                          -- Missing in service_point_office_level
             create_time,
             last_modified_time,
             is_deleted,
             created_by,
             last_modified_by,
             country_id,
             project_id,
             fiscal_year_id,
             NULL AS club_additional_data,                -- Missing in service_point_office_level
             gps_location,
             item_id,
             operational_period_id,
             office_id,
             reporting_date,
             plead_pa_pin,
             plead_pin,
             plead_formation_date,
             process_data,
             sp_name,
             sp_focal_person,
             sp_contact_number,
             sp_focal_person_phone,
             NULL AS upload_mou,                          -- Missing in service_point_office_level
             approval_status,
             last_sync_time,
             doc_upload,
             sp_contact_number_of_the_focal_persion,
             sp_availavble_kits,
             sp_b_type_of_service,
             sp_b_type_of_service_others,
             sp_b_have_safe_space_to_receive_survivors,
             sp_b_age_groups__activities_serve,
             sp_b_psychosocial_services_provided_by,
             sp_c_services_provide,
             sp_c_1_others,
             sp_c_specific_age_groups,
             sp_d_1,
             sp_d_2_others,
             sp_d_disability_support,
             sp_d_disability_support_services,
             sp_d_is_free_service,
             sp_e_1_others,
             sp_e_disability_support,
             sp_email,
             sp_family_planning_methods,
             sp_family_planning_methods_others,
             sp_e_disability_support_services,
             sp_f_1,
             sp_f_2,
             sp_f_2_othars,
             sp_f_3,
             sp_g_1,
             sp_g_1_others,
             sp_g_2,
             sp_h__1,
             sp_h__1_others,
             sp_h__2,
             sp_h__2_1,
             sp_h__10,
             sp_h__10_1,
             sp_h__10_2,
             sp_h__11,
             sp_h__11_1,
             sp_medical_personnel,
             sp_have_gbv_focal_points,
             sp_name_of_the_ocula_person,
             sp_medical_personnel_received_training,
             sp_have_post_rape_kits,
             sp_have_space_to_receive_survivors,
             sp_h_1,
             sp_h_2,
             sp_h_3,
             sp_h_3_others,
             sp_h_4,
             sp_h_5,
             sp_h__3,
             sp_h__3_1,
             sp_h__4,
             sp_h__4_1,
             sp_h__5,
             sp_h__5_1,
             sp_h__6,
             sp_h__6_1,
             sp_h__7,
             sp_h__7_1,
             sp_h__8,
             sp_h__8_1,
             sp_h__9,
             sp_h__9_1,
             sp_support_type,
             sp_provision_for_child_survivors,
             sp_which_srhr_services_you_offer,
             sp_srhr_other_services,
             modified_version,
             submission_status,
             version,
             meta_data,
             survey_meta_data,
             NULL AS sp_b_is_there_community_based_group, -- Missing in service_point_office_level
             NULL AS sp_d_1_provide_legal_support_or_not, -- Missing in service_point_office_level
             NULL AS sp_b_community_based_group_name,     -- Missing in service_point_office_level
             NULL AS sp_d_4_how_much_do_you_charge,       -- Missing in service_point_office_level
             NULL AS sp_c_is_your_office_requir_payment,  -- Missing in service_point_office_level
             NULL AS sp_c_how_much_for,                   -- Missing in service_point_office_level
             NULL AS sp_c_for_what_purpose,               -- Missing in service_point_office_level
             NULL AS sp_d_5_cost_covers_what_service,     -- Missing in service_point_office_level
             sp_a_fee_status_of_srhr_and_gbv,
             sp_c_fee_status_of_safety_and_protection,
             sp_d_fee,
             sp_c_total_fee,
             sp_d_paid_services,
             sp_e_is_fee_requir,
             sp_c_fee_for_purpose,
             sp_b_community_based_gvb_support,
             sp_b_is_fee_required,
             sp_d_provides_gbv_legal_support,
             name_of_the_school,
             community_village_of_school,
             region_province_county_name_of_school,
             district_name_of_school,
             ownership_type_of_the_school,
             type_of_school_based_on_highest_levels_of_education_offered,
             sp_a_serivce_wise_amount_of_fee_of_srhr_and_gbv,
             sp_b_serivce_wise_amount_of_fee_of_psychosocial,
             sp_e_serivce_wise_amount_of_fee_of_disability_support,
             sp_g_serivce_wise_amount_of_fee_of_agricultural_extension,
             sp_b_name_of_community_based_gvb_support_group
      FROM service_point_office_level) s
         CROSS JOIN LATERAL jsonb_to_record(s.answer::jsonb) AS a(
                                                                  approval_status text,
                                                                  _3955 text,
                                                                  community_village_of_school text,
                                                                  district_name_of_school text,
                                                                  doc_upload text,
                                                                  _3956 text,
                                                                  _3957 text,
                                                                  _3951 text,
                                                                  name_of_the_school text,
                                                                  ownership_type_of_the_school text,
                                                                  plead_formation_date text,
                                                                  plead_pa_pin text,
                                                                  plead_pin text,
                                                                  region_province_county_name_of_school text,
                                                                  _3958 text,
                                                                  sp_a_fee_status_of_srhr_and_gbv text,
                                                                  sp_availavble_kits text,
                                                                  sp_b_age_groups__activities_serve text,
                                                                  sp_b_community_based_gvb_support text,
                                                                  sp_b_have_safe_space_to_receive_survivors text,
                                                                  sp_b_is_fee_required text,
                                                                  sp_b_psychosocial_services_provided_by text,
                                                                  sp_b_type_of_service text,
                                                                  sp_b_type_of_service_others text,
                                                                  sp_c_1_others text,
                                                                  sp_c_fee_for_purpose text,
                                                                  sp_c_fee_status_of_safety_and_protection text,
                                                                  sp_contact_number text,
                                                                  sp_contact_number_of_the_focal_persion text,
                                                                  sp_c_services_provide text,
                                                                  sp_c_specific_age_groups text,
                                                                  sp_c_total_fee text,
                                                                  sp_d_1 text,
                                                                  sp_d_2_others text,
                                                                  sp_d_disability_support text,
                                                                  sp_d_disability_support_services text,
                                                                  sp_d_fee text,
                                                                  sp_d_is_free_service text,
                                                                  sp_d_paid_services text,
                                                                  sp_d_provides_gbv_legal_support text,
                                                                  sp_e_1_others text,
                                                                  sp_e_disability_support text,
                                                                  sp_e_disability_support_services text,
                                                                  sp_e_is_fee_requir text,
                                                                  sp_email text,
                                                                  sp_f_1 text,
                                                                  sp_f_2 text,
                                                                  sp_f_2_othars text,
                                                                  sp_f_3 text,
                                                                  sp_family_planning_methods text,
                                                                  sp_family_planning_methods_others text,
                                                                  sp_focal_person text,
                                                                  sp_focal_person_phone text,
                                                                  sp_g_1 text,
                                                                  sp_g_1_others text,
                                                                  sp_g_2 text,
                                                                  sp_h_1 text,
                                                                  sp_h__1 text,
                                                                  sp_h__10 text,
                                                                  sp_h__10_1 text,
                                                                  sp_h__10_2 text,
                                                                  sp_h__11 text,
                                                                  sp_h__11_1 text,
                                                                  sp_h__1_others text,
                                                                  sp_h_2 text,
                                                                  sp_h__2 text,
                                                                  sp_h__2_1 text,
                                                                  sp_h_3 text,
                                                                  sp_h__3 text,
                                                                  sp_h__3_1 text,
                                                                  sp_h_3_others text,
                                                                  sp_h_4 text,
                                                                  sp_h__4 text,
                                                                  sp_h__4_1 text,
                                                                  sp_h_5 text,
                                                                  sp_h__5 text,
                                                                  sp_h__5_1 text,
                                                                  sp_h__6 text,
                                                                  sp_h__6_1 text,
                                                                  sp_h__7 text,
                                                                  sp_h__7_1 text,
                                                                  sp_h__8 text,
                                                                  sp_h__8_1 text,
                                                                  sp_h__9 text,
                                                                  sp_h__9_1 text,
                                                                  sp_have_gbv_focal_points text,
                                                                  sp_have_post_rape_kits text,
                                                                  sp_have_space_to_receive_survivors text,
                                                                  sp_medical_personnel text,
                                                                  sp_medical_personnel_received_training text,
                                                                  sp_name text,
                                                                  sp_name_of_the_ocula_person text,
                                                                  sp_provision_for_child_survivors text,
                                                                  sp_srhr_other_services text,
                                                                  sp_support_type text,
                                                                  sp_which_srhr_services_you_offer text,
                                                                  type_of_school_based_on_highest_levels_of_education_offered text
    )



