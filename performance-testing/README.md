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

This will add the ELRs to the NBS_INTERFACE table in the NBS_MSGOUTE database with status marked as `QUEUED`. The local NBS 6 dev environment is configured to automatically import the queued ELRs into the ODSE database every few minutes. (See [https://github.com/CDCgov/NEDSS-DataReporting/blob/main/containers/wildfly/Dockerfile](https://github.com/CDCgov/NEDSS-DataReporting/blob/main/containers/wildfly/Dockerfile)). So you should soon see the data appear. New patients will be created, and (unless workflow decision procedures are configured) the ELRs will be dropped in either of two queues: Documents Requiring Review or Documents Requiring Security Assignment.

### ELRImporter batch process

If necessary, it is also possible to force the ELR importer to run immediately.
In the windows development environments the batch process can usually be found here: 

```
D:\wildfly-10.0.0.Final\nedssdomain\Nedss\BatchFiles\ELRImporter.bat
```

The batch process can also be triggered when running locally. The shell version of the batch process in included in more recent NBS 6 versions (6.0.17 and later). 

```
docker exec wildfly /opt/jboss/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/ELRImporter.sh  # import data to NBS_ODSE

```

Note that the batch process defaults to using the `nedss_elr_load` user. Depending on the environment, this user may need extra permissions.  

### Workflow decision support

The workflow_decision/ directory contains some algorithms to add workflow decision support for the conditions covered by the ELR generator. For example, this will add an active algorithm that will automatically create an investigation for an ELR containing a positive TB test:

```
sqlcmd -U 'superuser' -P [PASSWORD] -i Investigate_TB_positive_test.xml.sql
```

Algorithms can be added, activated, deactivated or removed through the UI, in the Decision Support Management section of the System Management area.

## TODO

- Add preliminary ELRs and ELR updates, not just final ELRs
- Add EICR generation to add more data

