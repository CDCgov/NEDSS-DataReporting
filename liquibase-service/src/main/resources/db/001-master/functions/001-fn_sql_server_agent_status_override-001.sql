-- This function needs to be created in master since the Sql Server agent is not exposed
-- We need to override this function in the helm chart distributed properties
IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[IsSqlAgentRunning]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[IsSqlAgentRunning]
GO 

CREATE FUNCTION [dbo].IsSqlAgentRunning() RETURNS BIT AS
BEGIN
    DECLARE @IsRunning BIT = 0;

    IF (EXISTS(SELECT dss.*
               FROM sys.dm_server_services dss
               WHERE dss.[servicename] LIKE N'SQL Server Agent (%'
                 AND dss.[status] = 4 -- Running
    ))
        BEGIN
            SET @IsRunning = 1;
        END;

    RETURN @IsRunning;
END
GO

GRANT VIEW SERVER STATE TO nbs_ods;
GO