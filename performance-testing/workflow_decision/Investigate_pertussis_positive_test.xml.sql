USE NBS_ODSE;
GO

INSERT INTO DSM_algorithm (
    algorithm_nm,
    event_type,
    condition_list,
    resulted_test_list,
    frequency,
    apply_to,
    sending_system_list,
    reporting_system_list,
    event_action,
    algorithm_payload,
    admin_comment,
    status_cd,
    status_time,
    last_chg_user_id,
    last_chg_time
) VALUES (
    'Investigate_pertussis_positive_test',                              -- algorithm_nm
    '11648804',                                -- event_type
    '10190',                            -- condition_list
    '55161-4',                             -- resulted_test_list
    '1',                                 -- frequency
    '1',                                  -- apply_to
    NULL,                                           -- sending_system_list
    NULL,                                           -- reporting_system_list
    '1',                                            -- event_action
    '<Algorithm xmlns="http://www.cdc.gov/NEDSS">
  <AlgorithmName>Investigate_pertussis_positive_test</AlgorithmName>
  <Event>
    <Code>11648804</Code>
    <CodeDescTxt>Laboratory Report</CodeDescTxt>
    <CodeSystemCode>2.16.840.1.113883.6.96</CodeSystemCode>
  </Event>
  <Frequency>
    <Code>1</Code>
    <CodeDescTxt>Real-Time</CodeDescTxt>
    <CodeSystemCode>L</CodeSystemCode>
  </Frequency>
  <AppliesToEntryMethods>
    <EntryMethod>
      <Code>1</Code>
      <CodeDescTxt>Electronic Document</CodeDescTxt>
      <CodeSystemCode>L</CodeSystemCode>
    </EntryMethod>
  </AppliesToEntryMethods>
  <InvestigationType>PG_Pertussis_Investigation</InvestigationType>
  <ApplyToConditions>
    <Condition>
      <Code>10190</Code>
      <CodeDescTxt>Pertussis</CodeDescTxt>
      <CodeSystemCode>2.16.840.1.114222.4.5.277</CodeSystemCode>
    </Condition>
  </ApplyToConditions>
  <Comment/>
  <ElrAdvancedCriteria>
    <EventDateLogic>
      <ElrTimeLogic>
        <ElrTimeLogicInd>
          <Code>N</Code>
        </ElrTimeLogicInd>
      </ElrTimeLogic>
    </EventDateLogic>
    <AndOrLogic>OR</AndOrLogic>
    <ElrCriteria>
      <ResultedTest>
        <Code>55161-4</Code>
        <CodeDescTxt>Bordetella pertussis IgA and IgG panel - Serum by Immunoassay (55161-4)</CodeDescTxt>
      </ResultedTest>
      <ElrCodedResultValue>
        <Code>260373001</Code>
        <CodeDescTxt>Detected (260373001)</CodeDescTxt>
      </ElrCodedResultValue>
    </ElrCriteria>
    <InvLogic>
      <InvLogicInd>
        <Code>N</Code>
      </InvLogicInd>
    </InvLogic>
  </ElrAdvancedCriteria>
  <Action>
    <CreateInvestigation>
      <OnFailureToCreateInvestigation>
        <Code>2</Code>
        <CodeDescTxt>Retain Event Record</CodeDescTxt>
        <CodeSystemCode>L</CodeSystemCode>
      </OnFailureToCreateInvestigation>
    </CreateInvestigation>
  </Action>
</Algorithm>',
    '',                                             -- admin_comment
    'A',                                            -- status_cd
    GETDATE(),                                      -- status_time
    -1,                                             -- last_chg_user_id
    GETDATE()                                       -- last_chg_time
);
GO
