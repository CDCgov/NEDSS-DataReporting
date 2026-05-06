# Test05 : STD case with contact tracing

This directory contains recordings for an STD case with contact tracing and supervisor approvals.

## Run test

```
node test05supervisorrejectstd.js
```

Without pausing after each step:

```
node test05supervisorrejectstd.js nopause
```

## Steps

### Step 01 : Create Patient and Lab Report
```
010.CreatePatientSwift_fake77gg.json
015.CreateLabReportSyphilis.json
```

### Step 02 : Create Investigation and Assign Investigator
```
020.CreateInvestigationSyphilis.json
022.CreateInvestigationProcessingDecisionPopup.json
024.CreateInvestigationSyphilisAssignInvestigator.json
```

### Step 03 : Add Treatment to the Investigation
```
030.AddTreatmentSyphilis.json
035.AddTreatmentSyphilisPopup.json
037.AddTreatmentSubmit.json
```

### Step 04 : Update Investigation Case Information. 
Add reporting provider. Note diagnosis as '720 Syphilis, secondary' and illness onset date. Status moves to surveillance followup.
```
040.InvestigateSyphilisInitialFollowup.json
```

### Step 05 : Assign investigator for field follow up. 
Case disposition to infected and brought to treatment; interviewer assigned; interview status "awaiting"
```
050.InvestigateSyphilisAssignFieldFollowup.json
```

### Step 06 : Patient interview
Patient interview status changed to "interviewed" and interview information added
```
060.InterviewInformationSyphilis.json
064.AddInterviewSyphilis.json
066.AddInterviewPopupSyphilis.json
```

### Step 07 : Contact record
Create contact record
```
070.AddContactSyphilis.json
072.AddContactPopup.json
```

### Step 08 : Disposition and Close Contact investigation
Change disposition to unable to locate. Send to supervisor queue, approved.
```
080.ChangeContactInvestigationDisposition.json
082.SupervisorApprovesContactDisposition.json
```

### Step 09 : Close investigation
Mark initial investigation as closed with note. Sends to supervisor queue.
```
090.CloseInvestigationSyphilis.json
```

### Step 10 : Supervisor rejects close investigation
```
100.SupervisorRejectsCloseInvestigation.json
```

### Step 11 : Update and close investigation and create notification 
```
110.UpdateInvestigationAndCloseSyphilis.json
112.CreateNotificationSyphilis.json
```

### Step 12 : Supervisor approves
```
120.SupervisorApprove.json
```


