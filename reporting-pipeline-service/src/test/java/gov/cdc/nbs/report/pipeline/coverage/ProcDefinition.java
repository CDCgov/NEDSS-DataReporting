package gov.cdc.nbs.report.pipeline.coverage;

import java.util.Set;

/**
 * The coverage "denominator" for a single stored procedure, parsed from its migration SQL source.
 *
 * @param fileName migration file the procedure is defined in (e.g. {@code
 *     013-sp_hepatitis_datamart_postprocessing-001.sql})
 * @param procName name from {@code CREATE PROCEDURE [dbo].[...]} (always present)
 * @param packageName identifier the procedure writes to {@code job_flow_log.package_name} — the key
 *     used to match runtime log rows back to this procedure; {@code null} when not resolvable
 * @param stepNumbers distinct {@code @Proc_Step_no} values the procedure can log (its step
 *     universe)
 * @param logsToJobFlowLog whether the procedure writes to {@code job_flow_log} at all
 */
public record ProcDefinition(
    String fileName,
    String procName,
    String packageName,
    Set<String> stepNumbers,
    boolean logsToJobFlowLog) {

  /** Number of distinct steps this procedure can log — its contribution to the step universe. */
  public int stepCount() {
    return stepNumbers.size();
  }
}
