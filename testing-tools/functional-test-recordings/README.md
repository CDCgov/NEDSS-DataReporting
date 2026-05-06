# Functional testing

This directory contains recordings for functional tests for RTR. The tests are described
in [this document](https://cdc-nbs.atlassian.net/wiki/spaces/NE/pages/2353102855/RTR+functional+testing)

## Recordings in json files

Each .json file contains UI interactions, created with the Chrome Dev Tool recorder.
They can be imported and run within Chrome Dev Tools. They can also be run with
the included puppeteer runner. The recordings are designed to run one after the other,
and-- except for the first step-- expect to already be logged in and on the correct page
to begin that step. 

----
001-create-patient-add-morbidity		005-syphilis-long-path-supervisor-reject	package.json
002-covid-negative-mark-reviewed		010.CreatePatientSwift_fake22bb.json		README.md
003-salmonella-skip-review			010.CreatePatientSwift_fake33cc.json		single.js
004-hepatitis-supervisor-review	
cd 002-covid-negative-mark-reviewed


## Setup

```
npm install
```

## test 01: Create Patient and Morbidity Report

```
cd 001-create-patient-add-morbidity
node test01createpatientaddmorbidity.js
```

## test 02: Create Negative Lab Report for Covid and Mark Reviewed

```
cd 002-covid-negative-mark-reviewed
node test03skipsupervisorreview.js  # pause after each step for data collection
```

```
002-covid-negative-mark-reviewed
node test03skipsupervisorreview.js nopause  # don't pause after each step
```

## test 03: Create Investigation for Salmonella, skip Review step and notify CDC

```
cd 003-salmonella-skip-review
node test03skipsupervisorreview.js  # pause after each step for data collection
```

```
cd 003-salmonella-skip-review
node test03skipsupervisorreview.js nopause  # don't pause after each step
```

## test 04: Create Hepatitis A Investigation, with Supervisor Review and CDC Notification
```
cd 004-hepatitis-supervisor-review
node test04supervisorreview.js  # pause after each step for data collection
```

```
cd 004-hepatitis-supervisor-review
node test04supervisorreview.js nopause  # don't pause after each step
```


## test 05: Create STD (Syphilis) Investigation, with Contact Tracing and Supervisor Review
```
cd 005-syphilis-long-path-supervisor-reject
node test05supervisorrejectstd.js  # pause after each step for data collection
```

```
cd 005-syphilis-long-path-supervisor-reject
node test05supervisorrejectstd.js nopause  # don't pause after each step
```

