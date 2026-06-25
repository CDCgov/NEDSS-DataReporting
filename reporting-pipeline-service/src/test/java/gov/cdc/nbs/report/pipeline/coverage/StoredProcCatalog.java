package gov.cdc.nbs.report.pipeline.coverage;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.util.StreamUtils;

/**
 * Builds the stored-procedure coverage denominator by parsing the migration SQL that ships on the
 * classpath under {@code db/changelog/migrations/.../routines}. For each {@code sp_*} routine it
 * extracts the procedure name, the identifier it logs to {@code job_flow_log.package_name}, and the
 * set of {@code @Proc_Step_no} steps it can emit.
 *
 * <p>The resulting catalog is the "what could be covered" side; pairing it with the distinct {@code
 * package_name} / {@code (package_name, step_number)} values found in {@code job_flow_log} after a
 * test suite yields procedure-level and step-depth coverage.
 */
public class StoredProcCatalog {

  static final String ROUTINES_LOCATION = "classpath*:db/changelog/migrations/*/rdb/routines/*.sql";

  private static final Pattern CREATE_PROC =
      Pattern.compile(
          "CREATE\\s+PROCEDURE\\s+\\[?dbo\\]?\\.\\[?([A-Za-z0-9_]+)\\]?", Pattern.CASE_INSENSITIVE);
  // The package_name is the string literal immediately before the 'START' status in a job_flow_log
  // VALUES(...) — robust whether the dataflow name is a literal or a variable.
  private static final Pattern PACKAGE_BEFORE_START =
      Pattern.compile("'([^']+)'\\s*,\\s*'START'", Pattern.CASE_INSENSITIVE);
  // Fallback: procedures that pass @package_name as a variable declare it with a literal.
  private static final Pattern PACKAGE_VAR =
      Pattern.compile("@package_name\\b[^=\\n]*=\\s*'([^']+)'", Pattern.CASE_INSENSITIVE);
  private static final Pattern STEP_NO =
      Pattern.compile("@Proc_Step_no\\s*=\\s*([0-9]+(?:\\.[0-9]+)?)", Pattern.CASE_INSENSITIVE);
  private static final Pattern JOB_FLOW_LOG =
      Pattern.compile("job_flow_log", Pattern.CASE_INSENSITIVE);

  private final ResourcePatternResolver resolver;

  public StoredProcCatalog() {
    this(new PathMatchingResourcePatternResolver());
  }

  public StoredProcCatalog(ResourcePatternResolver resolver) {
    this.resolver = resolver;
  }

  /** Parses every routine on the classpath into its coverage denominator, sorted by file name. */
  public List<ProcDefinition> load() {
    try {
      Resource[] resources = resolver.getResources(ROUTINES_LOCATION);
      List<ProcDefinition> definitions = new ArrayList<>(resources.length);
      for (Resource resource : resources) {
        definitions.add(parse(resource));
      }
      definitions.sort(Comparator.comparing(ProcDefinition::fileName));
      return definitions;
    } catch (IOException e) {
      throw new UncheckedIOException("Failed to read stored-procedure routines from classpath", e);
    }
  }

  private ProcDefinition parse(Resource resource) {
    String sql = read(resource);
    String packageName = firstGroup(PACKAGE_BEFORE_START, sql);
    if (packageName == null) {
      packageName = firstGroup(PACKAGE_VAR, sql);
    }

    Set<String> steps = new LinkedHashSet<>();
    Matcher stepMatcher = STEP_NO.matcher(sql);
    while (stepMatcher.find()) {
      steps.add(stepMatcher.group(1));
    }

    return new ProcDefinition(
        resource.getFilename(),
        firstGroup(CREATE_PROC, sql),
        packageName,
        steps,
        JOB_FLOW_LOG.matcher(sql).find());
  }

  private String read(Resource resource) {
    try {
      return StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
    } catch (IOException e) {
      throw new UncheckedIOException("Failed to read " + resource.getDescription(), e);
    }
  }

  private static String firstGroup(Pattern pattern, String text) {
    Matcher matcher = pattern.matcher(text);
    return matcher.find() ? matcher.group(1) : null;
  }

  /** Total step universe — the sum of each procedure's distinct step count. */
  public static int totalStepCount(List<ProcDefinition> definitions) {
    return definitions.stream().mapToInt(ProcDefinition::stepCount).sum();
  }

  /** Number of procedures that emit any {@code job_flow_log} row (the trackable denominator). */
  public static long loggingProcCount(List<ProcDefinition> definitions) {
    return definitions.stream().filter(ProcDefinition::logsToJobFlowLog).count();
  }
}
