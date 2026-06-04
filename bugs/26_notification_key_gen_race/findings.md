# Bug #26 — sp_nrt_notification_postprocessing non-atomic key-gen race (2627) — sibling of bug #17

REPRODUCED Error 2627 deterministically (12 parallel invocations, 3 rounds -> 7x 2627 + 1x sibling 547):
  step 5 "Insert into NOTIFICATION Dimension" (routine 006 lines 241-257):
  Violation of PRIMARY KEY constraint 'PK__NOTIFICA__...'. Cannot insert duplicate key in
  'dbo.NOTIFICATION'. The duplicate key value is (13)  [a d_notification_key].

ROOT CAUSE (ROUTINE BUG — NOT bad fixture data; NOT a harness double-call; same class as bug #17):
- #temp_ntf_table (lines 36-46) LEFT JOINs nrt_notification_key WITH (NOLOCK) to compute NOTIFICATION_KEY,
  captured at SP START (a stale snapshot).
- Line 238: INSERT INTO nrt_notification_key(notification_uid) SELECT ... WHERE notification_key IS NULL
  — keyed off the stale snapshot, NO live NOT EXISTS, and idx_nrt_notification_key_uid is NOT UNIQUE,
  so two overlapping first-time batches both mint a new IDENTITY d_notification_key for the same uid.
- Lines 241-257: INSERT INTO NOTIFICATION (... NOTIFICATION_KEY=k.d_notification_key) WHERE
  ntf.NOTIFICATION_KEY IS NULL — re-reads nrt_notification_key live, picks up the OTHER session's
  committed key, and inserts a NOTIFICATION row for a PK another session already inserted -> 2627. The
  whole step is in one BEGIN TRAN; the CATCH rolls back and (under the intentional fail-fast) poisons
  the co-batched notifications (e.g. 20000110, 20060010).
- nrt_investigation_notification PK=(notification_uid, source_act_uid), so the SOURCE cannot hold dup
  uids — the data is clean; the defect is purely the non-atomic key acquisition + snapshot guard.

WHY INTERMITTENT: only fires when two CDC-driven batches hit the FIRST-TIME insert for the same
notification_uid concurrently / within the snapshot window. Steady-state re-runs are idempotent (guard
correctly false). The summary notification 22065010 is a frequent repeat participant in the notification
batch (its SummaryNotification act_relationship + the fixture's last_chg_time re-emit), so it hits the
race more often — but it is NOT special in its data. Clean single-row first-time run succeeds.

FIX (routine, proven by bug #17's precedent — unambiguous concurrency correctness, NOT a design change):
serialize + live-guard the key-gen critical section. Either/both:
  1. EXEC sp_getapplock @Resource='nrt_notification_key_keygen', @LockMode='Exclusive',
     @LockOwner='Transaction' before the key-gen (mirrors the bug #17 fix in routines 017/018).
  2. Add a UNIQUE constraint on nrt_notification_key.notification_uid; make line 238 INSERT ... WHERE NOT
     EXISTS; change the line-257/306 guards from the snapshot `ntf.NOTIFICATION_KEY IS NULL` to a live
     `NOT EXISTS (SELECT 1 FROM dbo.NOTIFICATION n WHERE n.NOTIFICATION_KEY = k.d_notification_key)`.
  Also drop the WITH (NOLOCK) on the key lookups.
Confidence: HIGH (reproduced the exact statement + colliding key under concurrency; proved clean
first-time + steady-state paths do not throw; confirmed single-instance source/RDB data for 22065010).
