#!/usr/bin/env python3
"""
HL7 to XML Converter
Converts HL7 v2.5.1 ELR messages to CDC NEDSS Container XML format.

Usage:
    python convert.py < message.hl7 > message.xml
    
    # Output as SQL INSERT statement:
    cat message.hl7 | python convert.py --sql > insert.sql
"""

import sys
import argparse
import xml.etree.ElementTree as ET
from xml.dom import minidom

FIELD_SEP = '|'
COMPONENT_SEP = '^'
SUBCOMPONENT_SEP = '&'

NEDSS_NS = "http://www.cdc.gov/NEDSS"


def parse_hl7_message(hl7_text):
    """Parse an HL7 message into segments and fields"""

    hl7_text = hl7_text.replace('\n', '\r').replace('\r\r', '\r')
    segments = [s for s in hl7_text.split('\r') if s.strip()]
    
    parsed_segments = []
    for segment in segments:
        fields = segment.split('|')
        segment_name = fields[0]
        
        # MSH segment is special - MSH-1 is the field separator itself
        if segment_name == 'MSH':
            fields = ['MSH', '|'] + segment.split('|')[1:]
        
        parsed_segments.append({
            'name': segment_name,
            'fields': fields
        })
    
    return parsed_segments


def parse_components(field_value, component_sep='^', subcomponent_sep='&'):
    """Parse a field into components and subcomponents"""
    if not field_value:
        return []
    
    components = field_value.split(component_sep)
    parsed = []
    for comp in components:
        if subcomponent_sep in comp:
            parsed.append(comp.split(subcomponent_sep))
        else:
            parsed.append(comp)
    return parsed


def parse_hl7_datetime(dt_string):
    """Parse HL7 datetime string into components"""
    if not dt_string:
        return {}
    
    result = {}
    if len(dt_string) >= 4:
        result['year'] = dt_string[0:4]
    if len(dt_string) >= 6:
        result['month'] = dt_string[4:6]
    if len(dt_string) >= 8:
        result['day'] = dt_string[6:8]
    if len(dt_string) >= 10:
        result['hours'] = dt_string[8:10]
    if len(dt_string) >= 12:
        result['minutes'] = dt_string[10:12]
    if len(dt_string) >= 14:
        result['seconds'] = dt_string[12:14]
    
    # Handle timezone offset if present
    if len(dt_string) > 14:
        result['gmtOffset'] = dt_string[14:]
    else:
        result['gmtOffset'] = ''
    
    return result


def add_datetime_element(parent, dt_string, skip_empty_time=False):
    """Add datetime sub-elements to a parent element
    
    Args:
        parent: Parent XML element
        dt_string: HL7 datetime string
        skip_empty_time: If True, don't output hours/minutes/seconds/gmtOffset when empty
    """
    dt_parts = parse_hl7_datetime(dt_string)
    
    # Always output date components
    for key in ['year', 'month', 'day']:
        elem = ET.SubElement(parent, key)
        elem.text = dt_parts.get(key, '')
    
    # Output time components (optionally skip if empty)
    for key in ['hours', 'minutes', 'seconds', 'gmtOffset']:
        value = dt_parts.get(key, '')
        if skip_empty_time and not value:
            continue
        elem = ET.SubElement(parent, key)
        elem.text = value


def add_element(parent, tag, text=''):
    """Helper to add an element with text"""
    elem = ET.SubElement(parent, tag)
    if text:
        elem.text = str(text)
    return elem


