package gov.cdc.nbs.report.pipeline.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@ConfigurationProperties(prefix = "service.post-processing")
@Validated
public record PostProcessingProperties(@Min(0) int maxBatchSize) {}
