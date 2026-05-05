#!/usr/bin/env python3
"""
eICR Generator and Loader
Generates random eICR (Electronic Initial Case Report) CDA documents and creates SQL INSERT statements 
to load them into the NBS_MSGOUTE.dbo.NBS_interface table.

Usage:
    python3 eicr_generate_load.py -n 10 > load_eicr.sql
    python3 eicr_generate_load.py -n 1 -o eicr_output_dir
"""

import argparse
import random
import string
import sys
import os
from datetime import datetime 
from faker import Faker

fake = Faker()

GA_CITIES = [
    "Atlanta", "Savannah", "Augusta", "Macon", "Columbus",
    "Athens", "Sandy Springs", "Roswell", "Albany", "Marietta",
    "Alpharetta", "Johns Creek", "Valdosta", "Smyrna", "Dunwoody",
    "Rome", "Peachtree City", "Gainesville", "Warner Robins", "Decatur",
]

# Template for the main payload (CDA XML)
# Variable placeholders are marked with {VARIABLE_NAME}
PAYLOAD_TEMPLATE = """<?xml version="1.0"?>
<ClinicalDocument xmlns:sdtcxmlnamespaceholder="urn:hl7-org:v3"
    xmlns:sdt="urn:hl7-org:sdtc"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:hl7-org:v3 CDA_SDTC.xsd"
    xmlns="urn:hl7-org:v3">
    <realmCode code="US"/>
    <typeId root="2.16.840.1.113883.1.3" extension="POCD_HD000040"/>
    <id root="2.16.840.1.113883.19" extension="{MESSAGE_ID}" assigningAuthorityName="LR"/>
    <code code="55751-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Public Health Case Report - PHRI"/>
    <title>Public Health Case Report - Data from Legacy System to CDA</title>
    <effectiveTime value="{EFFECTIVE_TIME}"/>
    <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25"/>
    <languageCode code="en-US"/>
    <setId extension="ONGOING_CASE" displayable="true"/>
    <recordTarget>
        <patientRole>
            <id extension="{PATIENT_ID}" root="2.16.840.1.113883.4.1" assigningAuthorityName="LR"/>
            <addr use="H">
                <city><![CDATA[{CITY}]]></city>
                <country><![CDATA[USA^UNITED STATES^Country (ISO 3166-1)]]></country>
                <state><![CDATA[{STATE_CODE}^{STATE_NAME}^FIPS 5-2(State)]]></state>
                <postalCode><![CDATA[{ZIP}]]></postalCode>
                <streetAddressLine><![CDATA[{STREET}]]></streetAddressLine>
            </addr>
            <telecom use="HP" value="tel:+1-615-080-1212"/>
            <telecom use="HP" value="mailto:mailto:madeupemail@company.com"/>
            <patient>
                <name use="L">
                    <given><![CDATA[{FIRST_NAME}]]></given>
                    <family><![CDATA[{LAST_NAME}]]></family>
                </name>
                <administrativeGenderCode code="{GENDER_CODE}" codeSystem="2.16.840.1.113883.12.1" codeSystemName="Administrative sex (HL7)" displayName="{GENDER_DISPLAY}">
                    <translation code="{GENDER_CODE}" codeSystem="2.16.840.1.113883.12.1" codeSystemName="2.16.840.1.113883.12.1" displayName="{GENDER_DISPLAY}"/>
                </administrativeGenderCode>
                <birthTime value="{DOB}"/>
                <maritalStatusCode code="S" codeSystem="2.16.840.1.113883.5.2" codeSystemName="MaritalStatus" displayName="Never Married">
                    <translation code="S" codeSystem="2.16.840.1.113883.5.2" codeSystemName="2.16.840.1.113883.5.2" displayName="Single, never married"/>
                </maritalStatusCode>
                <urn:raceCode code="2106-3" codeSystem="2.16.840.1.113883.6.238" codeSystemName="Race &amp; Ethnicity - CDC" displayName="White"
                    xmlns:urn="urn:hl7-org:sdtc">
                    <translation code="2106-3" codeSystem="2.16.840.1.113883.6.238" codeSystemName="2.16.840.1.113883.6.238" displayName="White"/>
                </urn:raceCode>
                <ethnicGroupCode code="2186-5" codeSystem="2.16.840.1.113883.6.238" codeSystemName="Race &amp; Ethnicity - CDC" displayName="Not Hispanic or Latino">
                    <translation code="2186-5" codeSystem="2.16.840.1.113883.6.238" codeSystemName="2.16.840.1.113883.6.238" displayName="Not Hispanic or Latino"/>
                </ethnicGroupCode>
            </patient>
        </patientRole>
    </recordTarget>
    <author>
        <time value="{EFFECTIVE_TIME}"/>
        <assignedAuthor>
            <id root="2.16.840.1.113883.19.5"/>
            <assignedPerson>
                <name>
                    <family>Brown</family>
                    <given>Sarah</given>
                </name>
            </assignedPerson>
        </assignedAuthor>
    </author>
    <custodian>
        <assignedCustodian>
            <representedCustodianOrganization>
                <id extension="2.16.840.1.113883.19.5"/>
                <name>TDH Healthcare</name>
                <telecom value="tel:+1-615-698-3212"/>
                <addr>
                    <streetAddressLine>20 20th St</streetAddressLine>
                    <streetAddressLine/>
                    <city>Nashville</city>
                    <state>TN</state>
                    <postalCode>37243</postalCode>
                    <country>USA</country>
                </addr>
            </representedCustodianOrganization>
        </assignedCustodian>
    </custodian>
    <component>
        <structuredBody>
            <component>
                <section>
                    <id root="2.16.840.1.113883.19" extension="{MESSAGE_ID}" assigningAuthorityName="LR"/>
                    <code code="29762-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Social History"/>
                    <title><![CDATA[SOCIAL HISTORY INFORMATION]]></title>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="DEM114" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Birth Sex:"/>
                            <value code="{GENDER_CODE}" codeSystem="2.16.840.1.113883.12.1" codeSystemName="Administrative sex (HL7)" displayName="{GENDER_DISPLAY}" xsi:type="CE"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                                <translation code="{GENDER_CODE}" codeSystem="2.16.840.1.113883.12.1" codeSystemName="2.16.840.1.113883.12.1" displayName="{GENDER_DISPLAY}"/>
                            </value>
                        </observation>
                    </entry>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="DEM127" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Is this person deceased?"/>
                            <value code="N" codeSystem="2.16.840.1.113883.12.136" codeSystemName="Yes/No Indicator (HL7)" displayName="No" xsi:type="CE"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                                <translation code="false" codeSystem="2.16.840.1.113883.12.136" codeSystemName="2.16.840.1.113883.12.136" displayName="FALSE"/>
                            </value>
                        </observation>
                    </entry>
                </section>
            </component>
            <component>
                <section>
                    <id root="2.16.840.1.113883.19" extension="1.2.840.114350.1.13.5636.1.7.8.688883.215011" assigningAuthorityName="LR"/>
                    <code code="55752-0" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Clinical Information"/>
                    <title>CLINICAL INFORMATION</title>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="INV168" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Investigation ID"/>
                            <value xsi:type="ST"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><![CDATA[{MESSAGE_ID}]]></value>
                        </observation>
                    </entry>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="INV181" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Reporting Provider"/>
                            <value root="2.16.840.1.114222.4.5.232" extension="CSR1001001XX01" xsi:type="II"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                        </observation>
                    </entry>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="INV182" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Physician"/>
                            <value root="2.16.840.1.114222.4.5.232" extension="CSR1001000XX01" xsi:type="II"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                        </observation>
                    </entry>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <code code="INV183" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Reporting Organization"/>
                            <value root="2.16.840.1.114222.4.5.232" extension="CSR1001003XX01" xsi:type="II"
                                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                        </observation>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.22"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.22"/>
                    <templateId root="2.16.840.1.113883.10.20.22.2.22.1"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.22.1"/>
                    <code code="46240-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="HISTORY OF ENCOUNTERS"/>
                    <title>Encounter Details</title>
                    <text>
                        <br/>
                        <table styleCode="subSect2">
                            <colgroup>
                                <col width="10%"/>
                                <col width="15%"/>
                                <col width="25%"/>
                                <col width="25%"/>
                                <col width="25%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Type</th>
                                    <th>Department</th>
                                    <th>Care Team</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr ID="encounter20" styleCode="normRow">
                                    <td>6/12/18</td>
                                    <td ID="encounter20type">Hospital Encounter</td>
                                    <td>
                                        <paragraph>TDH Healthcare Emergency Medicine</paragraph>
                                    </td>
                                    <td>
                                        <paragraph styleCode="Bold">Sailor, Adam</paragraph>
                                        <br/>
                                        <paragraph styleCode="Bold">Starter, Provider Midname,
                                            MD</paragraph>
                                        <paragraph>710 James Robertson Parkway</paragraph>
                                        <paragraph>Nashville, TN 37243</paragraph>
                                        <paragraph>615-222-3304</paragraph>
                                    </td>
                                    <td ID="encounter20desc">Methadone Overdose</td>
                                </tr>
                                <tr>
                                    <td>10/30/18</td>
                                    <td ID="manualEncounter">Manually triggered eICR</td>
                                    <td/>
                                    <td/>
                                    <td>eICR triggered with opioid drug overdose.</td>
                                </tr>
                            </tbody>
                        </table>
                    </text>
                    <entry>
                        <encounter classCode="ENC" moodCode="EVN">
                            <templateId root="2.16.840.1.113883.10.20.22.4.49"/>
                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.49"/>
                            <id assigningAuthorityName="EPIC" extension="10000184264" root="1.2.840.114350.1.13.5636.1.7.3.698084.8"/>
                            <code code="IMP" codeSystem="2.16.840.1.113883.5.4" displayName="Inpatient Encounter">
                                <originalText>
                                    <reference value="#encounter20type"/>
                                </originalText>
                                <translation code="3" codeSystem="1.2.840.114350.1.13.5636.1.7.4.698084.30" codeSystemName="Epic.EncounterType" displayName="Hospital Encounter"/>
                                <translation code="3" codeSystem="1.2.840.114350.1.72.1.30" displayName="Hospital Encounter"/>
                            </code>
                            <text>
                                <reference value="#encounter20"/>
                            </text>
                            <statusCode code="normal"/>
                            <effectiveTime>
                                <low value="20180612154600-0500"/>
                            </effectiveTime>
                            <performer typeCode="PRF">
                                <time>
                                    <low nullFlavor="UNK"/>
                                    <high nullFlavor="UNK"/>
                                </time>
                                <assignedEntity classCode="ASSIGNED">
                                    <id extension="1000001291" root="2.16.840.1.113883.4.6"/>
                                    <code nullFlavor="UNK">
                                        <originalText>TDH Healthcare Emergency Medicine</originalText>
                                    </code>
                                    <addr>
                                        <streetAddressLine>710 James Robertson Parkway</streetAddressLine>
                                        <city>Nashville</city>
                                        <state>TN</state>
                                        <postalCode>37243</postalCode>
                                        <country>USA</country>
                                    </addr>
                                    <telecom nullFlavor="UNK"/>
                                    <assignedPerson>
                                        <name>
                                            <given>Provider</given>
                                            <given>Adam</given>
                                            <family>Sailor</family>
                                            <suffix qualifier="AC">MD</suffix>
                                        </name>
                                    </assignedPerson>
                                </assignedEntity>
                            </performer>
                            <performer typeCode="PRF">
                                <time>
                                    <low nullFlavor="UNK"/>
                                    <high nullFlavor="UNK"/>
                                </time>
                                <assignedEntity classCode="ASSIGNED">
                                    <id extension="1000001309" root="2.16.840.1.113883.4.6"/>
                                    <code nullFlavor="UNK">
                                        <originalText>TDH Healthcare Emergency Medicine</originalText>
                                    </code>
                                    <addr>
                                        <streetAddressLine>710 James Robertson Parkway</streetAddressLine>
                                        <city>Nashville</city>
                                        <state>TN</state>
                                        <postalCode>37243</postalCode>
                                        <country>USA</country>
                                    </addr>
                                    <telecom use="WP" value="tel:+1-608-222-3304"/>
                                    <assignedPerson>
                                        <name>
                                            <given>Provider</given>
                                            <given>Adam</given>
                                            <family>Sailor</family>
                                            <suffix qualifier="AC">MD</suffix>
                                        </name>
                                    </assignedPerson>
                                </assignedEntity>
                            </performer>
                            <participant typeCode="LOC">
                                <participantRole classCode="SDLOC">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.32"/>
                                    <id extension="2455100" root="1.2.840.114350.1.13.5636.1.7.2.686980"/>
                                    <code nullFlavor="UNK"/>
                                    <playingEntity classCode="PLC">
                                        <name>TDH Healthcare Emergency Medicine</name>
                                    </playingEntity>
                                </participantRole>
                            </participant>
                            <entryRelationship typeCode="COMP">
                                <act classCode="ACT" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.64"/>
                                    <code code="48767-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC"/>
                                    <text>
                                        <reference value="#encounter20desc"/>
                                    </text>
                                    <statusCode code="completed"/>
                                </act>
                            </entryRelationship>
                            <entryRelationship typeCode="SUBJ">
                                <act classCode="ACT" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.80"/>
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.80"/>
                                    <id extension="10000184264-865825" root="1.2.840.114350.1.13.5636.1.7.1.1099.1"/>
                                    <code code="29308-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Encounter Diagnosis"/>
                                    <statusCode code="active"/>
                                    <entryRelationship inversionInd="false" typeCode="SUBJ">
                                        <observation classCode="OBS" moodCode="EVN">
                                            <templateId root="2.16.840.1.113883.10.20.22.4.4"/>
                                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.4"/>
                                            <id extension="10000184264-865825" root="1.2.840.114350.1.13.5636.1.7.1.1099.1"/>
                                            <code code="282291009" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Diagnosis">
                                                <translation code="29308-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Diagnosis"/>
                                            </code>
                                            <text>Methadone overdose</text>
                                            <statusCode code="completed"/>
                                            <effectiveTime>
                                                <low value="20180612"/>
                                            </effectiveTime>
                                            <value code="295161000" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Methadone overdose" xsi:type="CD">
                                                <originalText>Methadone overdose<reference value="#vdx22Name"/>
                                                </originalText>
                                                <translation code="T40.3X1A" codeSystem="2.16.840.1.113883.6.90" codeSystemName="ICD-10-CM" displayName="Poisoning by methadone, accidental"/>
                                                <translation code="E850.1" codeSystem="2.16.840.1.113883.6.103" codeSystemName="ICD-9CM" displayName="Accidental Poisoning by Methadone"/>
                                            </value>
                                            <entryRelationship typeCode="REFR">
                                                <observation classCode="OBS" moodCode="EVN">
                                                    <templateId root="2.16.840.1.113883.10.20.22.4.6"/>
                                                    <code code="33999-4" codeSystem="2.16.840.1.113883.6.1" displayName="Status"/>
                                                    <statusCode code="completed"/>
                                                    <effectiveTime>
                                                        <low value="20180612"/>
                                                    </effectiveTime>
                                                    <value code="55561003" codeSystem="2.16.840.1.113883.6.96" displayName="Active" xsi:type="CD"/>
                                                </observation>
                                            </entryRelationship>
                                        </observation>
                                    </entryRelationship>
                                </act>
                            </entryRelationship>
                            <reference typeCode="REFR">
                                <externalObservation>
                                    <code code="7" codeSystem="1.2.840.114350.1.13.5636.1.7.3.688882.8100" codeSystemName="Epic.Encounter.Contents"/>
                                </externalObservation>
                            </reference>
                        </encounter>
                    </entry>
                    <entry>
                        <encounter classCode="ACT" moodCode="EVN">
                            <entryRelationship typeCode="SUBJ">
                                <observation classCode="OBS" moodCode="EVN">
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.4"/>
                                    <templateId extension="2016-12-01" root="2.16.840.1.113883.10.20.15.2.3.5"/>
                                    <id root="7183E4FC-DC67-11E8-B3B2-5B047B03C2DC"/>
                                    <code code="75322-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Complaint">
                                        <originalText>
                                            <reference value="#manualEncounter"/>
                                        </originalText>
                                        <translation code="409586006" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Complaint"/>
                                    </code>
                                    <statusCode code="completed"/>
                                    <effectiveTime>
                                        <low value="20181030121545"/>
                                    </effectiveTime>
                                    <value nullFlavor="OTH" xsi:type="CD">
                                        <originalText>eICR triggered with opioid overdose.</originalText>
                                    </value>
                                </observation>
                            </entryRelationship>
                        </encounter>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.17"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.17"/>
                    <code code="29762-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Social history"/>
                    <title>Social History</title>
                    <text>
                        <br/>
                        <table styleCode="subSect2">
                            <colgroup>
                                <col width="25%"/>
                                <col width="25%"/>
                                <col width="13%"/>
                                <col width="12%"/>
                                <col width="25%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Tobacco Use</th>
                                    <th>Types</th>
                                    <th>Packs/Day</th>
                                    <th>Years Used</th>
                                    <th>Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>Never Smoker</td>
                                    <td/>
                                    <td/>
                                    <td/>
                                    <td/>
                                </tr>
                                <tr>
                                    <td>Smokeless Tobacco: Never Used</td>
                                    <td/>
                                    <td colspan="2"/>
                                    <td/>
                                </tr>
                            </tbody>
                        </table>
                        <br/>
                        <table styleCode="subSect2">
                            <colgroup>
                                <col width="25%"/>
                                <col width="75%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Sex Assigned at Birth</th>
                                    <th>Date Recorded</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr ID="BirthSex19">
                                    <td ID="BirthSex19Value">Female</td>
                                    <td/>
                                </tr>
                            </tbody>
                        </table>
                        <footnote ID="subTitle17" styleCode="xSectionSubTitle xHidden">as of this
                            encounter</footnote>
                    </text>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <templateId root="2.16.840.1.113883.10.20.22.4.78"/>
                            <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.78"/>
                            <id extension="Z93796^64945^72166-2" root="1.2.840.114350.1.13.5636.1.7.1.1040.1"/>
                            <code code="72166-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Tobacco smoking status NHIS"/>
                            <statusCode code="completed"/>
                            <effectiveTime value="20181024"/>
                            <value code="266919005" codeSystem="2.16.840.1.113883.6.96" displayName="Never smoker" xsi:type="CD"/>
                        </observation>
                    </entry>
                    <entry>
                        <observation classCode="OBS" moodCode="EVN">
                            <templateId extension="2016-06-01" root="2.16.840.1.113883.10.20.22.4.200"/>
                            <code code="76689-9" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Sex Assigned At Birth"/>
                            <text>
                                <reference value="#BirthSex19"/>
                            </text>
                            <statusCode code="completed"/>
                            <value code="F" codeSystem="2.16.840.1.113883.5.1" xsi:type="CD">
                                <originalText>
                                    <reference value="#BirthSex19Value"/>
                                </originalText>
                            </value>
                        </observation>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.2"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.2"/>
                    <templateId root="2.16.840.1.113883.10.20.22.2.2.1"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.2.1"/>
                    <id root="716A249A-DC67-11E8-B3B2-5B047B03C2DC"/>
                    <code code="11369-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="HISTORY OF IMMUNIZATIONS"/>
                    <title>Immunizations</title>
                    <text>
                        <br/>
                        <table styleCode="subSect2">
                            <colgroup>
                                <col width="25%"/>
                                <col width="50%"/>
                                <col width="25%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Dates Previously Given</th>
                                    <th>Next Due</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr ID="immunization3">
                                    <td ID="immunization3Name">Influenza Virus Vaccine - Whole</td>
                                    <td>
                                        <content>3/26/18</content>
                                    </td>
                                    <td/>
                                </tr>
                            </tbody>
                        </table>
                        <footnote ID="subTitle2" styleCode="xSectionSubTitle xHidden">as of this
                            encounter</footnote>
                    </text>
                    <entry>
                        <substanceAdministration classCode="SBADM" moodCode="EVN" negationInd="false">
                            <templateId root="2.16.840.1.113883.10.20.22.4.52"/>
                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.52"/>
                            <id extension="28496" root="1.2.840.114350.1.13.5636.1.7.2.768076"/>
                            <code code="IMMUNIZ" codeSystem="2.16.840.1.113883.5.4" codeSystemName="ActCode"/>
                            <text>
                                <reference value="#immunization3"/>
                            </text>
                            <statusCode code="completed"/>
                            <effectiveTime value="20180326"/>
                            <consumable typeCode="CSM">
                                <manufacturedProduct classCode="MANU">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.54"/>
                                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.54"/>
                                    <manufacturedMaterial>
                                        <code nullFlavor="UNK">
                                            <originalText>
                                                <reference value="#immunization3Name"/>
                                            </originalText>
                                        </code>
                                        <lotNumberText nullFlavor="UNK"/>
                                    </manufacturedMaterial>
                                </manufacturedProduct>
                            </consumable>
                        </substanceAdministration>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.10"/>
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.2.10"/>
                    <code code="18776-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Treatment plan"/>
                    <title>Plan of Treatment</title>
                    <text>
                        <br/>
                        <table styleCode="subSect2">
                            <caption>Scheduled Tests</caption>
                            <colgroup>
                                <col width="40%"/>
                                <col width="10%"/>
                                <col width="25%"/>
                                <col width="25%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Priority</th>
                                    <th>Associated Diagnoses</th>
                                    <th>Order Schedule</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr ID="procedure10">
                                    <td ID="procedure10name">Methadone [Presence] in Urine by Screen method</td>
                                    <td>Routine</td>
                                    <td/>
                                    <td ID="procedure10schedule">Once for 1 Occurrences starting
                                        7/23/18 until 7/23/18</td>
                                </tr>
                            </tbody>
                        </table>
                        <footnote ID="subTitle8" styleCode="xSectionSubTitle xHidden">as of this
                            encounter</footnote>
                    </text>
                    <entry>
                        <observation classCode="OBS" moodCode="INT">
                            <templateId root="2.16.840.1.113883.10.20.22.4.44"/>
                            <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.44"/>
                            <id extension="2659443-6261" root="1.2.840.114350.1.13.5636.1.7.1.1988.1"/>
                            <code code="19550-3 " codeSystem="2.16.840.1.113883.6.12" codeSystemName="CPT-4" displayName="Methadone [Presence] in Urine by Screen method">
                                <originalText>
                                    <reference value="#procedure10name"/>
                                </originalText>
                            </code>
                            <text>
                                <reference value="#procedure10"/>
                            </text>
                            <statusCode code="active"/>
                            <effectiveTime>
                                <high value="20180723"/>
                            </effectiveTime>
                            <entryRelationship typeCode="COMP">
                                <act classCode="ACT" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.64"/>
                                    <code code="48767-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Annotation comment"/>
                                    <text>
                                        <reference value="#procedure10schedule"/>
                                    </text>
                                    <statusCode code="completed"/>
                                </act>
                            </entryRelationship>
                        </observation>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.3"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.3"/>
                    <templateId root="2.16.840.1.113883.10.20.22.2.3.1"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.3.1"/>
                    <id root="717F6E72-DC67-11E8-B3B2-5B047B03C2DC"/>
                    <code code="30954-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="STUDIES SUMMARY"/>
                    <title>Results</title>
                    <text>
                        <list styleCode="TOC">
                            <item ID="Result2660911">
                                <caption>Methadone [Presence] in Urine by Screen method (Tue Aug 7, 2018 10:42 AM)</caption>
                                <br/>
                                <table styleCode="subSect2">
                                    <colgroup>
                                        <col width="25%"/>
                                        <col width="30%"/>
                                        <col width="25%"/>
                                        <col width="20%"/>
                                    </colgroup>
                                    <thead>
                                        <tr>
                                            <th>Component</th>
                                            <th>Value</th>
                                            <th>Ref Range</th>
                                            <th>Performed At</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr ID="Result2660911Comp1">
                                            <td ID="Result2660911Comp1Name">Urine</td>
                                            <td>
                                                <content styleCode="flagData">3</content>
                                                <content styleCode="flagData"> (A)</content>
                                                <content styleCode="allIndent">
                                                    <content styleCode="cellHeader">Comment: </content>
                                                    <content ID="Result2660911Comp1Comment">From the
                                                  Results Generator</content>
                                                </content>
                                            </td>
                                            <td>3.5 - 5.0</td>
                                            <td/>
                                        </tr>
                                    </tbody>
                                </table>
                                <br/>
                                <table styleCode="subSect2">
                                    <colgroup>
                                        <col width="25%"/>
                                    </colgroup>
                                    <thead>
                                        <tr>
                                            <th>Specimen</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td ID="Result2660911Specimen">Urine</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </item>
                        </list>
                        <footnote ID="subTitle16" styleCode="xSectionSubTitle xHidden">documented in
                            this encounter</footnote>
                    </text>
                    <entry typeCode="DRIV">
                        <organizer classCode="BATTERY" moodCode="EVN">
                            <templateId root="2.16.840.1.113883.10.20.22.4.1"/>
                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.1"/>
                            <id extension="2660910" root="1.2.840.114350.1.13.5636.1.7.2.798268"/>
                            <code code="19550-3 " codeSystem="2.16.840.1.113883.6.12" codeSystemName="SNOMED CT">
                                <originalText>Methadone [Presence] in Urine by Screen method</originalText>
                            </code>
                            <statusCode code="completed"/>
                            <effectiveTime>
                                <low value="20180807144234+0000"/>
                                <high value="20180807144234+0000"/>
                            </effectiveTime>
                            <specimen typeCode="SPC">
                                <specimenRole classCode="SPEC">
                                    <id extension="2660910" root="1.2.840.114350.1.13.5636.1.7.7.798268.300"/>
                                    <specimenPlayingEntity>
                                        <code code="420135007" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT">
                                            <translation code="70" codeSystem="1.2.840.114350.1.13.5636.1.7.4.798268.300" codeSystemName="Epic.Specimen" displayName="Urine"/>
                                        </code>
                                    </specimenPlayingEntity>
                                </specimenRole>
                            </specimen>
                            <component>
                                <observation classCode="OBS" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.2"/>
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.2"/>
                                    <id extension="2660910.1" root="1.2.840.114350.1.13.5636.1.7.6.798268.2000"/>
                                    <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" nullFlavor="UNK">
                                        <originalText>Urine<reference value="#Result2660910Comp1Name"/>
                                        </originalText>
                                        <translation code="1" codeSystem="1.2.840.114350.1.13.5636.1.7.2.768282" codeSystemName="Epic.LRR.ID" displayName="Urine"/>
                                    </code>
                                    <text>
                                        <reference value="#Result2660910Comp1"/>
                                    </text>
                                    <statusCode code="completed"/>
                                    <effectiveTime value="20180807154234+0000"/>
                                    <value value="2" xsi:type="REAL"/>
                                    <interpretationCode code="A" codeSystem="2.16.840.1.113883.5.83">
                                        <originalText>Abnormal</originalText>
                                    </interpretationCode>
                                    <entryRelationship typeCode="COMP">
                                        <act classCode="ACT" moodCode="EVN">
                                            <templateId root="2.16.840.1.113883.10.20.22.4.64"/>
                                            <code code="48767-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Annotation comment"/>
                                            <text>
                                                <reference value="#Result2660910Comp1Comment"/>
                                            </text>
                                            <statusCode code="completed"/>
                                        </act>
                                    </entryRelationship>
                                    <referenceRange>
                                        <observationRange>
                                            <text>3.5 - 5.0</text>
                                            <value xsi:type="IVL_PQ">
                                                <low nullFlavor="OTH">
                                                    <translation nullFlavor="OTH" value="3.5">
                                                        <originalText>
                                                            <reference nullFlavor="UNK"/>
                                                        </originalText>
                                                    </translation>
                                                </low>
                                                <high nullFlavor="OTH">
                                                    <translation nullFlavor="OTH" value="5">
                                                        <originalText>
                                                            <reference nullFlavor="UNK"/>
                                                        </originalText>
                                                    </translation>
                                                </high>
                                            </value>
                                            <interpretationCode code="N" codeSystem="2.16.840.1.113883.5.83"/>
                                        </observationRange>
                                    </referenceRange>
                                </observation>
                            </component>
                            <component>
                                <observation classCode="OBS" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.2"/>
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.2"/>
                                    <templateId root="1.2.840.114350.1.72.3.3"/>
                                    <id extension="2660910" root="1.2.840.114350.1.13.5636.1.7.2.798268"/>
                                    <code code="56850-1" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC">
                                        <originalText>Lab Interpretation</originalText>
                                    </code>
                                    <text>
                                        <reference nullFlavor="UNK"/>
                                    </text>
                                    <statusCode code="completed"/>
                                    <effectiveTime value="20180807154234+0000"/>
                                    <value xsi:type="ST">Abnormal</value>
                                </observation>
                            </component>
                            <component typeCode="COMP">
                                <encounter classCode="ENC" moodCode="EVN">
                                    <id extension="10000184264" root="1.2.840.114350.1.13.5636.1.7.3.698084.8"/>
                                    <code code="3" codeSystem="1.2.840.114350.1.13.5636.1.7.4.698084.30" codeSystemName="Epic.EncounterType" displayName="Hospital Encounter"/>
                                    <effectiveTime>
                                        <low value="20180612154600-0500"/>
                                    </effectiveTime>
                                </encounter>
                            </component>
                        </organizer>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="2.16.840.1.113883.10.20.22.2.5"/>
                    <templateId root="2.16.840.1.113883.10.20.22.2.5.1"/>
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.2.5.1"/>
                    <id root="7178D1C0-DC67-11E8-B3B2-5B047B03C2DC"/>
                    <code code="11450-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="PROBLEM LIST"/>
                    <title>Problems</title>
                    <text>
                        <br/>
                        <table styleCode="subSect2">
                            <colgroup>
                                <col width="75%"/>
                                <col width="25%"/>
                            </colgroup>
                            <thead>
                                <tr>
                                    <th>Active Problems</th>
                                    <th>Noted Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr ID="problem14" styleCode="normRow">
                                    <td ID="problem14name">Methadone Overdose</td>
                                    <td>10/30/18</td>
                                </tr>
                                <tr ID="problem13" styleCode="altRow">
                                    <td ID="problem13name">Altered Mental Status</td>
                                    <td>10/19/18</td>
                                </tr>
                            </tbody>
                        </table>
                    </text>
                    <entry>
                        <act classCode="ACT" moodCode="EVN">
                            <templateId root="2.16.840.1.113883.10.20.22.4.3"/>
                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.3"/>
                            <id extension="28438" root="1.2.840.114350.1.13.5636.1.7.2.768076"/>
                            <code code="CONC" codeSystem="2.16.840.1.113883.5.6" codeSystemName="HL7ActClass" displayName="Concern"/>
                            <statusCode code="active"/>
                            <effectiveTime>
                                <low value="20181019"/>
                            </effectiveTime>
                            <entryRelationship inversionInd="false" typeCode="SUBJ">
                                <observation classCode="OBS" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.4"/>
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.4"/>
                                    <id extension="28438" root="1.2.840.114350.1.13.5636.1.7.2.768076"/>
                                    <code code="64572001" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Condition">
                                        <translation code="75323-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Condition"/>
                                    </code>
                                    <text>
                                        <reference value="#problem13name"/>
                                    </text>
                                    <statusCode code="completed"/>
                                    <effectiveTime>
                                        <low value="20181019"/>
                                    </effectiveTime>
                                    <value code="295161000" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Methadone Overdose" xsi:type="CD">
                                        <originalText>
                                            <reference value="#problem13name"/>
                                        </originalText>
                                        <translation code="T40.3X1A" codeSystem="2.16.840.1.113883.6.90" codeSystemName="ICD-10-CM" displayName="Poisoning by methadone, accidental"/>
                                        <translation code="E850.1" codeSystem="2.16.840.1.113883.6.103" codeSystemName="ICD-9CM" displayName="Accidental Poisoning by Methadone"/>
                                    </value>
                                    <author>
                                        <templateId root="2.16.840.1.113883.10.20.22.4.119"/>
                                        <time value="20181024220538+0000"/>
                                        <assignedAuthor>
                                            <id extension="1" root="1.2.840.114350.1.13.5636.1.7.2.697780"/>
                                            <addr>
                                                <streetAddressLine>20 20th St</streetAddressLine>
                                                <city>Nashville</city>
                                                <state>TN</state>
                                                <postalCode>37243</postalCode>
                                                <country>USA</country>
                                            </addr>
                                            <telecom nullFlavor="UNK"/>
                                            <representedOrganization>
                                                <id extension="1000000277" root="2.16.840.1.113883.4.6"/>
                                                <name>TDH Healthcare</name>
                                                <telecom nullFlavor="UNK"/>
                                            </representedOrganization>
                                        </assignedAuthor>
                                    </author>
                                    <entryRelationship typeCode="REFR">
                                        <observation classCode="OBS" moodCode="EVN">
                                            <templateId root="2.16.840.1.113883.10.20.22.4.6"/>
                                            <code code="33999-4" codeSystem="2.16.840.1.113883.6.1" displayName="Status"/>
                                            <statusCode code="completed"/>
                                            <effectiveTime>
                                                <low value="20181019"/>
                                            </effectiveTime>
                                            <value code="55561003" codeSystem="2.16.840.1.113883.6.96" displayName="Active" xsi:type="CD"/>
                                        </observation>
                                    </entryRelationship>
                                </observation>
                            </entryRelationship>
                        </act>
                    </entry>
                    <entry>
                        <act classCode="ACT" moodCode="EVN">
                            <templateId root="2.16.840.1.113883.10.20.22.4.3"/>
                            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.3"/>
                            <id extension="28495" root="1.2.840.114350.1.13.5636.1.7.2.768076"/>
                            <code code="CONC" codeSystem="2.16.840.1.113883.5.6" codeSystemName="HL7ActClass" displayName="Concern"/>
                            <statusCode code="active"/>
                            <effectiveTime>
                                <low value="20181030"/>
                            </effectiveTime>
                            <entryRelationship inversionInd="false" typeCode="SUBJ">
                                <observation classCode="OBS" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.4"/>
                                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.4"/>
                                    <id extension="28495" root="1.2.840.114350.1.13.5636.1.7.2.768076"/>
                                    <code code="64572001" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Condition">
                                        <translation code="75323-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Condition"/>
                                    </code>
                                    <text>
                                        <reference value="#problem14name"/>
                                    </text>
                                    <statusCode code="completed"/>
                                    <effectiveTime>
                                        <low value="20181030"/>
                                    </effectiveTime>
                                    <value code="419284004" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Altered Mental Status" xsi:type="CD">
                                        <originalText>
                                            <reference value="#problem14name"/>
                                        </originalText>
                                        <translation code="R41.82" codeSystem="2.16.840.1.113883.6.90" codeSystemName="ICD-10-CM" displayName="Altered Mental Status"/>
                                        <translation code="780.97" codeSystem="2.16.840.1.113883.6.103" codeSystemName="ICD-9CM" displayName="Altered Mental Status"/>
                                    </value>
                                    <author>
                                        <templateId root="2.16.840.1.113883.10.20.22.4.119"/>
                                        <time value="20181030160234+0000"/>
                                        <assignedAuthor>
                                            <id extension="1" root="1.2.840.114350.1.13.5636.1.7.2.697780"/>
                                        </assignedAuthor>
                                    </author>
                                    <entryRelationship typeCode="REFR">
                                        <observation classCode="OBS" moodCode="EVN">
                                            <templateId root="2.16.840.1.113883.10.20.22.4.6"/>
                                            <code code="33999-4" codeSystem="2.16.840.1.113883.6.1" displayName="Status"/>
                                            <statusCode code="completed"/>
                                            <effectiveTime>
                                                <low value="20181030"/>
                                            </effectiveTime>
                                            <value code="55561003" codeSystem="2.16.840.1.113883.6.96" displayName="Active" xsi:type="CD"/>
                                        </observation>
                                    </entryRelationship>
                                </observation>
                            </entryRelationship>
                        </act>
                    </entry>
                </section>
            </component>
            <component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <section>
                    <templateId root="1.3.6.1.4.1.19376.1.5.3.1.3.4"/>
                    <code code="10164-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="HISTORY OF PRESENT ILLNESS"/>
                    <title>Miscellaneous Notes</title>
                    <text>
                        <list styleCode="TOC">
                            <item>
                                <caption>H&amp;P - Brown, Sarah - Fri Oct 19, 2018 5:28 PM
                                    CDT</caption>
                                <paragraph>
                                    <content styleCode="label">Formatting of this note may be
                                        different from the original.</content>
                                    <br/>
Minnie Mouse test
                                    hospital encounter H&amp;P note<br/>
                                <br/>
Patient Active Problem
                                    List <br/>
Diagnosis SNOMED CT(R) <br/>
? Methadone overdose
                        <br/>
                        <br/>
So this encounter should be picked
                                    up for Opioid Drug overdose reporting.</paragraph>
                </item>
            </list>
            <footnote ID="subTitle1" styleCode="xSectionSubTitle xHidden">documented in
                            this encounter</footnote>
        </text>
    </section>
</component>
<component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <section>
        <templateId root="2.16.840.1.113883.10.20.22.2.38"/>
        <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.2.38"/>
        <id root="7172F480-DC67-11E8-B3B2-5B047B03C2DC"/>
        <code code="29549-3" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="MEDICATIONS ADMINISTERED"/>
        <title>Administered Medications</title>
        <text>
            <table ID="admMedTable7">
                <caption>Active Administered Medications - up to 3 most recent
                                administrations</caption>
                <colgroup>
                    <col width="40%"/>
                    <col width="12%"/>
                    <col width="12%"/>
                    <col width="12%"/>
                    <col width="12%"/>
                    <col width="12%"/>
                </colgroup>
                <thead>
                    <tr>
                        <th>Medication Order</th>
                        <th>MAR Action</th>
                        <th>Action Date</th>
                        <th>Dose</th>
                        <th>Rate</th>
                        <th>Site</th>
                    </tr>
                </thead>
                <tbody>
                    <tr styleCode="normRow medRow">
                        <td styleCode="Rrule">
                            <paragraph ID="med5">Naloxone Hydrochloride (Narcan) nasal spray 40 MG/ML</paragraph>
                            <paragraph styleCode="indent">40 MG/ML, Nasal, Once</paragraph>
                        </td>
                        <td colspan="5"/>
                    </tr>
                    <tr styleCode="normRow xMergeUp">
                        <td styleCode="Rrule"/>
                        <td colspan="5"/>
                    </tr>
                    <tr styleCode="altRow medRow">
                        <td styleCode="Rrule">
                            <paragraph ID="med4">Naloxone Hydrochloride (Narcan) nasal spray 40 MG/ML</paragraph>
                            <paragraph styleCode="indent">40 MG/ML, Nasal, Once</paragraph>
                        </td>
                        <td colspan="5"/>
                    </tr>
                    <tr styleCode="altRow xMergeUp">
                        <td styleCode="Rrule"/>
                        <td colspan="5"/>
                    </tr>
                </tbody>
            </table>
            <footnote ID="subTitle6" styleCode="xSectionSubTitle xHidden">in this
                            encounter</footnote>
        </text>
        <entry>
            <substanceAdministration classCode="SBADM" moodCode="EVN">
                <templateId root="2.16.840.1.113883.10.20.22.4.16"/>
                <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16"/>
                <id extension="2659441" root="1.2.840.114350.1.13.5636.1.7.2.798268"/>
                <text>[Order 1 Start] Name: Naloxone Hydrochloride (Narcan) nasal spray 40 MG/ML
								Signed Summary: 40 mg/ml, nasal, once on 7/23/18 at 1730 [Order 1 End]
								[Order 2 Start] Name: aloxone Hydrochloride (Narcan) nasal spray 40 MG/ML
                                Signed Summary: 40 mg/ml, nasal, once on 7/23/18 at 1730 [Order 2 End]
                </text>
                <statusCode code="active"/>
                <effectiveTime xsi:type="IVL_TS">
                    <low value="20180723223000+0000"/>
                </effectiveTime>
                <routeCode code="C38284PO" codeSystem="2.16.840.1.113883.3.26.1.1" codeSystemName="NCI Thesaurus" displayName="Nasal"/>
                <doseQuantity unit="mg/ml" value="40"/>
                <consumable typeCode="CSM">
                    <manufacturedProduct classCode="MANU">
                        <templateId root="2.16.840.1.113883.10.20.22.4.23"/>
                        <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.23"/>
                        <manufacturedMaterial>
                            <code code="1725059" codeSystem="2.16.840.1.113883.6.88" codeSystemName="RXNorm" displayName="Naloxone Hydrochloride 40 MG/ML Nasal Spray">
                                <originalText>
                                    <reference value="#med5"/>
                                </originalText>
                            </code>
                        </manufacturedMaterial>
                    </manufacturedProduct>
                </consumable>
                <author>
                    <templateId root="2.16.840.1.113883.10.20.22.4.119"/>
                    <time value="20180723212022+0000"/>
                    <assignedAuthor>
                        <id root="2.16.840.1.113883.4.6"/>
                        <telecom nullFlavor="UNK"/>
                        <representedOrganization>
                            <id extension="1000000277" root="2.16.840.1.113883.4.6"/>
                            <name>TDH Healthcare Emergency Medicine</name>
                            <telecom use="WP" value="tel:+1-615-698-3212"/>
                        </representedOrganization>
                    </assignedAuthor>
                </author>
                <entryRelationship typeCode="REFR">
                    <observation classCode="OBS" moodCode="EVN">
                        <templateId root="2.16.840.1.113883.10.20.1.47"/>
                        <code code="33999-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Status"/>
                        <statusCode code="completed"/>
                        <value code="55561003" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Active" xsi:type="CE"/>
                    </observation>
                </entryRelationship>
                <entryRelationship inversionInd="true" typeCode="SUBJ">
                    <observation classCode="OBS" moodCode="EVN">
                        <code code="FREQUENCY"/>
                        <value xsi:type="ST">once
                        </value>
                    </observation>
                </entryRelationship>
            </substanceAdministration>
        </entry>
    </section>
</component>
<component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <section>
        <templateId root="2.16.840.1.113883.10.20.22.2.12"/>
        <code code="29299-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="REASON FOR VISIT"/>
        <title>Reason for Visit</title>
        <text>
            <list>
                <item>
                    <caption>Suspected Opioid overdose</caption>
                    <br/>
                    <table styleCode="subSect2">
                        <colgroup>
                            <col width="16%"/>
                            <col width="16%"/>
                            <col width="18%"/>
                            <col width="16%"/>
                            <col width="16%"/>
                            <col width="18%"/>
                        </colgroup>
                        <thead>
                            <tr>
                                <th>Status</th>
                                <th>Reason</th>
                                <th>Specialty</th>
                                <th>Diagnoses / Procedures</th>
                                <th>Referred By Contact</th>
                                <th>Referred To Contact</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td styleCode="flagData">Pending Review</td>
                                <td>
                                    <paragraph>Specialty Services Required</paragraph>
                                </td>
                                <td>Condition</td>
                                <td>
                                    <paragraph styleCode="cellHeader">Diagnosis</paragraph>
                                    <paragraph>Methadone Urine Screen</paragraph>
                                </td>
                                <td>
                                    <paragraph>Sailor, Provider Adam, MD</paragraph>
                                    <paragraph>710 James Robertson Parkway</paragraph>
                                    <paragraph>Nashville. TN 37234</paragraph>
                                    <paragraph>Phone: 615-222-3304</paragraph>
                                </td>
                                <td>
                                    <paragraph/>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <br/>
                </item>
            </list>
        </text>
    </section>
</component>
<component>
    <section>
        <code code="123-4567" codeSystem="Local-codesystem-oid" codeSystemName="LocalSystem" displayName="Interested Parties Section"/>
        <title>INTERESTED PARTIES SECTION</title>
        <entry typeCode="COMP">
            <act classCode="ACT" moodCode="EVN">
                <code code="PSN" codeSystem="Local-codesystem-oid" codeSystemName="LocalSystem" displayName="Interested Party"/>
                <participant typeCode="PRF">
                    <participantRole>
                        <id extension="CSR1001000XX01" root="2.16.840.1.113883.11.19745" assigningAuthorityName="LR"/>
                        <addr>
                            <streetAddressLine><![CDATA[755 Jefferson Avenue]]></streetAddressLine>
                            <city><![CDATA[Nashville]]></city>
                            <postalCode><![CDATA[37243]]></postalCode>
                            <state><![CDATA[47^Tennessee^FIPS 5-2(State)]]></state>
                            <country><![CDATA[USA^UNITED STATES^Country (ISO 3166-1)]]></country>
                        </addr>
                        <addr/>
                        <addr/>
                        <addr/>
                        <addr/>
                        <telecom use="WP" value="tel:+1-615-698-3212"/>
                        <playingEntity>
                            <name use="L">
                                <given><![CDATA[Sarah]]></given>
                                <family><![CDATA[Brown]]></family>
                            </name>
                        </playingEntity>
                    </participantRole>
                </participant>
            </act>
        </entry>
        <entry typeCode="COMP">
            <act classCode="ACT" moodCode="EVN">
                <code code="PSN" codeSystem="Local-codesystem-oid" codeSystemName="LocalSystem" displayName="Interested Party"/>
                <participant typeCode="PRF">
                    <participantRole>
                        <id extension="CSR1001001XX01" root="2.16.840.1.113883.11.19745" assigningAuthorityName="LR"/>
                        <playingEntity>
                            <name use="L">
                                <given><![CDATA[Sarah]]></given>
                                <family><![CDATA[Brown]]></family>
                            </name>
                        </playingEntity>
                    </participantRole>
                </participant>
            </act>
        </entry>
        <entry typeCode="COMP">
            <act classCode="ACT" moodCode="EVN">
                <code code="ORG" codeSystem="Local-codesystem-oid" codeSystemName="LocalSystem" displayName="Interested Party"/>
                <participant typeCode="PRF">
                    <participantRole>
                        <id root="2.16.840.1.113883.4.6" extension="CSR1001003XX01" assigningAuthorityName="LR"/>
                        <addr use="WP">
                            <streetAddressLine><![CDATA[20 20th St]]></streetAddressLine>
                            <city><![CDATA[Atlanta]]></city>
                            <state><![CDATA[13^Georgia^FIPS 5-2(State)]]></state>
                            <postalCode><![CDATA[30329]]></postalCode>
                            <country><![CDATA[USA^UNITED STATES^Country (ISO 3166-1)]]></country>
                        </addr>
                        <addr/>
                        <addr/>
                        <addr/>
                        <addr/>
                        <addr/>
                        <telecom use="WP" value="tel:+1-615-698-3212"/>
                        <playingEntity>
                            <name><![CDATA[TDH Healthcare]]></name>
                        </playingEntity>
                    </participantRole>
                </participant>
            </act>
        </entry>
    </section>
</component>
        </structuredBody>
    </component>
</ClinicalDocument>"""

