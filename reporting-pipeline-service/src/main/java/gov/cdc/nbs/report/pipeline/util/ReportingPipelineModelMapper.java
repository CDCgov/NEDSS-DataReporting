package gov.cdc.nbs.report.pipeline.util;

import org.modelmapper.AbstractConverter;
import org.modelmapper.ModelMapper;
import org.springframework.util.StringUtils;

public class ReportingPipelineModelMapper extends ModelMapper {
  public ReportingPipelineModelMapper() {
    super();
    this.addConverter(
        new AbstractConverter<String, String>() {
          @Override
          protected String convert(String source) {
            return StringUtils.hasText(source) ? source : null;
          }
        });
  }
}
