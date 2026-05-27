## Summary

These are not typical recordings; they are ELRs, or Electronic Lab Reports. ELRs are submitted to NBS through Rhapsody. At a high level, the ELR is converted from HL7 to XML and then inserted into `[NBS_MSGOUTE].[dbo].[NBS_interface]`.

## Process

1. Run `ELRImporter.sh` in wildfly (`docker compose exec -it wildfly sh /opt/jboss/wildfly/nedssdomain/Nedss/BatchFiles/ELRImporter.sh`) to import any existing ELRs

### Loop:

2. Write the ELR as XML to [NBS_MSGOUTE].[dbo].[NBS_interface]
3. `trace_db_dual_capture`
4. Run `ELRImporter.sh` in wildfly (`docker compose exec -it wildfly sh /opt/jboss/wildfly/nedssdomain/Nedss/BatchFiles/ELRImporter.sh`)
5. Back in NBS, the ELR should have landed in:
    - Documents Requiring Security Assignment
        - if the GA county, condition and program don't align
        - Set Program Area to GDC
    - Documents Requiring Review
6. From the Documents Requiring Review queue, click on the Lab Report and Create Investigation

## Resources

- https://www.dshs.texas.gov/sites/default/files/PHID/Documents/Texas-HL72.5.1-ELR-Guide.pdf
- https://www.health.state.mn.us/diseases/reportable/medss/elrappb.pdf
- https://www.dhhs.nh.gov/sites/g/files/ehbemt476/files/documents/2021-12/elrguide.pdf (Appendix III)
- https://hhs.iowa.gov/media/7824/download?inline
- https://github.com/CDCgov/dibbs-ecr-refiner/tree/main/docs/tes
- https://github.com/synthetichealth/synthea
- NEDSSDB/src/seed_data

Here's an example for a single patient that comes to mind in the foodborne world - Taylor Swift experiences nausea and vomiting after drinking raw milk. She goes and sees her doctor who takes a stool sample.

1. Taylor's stool sample is tested and the following is received -
    - Condition = Shiga toxin-producing E. coli (STEC)
    - Test Type/Method = BioFire GI Panel
    - Result = detected (i.e. positive)
    - Status = preliminary
2. Once the panel test is complete, the result will come in with the status marked as final. If I recall correctly, this ELR comes in as an update rather than a new lab report document in NBS.
3. In addition to the panel that's done, the lab also performs a stool culture to confirm the pathogen by isolating STEC. There are 3 results that come in for this. Typically the way we'd see it is as follows -
   a. 1 lab report created for the E. coli serotype - test type would be listed as stool culture and the result could be E. coli O157:H7 for example
   b. 1 lab report created for the shiga toxin results (there are 2) - shiga toxin 1 is detected (positive), shiga toxin 2 is not detected (negative)
4. Because Taylor is a day care employee, she needs test negative in order to return to work.
   a. After her symptoms resolve, she has another specimen collected to do that additional testing. That ELR comes in as a PCR test and the result is indeterminate with the status as final.
   b. A few days later, a corrected ELR comes in with a result of negative and status = corrected.
