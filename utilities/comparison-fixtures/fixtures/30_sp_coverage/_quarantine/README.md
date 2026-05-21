# _quarantine — DEPRECATED

Empty as of 2026-05-21 (Agent B Phase-2 debug pass).

This directory previously held COVID and Varicella full-chain fixtures
that were quarantined because they regressed the TB cluster in a merged
pipeline run. The root cause turned out to be trivial: both fixtures
were missing `SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON/OFF` around
their `nbs_case_answer` INSERT block (same bug TB had originally — see
commit a7757dbc). The COVID INSERT failed mid-apply with
`Cannot insert explicit value for identity column in table
'NBS_case_answer' when IDENTITY_INSERT is set to OFF`. Because
`scripts/merge_and_verify.sh` runs `set -euo pipefail`, the COVID
fixture failure aborted Step 8 before TB's tail-EXECs ran, leaving
D_TB_PAM / F_TB_PAM / TB_DATAMART at 0 rows. There was no
cross-fixture interference — the two fixtures compose cleanly with
TB once the IDENTITY_INSERT toggle is added.

Both fixtures are now restored to `fixtures/30_sp_coverage/` with the
fix applied. Merged pipeline now lands at 33.6% column coverage
(+5.7pp over the prior 27.9% TB+STD+BMIRD baseline).

Keep this directory empty as a marker. Future quarantines should
allocate new sibling directories.
