package gov.cdc.nbs.report.pipeline.person.model.dto.persondetail;

import lombok.Getter;

@Getter
public enum NameUseCd {
  LEGAL("L"),
  ALIAS("AL");
  private final String val;

  NameUseCd(String val) {
    this.val = val;
  }
}
