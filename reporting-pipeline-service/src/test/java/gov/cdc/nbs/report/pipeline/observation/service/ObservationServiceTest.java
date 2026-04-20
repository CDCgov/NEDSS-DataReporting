package gov.cdc.nbs.report.pipeline.observation.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;
import org.mockito.*;

class ObservationServiceTest {

  private final String observationTopic = "Observation";
  private final String actRelationshipTopic = "Act_relationship";

  @Mock ObservationProcessor processor = Mockito.mock(ObservationProcessor.class);
  private ObservationService service =
      new ObservationService(processor, observationTopic, actRelationshipTopic, 1);

  @Test
  void processesObservationMessage() { // observation_uid
    String message =
        """
        {
          "payload" : {
            "op": "c",
            "after": {
              "observation_uid": "123"
            }
          }
        }
        """;
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>(observationTopic, 0, 1l, null, message);
    // receives valid observation message
    service.processMessage(consumerRecord).join();

    // sends to ObservationProcessor
    verify(processor, times(1)).process(0, "123");
  }

  @Test
  void processesActRelationshipMessage() {
    String message =
        """
        {
          "payload" : {
            "op": "d",
            "before": {
              "source_act_uid": "1",
              "type_cd": "LabReport",
              "target_class_cd": "OBS"
            }
          }
        }
        """;
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>(actRelationshipTopic, 0, 1l, null, message);
    // receives valid act_relationship message
    service.processMessage(consumerRecord).join();

    // sends to ObservationProcessor
    verify(processor, times(1)).process(0, "1");
  }

  @Test
  void doesNotProcessActRelationshipMessageBadOp() {
    String message =
        """
        {
          "payload" : {
            "op": "c",
            "before": {
              "source_act_uid": "1",
              "type_cd": "LabReport",
              "target_class_cd": "OBS"
            }
          }
        }
        """;
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>(actRelationshipTopic, 0, 1l, null, message);
    // receives non 'delete' act_relationship message
    service.processMessage(consumerRecord).join();

    // does not send to ObservationProcessor
    verifyNoInteractions(processor);
  }

  @Test
  void doesNotProcessActRelationshipMessageBadTypeCd() {
    String message =
        """
        {
          "payload" : {
            "op": "d",
            "before": {
              "source_act_uid": "1",
              "type_cd": "BadValue",
              "target_class_cd": "OBS"
            }
          }
        }
        """;
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>(actRelationshipTopic, 0, 1l, null, message);
    // receives act_relationship message with a type_cd other than 'LabReport'
    service.processMessage(consumerRecord).join();

    // does not send to ObservationProcessor
    verifyNoInteractions(processor);
  }

  @Test
  void throwsExceptionForBadTopic() {
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>("bad_topic", 0, 1l, null, "");
    CompletableFuture<Void> future = service.processMessage(consumerRecord);

    CompletionException ex = assertThrows(CompletionException.class, future::join);
    assertThat(ex.getCause().getMessage())
        .isEqualTo("Received data from an unknown topic: bad_topic");
  }

  @Test
  void throwsExceptionForBadActRelationshipMessage() {
    String message =
        """
        {
          "payload" : {
            "op": "d",
            "before": {
            }
          }
        }
        """;
    ConsumerRecord<String, String> consumerRecord =
        new ConsumerRecord<>(actRelationshipTopic, 0, 1l, null, message);
    CompletableFuture<Void> future = service.processMessage(consumerRecord);

    CompletionException ex = assertThrows(CompletionException.class, future::join);
    assertThat(ex.getCause().getMessage())
        .isEqualTo(
            "Error processing ActRelationship data: The source_act_uid field is missing in the message payload.");
  }
}
