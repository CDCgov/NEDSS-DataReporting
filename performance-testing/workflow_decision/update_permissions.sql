USE NBS_ODSE;
GO

-- Update existing permissions for nedss_elr_load to use superuser permission set
-- Temporary hack for local dev
UPDATE ur
SET ur.auth_perm_set_uid = ps.auth_perm_set_uid,
    ur.auth_role_nm = ps.perm_set_nm,
    ur.read_only_ind = 'F',  -- Write access
    ur.last_chg_time = GETDATE(),
    ur.last_chg_user_id = -1
FROM Auth_user_role ur
INNER JOIN Auth_user u ON ur.auth_user_uid = u.auth_user_uid
CROSS JOIN Auth_perm_set ps
WHERE u.user_id = 'nedss_elr_load'
  AND ur.record_status_cd = 'ACTIVE'
  AND ps.perm_set_nm IN ('superuser', 'SUPERUSER');
GO

