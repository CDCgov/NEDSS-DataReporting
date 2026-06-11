-- GREEN only when sp_sld_investigation_repeat_postprocessing both (a) lands the
-- new repeat rows in D_INVESTIGATION_REPEAT (bug #10: pre-fix the D_REPT_KEY
-- sentinel=1 filter drops them all) and (b) populates the TEXT pivot column
-- (bug #13: pre-fix the NULL-propagating column-list builder leaves it NULL).
-- Pre-fix either bug => no row matches => Await times out => RED.
SELECT TRAVEL_LOCATION_TEXT
FROM RDB_MODERN.dbo.D_INVESTIGATION_REPEAT
WHERE TRAVEL_LOCATION_TEXT = N'San Francisco';
