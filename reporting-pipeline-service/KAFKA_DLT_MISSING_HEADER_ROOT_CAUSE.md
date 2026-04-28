# Root Cause: Missing `kafka_dlt-original-consumer-group` Header in DLT Messages

## Symptom

```
Caused by: org.springframework.messaging.MessageHandlingException:
Missing header 'kafka_dlt-original-consumer-group' for method parameter type [class java.lang.String]
```

`DeadLetterProcessingService.handlingDeadLetter` fails before its method body runs. Spring Kafka
retries the same DLT record up to `maxAttempts` times per the `FixedBackOff` on the DLT container,
then moves on. New poisoned records keep arriving, so offsets advance continuously and logs stay
noisy.

## Root Cause

`DeadLetterPublishingRecoverer.addHeaders()` reads the consumer group ID via
`ListenerUtils.consumerGroupId()`, which is backed by a **ThreadLocal** variable. That ThreadLocal
is set exactly once when the Kafka listener thread inside
`KafkaMessageListenerContainer$ListenerConsumer.run()` starts. It is **never** set on any other
thread.

Every affected service in `reporting-pipeline-service` uses this pattern:

```java
@RetryableTopic(kafkaTemplate = "xKafkaTemplate", ...)
@KafkaListener(containerFactory = "xKafkaListenerContainerFactory")
public CompletableFuture<Void> processMessage(ConsumerRecord<String, String> rec) {
    return CompletableFuture.runAsync(() -> {
        processXxx(rec.value());   // exception thrown HERE
    }, xExecutor);                 // <-- runs on a SEPARATE thread pool
}
```

When `processXxx` throws on `xExecutor`:
1. The `CompletableFuture` completes exceptionally on `xExecutor`.
2. Spring Kafka's `@RetryableTopic` interceptor has a `whenComplete` callback chained to the
   returned future; that callback also fires **on `xExecutor`**, not on the Kafka listener thread.
3. Inside that callback, `DeadLetterPublishingRecoverer.addHeaders()` calls
   `ListenerUtils.consumerGroupId()` — the ThreadLocal is **null** on `xExecutor` — so
   `kafka_dlt-original-consumer-group` is never written.
4. The record lands in the `_dlt` topic without the expected Spring headers.
5. `DeadLetterProcessingService` tries to bind `kafka_dlt-original-consumer-group` as a required
   `@Header` → `MessageHandlingException` → retry loop.

The `setAsyncAcks(true)` on each container factory is what enables this flow: it tells the
container to track the future's completion before committing the offset, which is correct, but it
does not propagate the listener-thread ThreadLocal to the executor.

## Affected Services

| Service class | Outer executor (removed) | Inner executor (kept — used for fire-and-forget work) |
|---|---|---|
| `ldfdata/LdfDataService` | `ldfExecutor` | — |
| `investigation/InvestigationService` | `invExecutor` | `phcExecutor` (processPhcFactDatamart) |
| `observation/ObservationService` | `obsExecutor` | — |
| `organization/OrganizationService` | `orgExecutor` | `rtrExecutor` (processPhcFactDatamart) |
| `person/PersonService` | `prsExecutor` | `rtrExecutor` (processPhcFactDatamart) |

## Fix

Remove `CompletableFuture.runAsync()` from each `processMessage` listener method. Execute
processing synchronously on the Kafka listener thread so Spring's ThreadLocal remains available
when `DeadLetterPublishingRecoverer` runs. Listener methods may still return
`CompletableFuture.completedFuture(...)` or `CompletableFuture.failedFuture(...)`; the key
requirement is to avoid delegating work to a separate executor in the listener entry point.

Also remove `setAsyncAcks(true)` from each matching `KafkaConsumerConfig` listener container
factory.

Parallelism should be obtained by setting `concurrency` on the `@KafkaListener` annotation or the
container factory, not by delegating to an internal executor inside the listener.

## Files Changed

- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/ldfdata/service/LdfDataService.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/ldfdata/config/KafkaConsumerConfig.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/investigation/service/InvestigationService.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/investigation/config/KafkaConsumerConfig.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/observation/service/ObservationService.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/observation/config/KafkaConsumerConfig.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/organization/service/OrganizationService.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/organization/config/KafkaConsumerConfig.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/person/service/PersonService.java`
- `reporting-pipeline-service/src/main/java/gov/cdc/nbs/report/pipeline/person/config/KafkaConsumerConfig.java`
