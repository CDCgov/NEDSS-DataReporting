IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_CASE_MANAGEMENT' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_case_management_key ON

        INSERT INTO [dbo].nrt_case_management_key(
            d_case_management_key, public_health_case_uid
        )
        select 
        dc.d_case_management_key,
        i.case_uid as public_health_case_uid
        from dbo.D_CASE_MANAGEMENT dc with (nolock) 
        inner join (select distinct CASE_UID, INVESTIGATION_KEY from dbo.INVESTIGATION with (nolock)) i 
            on dc.INVESTIGATION_KEY = i.INVESTIGATION_KEY
        left join dbo.nrt_case_management_key k with (nolock) 
            on k.d_case_management_key = dc.d_case_management_key
            and k.public_health_case_uid = i.CASE_UID
        where k.d_case_management_key is null and k.public_health_case_uid is null
        order by dc.d_case_management_key

        SET IDENTITY_INSERT [dbo].nrt_case_management_key OFF

    END