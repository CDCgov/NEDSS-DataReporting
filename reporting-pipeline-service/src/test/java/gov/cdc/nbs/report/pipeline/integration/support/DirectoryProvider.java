package gov.cdc.nbs.report.pipeline.integration.support;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

public class DirectoryProvider {

  private DirectoryProvider() {}

  /**
   * Returns a stream of {@link Path} for each directory contained within the specified root and
   * optionally filtered. If no entries are present in the filter, all entries will be returned.
   *
   * @param root the path to scan for sub-directories
   * @param filter optional list of directory names to filter by
   * @return stream of {@link Path} that are contained in the root and match the filter list if
   *     provided
   * @throws IOException
   */
  public static Stream<Path> stream(String root, List<String> filter) throws IOException {
    Stream<Path> directories = Files.list(Paths.get(root)).filter(Files::isDirectory);

    if (filter == null || filter.isEmpty()) {
      return directories;
    }

    Set<String> selectedNames =
        filter.stream().map(String::toLowerCase).collect(java.util.stream.Collectors.toSet());

    return directories.filter(
        directory -> selectedNames.contains(directory.getFileName().toString().toLowerCase()));
  }
}
