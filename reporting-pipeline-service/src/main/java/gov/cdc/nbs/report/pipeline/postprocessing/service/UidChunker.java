package gov.cdc.nbs.report.pipeline.postprocessing.service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

final class UidChunker {

  private UidChunker() {}

  static <T> List<List<T>> chunkDistinct(Collection<T> values, int maxSize) {
    Objects.requireNonNull(values, "values");
    validateMaxSize(maxSize);

    List<T> distinctValues = values.stream().distinct().toList();
    if (distinctValues.isEmpty()) {
      return List.of();
    }
    if (maxSize == 0 || distinctValues.size() <= maxSize) {
      return List.of(distinctValues);
    }

    List<List<T>> chunks = new ArrayList<>((distinctValues.size() - 1) / maxSize + 1);
    for (int start = 0; start < distinctValues.size(); start += maxSize) {
      int end = Math.min(start + maxSize, distinctValues.size());
      chunks.add(List.copyOf(distinctValues.subList(start, end)));
    }
    return List.copyOf(chunks);
  }

  static <K, T> List<Map<K, List<T>>> chunkDistinct(
      Map<K, ? extends Collection<T>> valuesByKey, int maxSize) {
    Objects.requireNonNull(valuesByKey, "valuesByKey");
    validateMaxSize(maxSize);

    Map<K, List<T>> distinctValues = new LinkedHashMap<>();
    valuesByKey.forEach(
        (key, values) -> {
          if (values == null) {
            return;
          }
          List<List<T>> distinctChunks = chunkDistinct(values, 0);
          if (!distinctChunks.isEmpty()) {
            distinctValues.put(key, distinctChunks.get(0));
          }
        });

    if (distinctValues.isEmpty()) {
      return List.of();
    }
    int distinctValueCount = distinctValues.values().stream().mapToInt(List::size).sum();
    if (maxSize == 0 || distinctValueCount <= maxSize) {
      return List.of(copyMap(distinctValues));
    }

    List<Map<K, List<T>>> chunks = new ArrayList<>();
    Map<K, List<T>> currentChunk = new LinkedHashMap<>();
    int currentSize = 0;
    for (Map.Entry<K, List<T>> entry : distinctValues.entrySet()) {
      for (T value : entry.getValue()) {
        if (currentSize == maxSize) {
          chunks.add(copyMap(currentChunk));
          currentChunk = new LinkedHashMap<>();
          currentSize = 0;
        }
        currentChunk.computeIfAbsent(entry.getKey(), ignored -> new ArrayList<>()).add(value);
        currentSize++;
      }
    }
    if (currentSize > 0) {
      chunks.add(copyMap(currentChunk));
    }
    return List.copyOf(chunks);
  }

  private static void validateMaxSize(int maxSize) {
    if (maxSize < 0) {
      throw new IllegalArgumentException("maxSize must be zero or greater");
    }
  }

  private static <K, T> Map<K, List<T>> copyMap(Map<K, List<T>> values) {
    Map<K, List<T>> copy = new LinkedHashMap<>();
    values.forEach((key, value) -> copy.put(key, List.copyOf(value)));
    return Collections.unmodifiableMap(copy);
  }
}
