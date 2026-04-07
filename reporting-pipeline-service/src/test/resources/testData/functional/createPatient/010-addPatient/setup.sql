-- Uses IDs -1
-- Entity
insert into NBS_ODSE.dbo.Entity(entity_uid, class_cd) values (-1, 'PSN');

--- Person
insert into NBS_ODSE.dbo.Person(
    person_uid,
    person_parent_uid,
    local_id,
    version_ctrl_nbr,
    cd,
    electronic_ind,
    edx_ind,
    add_time,
    add_user_id,
    last_chg_time,
    last_chg_user_id,
    record_status_cd,
    record_status_time,
    status_cd,
    status_time
) values (
    -1,
    -1,
    'PSN-1GA01',
    1,
    'PAT',
    'N',
    'Y',
    '2026-04-03 14:43:37.000',
    '9999',
    '2026-04-03 14:43:38.000',
    '9999',
    'ACTIVE',
    '2026-04-03 14:43:39.000',
    'A',
    '2026-04-03 14:43:40.000'
);
