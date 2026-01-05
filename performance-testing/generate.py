# !/usr/bin/env python3
"""
Fake ELR (Electronic Laboratory Report) HL7 Message Generator
Generates HL7 v2.5.1 messages for testing purposes

python3 generate.py                   # make one message
python3 generate.py -n 10             # make 10 messages
python3 generate.py -n 10 -o examples # make 10 messages, output to examples directory
"""

import random
import string
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()

# HL7 delimiters
FIELD_SEP = '|'
COMPONENT_SEP = '^'
REPEAT_SEP = '~'
ESCAPE_CHAR = '\\'
SUBCOMPONENT_SEP = '&'
SEGMENT_SEP = '\r'

# Sample lab tests for different program areas.
# Each of this tests uses a LOINC code found in NBS_SRTE dev data,
# mapping tests to condition codes, and condition codes to program areas.
# See, e.g. tables Loinc_condition and Snomed_condition for mapping to condition codes. 
# This list could be developed to be more realistic.

LAB_TESTS = [

# ABOR
{"loinc": "30178-8", "name": "West Nile virus Ab", "specimen": "Serum", "results": ["Detected", "Not Detected"]},

{"loinc": "6388-3", "name": "Eastern equine encephalitis virus Ab", "specimen": "Serum", "results": ["Detected", "Not Detected"]},

# BMIRD
{"loinc": "62493-2", "name": "Streptococcus pneumoniae Ag", "specimen": "Blood", "results": ["Streptococcus pneumoniae", "Not Detected"]},

# VPD
{"loinc": "55161-4", "name": "Bordetella pertussis", "specimen": "NP Swab", "results": ["Detected", "Not Detected"]},

# HEP
{"loinc": "65633-0", "name": "Hepatitis B virus", "specimen": "Serum", "results": ["Detected", "Not Detected"]},
{"loinc": "75886-2", "name": "Hepatitis C virus", "specimen": "Serum", "results": ["Detected", "Not Detected"]},

# GCD
{"loinc": "10351-5", "name": "HIV 1 Ab", "specimen": "Blood", "results": ["Detected", "Not Detected"]},

# STD
{"loinc": "70161-5", "name": "Chlamydia trachomatis", "specimen": "Genital Swab", "results": ["Detected", "Not Detected"]},

# TB
{"loinc": "64084-7", "name": "Mycobacterium tuberculosis", "specimen": "Sputum", "results": ["Detected", "Not Detected"]},

# VPD
{"loinc": "5401-5", "name": "Varicella zoster virus", "specimen": "Lesion Swab", "results": ["Detected", "Not Detected"]},

]

FACILITIES = [
    {"name": "St Mungos Hospital", "clia": "12D3456789", "npi": "1234567890"},
    {"name": "Hogwarts Infirmary", "clia": "34D5678901", "npi": "2345678901"},
    {"name": "Diagon Alley Diagnostics", "clia": "45D6789012", "npi": "3456789012"},
    {"name": "Hogsmeade Health Lab", "clia": "56D7890123", "npi": "4567890123"},
    {"name": "Madam Pomfrey Clinical Services", "clia": "67D8901234", "npi": "5678901234"},
    {"name": "Ministry of Magic Medical Division", "clia": "78D9012345", "npi": "6789012345"},
    {"name": "Slug and Jiggers Apothecary Lab", "clia": "89D0123456", "npi": "7890123456"},
    {"name": "Knockturn Alley Specimen Services", "clia": "90D1234567", "npi": "8901234567"},
    {"name": "Order of the Phoenix Medical", "clia": "01D2345678", "npi": "9012345678"},
    {"name": "Dumbledore Memorial Laboratory", "clia": "23D4567890", "npi": "0123456789"},
]

RACES = [
    ("2106-3", "White"),
    ("2054-5", "Black or African American"),
    ("2028-9", "Asian"),
    ("1002-5", "American Indian or Alaska Native"),
    ("2076-8", "Native Hawaiian or Other Pacific Islander"),
    ("2131-1", "Other Race"),
]

ETHNICITIES = [
    ("2135-2", "Hispanic or Latino"),
    ("2186-5", "Not Hispanic or Latino"),
]

GA_CITIES = [
    "Atlanta", "Savannah", "Augusta", "Macon", "Columbus",
    "Athens", "Sandy Springs", "Roswell", "Albany", "Marietta",
    "Alpharetta", "Johns Creek", "Valdosta", "Smyrna", "Dunwoody",
    "Rome", "Peachtree City", "Gainesville", "Warner Robins", "Decatur",
]

