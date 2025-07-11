IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_CONTACT_RECORD' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_contact_key ON

        INSERT INTO [dbo].nrt_contact_key(
            d_contact_record_key, contact_uid
        )
        select dcr.d_contact_record_key,
        cc.ct_contact_uid as contact_uid
        from dbo.d_contact_record dcr with (nolock)
        inner join (select distinct ct_contact_uid, local_id, version_ctrl_nbr from nbs_odse.dbo.CT_CONTACT with (nolock)) cc 
            on dcr.LOCAL_ID = cc.local_id
            and dcr.version_ctrl_nbr = cc.version_ctrl_nbr
        left join dbo.nrt_contact_key k with (nolock)
            on k.d_contact_record_key = dcr.d_contact_record_key
            and k.contact_uid = cc.ct_contact_uid
        where k.d_contact_record_key is null and 
        k.contact_uid is null order by dcr.d_contact_record_key;

        SET IDENTITY_INSERT [dbo].nrt_contact_key OFF

    END