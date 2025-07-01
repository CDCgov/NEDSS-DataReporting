IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_backfill_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_backfill_event]
END
GO 

CREATE PROCEDURE dbo.sp_nrt_backfill_event  @status_cd nvarchar(1000)
AS
Begin

    BEGIN TRY
    
        select 
            record_key,
            entity_type,
            record_uid_list,
            rdb_table_map,
            batch_id,
            err_description,
            status_cd,
            retry_count,
            retry_count,
            created_dttm,
            updated_dttm
        from [dbo].nrt_backfill with (nolock)
        where status_cd = @status_cd

    end try

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        return @ErrorMessage;

    END CATCH

end;