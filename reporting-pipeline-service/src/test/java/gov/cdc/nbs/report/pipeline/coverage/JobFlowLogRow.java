package gov.cdc.nbs.report.pipeline.coverage;

/**
 * A single observed {@code job_flow_log} row, reduced to the fields coverage cares about. The
 * eventual JDBC adapter maps a result set into these; tests construct them directly.
 *
 * @param packageName value of {@code job_flow_log.package_name} (the procedure identifier)
 * @param stepNumber value of {@code job_flow_log.step_number}, or {@code null}
 * @param statusType {@code START} / {@code COMPLETE} / {@code ERROR}
 */
public record JobFlowLogRow(String packageName, String stepNumber, String statusType) {}