# Template for the original payload (can be same or different, usually somewhat similar in structure)
# Simplified for this script to largely match the payload but with different wrapper if needed.
# For this purpose, we will use a slightly simplified version of the payload template or the same one.
# The example SQL shows a slightly different structure for original payload (Initial Public Health Case Report).
ORIGINAL_PAYLOAD_TEMPLATE = """<?xml version="1.0" encoding="windows-1252" ?>
<?xml-stylesheet type="text/xsl" href="../../transform/cda.xsl"?>
<ClinicalDocument xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:voc="http://www.lantanagroup.com/voc" xmlns="urn:hl7-org:v3"
    xmlns:cda="urn:hl7-org:v3" xmlns:sdtc="urn:hl7-org:sdtc" xsi:schemaLocation="urn:hl7-org:v3 ../../schema/infrastructure/cda/CDA_SDTC.xsd">
    <realmCode code="US"/>
    <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3"/>
    <id assigningAuthorityName="EPC" root="1.2.840.114350.1.13.5636.1.7.8.688883.215011"/>
    <code code="55751-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC"
        displayName="Initial Public Health Case Report"/>
    <title>Initial Public Health Case Report</title>
    <effectiveTime value="{EFFECTIVE_TIME}"/>
    <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" displayName="Normal"/>
    <languageCode code="en-US"/>
    <recordTarget>
        <patientRole>
            <id assigningAuthorityName="EPI" root="1.2.840.114350.1.13.1.1.7.2.698084"
                extension="{PATIENT_ID}"/>
            <addr use="HP">
                <streetAddressLine>{STREET}</streetAddressLine>
                <city>{CITY}</city>
                <state>{STATE_CODE}</state>
                <postalCode>{ZIP}</postalCode>
                <country>USA</country>
            </addr>
            <telecom use="HP" value="tel:+1-615-080-1212"/>
            <patient>
                <name use="L">
                    <given>{FIRST_NAME}</given>
                    <family>{LAST_NAME}</family>
                </name>
                <administrativeGenderCode code="{GENDER_CODE}" codeSystem="2.16.840.1.113883.5.1"
                    codeSystemName="AdministrativeGenderCode" displayName="{GENDER_DISPLAY}"/>
                <birthTime value="{DOB}"/>
            </patient>
        </patientRole>
    </recordTarget>
</ClinicalDocument>"""


