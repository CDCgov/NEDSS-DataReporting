# Performance and quality testing

This directory contains tools to add data intended to test the performance and accuracy of RTR.

## Data generation

`generate.py` : create fake ELRs 

`convert.py` : convert an ELR into NBS XML format

### Setup

```
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```


### Create fake ELRs

### Usage: generate.py

```usage: generate.py [-h] [-n COUNT] [-o OUTPUT]

Generate fake ELR HL7 messages

optional arguments:
  -h, --help            show this help message and exit
  -n COUNT, --count COUNT
                        Number of messages to generate
  -o OUTPUT, --output OUTPUT
                        Output file path
```

### Usage: convert.py

```usage: convert.py [-h] [--sql]

Convert HL7 v2.5.1 ELR messages to XML or SQL format

optional arguments:
  -h, --help  show this help message and exit
  --sql       Output as SQL INSERT statement instead of XML

Examples:
    cat message.hl7 | python convert.py > message.xml
    cat message.hl7 | python convert.py --sql > insert.sql
    python convert.py < message.hl7 > message.xml
```


### Example

```
rm -rf examples; mkdir examples # create directory for fake ELRs

python3 generate.py -n 100 -o examples # make 100 fake ELRs

cd examples

for i in *hl7; do ; python3 ../convert.py --sql < $i > $i.sql ; echo $i; done  # convert to XML ready to insert into databse

for i in *sql; do; sqlcmd -U 'superuser' -P [PASSWORD] -i $i; echo $i; done  # add to the NBS_MSGOUTE database

docker exec wildfly /opt/jboss/wildfly/nedssdomain/Nedss/BatchFiles/ELRImporter.sh  # import data to NBS_ODSE
```

## TODO: more data generation tools

- Add Decision Support Management Rules to create investigations and mark as reviewed
- Add preliminary ELRs and ELR updates, not just final ELRs
- Add EICR generation to add more data 



