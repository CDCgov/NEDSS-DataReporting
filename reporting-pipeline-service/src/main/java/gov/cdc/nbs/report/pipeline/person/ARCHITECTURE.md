# Person Event Processing — Conditional Data Flow

Describes how `PersonService` routes Patient/Provider/Auth User CDC events, including the
`person-service-direct-write` branch and how both paths converge on the shared postprocessing
pipeline.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
  'primaryColor': '#16273d',
  'primaryTextColor': '#d7e3f0',
  'primaryBorderColor': '#3d5a7a',
  'lineColor': '#7d93ad',
  'secondaryColor': '#16273d',
  'tertiaryColor': '#16273d',
  'fontFamily': 'ui-monospace, SFMono-Regular, Consolas, monospace',
  'fontSize': '15px'
}}}%%
flowchart TD
    subgraph SRC["CDC Source"]
        ODSEPerson[(ODSE.Person)]
        ODSEAuthUser[(ODSE.Auth_user)]
    end

    ODSEPerson -->|Debezium CDC| TopicPerson[["nbs_Person"]]
    ODSEAuthUser -->|Debezium CDC| TopicAuthUser[["nbs_Auth_user"]]

    TopicPerson --> PS["PersonService.processMessage()"]
    TopicAuthUser --> PS

    PS --> TopicSwitch{"which topic?"}
    TopicSwitch -->|nbs_Person| CdSwitch{"cd field"}
    TopicSwitch -->|nbs_Auth_user| ComputeAuthUser["sp_auth_user_event"]

    CdSwitch -->|PAT| ComputePatient["sp_Patient_Event"]
    CdSwitch -->|PRV| ComputeProvider["sp_provider_event"]

    subgraph DIRECTWRITE["Conditional: person-service-direct-write"]
        DW{"directWrite flag"}
        DW -->|true| JpaSave["JPA save<br/>→ nrt_patient / nrt_provider / nrt_auth_user"]
        DW -->|false| KafkaPublish["Publish enriched JSON<br/>→ nrt.patient / nrt.provider / nrt.auth-user"]
        KafkaPublish --> KafkaConnect["Kafka-Connect JDBC Sink<br/>upserts nrt_* table"]
        KafkaPublish --> PPListener["PostProcessingService<br/>@KafkaListener on nrt.* topic"]
    end

    ComputePatient --> DW
    ComputeProvider --> DW
    ComputeAuthUser --> DW

    JpaSave --> Enqueue["PostProcessingService.enqueue(topic, uid)<br/>(direct in-process call — no Kafka round-trip)"]
    PPListener --> ProcessNrt["processNrtMessage()<br/>parses Kafka payload"]
    ProcessNrt --> Enqueue

    subgraph POSTPROC["Shared postprocessing pipeline (priority-ordered batch)"]
        Enqueue --> IdCache[("idCache<br/>keyed by topic<br/>producer adds + drain snapshot/clear both under cacheLock")]
        IdCache -->|"@Scheduled processCachedIds()<br/>sorted by Entity.priority"| Drain["Priority-ordered SP execution"]
        Drain --> PatientSP["sp_nrt_patient_postprocessing<br/>→ D_PATIENT"]
        Drain --> ProviderSP["sp_nrt_provider_postprocessing<br/>→ D_PROVIDER"]
        Drain --> AuthUserSP["sp_user_profile_postprocessing<br/>→ USER_PROFILE"]
        Drain -.->|"same batch,<br/>later priority"| InvSP["Investigation / case_management<br/>postprocessing (unrelated to Person, unchanged)"]
    end

    PatientSP -->|"returns Covid_*_Datamart rows<br/>(empty for Provider/AuthUser happy path)"| DmData["DatamartData"]

    subgraph DATAMART["Datamart routing"]
        DmData --> DatamartTopic[["nbs_Datamart"]]
        DatamartTopic --> DmCache[("dmCache")]
        DmCache -->|"@Scheduled processDatamartIds()"| DatamartSP["Datamart-specific stored procs<br/>e.g. sp_covid_case_datamart_postprocessing"]
    end

    InvSP -.->|"LEFT JOIN D_PATIENT<br/>(ordering-dependent)"| DatamartSP2["sp_std_hiv_datamart_postprocessing"]

    classDef highlight fill:#3a2a12,stroke:#e7a53d,color:#f4dcae,stroke-width:2px;
    classDef muted fill:#16273d,stroke:#48607e,color:#6c839c,stroke-dasharray: 3 3;
    class DW,JpaSave highlight;
    class KafkaPublish,KafkaConnect,PPListener,ProcessNrt muted;
```

🟧 amber = `person-service-direct-write` (active path) · ⬜ dashed = Kafka-Connect (legacy, feature-flagged off)

## Key conditionals

- **`cd` field** routes `nbs_Person` events to patient vs. provider stored procs.
- **`person-service-direct-write` flag** is the main fork: JPA save (direct-write) vs. Kafka
  publish → Kafka-Connect (legacy). Both paths converge on the same
  `PostProcessingService.enqueue()` call into the shared `idCache` — direct-write calls it
  in-process, the legacy path via its existing `@KafkaListener` → `processNrtMessage()`, which
  itself now delegates to `enqueue()` for id-caching.
- **Priority-ordered batch drain** is what keeps `D_PATIENT` hydration ahead of
  investigation/case_management processing within the same cycle. Direct-write must go through
  this same shared pipeline rather than calling postprocessing stored procedures itself —
  bypassing it breaks that ordering guarantee (see APP-787).
- **`cacheLock`** guards every producer-side cache write (`enqueue()` and the legacy path's
  payload-enrichment writes) against the scheduled drain's snapshot-then-clear. Without it, an
  add landing between the drain's snapshot and its `clear()` was silently and permanently
  dropped rather than merely delayed — this affected every entity type processed by this shared
  service, not just Patient/Provider/AuthUser (see APP-787 concurrency follow-up).
- **Datamart routing** only actually carries rows in the happy path for Patient (Covid
  datamarts); Provider/AuthUser postprocessing stored procedures return empty result sets there.

Not shown (orthogonal, non-blocking flags that don't affect this core routing):
`elasticSearchEnable` (publishes to `elastic_search_patient`/`elastic_search_provider` regardless
of direct-write) and `phcDatamartEnable` (async PHC fact datamart update).