def generate_random_data():
    """Generates a dictionary of random data for the templates."""
    gender = random.choice([('M', 'Male'), ('F', 'Female')])
    
    # Generate a random ID
    msg_id = ''.join(random.choices(string.digits, k=20))
    # Generate Patient ID
    pat_id = 'CSR' + ''.join(random.choices(string.digits, k=8))
    
    # Date of Birth (last 90 years)
    dob = fake.date_of_birth(minimum_age=1, maximum_age=90)
    dob_str = dob.strftime("%Y%m%d")
    
    # Effective Time (now)
    now = datetime.now()
    eff_time_str = now.strftime("%Y%m%d%H%M%S")
    
    # Restrict to Georgia
    state_code = "13"
    state_name = "Georgia"
    city = random.choice(GA_CITIES)
    
    return {
        'MESSAGE_ID': msg_id,
        'EFFECTIVE_TIME': eff_time_str,
        'PATIENT_ID': pat_id,
        'FIRST_NAME': fake.first_name(),
        'LAST_NAME': fake.last_name(),
        'STREET': fake.street_address(),
        'CITY': city,
        'STATE_CODE': state_code,
        'STATE_NAME': state_name,
        'ZIP': fake.zipcode_in_state("GA"),
        'GENDER_CODE': gender[0],
        'GENDER_DISPLAY': gender[1],
        'DOB': dob_str
    }