def convert_msh_to_xml(segment, parent):
    """Convert MSH segment to XML"""
    fields = segment['fields']
    msh = ET.SubElement(parent, 'HL7MSH')
    
    add_element(msh, 'FieldSeparator', '|')
    add_element(msh, 'EncodingCharacters', fields[2] if len(fields) > 2 else '^~\\&')
    
    # MSH-3: Sending Application
    if len(fields) > 3 and fields[3]:
        sending_app = ET.SubElement(msh, 'SendingApplication')
        comps = parse_components(fields[3])
        add_element(sending_app, 'HL7NamespaceID', comps[0] if len(comps) > 0 else '')
        add_element(sending_app, 'HL7UniversalID', comps[1] if len(comps) > 1 else '')
        add_element(sending_app, 'HL7UniversalIDType', comps[2] if len(comps) > 2 else '')
    
    # MSH-4: Sending Facility
    if len(fields) > 4 and fields[4]:
        sending_fac = ET.SubElement(msh, 'SendingFacility')
        comps = parse_components(fields[4])
        add_element(sending_fac, 'HL7NamespaceID', comps[0] if len(comps) > 0 else '')
        add_element(sending_fac, 'HL7UniversalID', comps[1] if len(comps) > 1 else '')
        add_element(sending_fac, 'HL7UniversalIDType', comps[2] if len(comps) > 2 else '')
    
    # MSH-5: Receiving Application
    if len(fields) > 5 and fields[5]:
        recv_app = ET.SubElement(msh, 'ReceivingApplication')
        comps = parse_components(fields[5])
        add_element(recv_app, 'HL7NamespaceID', comps[0] if len(comps) > 0 else '')
        add_element(recv_app, 'HL7UniversalID', comps[1] if len(comps) > 1 else '')
        add_element(recv_app, 'HL7UniversalIDType', comps[2] if len(comps) > 2 else '')
    
    # MSH-6: Receiving Facility
    if len(fields) > 6 and fields[6]:
        recv_fac = ET.SubElement(msh, 'ReceivingFacility')
        comps = parse_components(fields[6])
        add_element(recv_fac, 'HL7NamespaceID', comps[0] if len(comps) > 0 else '')
        add_element(recv_fac, 'HL7UniversalID', comps[1] if len(comps) > 1 else '')
        add_element(recv_fac, 'HL7UniversalIDType', comps[2] if len(comps) > 2 else '')
    
    # MSH-7: Date/Time of Message
    dt_msg = ET.SubElement(msh, 'DateTimeOfMessage')
    add_datetime_element(dt_msg, fields[7] if len(fields) > 7 else '')
    
    # MSH-8: Security
    add_element(msh, 'Security', fields[8] if len(fields) > 8 else '')
    
    # MSH-9: Message Type
    if len(fields) > 9 and fields[9]:
        msg_type = ET.SubElement(msh, 'MessageType')
        comps = parse_components(fields[9])
        add_element(msg_type, 'MessageCode', comps[0] if len(comps) > 0 else '')
        add_element(msg_type, 'TriggerEvent', comps[1] if len(comps) > 1 else '')
        add_element(msg_type, 'MessageStructure', comps[2] if len(comps) > 2 else '')
    
    # MSH-10: Message Control ID
    add_element(msh, 'MessageControlID', fields[10] if len(fields) > 10 else '')
    
    # MSH-11: Processing ID
    proc_id = ET.SubElement(msh, 'ProcessingID')
    if len(fields) > 11 and fields[11]:
        comps = parse_components(fields[11])
        add_element(proc_id, 'HL7ProcessingID', comps[0] if len(comps) > 0 else '')
        add_element(proc_id, 'HL7ProcessingMode', comps[1] if len(comps) > 1 else '')
    else:
        add_element(proc_id, 'HL7ProcessingID', '')
        add_element(proc_id, 'HL7ProcessingMode', '')
    
    # MSH-12: Version ID
    ver_id = ET.SubElement(msh, 'VersionID')
    add_element(ver_id, 'HL7VersionID', fields[12] if len(fields) > 12 else '')
    
    # MSH-15: Accept Acknowledgment Type
    add_element(msh, 'AcceptAcknowledgmentType', fields[15] if len(fields) > 15 else '')
    
    # MSH-16: Application Acknowledgment Type
    add_element(msh, 'ApplicationAcknowledgmentType', fields[16] if len(fields) > 16 else '')
    
    # MSH-17: Country Code
    add_element(msh, 'CountryCode', fields[17] if len(fields) > 17 else '')
    
    # MSH-18: Character Set
    add_element(msh, 'CharacterSet', fields[18] if len(fields) > 18 else '')
    
    # MSH-21: Message Profile Identifier
    if len(fields) > 21 and fields[21]:
        profile = ET.SubElement(msh, 'MessageProfileIdentifier')
        comps = parse_components(fields[21])
        add_element(profile, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(profile, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(profile, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(profile, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    return msh


def convert_sft_to_xml(segment, parent):
    """Convert SFT segment to XML"""
    fields = segment['fields']
    sft = ET.SubElement(parent, 'HL7SoftwareSegment')
    
    # SFT-1: Software Vendor Organization
    vendor = ET.SubElement(sft, 'SoftwareVendorOrganization')
    if len(fields) > 1 and fields[1]:
        comps = parse_components(fields[1])
        add_element(vendor, 'HL7OrganizationName', comps[0] if len(comps) > 0 else '')
        add_element(vendor, 'HL7OrganizationNameTypeCode', comps[1] if len(comps) > 1 else '')
    add_element(vendor, 'HL7IDNumber')
    add_element(vendor, 'HL7CheckDigit')
    
    # SFT-2: Software Version
    add_element(sft, 'SoftwareCertifiedVersionOrReleaseNumber', fields[2] if len(fields) > 2 else '')
    
    # SFT-3: Software Product Name
    add_element(sft, 'SoftwareProductName', fields[3] if len(fields) > 3 else '')
    
    # SFT-4: Software Binary ID
    add_element(sft, 'SoftwareBinaryID', fields[4] if len(fields) > 4 else '')
    
    # SFT-5: Software Product Information
    add_element(sft, 'SoftwareProductInformation', fields[5] if len(fields) > 5 else '')
    
    return sft


def convert_pid_to_xml(segment, parent):
    """Convert PID segment to XML"""
    fields = segment['fields']
    pid = ET.SubElement(parent, 'PatientIdentification')
    
    # PID-1: Set ID
    set_id = ET.SubElement(pid, 'SetIDPID')
    add_element(set_id, 'HL7SequenceID', fields[1] if len(fields) > 1 else '')
    
    # PID-3: Patient Identifier List
    if len(fields) > 3 and fields[3]:
        pat_id = ET.SubElement(pid, 'PatientIdentifierList')
        comps = parse_components(fields[3])
        add_element(pat_id, 'HL7IDNumber', comps[0] if len(comps) > 0 else '')
        
        # Assigning Authority (component 4, which is index 3)
        if len(comps) > 3 and comps[3]:
            auth = ET.SubElement(pat_id, 'HL7AssigningAuthority')
            if isinstance(comps[3], list):
                subcomps = comps[3]
            else:
                subcomps = [comps[3]]
            add_element(auth, 'HL7NamespaceID', subcomps[0] if len(subcomps) > 0 else '')
            add_element(auth, 'HL7UniversalID', subcomps[1] if len(subcomps) > 1 else '')
            add_element(auth, 'HL7UniversalIDType', subcomps[2] if len(subcomps) > 2 else '')
        
        add_element(pat_id, 'HL7IdentifierTypeCode', comps[4] if len(comps) > 4 else '')
    
    # PID-5: Patient Name
    if len(fields) > 5 and fields[5]:
        pat_name = ET.SubElement(pid, 'PatientName')
        comps = parse_components(fields[5])
        
        family = ET.SubElement(pat_name, 'HL7FamilyName')
        add_element(family, 'HL7Surname', comps[0] if len(comps) > 0 else '')
        
        add_element(pat_name, 'HL7GivenName', comps[1] if len(comps) > 1 else '')
        add_element(pat_name, 'HL7Degree', comps[5] if len(comps) > 5 else '')
    
    # PID-7: Date/Time of Birth
    dob = ET.SubElement(pid, 'DateTimeOfBirth')
    add_datetime_element(dob, fields[7] if len(fields) > 7 else '', skip_empty_time=True)
    
    # PID-8: Administrative Sex
    add_element(pid, 'AdministrativeSex', fields[8] if len(fields) > 8 else '')
    
    # PID-10: Race
    if len(fields) > 10 and fields[10]:
        race = ET.SubElement(pid, 'Race')
        comps = parse_components(fields[10])
        add_element(race, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(race, 'HL7Text', comps[1] if len(comps) > 1 else '')
        add_element(race, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    # PID-11: Patient Address
    if len(fields) > 11 and fields[11]:
        addr = ET.SubElement(pid, 'PatientAddress')
        comps = parse_components(fields[11])
        
        street = ET.SubElement(addr, 'HL7StreetAddress')
        add_element(street, 'HL7StreetOrMailingAddress', comps[0] if len(comps) > 0 else '')
        
        add_element(addr, 'HL7City', comps[2] if len(comps) > 2 else '')
        add_element(addr, 'HL7StateOrProvince', comps[3] if len(comps) > 3 else '')
        add_element(addr, 'HL7ZipOrPostalCode', comps[4] if len(comps) > 4 else '')
        add_element(addr, 'HL7Country', comps[5] if len(comps) > 5 else '')
        add_element(addr, 'HL7AddressType', comps[6] if len(comps) > 6 else '')
    
    # PID-13: Phone Number - Home
    if len(fields) > 13 and fields[13]:
        phone = ET.SubElement(pid, 'PhoneNumberHome')
        comps = parse_components(fields[13])
        add_element(phone, 'HL7TelecommunicationUseCode', comps[1] if len(comps) > 1 else '')
        add_element(phone, 'HL7TelecommunicationEquipmentType', comps[2] if len(comps) > 2 else '')
        
        country = ET.SubElement(phone, 'HL7CountryCode')
        add_element(country, 'HL7Numeric', comps[4] if len(comps) > 4 else '')
        
        area = ET.SubElement(phone, 'HL7AreaCityCode')
        area_code = comps[5] if len(comps) > 5 else ''
        # Strip leading + from area code
        area_code = area_code.lstrip('+')
        add_element(area, 'HL7Numeric', area_code)
        
        local = ET.SubElement(phone, 'HL7LocalNumber')
        add_element(local, 'HL7Numeric', comps[6] if len(comps) > 6 else '')
        
        add_element(phone, 'HL7Extension')
    
    # PID-19: SSN - extract just the SSN value (first component)
    ssn_value = ''
    if len(fields) > 19 and fields[19]:
        ssn_comps = parse_components(fields[19])
        ssn_value = ssn_comps[0] if ssn_comps else ''
    add_element(pid, 'SSNNumberPatient', ssn_value)
    
    # PID-22: Ethnic Group
    if len(fields) > 22 and fields[22]:
        ethnic = ET.SubElement(pid, 'EthnicGroup')
        comps = parse_components(fields[22])
        add_element(ethnic, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(ethnic, 'HL7Text', comps[1] if len(comps) > 1 else '')
        add_element(ethnic, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    add_element(pid, 'BirthOrder')
    
    return pid


def convert_orc_to_xml(segment, parent):
    """Convert ORC segment to XML"""
    fields = segment['fields']
    orc = ET.SubElement(parent, 'CommonOrder')
    
    # ORC-1: Order Control
    add_element(orc, 'OrderControl', fields[1] if len(fields) > 1 else '')
    
    # ORC-2: Placer Order Number
    if len(fields) > 2 and fields[2]:
        placer = ET.SubElement(orc, 'PlacerOrderNumber')
        comps = parse_components(fields[2])
        add_element(placer, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(placer, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(placer, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(placer, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    # ORC-3: Filler Order Number
    if len(fields) > 3 and fields[3]:
        filler = ET.SubElement(orc, 'FillerOrderNumber')
        comps = parse_components(fields[3])
        add_element(filler, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(filler, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(filler, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(filler, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    # ORC-4: Placer Group Number (using same structure as Placer Order Number)
    if len(fields) > 2 and fields[2]:
        placer_grp = ET.SubElement(orc, 'PlacerGroupNumber')
        comps = parse_components(fields[2])
        add_element(placer_grp, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(placer_grp, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(placer_grp, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(placer_grp, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    # ORC-5: Order Status
    add_element(orc, 'OrderStatus', fields[5] if len(fields) > 5 else '')
    
    # ORC-9: Date/Time of Transaction
    dt_trans = ET.SubElement(orc, 'DateTimeOfTransaction')
    add_datetime_element(dt_trans, fields[9] if len(fields) > 9 else '')
    
    # ORC-12: Ordering Provider
    if len(fields) > 12 and fields[12]:
        provider = ET.SubElement(orc, 'OrderingProvider')
        comps = parse_components(fields[12])
        add_element(provider, 'HL7IDNumber', comps[0] if len(comps) > 0 else '')
        
        family = ET.SubElement(provider, 'HL7FamilyName')
        add_element(family, 'HL7Surname', comps[1] if len(comps) > 1 else '')
        
        add_element(provider, 'HL7GivenName', comps[2] if len(comps) > 2 else '')
        add_element(provider, 'HL7NameTypeCode', comps[9] if len(comps) > 9 else '')
        add_element(provider, 'HL7IdentifierTypeCode', comps[12] if len(comps) > 12 else '')
    
    # ORC-21: Ordering Facility Name
    if len(fields) > 21 and fields[21]:
        fac_name = ET.SubElement(orc, 'OrderingFacilityName')
        comps = parse_components(fields[21])
        add_element(fac_name, 'HL7OrganizationName', comps[0] if len(comps) > 0 else '')
        add_element(fac_name, 'HL7OrganizationNameTypeCode', comps[1] if len(comps) > 1 else '')
        add_element(fac_name, 'HL7IDNumber')
        add_element(fac_name, 'HL7CheckDigit')
        
        auth = ET.SubElement(fac_name, 'HL7AssigningAuthority')
        if len(comps) > 5 and comps[5]:
            if isinstance(comps[5], list):
                subcomps = comps[5]
            else:
                subcomps = comps[5].split('&')
            add_element(auth, 'HL7NamespaceID', subcomps[0] if len(subcomps) > 0 else '')
            add_element(auth, 'HL7UniversalID', subcomps[1] if len(subcomps) > 1 else '')
            add_element(auth, 'HL7UniversalIDType', subcomps[2] if len(subcomps) > 2 else '')
        
        add_element(fac_name, 'HL7IdentifierTypeCode', comps[6] if len(comps) > 6 else '')
        add_element(fac_name, 'HL7OrganizationIdentifier', comps[9] if len(comps) > 9 else '')
    
    # ORC-22: Ordering Facility Address
    if len(fields) > 22 and fields[22]:
        fac_addr = ET.SubElement(orc, 'OrderingFacilityAddress')
        comps = parse_components(fields[22])
        
        street = ET.SubElement(fac_addr, 'HL7StreetAddress')
        add_element(street, 'HL7StreetOrMailingAddress', comps[0] if len(comps) > 0 else '')
        
        add_element(fac_addr, 'HL7City', comps[2] if len(comps) > 2 else '')
        add_element(fac_addr, 'HL7StateOrProvince', comps[3] if len(comps) > 3 else '')
        add_element(fac_addr, 'HL7ZipOrPostalCode', comps[4] if len(comps) > 4 else '')
        add_element(fac_addr, 'HL7Country', comps[5] if len(comps) > 5 else '')
        add_element(fac_addr, 'HL7AddressType', comps[6] if len(comps) > 6 else '')
    
    # ORC-23: Ordering Facility Phone Number
    if len(fields) > 23 and fields[23]:
        fac_phone = ET.SubElement(orc, 'OrderingFacilityPhoneNumber')
        comps = parse_components(fields[23])
        add_element(fac_phone, 'HL7TelecommunicationUseCode', comps[1] if len(comps) > 1 else '')
        add_element(fac_phone, 'HL7TelecommunicationEquipmentType', comps[2] if len(comps) > 2 else '')
        
        country = ET.SubElement(fac_phone, 'HL7CountryCode')
        add_element(country, 'HL7Numeric', comps[4] if len(comps) > 4 else '')
        
        area = ET.SubElement(fac_phone, 'HL7AreaCityCode')
        add_element(area, 'HL7Numeric', comps[5] if len(comps) > 5 else '')
        
        local = ET.SubElement(fac_phone, 'HL7LocalNumber')
        add_element(local, 'HL7Numeric', comps[6] if len(comps) > 6 else '')
        
        add_element(fac_phone, 'HL7Extension')
    
    # ORC-24: Ordering Provider Address
    if len(fields) > 24 and fields[24]:
        prov_addr = ET.SubElement(orc, 'OrderingProviderAddress')
        comps = parse_components(fields[24])
        
        street = ET.SubElement(prov_addr, 'HL7StreetAddress')
        add_element(street, 'HL7StreetOrMailingAddress', comps[0] if len(comps) > 0 else '')
        
        add_element(prov_addr, 'HL7City', comps[2] if len(comps) > 2 else '')
        add_element(prov_addr, 'HL7StateOrProvince', comps[3] if len(comps) > 3 else '')
        add_element(prov_addr, 'HL7ZipOrPostalCode', comps[4] if len(comps) > 4 else '')
        add_element(prov_addr, 'HL7Country', comps[5] if len(comps) > 5 else '')
        add_element(prov_addr, 'HL7AddressType', comps[6] if len(comps) > 6 else '')
    
    return orc


def convert_obr_to_xml(segment, parent):
    """Convert OBR segment to XML"""
    fields = segment['fields']
    obr = ET.SubElement(parent, 'ObservationRequest')
    
    # OBR-1: Set ID
    set_id = ET.SubElement(obr, 'SetIDOBR')
    add_element(set_id, 'HL7SequenceID', fields[1] if len(fields) > 1 else '')
    
    # OBR-2: Placer Order Number
    if len(fields) > 2 and fields[2]:
        placer = ET.SubElement(obr, 'PlacerOrderNumber')
        comps = parse_components(fields[2])
        add_element(placer, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(placer, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(placer, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(placer, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    # OBR-3: Filler Order Number
    if len(fields) > 3 and fields[3]:
        filler = ET.SubElement(obr, 'FillerOrderNumber')
        comps = parse_components(fields[3])
        add_element(filler, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        add_element(filler, 'HL7NamespaceID', comps[1] if len(comps) > 1 else '')
        add_element(filler, 'HL7UniversalID', comps[2] if len(comps) > 2 else '')
        add_element(filler, 'HL7UniversalIDType', comps[3] if len(comps) > 3 else '')
    
    # OBR-4: Universal Service Identifier
    if len(fields) > 4 and fields[4]:
        svc_id = ET.SubElement(obr, 'UniversalServiceIdentifier')
        comps = parse_components(fields[4])
        add_element(svc_id, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(svc_id, 'HL7Text', comps[1] if len(comps) > 1 else '')
        add_element(svc_id, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    # OBR-7: Observation Date/Time
    obs_dt = ET.SubElement(obr, 'ObservationDateTime')
    add_datetime_element(obs_dt, fields[7] if len(fields) > 7 else '')
    
    # OBR-14: Specimen Received Date/Time
    spec_dt = ET.SubElement(obr, 'SpecimenReceivedDateTime')
    add_datetime_element(spec_dt, fields[14] if len(fields) > 14 else '')
    
    # OBR-15: Specimen Source
    if len(fields) > 15 and fields[15]:
        spec_src = ET.SubElement(obr, 'SpecimenSource')
        comps = parse_components(fields[15])
        
        src_name = ET.SubElement(spec_src, 'HL7SpecimenSourceNameOrCode')
        add_element(src_name, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        
        additives = ET.SubElement(spec_src, 'HL7Additives')
        add_element(additives, 'HL7Identifier', comps[1] if len(comps) > 1 else '')
        
        method = ET.SubElement(spec_src, 'HL7SpecimenCollectionMethod')
        add_element(method, 'HL7String', comps[2] if len(comps) > 2 else '')
        
        add_element(spec_src, 'HL7BodySite')
        add_element(spec_src, 'HL7SiteModifier')
        add_element(spec_src, 'HL7CollectionMethodModifierCode')
        add_element(spec_src, 'HL7SpecimenRole')
    
    # OBR-16: Ordering Provider
    if len(fields) > 16 and fields[16]:
        provider = ET.SubElement(obr, 'OrderingProvider')
        comps = parse_components(fields[16])
        add_element(provider, 'HL7IDNumber', comps[0] if len(comps) > 0 else '')
        
        family = ET.SubElement(provider, 'HL7FamilyName')
        add_element(family, 'HL7Surname', comps[1] if len(comps) > 1 else '')
        
        add_element(provider, 'HL7GivenName', comps[2] if len(comps) > 2 else '')
        add_element(provider, 'HL7NameTypeCode', comps[9] if len(comps) > 9 else '')
        add_element(provider, 'HL7IdentifierTypeCode', comps[12] if len(comps) > 12 else '')
    
    # OBR-22: Results Rpt/Status Change Date/Time
    results_dt = ET.SubElement(obr, 'ResultsRptStatusChngDateTime')
    add_datetime_element(results_dt, fields[22] if len(fields) > 22 else '')
    
    # OBR-25: Result Status
    add_element(obr, 'ResultStatus', fields[25] if len(fields) > 25 else '')
    
    add_element(obr, 'NumberofSampleContainers')
    
    return obr


def convert_obx_to_xml(segment, parent):
    """Convert OBX segment to XML"""
    fields = segment['fields']
    obx = ET.SubElement(parent, 'ObservationResult')
    
    # OBX-1: Set ID
    set_id = ET.SubElement(obx, 'SetIDOBX')
    add_element(set_id, 'HL7SequenceID', fields[1] if len(fields) > 1 else '')
    
    # OBX-2: Value Type (NM, CWE, SN, etc.) - read directly from field
    value_type = fields[2] if len(fields) > 2 else ''
    add_element(obx, 'ValueType', value_type)
    
    # OBX-3: Observation Identifier
    if len(fields) > 3 and fields[3]:
        obs_id = ET.SubElement(obx, 'ObservationIdentifier')
        comps = parse_components(fields[3])
        add_element(obs_id, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(obs_id, 'HL7Text', comps[1] if len(comps) > 1 else '')
        add_element(obs_id, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    # OBX-5: Observation Value - read directly from field
    obs_value = fields[5] if len(fields) > 5 else ''
    add_element(obx, 'ObservationValue', obs_value)
    
    # OBX-6: Units
    if len(fields) > 6 and fields[6]:
        units = ET.SubElement(obx, 'Units')
        comps = parse_components(fields[6])
        add_element(units, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(units, 'HL7Text', comps[1] if len(comps) > 1 else '')
        add_element(units, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    add_element(obx, 'Probability')
    
    # OBX-11: Observation Result Status
    add_element(obx, 'ObservationResultStatus', fields[11] if len(fields) > 11 else '')
    
    # OBX-14: Date/Time of the Observation
    obs_dt = ET.SubElement(obx, 'DateTimeOftheObservation')
    add_datetime_element(obs_dt, fields[14] if len(fields) > 14 else '')
    
    # OBX-19: Date/Time of the Analysis
    anal_dt = ET.SubElement(obx, 'DateTimeOftheAnalysis')
    add_datetime_element(anal_dt, fields[19] if len(fields) > 19 else '')
    
    return obx


def convert_spm_to_xml(segment, parent):
    """Convert SPM segment to XML"""
    fields = segment['fields']
    spm_outer = ET.SubElement(parent, 'SPECIMEN')
    spm = ET.SubElement(spm_outer, 'SPECIMEN')
    
    # SPM-1: Set ID
    set_id = ET.SubElement(spm, 'SetIDSPM')
    add_element(set_id, 'HL7SequenceID', fields[1] if len(fields) > 1 else '')
    
    # SPM-2: Specimen ID
    if len(fields) > 2 and fields[2]:
        spec_id = ET.SubElement(spm, 'SpecimenID')
        comps = parse_components(fields[2])
        
        placer = ET.SubElement(spec_id, 'HL7PlacerAssignedIdentifier')
        add_element(placer, 'HL7EntityIdentifier', comps[0] if len(comps) > 0 else '')
        
        filler = ET.SubElement(spec_id, 'HL7FillerAssignedIdentifier')
        add_element(filler, 'HL7EntityIdentifier', comps[1] if len(comps) > 1 else '')
    
    # SPM-4: Specimen Type
    if len(fields) > 4 and fields[4]:
        spec_type = ET.SubElement(spm, 'SpecimenType')
        comps = parse_components(fields[4])
        add_element(spec_type, 'HL7Identifier', comps[0] if len(comps) > 0 else '')
        add_element(spec_type, 'HL7NameofCodingSystem', comps[2] if len(comps) > 2 else '')
    
    add_element(spm, 'GroupedSpecimenCount')
    
    # SPM-17: Specimen Collection Date/Time
    if len(fields) > 17 and fields[17]:
        coll_dt = ET.SubElement(spm, 'SpecimenCollectionDateTime')
        range_start = ET.SubElement(coll_dt, 'HL7RangeStartDateTime')
        add_datetime_element(range_start, fields[17])
    
    # SPM-18: Specimen Received Date/Time
    recv_dt = ET.SubElement(spm, 'SpecimenReceivedDateTime')
    add_datetime_element(recv_dt, fields[18] if len(fields) > 18 else '')
    
    add_element(spm, 'NumberOfSpecimenContainers')
    
    return spm


def hl7_to_xml(hl7_message, pretty_print=True):
    """
    Convert an HL7 message to CDC NEDSS Container XML format.
    
    Args:
        hl7_message: String containing the HL7 message
        pretty_print: If True, return formatted XML with indentation
        
    Returns:
        String containing the XML representation
    """
    # Parse the HL7 message
    segments = parse_hl7_message(hl7_message)
    
    # Create root element with namespace
    root = ET.Element('Container')
    root.set('xmlns', NEDSS_NS)
    
    # Create HL7LabReport element
    lab_report = ET.SubElement(root, 'HL7LabReport')
    
    # Process each segment
    patient_result = None
    order_observation = None
    patient_result_order_obs = None
    
    for segment in segments:
        seg_name = segment['name']
        
        if seg_name == 'MSH':
            convert_msh_to_xml(segment, lab_report)
        
        elif seg_name == 'SFT':
            convert_sft_to_xml(segment, lab_report)
        
        elif seg_name == 'PID':
            # Create PATIENT_RESULT structure if not exists
            if patient_result is None:
                patient_result = ET.SubElement(lab_report, 'HL7PATIENT_RESULT')
            
            patient = ET.SubElement(patient_result, 'PATIENT')
            convert_pid_to_xml(segment, patient)
        
        elif seg_name == 'ORC':
            # Create ORDER_OBSERVATION structure if not exists
            if patient_result is None:
                patient_result = ET.SubElement(lab_report, 'HL7PATIENT_RESULT')
            if order_observation is None:
                order_observation = ET.SubElement(patient_result, 'ORDER_OBSERVATION')
            
            convert_orc_to_xml(segment, order_observation)
        
        elif seg_name == 'OBR':
            if patient_result is None:
                patient_result = ET.SubElement(lab_report, 'HL7PATIENT_RESULT')
            if order_observation is None:
                order_observation = ET.SubElement(patient_result, 'ORDER_OBSERVATION')
            
            convert_obr_to_xml(segment, order_observation)
        
        elif seg_name == 'OBX':
            if patient_result is None:
                patient_result = ET.SubElement(lab_report, 'HL7PATIENT_RESULT')
            if order_observation is None:
                order_observation = ET.SubElement(patient_result, 'ORDER_OBSERVATION')
            if patient_result_order_obs is None:
                patient_result_order_obs = ET.SubElement(order_observation, 'PatientResultOrderObservation')
            
            observation = ET.SubElement(patient_result_order_obs, 'OBSERVATION')
            convert_obx_to_xml(segment, observation)
        
        elif seg_name == 'SPM':
            if patient_result is None:
                patient_result = ET.SubElement(lab_report, 'HL7PATIENT_RESULT')
            if order_observation is None:
                order_observation = ET.SubElement(patient_result, 'ORDER_OBSERVATION')
            
            spm_obs = ET.SubElement(order_observation, 'PatientResultOrderSPMObservation')
            convert_spm_to_xml(segment, spm_obs)
    
    # Convert to string
    if pretty_print:
        xml_str = ET.tostring(root, encoding='unicode')
        dom = minidom.parseString(xml_str)
        # Get pretty printed XML without declaration
        pretty_xml = dom.toprettyxml(indent='    ', encoding=None)
        # Replace the default declaration with the proper one
        pretty_xml = pretty_xml.replace(
            '<?xml version="1.0" ?>',
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        )
        return pretty_xml
    else:
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n' + ET.tostring(root, encoding='unicode')


def extract_hl7_metadata(hl7_message):
    """
    Extract metadata from HL7 message for SQL INSERT.
    
    Returns dict with:
        - filler_order_nbr: from OBR-3 (FillerOrderNumber.EntityIdentifier)
        - lab_clia: from MSH-4 (SendingFacility.UniversalID)
        - order_test_code: from OBR-4 (UniversalServiceIdentifier.Identifier)
        - specimen_coll_date: from SPM-17 (SpecimenCollectionDateTime)
    """
    segments = parse_hl7_message(hl7_message)
    
    metadata = {
        'filler_order_nbr': '',
        'lab_clia': '',
        'order_test_code': '',
        'specimen_coll_date': ''
    }
    
    for segment in segments:
        seg_name = segment['name']
        fields = segment['fields']
        
        if seg_name == 'MSH':
            # MSH-4: Sending Facility - get UniversalID (component 2)
            if len(fields) > 4 and fields[4]:
                comps = parse_components(fields[4])
                if len(comps) > 1:
                    metadata['lab_clia'] = comps[1] if not isinstance(comps[1], list) else comps[1][0]
        
        elif seg_name == 'OBR':
            # OBR-3: Filler Order Number - get EntityIdentifier (component 1)
            if len(fields) > 3 and fields[3]:
                comps = parse_components(fields[3])
                if len(comps) > 0:
                    metadata['filler_order_nbr'] = comps[0] if not isinstance(comps[0], list) else comps[0][0]
            
            # OBR-4: Universal Service Identifier - get Identifier (component 1)
            if len(fields) > 4 and fields[4]:
                comps = parse_components(fields[4])
                if len(comps) > 0:
                    metadata['order_test_code'] = comps[0] if not isinstance(comps[0], list) else comps[0][0]
        
        elif seg_name == 'SPM':
            # SPM-17: Specimen Collection Date/Time
            if len(fields) > 17 and fields[17]:
                metadata['specimen_coll_date'] = fields[17]
    
    return metadata


def format_hl7_datetime_to_sql(hl7_datetime):
    """
    Convert HL7 datetime (YYYYMMDDHHMMSS) to SQL datetime format (YYYY-MM-DD HH:MM:SS)
    """
    if not hl7_datetime:
        return None
    
    # Handle various HL7 datetime lengths
    dt = hl7_datetime
    
    year = dt[0:4] if len(dt) >= 4 else '1900'
    month = dt[4:6] if len(dt) >= 6 else '01'
    day = dt[6:8] if len(dt) >= 8 else '01'
    hour = dt[8:10] if len(dt) >= 10 else '00'
    minute = dt[10:12] if len(dt) >= 12 else '00'
    second = dt[12:14] if len(dt) >= 14 else '00'
    
    return f"{year}-{month}-{day} {hour}:{minute}:{second}"


def hl7_to_sql(hl7_message):
    """
    Convert HL7 message to SQL INSERT statement.
    
    Args:
        hl7_message: String containing the HL7 message
        
    Returns:
        String containing the SQL INSERT statement
    """
    # Generate XML payload
    xml_output = hl7_to_xml(hl7_message)
    
    # Extract metadata
    metadata = extract_hl7_metadata(hl7_message)
    
    # Escape single quotes in XML for SQL
    xml_escaped = xml_output.replace("'", "''")
    
    # Format specimen collection date
    specimen_date = format_hl7_datetime_to_sql(metadata['specimen_coll_date'])
    if specimen_date:
        specimen_date_sql = f"CAST('{specimen_date}' AS DATETIME)"
    else:
        specimen_date_sql = "NULL"
    
    sql = f"""USE [NBS_MSGOUTE];
GO

INSERT INTO [dbo].[NBS_interface]
(
    payload,
    imp_exp_ind_cd,
    record_status_cd,
    record_status_time,
    add_time,
    system_nm,
    doc_type_cd,
    filler_order_nbr,
    lab_clia,
    order_test_code,
    specimen_coll_date
)
VALUES (
    '{xml_escaped}',
    N'I',                                   -- Import indicator
    N'QUEUED',                              -- Status: queued for processing
    CURRENT_TIMESTAMP,                      -- Record status time
    CURRENT_TIMESTAMP,                      -- Add time
    N'NBS',                                 -- System name
    N'11648804',                            -- ELR document type code
    N'{metadata['filler_order_nbr']}',      -- filler_order_nbr from OBR.FillerOrderNumber.EntityIdentifier
    N'{metadata['lab_clia']}',              -- lab_clia from MSH.SendingFacility.UniversalID
    N'{metadata['order_test_code']}',       -- order_test_code from OBR.UniversalServiceIdentifier.Identifier
    {specimen_date_sql}                     -- specimen_coll_date from SPM.SpecimenCollectionDateTime
);
"""
    return sql


def main():
    parser = argparse.ArgumentParser(
        description="Convert HL7 v2.5.1 ELR messages to XML or SQL format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    cat message.hl7 | python convert.py > message.xml
    cat message.hl7 | python convert.py --sql > insert.sql
    python convert.py < message.hl7 > message.xml
        """
    )
    parser.add_argument(
        '--sql', 
        action='store_true',
        help='Output as SQL INSERT statement instead of XML'
    )
    
    args = parser.parse_args()
    
    # Read HL7 from stdin
    hl7_input = sys.stdin.read()
    
    if not hl7_input.strip():
        print("Error: No input received. Pipe an HL7 message to stdin.", file=sys.stderr)
        print("Usage: cat message.hl7 | python hl7_to_xml.py", file=sys.stderr)
        sys.exit(1)
    
    # Convert and write to stdout
    if args.sql:
        output = hl7_to_sql(hl7_input)
    else:
        output = hl7_to_xml(hl7_input)
    
    print(output)


if __name__ == "__main__":
    main()
