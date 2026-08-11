package gov.cdc.nbs.report.pipeline.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "feature-flag")
public record EventProcedureLoggingProperties(boolean eventProcedureDebugLogging) {}
