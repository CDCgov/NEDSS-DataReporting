#!/usr/bin/env bash
# APP-926 equivalence harness.
#   1. deploy ORIGINAL SP, capture 8 scenarios -> dbo.orig_1..8, then again -> dbo.orig2_1..8 (determinism)
#   2. deploy OPTIMIZED SP, capture 8 scenarios -> dbo.new_1..8
#   3. compare orig vs new (equivalence) and orig vs orig2 (determinism)
# Leaves the OPTIMIZED SP deployed at the end.
set -euo pipefail

C="nedss-datareporting-nbs-mssql-1"
SQL="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P PizzaIsGood33! -C -d RDB_MODERN"
ORIG="/home/ec2-user/seer/app-926/sp_original.sql"
OPT="/home/ec2-user/worktrees/app-926/reporting-pipeline-service/src/main/resources/db/changelog/migrations/v7.13/rdb/routines/048-sp_morbidity_report_datamart_postprocessing-001.sql"
DIR="/home/ec2-user/seer/app-926"

deploy () { docker cp "$1" "$C:/tmp/sp.sql" >/dev/null; docker exec "$C" $SQL -b -i /tmp/sp.sql >/dev/null; echo "deployed: $2"; }
capture () { docker exec "$C" $SQL -W -v PFX="$1" -i /tmp/run_capture.sql; }

docker cp "$DIR/run_capture.sql" "$C:/tmp/run_capture.sql" >/dev/null
docker cp "$DIR/compare.sql"     "$C:/tmp/compare.sql"     >/dev/null

echo "== reseed (idempotent) =="
docker cp "$DIR/seed.sql" "$C:/tmp/seed.sql" >/dev/null
docker exec "$C" $SQL -W -i /tmp/seed.sql >/dev/null && echo "seed ok"

deploy "$ORIG" "ORIGINAL"
echo "== capture orig =="; capture orig
echo "== capture orig2 (determinism) =="; capture orig2

deploy "$OPT" "OPTIMIZED"
echo "== capture new =="; capture new

echo "== JOB_FLOW_LOG ERROR rows during captures (last 15 min) =="
docker exec "$C" $SQL -W -Q "SELECT Step_Name, LEFT(Error_Description,120) err FROM dbo.job_flow_log WHERE Status_Type='ERROR' AND package_Name='sp_morbidity_report_datamart_postprocessing' AND create_dttm > DATEADD(minute,-15,GETDATE()) ORDER BY record_id DESC;" || true

echo "== EQUIVALENCE: orig vs new =="
docker exec "$C" $SQL -W -i /tmp/compare.sql

echo "== DETERMINISM: orig vs orig2 (should all PASS / zero diff) =="
docker exec "$C" $SQL -W -Q "
SET NOCOUNT ON;
DECLARE @i INT=1;
WHILE @i<=8 BEGIN
  DECLARE @s NVARCHAR(MAX)=N'SELECT '+CAST(@i AS VARCHAR)+N' sc,
    (SELECT COUNT(*) FROM (SELECT * FROM dbo.orig_'+CAST(@i AS VARCHAR)+N' EXCEPT SELECT * FROM dbo.orig2_'+CAST(@i AS VARCHAR)+N') a) o_minus_o2,
    (SELECT COUNT(*) FROM (SELECT * FROM dbo.orig2_'+CAST(@i AS VARCHAR)+N' EXCEPT SELECT * FROM dbo.orig_'+CAST(@i AS VARCHAR)+N') b) o2_minus_o;';
  EXEC sp_executesql @s; SET @i+=1; END" || true

echo "== confirm OPTIMIZED left deployed =="
docker exec "$C" $SQL -W -h -1 -Q "SELECT CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_morbidity_report_datamart_postprocessing')) LIKE '%#uid_obs%' THEN 'OPTIMIZED deployed' ELSE 'ORIGINAL deployed' END;"