# zipcodes known in dev instances in NBS_SRTE.dbo.Jurisdiction_participation with unique jurisdictions
GA_ZIPCODES = [
    "30309", "30311", "30331", "30342", "31106", "31107", "31126", "31131", "31139", "30029", "78613", "30322"
]


def generate_control_id():
    """Generate a unique message control ID"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    random_suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    return f"{timestamp}{random_suffix}"


def format_hl7_datetime(dt=None, precision="full"):
    """Format datetime for HL7"""
    if dt is None:
        dt = datetime.now()
    if precision == "full":
        return dt.strftime("%Y%m%d%H%M%S")
    elif precision == "date":
        return dt.strftime("%Y%m%d")
    return dt.strftime("%Y%m%d%H%M%S")


def generate_msh_segment(sending_facility, message_type="ORU^R01^ORU_R01"):
    """Generate MSH (Message Header) segment"""
    fields = [
        "MSH",
        f"{COMPONENT_SEP}{REPEAT_SEP}{ESCAPE_CHAR}{SUBCOMPONENT_SEP}",  # Encoding characters
        f"{sending_facility['name']}^{sending_facility['clia']}^CLIA",  # Sending Application
        f"{sending_facility['name']}^{sending_facility['npi']}^NPI",  # Sending Facility
        "State Public Health Lab^2.16.840.1.114222^ISO",  # Receiving Application
        "State DOH^2.16.840.1.114222.1^ISO",  # Receiving Facility
        format_hl7_datetime(),  # Date/Time of Message
        "",  # Security
        message_type,  # Message Type
        generate_control_id(),  # Message Control ID
        "P",  # Processing ID (P=Production, T=Training, D=Debugging)
        "2.5.1",  # Version ID
        "",  # Sequence Number
        "",  # Continuation Pointer
        "NE",  # Accept Acknowledgment Type
        "NE",  # Application Acknowledgment Type
        "USA",  # Country Code
        "UNICODE UTF-8",  # Character Set
        "",  # Principal Language
        "",  # Alternate Character Set
        "PHLabReport-NoAck^ELR251R1_Rcvr_Prof^2.16.840.1.113883.9.11^ISO",  # Message Profile Identifier
    ]
    return FIELD_SEP.join(fields)


def generate_sft_segment():
    """Generate SFT (Software) segment"""
    fields = [
        "SFT",
        "Fake ELR Generator^L",  # Software Vendor Organization
        "1.0",  # Software Version
        "FakeELR",  # Software Product Name
        "1.0.0",  # Software Binary ID
        "",  # Software Product Information
        "",  # Software Install Date
    ]
    return FIELD_SEP.join(fields)

HP_CHARACTERS = [
    {"first": "Harry", "last": "Potter", "gender": "M"},
    {"first": "Hermione", "last": "Granger", "gender": "F"},
    {"first": "Ron", "last": "Weasley", "gender": "M"},
    {"first": "Albus", "last": "Dumbledore", "gender": "M"},
    {"first": "Severus", "last": "Snape", "gender": "M"},
    {"first": "Minerva", "last": "McGonagall", "gender": "F"},
    {"first": "Rubeus", "last": "Hagrid", "gender": "M"},
    {"first": "Draco", "last": "Malfoy", "gender": "M"},
    {"first": "Luna", "last": "Lovegood", "gender": "F"},
    {"first": "Neville", "last": "Longbottom", "gender": "M"},
    {"first": "Ginny", "last": "Weasley", "gender": "F"},
    {"first": "Fred", "last": "Weasley", "gender": "M"},
    {"first": "George", "last": "Weasley", "gender": "M"},
    {"first": "Sirius", "last": "Black", "gender": "M"},
    {"first": "Remus", "last": "Lupin", "gender": "M"},
    {"first": "Bellatrix", "last": "Lestrange", "gender": "F"},
    {"first": "Nymphadora", "last": "Tonks", "gender": "F"},
    {"first": "Cedric", "last": "Diggory", "gender": "M"},
    {"first": "Cho", "last": "Chang", "gender": "F"},
    {"first": "Dobby", "last": "Elf", "gender": "M"},
    {"first": "Lucius", "last": "Malfoy", "gender": "M"},
    {"first": "Narcissa", "last": "Malfoy", "gender": "F"},
    {"first": "Arthur", "last": "Weasley", "gender": "M"},
    {"first": "Molly", "last": "Weasley", "gender": "F"},
    {"first": "Percy", "last": "Weasley", "gender": "M"},
    {"first": "Bill", "last": "Weasley", "gender": "M"},
    {"first": "Charlie", "last": "Weasley", "gender": "M"},
    {"first": "Fleur", "last": "Delacour", "gender": "F"},
    {"first": "Viktor", "last": "Krum", "gender": "M"},
    {"first": "Dolores", "last": "Umbridge", "gender": "F"},
    {"first": "Gilderoy", "last": "Lockhart", "gender": "M"},
    {"first": "Horace", "last": "Slughorn", "gender": "M"},
    {"first": "Argus", "last": "Filch", "gender": "M"},
    {"first": "Pomona", "last": "Sprout", "gender": "F"},
    {"first": "Filius", "last": "Flitwick", "gender": "M"},
    {"first": "Sybill", "last": "Trelawney", "gender": "F"},
    {"first": "Tom", "last": "Riddle", "gender": "M"},
    {"first": "Gellert", "last": "Grindelwald", "gender": "M"},
    {"first": "Newt", "last": "Scamander", "gender": "M"},
    {"first": "Kingsley", "last": "Shacklebolt", "gender": "M"},
]


def generate_pid_segment():
    """Generate PID (Patient Identification) segment using Harry Potter characters"""
    
    # add a random string to Harry Potter name so there can be many different patients
    patient_number = ''.join(random.choices(string.ascii_letters + string.digits, k=8))

    # Select character
    character = random.choice(HP_CHARACTERS)
    
    first_name = character['first']
    last_name = f"{character['last']}_{patient_number}"
    gender = character['gender']
    
    dob = fake.date_of_birth(minimum_age=1, maximum_age=90)
    race = random.choice(RACES)
    ethnicity = random.choice(ETHNICITIES)
    
    patient_id = f"HP{patient_number}"
    ssn = f"{random.randint(100, 999)}-{random.randint(10, 99)}-{random.randint(1000, 9999)}"
    
    address = fake.street_address()
    city = random.choice(GA_CITIES)
    state = "GA"
    zipcode = random.choice(GA_ZIPCODES)
    #zipcode = fake.zipcode_in_state("GA")
    #address = fake.street_address()
    #city = fake.city()
    #state = fake.state_abbr()
    #zipcode = fake.zipcode()
    phone_digits = ''.join(c for c in fake.phone_number() if c.isdigit())
    if len(phone_digits) > 10:
        if phone_digits.startswith('001'):
            phone_digits = phone_digits[3:]
        elif phone_digits[0] == '1':
            phone_digits = phone_digits[1:]
    phone = phone_digits[:10]

    fields = [
        "PID",
        "1",  # Set ID
        "",  # Patient ID (External)
        f"{patient_id}^^^{random.choice(FACILITIES)['name']}&2.16.840.1.113883.19.4.6&ISO^MR",  # Patient ID (Internal)
        "",  # Alternate Patient ID
        f"{last_name}^{first_name}^^^^L",  # Patient Name
        "",  # Mother's Maiden Name
        format_hl7_datetime(datetime.combine(dob, datetime.min.time()), "date"),  # DOB
        gender,  # Gender
        "",  # Patient Alias
        f"{race[0]}^{race[1]}^HL70005",  # Race
        f"{address}^^{city}^{state}^{zipcode}^USA^H",  # Address
        "",  # County Code
        f"^PRN^PH^^1^{phone[:3]}^{phone[3:]}",  # Phone - Home
        "",  # Phone - Business
        "",  # Primary Language
        "",  # Marital Status
        "",  # Religion
        "",  # Patient Account Number
        f"{ssn}^^^USA^SS",  # SSN
        "",  # Driver's License
        "",  # Mother's Identifier
        f"{ethnicity[0]}^{ethnicity[1]}^HL70189",  # Ethnic Group
        "",  # Birth Place
        "",  # Multiple Birth Indicator
        "",  # Birth Order
        "",  # Citizenship
        "",  # Veterans Status
        "",  # Nationality
        "",  # Patient Death Date/Time
        "",  # Patient Death Indicator
    ]
    return FIELD_SEP.join(fields)

def generate_orc_segment(order_number, facility):
    """Generate ORC (Common Order) segment"""
    provider_npi = ''.join(random.choices(string.digits, k=10))
    provider_first = fake.first_name()
    provider_last = fake.last_name()
    
    order_datetime = datetime.now() - timedelta(hours=random.randint(1, 48))
    
    fields = [
        "ORC",
        "RE",  # Order Control (RE = Observations/Performed Service to follow)
        f"{order_number}^{facility['name']}^{facility['clia']}^CLIA",  # Placer Order Number
        f"{order_number}^{facility['name']}^{facility['clia']}^CLIA",  # Filler Order Number
        "",  # Placer Group Number
        "CM",  # Order Status (CM = Completed)
        "",  # Response Flag
        "",  # Quantity/Timing
        "",  # Parent
        format_hl7_datetime(order_datetime),  # Date/Time of Transaction
        "",  # Entered By
        "",  # Verified By
        f"{provider_npi}^{provider_last}^{provider_first}^^^^^^NPI^L^^^NPI",  # Ordering Provider
        "",  # Enterer's Location
        "",  # Callback Phone Number
        "",  # Order Effective Date/Time
        "",  # Order Control Code Reason
        f"{facility['name']}^L^^^^CLIA&2.16.840.1.113883.4.7&ISO^XX^^^{facility['clia']}",  # Entering Organization
        "",  # Entering Device
        "",  # Action By
        "",  # Advanced Beneficiary Notice Code
        f"{facility['name']}^L^^^^CLIA&2.16.840.1.113883.4.7&ISO^XX^^^{facility['clia']}",  # Ordering Facility Name
        f"{fake.street_address()}^^{fake.city()}^{fake.state_abbr()}^{fake.zipcode()}^USA^B",  # Ordering Facility Address
        f"^WPN^PH^^1^{random.randint(200,999)}^{random.randint(1000000,9999999)}",  # Ordering Facility Phone
        f"{fake.street_address()}^^{fake.city()}^{fake.state_abbr()}^{fake.zipcode()}^USA^B",  # Ordering Provider Address
    ]
    return FIELD_SEP.join(fields)


def generate_obr_segment(order_number, test_info, facility):
    """Generate OBR (Observation Request) segment"""
    collection_datetime = datetime.now() - timedelta(hours=random.randint(24, 72))
    result_datetime = datetime.now() - timedelta(hours=random.randint(1, 24))
    
    provider_npi = ''.join(random.choices(string.digits, k=10))
    provider_first = fake.first_name()
    provider_last = fake.last_name()
    
    fields = [
        "OBR",
        "1",  # Set ID
        f"{order_number}^{facility['name']}^{facility['clia']}^CLIA",  # Placer Order Number
        f"{order_number}^{facility['name']}^{facility['clia']}^CLIA",  # Filler Order Number
        f"{test_info['loinc']}^{test_info['name']}^LN",  # Universal Service Identifier
        "",  # Priority
        "",  # Requested Date/Time
        format_hl7_datetime(collection_datetime),  # Observation Date/Time (Collection)
        "",  # Observation End Date/Time
        "",  # Collection Volume
        "",  # Collector Identifier
        "",  # Specimen Action Code
        "",  # Danger Code
        "",  # Relevant Clinical Info
        format_hl7_datetime(collection_datetime),  # Specimen Received Date/Time
        f"{test_info['specimen']}^{test_info['specimen']}^HL70487",  # Specimen Source
        f"{provider_npi}^{provider_last}^{provider_first}^^^^^^NPI^L^^^NPI",  # Ordering Provider
        "",  # Order Callback Phone Number
        "",  # Placer Field 1
        "",  # Placer Field 2
        "",  # Filler Field 1
        "",  # Filler Field 2
        format_hl7_datetime(result_datetime),  # Results Rpt/Status Change
        "",  # Charge to Practice
        "",  # Diagnostic Serv Sect ID
        "F",  # Result Status (F = Final)
        "",  # Parent Result
        "",  # Quantity/Timing
        "",  # Result Copies To
        "",  # Parent
        "",  # Transportation Mode
        "",  # Reason for Study
        "",  # Principal Result Interpreter
        "",  # Assistant Result Interpreter
        "",  # Technician
        "",  # Transcriptionist
        "",  # Scheduled Date/Time
    ]
    return FIELD_SEP.join(fields)


def generate_obx_segment(set_id, test_info):
    """Generate OBX (Observation Result) segment"""
    result = random.choice(test_info['results'])
    result_datetime = datetime.now() - timedelta(hours=random.randint(1, 24))
    
    # Determine if result is numeric or coded
    is_numeric = result.replace(".", "").isdigit()

    # SNOMED CT codes for organism/result values
    RESULT_CODES = {
      # Qualitative results
      "Detected": "260373001",
      "Positive": "10828004",
      "Reactive": "11214006",
      "Not Detected": "260415000",
      "Negative": "260385009",
      "Non-Reactive": "131194007",
      "No Growth": "264868006",
      # Organisms
      "Streptococcus pneumoniae": "9861002",
      "Bordetella pertussis": "5247005",
      "Hepatitis B virus": "81665004",
      "Hepatitis C virus": "62944002",
      "Chlamydia trachomatis": "63938009",
      "Mycobacterium tuberculosis": "113861009",
      "Varicella zoster virus": "19551004",
      "HIV 1": "19030005",
    } 
    
    if is_numeric:
        value_type = "NM"
        result_field = result
        units = "ug/dL^ug/dL^UCUM" if "Lead" in test_info['name'] else ""
    else:
        value_type = "CWE"
        # Get SNOMED code if available, otherwise generate a placeholder
        result_code = RESULT_CODES.get(result, "")
        if result_code:
            result_field = f"{result_code}^{result}^SCT"
        else:
            result_field = f"^{result}^L"
            # Use a hash-based code as fallback for unknown results
            fallback_code = str(abs(hash(result)) % 900000000 + 100000000)
            result_field = f"{fallback_code}^{result}^L"
        units = ""
    
    # Determine abnormal flag
    if result in ["Detected", "Positive", "Reactive"] or (is_numeric and float(result) > 5):
        abnormal_flag = "A"
    else:
        abnormal_flag = "N"
    
    fields = [
        "OBX",
        str(set_id),  # Set ID
        value_type,  # Value Type
        f"{test_info['loinc']}^{test_info['name']}^LN",  # Observation Identifier
        "",  # Observation Sub-ID
        result_field,  # Observation Value
        units,  # Units
        "",  # Reference Range
        abnormal_flag,  # Abnormal Flags
        "",  # Probability
        "",  # Nature of Abnormal Test
        "F",  # Observation Result Status (F = Final)
        "",  # Effective Date of Reference Range
        "",  # User Defined Access Checks
        format_hl7_datetime(result_datetime),  # Date/Time of Observation
        "",  # Producer's ID
        "",  # Responsible Observer
        "",  # Observation Method
        "",  # Equipment Instance Identifier
        format_hl7_datetime(result_datetime),  # Date/Time of Analysis
    ]
    return FIELD_SEP.join(fields)


def generate_spm_segment(test_info):
    """Generate SPM (Specimen) segment"""
    collection_datetime = datetime.now() - timedelta(hours=random.randint(24, 72))
    specimen_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
    
    fields = [
        "SPM",
        "1",  # Set ID
        f"{specimen_id}^{specimen_id}",  # Specimen ID
        "",  # Specimen Parent IDs
        f"{test_info['specimen']}^^HL70487",  # Specimen Type
        "",  # Specimen Type Modifier
        "",  # Specimen Additives
        "",  # Specimen Collection Method
        "",  # Specimen Source Site
        "",  # Specimen Source Site Modifier
        "",  # Specimen Collection Site
        "",  # Specimen Role
        "",  # Specimen Collection Amount
        "",  # Grouped Specimen Count
        "",  # Specimen Description
        "",  # Specimen Handling Code
        "",  # Specimen Risk Code
        format_hl7_datetime(collection_datetime),  # Specimen Collection Date/Time
        format_hl7_datetime(collection_datetime + timedelta(hours=2)),  # Specimen Received Date/Time
    ]
    return FIELD_SEP.join(fields)


def generate_elr_message():
    """Generate a complete ELR HL7 message"""
    facility = random.choice(FACILITIES)
    test = random.choice(LAB_TESTS)
    order_number = ''.join(random.choices(string.digits, k=10))
    
    segments = [
        generate_msh_segment(facility),
        generate_sft_segment(),
        generate_pid_segment(),
        generate_orc_segment(order_number, facility),
        generate_obr_segment(order_number, test, facility),
        generate_obx_segment(1, test),
        generate_spm_segment(test),
    ]
    
    return SEGMENT_SEP.join(segments) + SEGMENT_SEP


def main():
    import argparse
    import os
    
    parser = argparse.ArgumentParser(description="Generate fake ELR HL7 messages")
    parser.add_argument("-n", "--count", type=int, default=1, help="Number of messages to generate")
    parser.add_argument("-o", "--output", type=str, help="Output file path")
    
    args = parser.parse_args()
    
    if not args.output:
        print(generate_elr_message())
        return

    digits = max(2, len(str(args.count)))
   
    for i in range(args.count):
        message = generate_elr_message()
        filename = f"{str(i+1).zfill(digits)}.hl7"
        filepath = os.path.join(args.output, filename)
        with open(filepath, 'w') as f:
            f.write(message)
    
    print(f"Generated {args.count} message(s) in {args.output}/")


if __name__ == "__main__":
    main()

