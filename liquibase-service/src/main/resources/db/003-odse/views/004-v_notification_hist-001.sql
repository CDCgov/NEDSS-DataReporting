IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_notification_hist')
BEGIN
    DROP VIEW [dbo].v_notification_hist
END
GO

CREATE VIEW [dbo].v_notification_hist
AS
WITH NotifHist AS (
    SELECT  DISTINCT
        TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
        ,TARGET_CLASS_CD
        ,SOURCE_ACT_UID
        ,SOURCE_CLASS_CD
        ,NF.VERSION_CTRL_NBR
        ,NF.ADD_TIME
        ,NF.ADD_USER_ID
        ,NF.RPT_SENT_TIME
        ,NF.RECORD_STATUS_CD
        ,NF.RECORD_STATUS_TIME
        ,NF.LAST_CHG_TIME
        ,NF.LAST_CHG_USER_ID
        ,'Y' AS HIST_IND
        , NF.txt
        ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
        ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
        ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
        ,CAST(NULL AS INT) AS X1
        ,CAST(NULL AS INT) AS X2
        ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
        ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
        ,notification_uid
    FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
    INNER JOIN NBS_ODSE.DBO.NOTIFICATION_HIST NF WITH (NOLOCK) 
        ON AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
    WHERE
        SOURCE_CLASS_CD = 'NOTF'
        AND TARGET_CLASS_CD = 'CASE'
        AND NF.CD='NOTF'
        AND (
                NF.RECORD_STATUS_CD = 'COMPLETED'
                OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                OR NF.RECORD_STATUS_CD = 'REJECTED'
                OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                OR NF.RECORD_STATUS_CD = 'APPROVED'
            )
    UNION
    SELECT  
        TARGET_ACT_UID
        ,TARGET_CLASS_CD
        ,SOURCE_ACT_UID
        ,SOURCE_CLASS_CD
        ,NF.VERSION_CTRL_NBR
        ,NF.ADD_TIME
        ,NF.ADD_USER_ID
        ,NF.RPT_SENT_TIME
        ,NF.RECORD_STATUS_CD
        ,NF.RECORD_STATUS_TIME
        ,NF.LAST_CHG_TIME
        ,NF.LAST_CHG_USER_ID
        ,'N' AS HIST_IND
        , NULL AS TXT
        ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
        ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
        ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
        ,CAST(NULL AS INT) AS X1
        ,CAST(NULL AS INT) AS X2
        ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
        ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
        ,notification_uid
    FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
       ,NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
    WHERE 
        AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
        AND SOURCE_CLASS_CD = 'NOTF'
        AND TARGET_CLASS_CD = 'CASE'
        AND NF.CD='NOTF'
        AND (
                NF.RECORD_STATUS_CD = 'COMPLETED'
                OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                OR NF.RECORD_STATUS_CD = 'REJECTED'
                OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                OR NF.RECORD_STATUS_CD = 'APPROVED'
            )
),
orderedHist AS(
    SELECT
        PUBLIC_HEALTH_CASE_UID
        ,TARGET_CLASS_CD
        ,SOURCE_ACT_UID
        ,SOURCE_CLASS_CD
        ,VERSION_CTRL_NBR
        ,ADD_TIME
        ,ADD_USER_ID
        ,RPT_SENT_TIME
        ,RECORD_STATUS_CD
        ,RECORD_STATUS_TIME
        ,LAST_CHG_TIME
        ,LAST_CHG_USER_ID
        ,HIST_IND
        ,TXT
        ,NOTIFSENTCOUNT
        ,NOTIFREJECTEDCOUNT
        ,NOTIFCREATEDCOUNT
        ,X1
        ,X2
        ,FIRSTNOTIFICATIONSENDDATE
        ,NOTIFICATIONDATE
        ,notification_uid
        ,ROW_NUMBER() OVER (PARTITION BY PUBLIC_HEALTH_CASE_UID ORDER BY VERSION_CTRL_NBR DESC) notif_latest_rownum
    FROM NotifHist
)
SELECT DISTINCT 
    MIN(CASE
            WHEN VERSION_CTRL_NBR = 1
            THEN RECORD_STATUS_CD
    END) AS first_notification_status
    ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'REJECTED'
            THEN 1
            ELSE 0
    END) notif_rejected_count
    ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'APPROVED' OR RECORD_STATUS_CD = 'PEND_APPR'
            THEN 1
            WHEN RECORD_STATUS_CD = 'REJECTED'
            THEN -1
            ELSE 0
    END) notif_created_count
    ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
            THEN 1
            ELSE 0
    END) notif_sent_count
    ,MIN(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
            THEN RPT_SENT_TIME
    END) AS first_notification_send_date
    ,SUM(CASE
            WHEN RECORD_STATUS_CD = 'PEND_APPR'
            THEN 1
            ELSE 0
    END) notif_created_pending_count
    ,MAX(CASE
            WHEN RECORD_STATUS_CD = 'APPROVED' OR RECORD_STATUS_CD = 'PEND_APPR'
            THEN LAST_CHG_TIME
    END) AS last_notification_date
    ,MAX(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED'
            THEN RPT_SENT_TIME
    END) AS last_notification_send_date
    ,MIN(ADD_TIME) AS first_notification_date
    ,MAX(CASE
            WHEN version_ctrl_nbr != 1 THEN -1
            ELSE add_user_id
        END) AS first_notification_submitted_by
    ,MAX(CASE
            WHEN notif_latest_rownum != 1 THEN -1
            ELSE last_chg_user_id
        END) AS last_notification_submitted_by
    ,MIN(CASE
            WHEN RECORD_STATUS_CD = 'COMPLETED' AND RPT_SENT_TIME IS NOT NULL
            THEN RPT_SENT_TIME
    END) AS notification_date
    ,PUBLIC_HEALTH_CASE_UID
    ,notification_uid
FROM orderedHist
GROUP BY PUBLIC_HEALTH_CASE_UID, notification_uid;