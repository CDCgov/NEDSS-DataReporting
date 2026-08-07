package gov.cdc.nbs.report.pipeline.actrelationship;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;

import java.util.concurrent.CompletableFuture;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.header.internals.RecordHeaders;
import org.apache.kafka.common.record.TimestampType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ActRelationshipListenerTest {

  @Mock private ActRelationshipProcessor mockProcessor;

  private ActRelationshipListener listener;

  @BeforeEach
  void setup() {
    listener = new ActRelationshipListener(mockProcessor, 1);
  }

  @Test
  void handles_act_relationship_message() {
    // given a act_relationship kafka message
    String payload =
        """
        {
          "payload": {
            "after": {
              "source_act_uid": "7",
              "type_cd": "1180"
            },
            "op": "c"
          }
        }
        """;
    ConsumerRecord<String, String> message =
        new ConsumerRecord<>("act_relationship", 4, 19, "key", payload);

    // when the listener receives it
    CompletableFuture<Void> future = listener.processMessage(message);
    future.join();

    // then the processor is called with the message and a batch Id
    verify(mockProcessor).process(payload, 22);
  }

  @Test
  void handles_act_relationship_retry_message() {
    // given a act_relationship kafka message
    String payload =
        """
        {
          "payload": {
          }
        }
        """;
    ConsumerRecord<String, String> message =
        new ConsumerRecord<>("act_relationship_retry-0", 4, 19, "key", payload);

    // when the listener receives it
    CompletableFuture<Void> future = listener.processMessage(message);
    future.join();

    // then the processor is called with the message and a batch Id
    verify(mockProcessor).process(payload, 22);
  }

  @ParameterizedTest
  @CsvSource({"1,2,3,6", "4,5,6,15", "0,0,0,0"})
  void generates_batch_id(int partition, int offset, int timestamp, long expected) {
    // given a message with timestamp, offset, and partition values
    ConsumerRecord<String, String> message =
        new ConsumerRecord<String, String>(
            "act_relationship",
            partition,
            offset,
            timestamp,
            TimestampType.NO_TIMESTAMP_TYPE,
            0,
            0,
            null,
            null,
            new RecordHeaders(),
            null);

    // when a batchId is created
    long batchId = listener.generateBatchId(message);

    // then it matches the expected value
    assertThat(batchId).isEqualTo(expected);
  }
}
