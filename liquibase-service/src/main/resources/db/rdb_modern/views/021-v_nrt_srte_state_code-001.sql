CREATE OR ALTER VIEW [dbo].[v_nrt_srte_state_code]
    AS
    SELECT 
        state_cd,
        assigning_authority_cd,
        assigning_authority_desc_txt,
        state_nm,
        code_desc_txt,
        code_desc_txt AS code_short_desc_txt,
        effective_from_time,
        effective_to_time,
        excluded_txt,
        indent_level_nbr,
        is_modifiable_ind,
        key_info_txt,
        parent_is_cd,
        status_cd,
        status_time,
        code_set_nm,
        seq_num,
        nbs_uid,
        source_concept_id,
        code_system_cd,
        code_system_desc_txt,
        state_cd AS code,
        state_cd AS concept_code,
        code_desc_txt AS concept_preferred_nm, 
        code_desc_txt AS concept_nm
    FROM [dbo].nrt_srte_State_code;