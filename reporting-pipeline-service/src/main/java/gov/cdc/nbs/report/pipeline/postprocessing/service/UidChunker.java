package gov.cdc.nbs.report.pipeline.postprocessing.service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Objects;

final class UidChunker {

  private UidChunker() {}

  static <T> List<List<T>> chunkDistinct(Collection<T> values, int maxSize) {
    Objects.requireNonNull(values, "values");
    if (maxSize < 0) {
      throw new IllegalArgumentException("maxSize must be zero or greater");
    }

    List<T> distinctValues = values.stream().distinct().toList();
    if (distinctValues.isEmpty()) {
      return List.of();
    }
    if (maxSize == 0) {
      return List.of(distinctValues);
    }

    List<List<T>> chunks = new ArrayList<>((distinctValues.size() - 1) / maxSize + 1);
    for (int start = 0; start < distinctValues.size(); start += maxSize) {
      int end = Math.min(start + maxSize, distinctValues.size());
      chunks.add(List.copyOf(distinctValues.subList(start, end)));
    }
    return List.copyOf(chunks);
  }
}
