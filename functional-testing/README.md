# Functional testing

This directory contains recordings for functional tests for RTR. The tests are described
in [this document](https://cdc-nbs.atlassian.net/wiki/spaces/NE/pages/2353102855/RTR+functional+testing)

## Recordings in json files

Each .json file contains UI interactions, created with the Chrome Dev Tool recorder.
They can be imported and run within Chrome Dev Tools. They can also be run with
the included puppeteer runner. The recordings are designed to run one after the other,
and-- except for the first step-- expect to already be logged in and on the correct page
to begin that step. 

## Setup

```
npm install
```

## test 01: Create Patient and Morbidity Report

```
node test01createpatientaddmorbidity.js
```

## test 03: Create Investigation for Salmonella, skip Review step and notify CDC

```
node test03skipsupervisorreview.js  # pause after each step for data collection
```

```
node test03skipsupervisorreview.js nopause  # don't pause after each step
```