def generate_eicr_content(data):
    """Generates the filled XML strings."""
    payload = PAYLOAD_TEMPLATE.format(**data)
    original_payload = ORIGINAL_PAYLOAD_TEMPLATE.format(**data)
    return payload, original_payload

def generate_sql_insert(payload, original_payload):
    """Generates the SQL INSERT statement."""
    # Escape single quotes for SQL
    payload_sql = payload.replace("'", "''")
    original_payload_sql = original_payload.replace("'", "''")
    
    sql = f"""INSERT INTO [dbo].[NBS_interface] (
    payload,
    imp_exp_ind_cd,
    record_status_cd,
    record_status_time,
    add_time,
    system_nm,
    doc_type_cd,
    original_payload,
    original_doc_type_cd
) VALUES (
    N'{payload_sql}',
    N'I',
    N'QUEUED',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    N'NBS',
    N'PHC236',
    N'{original_payload_sql}',
    N'2.16.840.1.113883.10.20.15.2^2022-05-01'
);"""
    return sql

def main():
    parser = argparse.ArgumentParser(description="Generate random eICR XMLs and SQL loading script")
    parser.add_argument("-n", "--count", type=int, default=1, help="Number of records to generate")
    parser.add_argument("-o", "--output-dir", type=str, help="Optional: Output directory to save individual XML files")
    
    args = parser.parse_args()
    
    print("USE [NBS_MSGOUTE];", file=sys.stdout)
    print("GO", file=sys.stdout)
    print("", file=sys.stdout)

    if args.output_dir and not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)

    for i in range(args.count):
        data = generate_random_data()
        payload, original_payload = generate_eicr_content(data)
        
        if args.output_dir:
            filename = f"eICR_{data['MESSAGE_ID']}.xml"
            with open(os.path.join(args.output_dir, filename), 'w') as f:
                f.write(payload)
        
        sql = generate_sql_insert(payload, original_payload)
        print(sql, file=sys.stdout)
        print("GO", file=sys.stdout) # Good practice for batch inserts in SQL Server

if __name__ == "__main__":
    main()
