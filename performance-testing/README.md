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

```

This will add the ELRs to the NBS_INTERFACE table in the NBS_MSGOUTE database with status marked as `QUEUED`. The `ELRImporter.sh` script should then be executed to process the ELRs.

```sh
docker exec -it rtr-wildfly /opt/jboss/wildfly/nedssdomain/Nedss/BatchFiles/ELRImporter.sh
```

Once the script is run you should soon see the data appear. New patients will be created, and (unless workflow decision procedures are configured) the ELRs will be dropped in either of two queues: Documents Requiring Review or Documents Requiring Security Assignment.

### Workflow decision support

The workflow_decision/ directory contains some algorithms to add workflow decision support for the conditions covered by the ELR generator. For example, this will add an active algorithm that will automatically create an investigation for an ELR containing a positive TB test:

```
sqlcmd -U 'superuser' -P [PASSWORD] -i Investigate_TB_positive_test.xml.sql
```

Algorithms can be added, activated, deactivated or removed through the UI, in the Decision Support Management section of the System Management area.

Note that, depending on the completeness of the database snapshot, errors may be seen in the wildfly logs when automatically creating investigations ("prepop caching failed due to question Identifier :null"). This does not prevent the investigation from being created and can be ignored in local development. The error is caused by partially missing data for some conditions that use page builder templates. The missing data is used to prepopulate answers to some investigation questions. Adding complete data to the development snapshots is left as a todo. If necessary, the errors can be avoided by emptying the NBS_ODSE..LOOKUP_ANSWER and NBS_ODSE..LOOKUP_QUESTION tables.

## TODO

- Add preliminary ELRs and ELR updates, not just final ELRs
- Add EICR generation to add more data
- Update the local database snapshots to contain full data for page builder question prepopulation
