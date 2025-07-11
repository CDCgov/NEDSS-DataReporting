IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_group_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_GROUP' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_ldf_group_key ON

        INSERT INTO [dbo].nrt_ldf_group_key(
            d_ldf_group_key,
            business_object_uid
        )
        select 
            d.ldf_group_key as d_ldf_group_key, 
            d.business_object_uid
        from dbo.LDF_GROUP d with (nolock)
        left join dbo.nrt_ldf_group_key k with (nolock)
            on k.d_ldf_group_key = d.ldf_group_key
            and k.business_object_uid = d.business_object_uid 
        where k.d_ldf_group_key is null and k.business_object_uid is null
        and d.business_object_uid is not null
        order by d.ldf_group_key;

        SET IDENTITY_INSERT [dbo].nrt_ldf_group_key OFF

    END