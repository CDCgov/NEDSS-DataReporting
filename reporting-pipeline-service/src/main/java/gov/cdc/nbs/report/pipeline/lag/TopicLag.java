package gov.cdc.nbs.report.pipeline.lag;

/**
 * Aggregated offset state for a single topic, summed across its partitions.
 *
 * @param endOffset sum of the log-end offsets (how many records the topic has ever held)
 * @param lag sum of {@code endOffset - committedOffset} for the inspected consumer group
 * @param oldestUnconsumedTimestampMillis producer timestamp of the oldest record the group has not
 *     yet consumed (min across partitions), or {@code null} when the topic is fully drained or the
 *     timestamp could not be read
 */
public record TopicLag(long endOffset, long lag, Long oldestUnconsumedTimestampMillis) {

  /** A topic is drained when the consumer group has consumed every record produced to it. */
  public boolean drained() {
    return lag == 0;
  }

  /** True once any record has been produced to the topic (the snapshot has started flowing). */
  public boolean hasData() {
    return endOffset > 0;
  }
}
