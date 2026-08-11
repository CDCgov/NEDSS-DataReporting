package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class UidChunkerTest {

  @Test
  void returnsNoChunksForEmptyInput() {
    assertEquals(List.of(), UidChunker.chunkDistinct(List.of(), 2));
  }

  @Test
  void removesDuplicatesBeforeCreatingOrderedChunks() {
    List<List<Long>> chunks = UidChunker.chunkDistinct(List.of(3L, 1L, 3L, 2L, 1L), 2);

    assertEquals(List.of(List.of(3L, 1L), List.of(2L)), chunks);
  }

  @Test
  void returnsOneChunkWhenInputFitsLimit() {
    assertEquals(List.of(List.of(1L, 2L, 3L)), UidChunker.chunkDistinct(List.of(1L, 2L, 3L), 3));
  }

  @Test
  void createsFinalPartialChunkWhenInputExceedsLimit() {
    assertEquals(
        List.of(List.of(1L, 2L), List.of(3L, 4L), List.of(5L)),
        UidChunker.chunkDistinct(List.of(1L, 2L, 3L, 4L, 5L), 2));
  }

  @Test
  void zeroLimitDisablesChunkingButStillRemovesDuplicates() {
    assertEquals(
        List.of(List.of("a", "b", "c")), UidChunker.chunkDistinct(List.of("a", "b", "a", "c"), 0));
  }

  @Test
  void chunksDistinctValuesAcrossOrderedMapEntries() {
    Map<String, List<Long>> values = new LinkedHashMap<>();
    values.put("investigation", List.of(1L, 2L, 1L));
    values.put("observation", List.of(3L, 4L));

    assertEquals(
        List.of(
            Map.of("investigation", List.of(1L, 2L), "observation", List.of(3L)),
            Map.of("observation", List.of(4L))),
        UidChunker.chunkDistinct(values, 3));
  }

  @Test
  void returnsOneDistinctMapChunkWhenMapLimitIsZero() {
    Map<String, List<Long>> values = new LinkedHashMap<>();
    values.put("investigation", List.of(1L, 1L));

    assertEquals(
        List.of(Map.of("investigation", List.of(1L))), UidChunker.chunkDistinct(values, 0));
  }

  @Test
  void rejectsNegativeLimit() {
    assertThrows(IllegalArgumentException.class, () -> UidChunker.chunkDistinct(List.of(1L), -1));
  }
}
