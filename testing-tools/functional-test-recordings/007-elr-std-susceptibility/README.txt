Arthur Jones STD ELR test messages

Source scenario: [APP-678] Add functional test that includes STD ELRs

Timeline used:
- 2026-05-12: Dermatology visit, NP swab collected for measles PCR. Negative final/confirmed result same day.
- 2026-05-13: Urgent care visit, serum collected for syphilis RPR titer. Preliminary positive 1:128 same day.
- 2026-05-15: Health department visit for syphilis follow-up, treatment, confirmatory TPPA, rapid HIV, HIV differentiation serum collection, and GC NAAT urine collection.
- 2026-05-17: HIV differentiation result updated to negative using same order/specimen as the initial inconclusive result.
- 2026-05-22: Follow-up GC culture/AST specimen collected after persistent painful urination.
- 2026-05-24: GC culture/AST positive with ceftriaxone resistance.
- 2026-05-29: GC test-of-cure specimen collected.
- 2026-05-30: GC test-of-cure NAAT negative.

Files:
01_measles_pcr_negative_confirmed.hl7
02_syphilis_rpr_titer_preliminary_positive.hl7
03_syphilis_tppa_positive_confirmed.hl7
04_hiv_rapid_saliva_preliminary_positive.hl7
05a_hiv_differentiation_inconclusive_preliminary.hl7
05b_hiv_differentiation_negative_confirmed_update.hl7
06_gonorrhea_naat_urine_positive.hl7
07_gonorrhea_culture_ast_ceftriaxone_resistant.hl7
08_gonorrhea_naat_urine_test_of_cure_negative.hl7

Notes:
- The HIV confirmatory negative update reuses the same placer/filler order numbers as the initial inconclusive HIV differentiation result.
- The GC AST message includes culture positivity plus ceftriaxone MIC and susceptibility interpretation OBX segments.
- Dates/times are intentionally before 2026-06-01.
