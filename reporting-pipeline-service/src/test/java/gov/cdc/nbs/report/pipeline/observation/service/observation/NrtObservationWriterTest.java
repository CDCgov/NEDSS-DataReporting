package gov.cdc.nbs.report.pipeline.observation.service.observation;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import gov.cdc.nbs.report.pipeline.integration.unit.UnitTest;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationCoded;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationDate;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationEdx;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationMaterial;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationNumeric;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReason;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTxt;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import org.json.JSONException;
import org.junit.jupiter.api.Test;
import org.skyscreamer.jsonassert.Customization;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.skyscreamer.jsonassert.comparator.CustomComparator;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.simple.JdbcClient;

class NrtObservationWriterTest extends UnitTest {

  private final JdbcClient client;
  private final NrtObservationWriter writer;
  private static final ObjectMapper mapper =
      new ObjectMapper()
          .enable(SerializationFeature.INDENT_OUTPUT)
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          .setDateFormat(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS"));

  public NrtObservationWriterTest(@Qualifier("rtrClient") final JdbcClient client) {
    this.client = client;
    this.writer = new NrtObservationWriter(client);
  }

  @Test
  void insertsMaterialData() throws JsonProcessingException, JSONException {
    // Insert material data
    ObservationMaterial material = new ObservationMaterial();
    material.setActUid(2L);
    material.setTypeCd("SPC");
    material.setMaterialId(2L);
    material.setSubjectClassCd("MAT");
    material.setRecordStatus("ACTIVE");
    material.setTypeDescTxt("Specimen");
    material.setLastChgTime("2024-01-01T00:00:00.000");
    material.setMaterialCd("UNK");
    material.setMaterialNm("name");
    material.setMaterialDetails("Details");
    material.setMaterialCollectionVol("36");
    material.setMaterialCollectionVolUnit("ML");
    material.setMaterialDesc("Lymphocytes");
    material.setRiskCd("rsk");
    material.setRiskDescTxt("rskDesc");

    writer.persistMaterials(List.of(material));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_material WHERE act_uid = 2 AND material_id = 2")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(material);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesMaterialData() throws JsonProcessingException, JSONException {
    // Insert material data
    ObservationMaterial material = new ObservationMaterial();
    material.setActUid(3L);
    material.setTypeCd("SPC");
    material.setMaterialId(3L);
    material.setSubjectClassCd("MAT");
    material.setRecordStatus("ACTIVE");
    material.setTypeDescTxt("Specimen");
    material.setLastChgTime("2024-01-01T00:00:00.000");
    material.setMaterialCd("UNK");
    material.setMaterialNm("name");
    material.setMaterialDetails("Details");
    material.setMaterialCollectionVol("36");
    material.setMaterialCollectionVolUnit("ML");
    material.setMaterialDesc("Lymphocytes");
    material.setRiskCd("rsk");
    material.setRiskDescTxt("rskDesc");

    writer.persistMaterials(List.of(material));

    // Upsert material data
    material.setTypeCd("CPS");
    material.setSubjectClassCd("TAM");
    material.setRecordStatus("INACTIVE");
    material.setTypeDescTxt("NEW");
    material.setLastChgTime("2025-01-01T00:00:00.000");
    material.setMaterialCd("ST");
    material.setMaterialNm("NEW_NAME");
    material.setMaterialDetails("Updated Details");
    material.setMaterialCollectionVol("34");
    material.setMaterialCollectionVolUnit("LM");
    material.setMaterialDesc("Something");
    material.setRiskCd("UpdatedRisk");
    material.setRiskDescTxt("NewRiskDesc");
    writer.persistMaterials(List.of(material));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_material WHERE act_uid = 3 AND material_id = 3")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_material WHERE act_uid = 3 AND material_id = 3")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(material);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void insertsCodedEntry() throws JSONException, JsonProcessingException {
    // Insert coded data
    ObservationCoded coded = new ObservationCoded();
    coded.setObservationUid(4L);
    coded.setBatchId(0L);
    coded.setOvcCode("CE04");
    coded.setOvcCodeSystemCd("SNM");
    coded.setOvcCodeSystemDescTxt("SNOMED");
    coded.setOvcDisplayName("Normal]");
    coded.setOvcAltCd("A-124");
    coded.setOvcAltCdDescTxt("NORMAL");

    writer.persistCoded(List.of(coded));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql(
                "SELECT * FROM nrt_observation_coded WHERE observation_uid = 4 AND ovc_code = 'CE04'")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(coded);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesCodedEntry() throws JSONException, JsonProcessingException {
    // Insert coded data
    ObservationCoded coded = new ObservationCoded();
    coded.setObservationUid(5L);
    coded.setBatchId(0L);
    coded.setOvcCode("CE05");
    coded.setOvcCodeSystemCd("SNM");
    coded.setOvcCodeSystemDescTxt("SNOMED");
    coded.setOvcDisplayName("Normal]");
    coded.setOvcAltCd("A-124");
    coded.setOvcAltCdDescTxt("NORMAL");

    writer.persistCoded(List.of(coded));

    // Upsert coded data
    coded.setBatchId(1L);
    coded.setOvcCodeSystemCd("MNS");
    coded.setOvcCodeSystemDescTxt("LOINC");
    coded.setOvcDisplayName("NotNormal");
    coded.setOvcAltCd("D-444");
    coded.setOvcAltCdDescTxt("ABOVE");

    writer.persistCoded(List.of(coded));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_coded WHERE observation_uid = 5 AND ovc_code = 'CE05'")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql(
                "SELECT * FROM nrt_observation_coded WHERE observation_uid = 5 AND ovc_code = 'CE05'")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(coded);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void insertDateEntry() throws JsonProcessingException, JSONException {
    // Insert Date data
    ObservationDate date = new ObservationDate();
    date.setObservationUid(6L);
    date.setBatchId(0L);
    date.setOvdFromDate("2024-08-16T00:00:00.000");
    date.setOvdSeq(1);

    writer.persistDate(List.of(date));

    // Verify data is as expected
    Integer count =
        client
            .sql("SELECT COUNT(*) FROM nrt_observation_date WHERE observation_uid = 6")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_date WHERE observation_uid = 6")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(date);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesDateEntry() throws JsonProcessingException, JSONException {
    // Insert Date data
    ObservationDate date = new ObservationDate();
    date.setObservationUid(7L);
    date.setBatchId(0L);
    date.setOvdFromDate("2024-08-16T00:00:00.000");
    date.setOvdSeq(1);

    writer.persistDate(List.of(date));

    // Upsert date data
    date.setBatchId(2L);
    date.setOvdFromDate("2025-08-16T00:00:00.000");
    date.setOvdSeq(2);

    writer.persistDate(List.of(date));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_date WHERE observation_uid = 7")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(date);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void insertEdx() throws JsonProcessingException, JSONException {
    // Insert edx data
    ObservationEdx edx = new ObservationEdx();
    edx.setEdxActUid(8l);
    edx.setEdxDocumentUid(9L);
    edx.setEdxAddTime("2024-09-30T21:08:19.017");

    writer.persistEdx(List.of(edx));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_edx WHERE edx_act_uid = 8 AND edx_document_uid = 9")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(edx);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesEdx() throws JsonProcessingException, JSONException {
    // Insert edx data
    ObservationEdx edx = new ObservationEdx();
    edx.setEdxActUid(9l);
    edx.setEdxDocumentUid(10L);
    edx.setEdxAddTime("2024-09-30T21:08:19.017");

    writer.persistEdx(List.of(edx));

    // Upsert edx data
    edx.setEdxAddTime("2025-10-02T20:04:09.000");

    writer.persistEdx(List.of(edx));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_edx WHERE edx_act_uid = 9 AND edx_document_uid = 10")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql(
                "SELECT * FROM nrt_observation_edx WHERE edx_act_uid = 9 AND edx_document_uid = 10")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(edx);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void insertNumeric() {
    // Insert numeric data
    ObservationNumeric numeric = new ObservationNumeric();
    numeric.setObservationUid(10L);
    numeric.setOvnSeq(1);
    numeric.setBatchId(0l);
    numeric.setOvnComparatorCd1("100");
    numeric.setOvnLowRange("10-100");
    numeric.setOvnHighRange("100-1000");
    numeric.setOvnNumericValue1("23.10000");
    numeric.setOvnNumericValue2("1.00000");
    numeric.setOvnNumericUnitCd("mL");
    numeric.setOvnSeparatorCd(":");

    writer.persistNumeric(List.of(numeric));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_numeric WHERE observation_uid = 10 AND ovn_seq = 1")
            .query()
            .singleRow();

    // Field comparison due to type mismatch from String to numeric(15,5) of numeric value fields
    assertThat(data)
        .containsEntry("observation_uid", numeric.getObservationUid())
        .containsEntry("ovn_high_range", numeric.getOvnHighRange())
        .containsEntry("ovn_low_range", numeric.getOvnLowRange())
        .containsEntry("ovn_comparator_cd_1", numeric.getOvnComparatorCd1())
        .containsEntry("ovn_numeric_unit_cd", numeric.getOvnNumericUnitCd())
        .containsEntry("ovn_separator_cd", numeric.getOvnSeparatorCd())
        .containsEntry("batch_id", numeric.getBatchId());

    assertThat(data.get("ovn_seq")).hasToString(numeric.getOvnSeq().toString());
    assertThat(data.get("ovn_numeric_value_1")).hasToString(numeric.getOvnNumericValue1());
    assertThat(data.get("ovn_numeric_value_2")).hasToString(numeric.getOvnNumericValue2());
  }

  @Test
  void updatesNumeric() {
    // Insert numeric data
    ObservationNumeric numeric = new ObservationNumeric();
    numeric.setObservationUid(11L);
    numeric.setOvnSeq(2);
    numeric.setBatchId(0l);
    numeric.setOvnComparatorCd1("100");
    numeric.setOvnLowRange("10-100");
    numeric.setOvnHighRange("100-1000");
    numeric.setOvnNumericValue1("23");
    numeric.setOvnNumericValue2("1.0");
    numeric.setOvnNumericUnitCd("mL");
    numeric.setOvnSeparatorCd(":");

    writer.persistNumeric(List.of(numeric));

    // Upsert numeric data
    numeric.setBatchId(1l);
    numeric.setOvnComparatorCd1("200");
    numeric.setOvnLowRange("20-200");
    numeric.setOvnHighRange("200-2000");
    numeric.setOvnNumericValue1("34.00000");
    numeric.setOvnNumericValue2("2.00000");
    numeric.setOvnNumericUnitCd("LM");
    numeric.setOvnSeparatorCd("!");

    writer.persistNumeric(List.of(numeric));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_numeric WHERE observation_uid = 11 AND ovn_seq = 2")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_numeric WHERE observation_uid = 11 AND ovn_seq = 2")
            .query()
            .singleRow();

    assertThat(data)
        .containsEntry("observation_uid", numeric.getObservationUid())
        .containsEntry("ovn_high_range", numeric.getOvnHighRange())
        .containsEntry("ovn_low_range", numeric.getOvnLowRange())
        .containsEntry("ovn_comparator_cd_1", numeric.getOvnComparatorCd1())
        .containsEntry("ovn_numeric_unit_cd", numeric.getOvnNumericUnitCd())
        .containsEntry("ovn_separator_cd", numeric.getOvnSeparatorCd())
        .containsEntry("batch_id", numeric.getBatchId());

    assertThat(data.get("ovn_seq")).hasToString(numeric.getOvnSeq().toString());
    assertThat(data.get("ovn_numeric_value_1")).hasToString(numeric.getOvnNumericValue1());
    assertThat(data.get("ovn_numeric_value_2")).hasToString(numeric.getOvnNumericValue2());
  }

  @Test
  void insertsReason() throws JsonProcessingException, JSONException {
    // Insert reason data
    ObservationReason reason = new ObservationReason();
    reason.setObservationUid(12l);
    reason.setReasonCd("80008");
    reason.setReasonDescTxt("PRESENCE OF REASON");
    reason.setBatchId(12l);

    writer.persistReason(List.of(reason));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql(
                "SELECT * FROM nrt_observation_reason WHERE observation_uid = 12 AND reason_cd = '80008'")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(reason);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesReason() throws JsonProcessingException, JSONException {
    // Insert reason data
    ObservationReason reason = new ObservationReason();
    reason.setObservationUid(13l);
    reason.setReasonCd("9009");
    reason.setReasonDescTxt("PRESENCE OF REASON");
    reason.setBatchId(13l);

    writer.persistReason(List.of(reason));

    // Upsert reason data
    reason.setReasonDescTxt("A DIFFERENT REASON");
    reason.setBatchId(14l);

    writer.persistReason(List.of(reason));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_reason WHERE observation_uid = 13 AND reason_cd = '9009'")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql(
                "SELECT * FROM nrt_observation_reason WHERE observation_uid = 13 AND reason_cd = '9009'")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(reason);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void insertsText() throws JsonProcessingException, JSONException {
    // Insert text data
    ObservationTxt txt = new ObservationTxt();
    txt.setObservationUid(14L);
    txt.setOvtSeq(1);
    txt.setBatchId(14L);
    txt.setOvtTxtTypeCd("N");
    txt.setOvtValueTxt("RECOMMENDED IN SUCH INSTANCES.");

    writer.persistText(List.of(txt));

    // Verify data is as expected
    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_txt WHERE observation_uid = 14 AND ovt_seq = 1")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(txt);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }

  @Test
  void updatesText() throws JsonProcessingException, JSONException {
    // Insert text data
    ObservationTxt txt = new ObservationTxt();
    txt.setObservationUid(15L);
    txt.setOvtSeq(2);
    txt.setBatchId(15L);
    txt.setOvtTxtTypeCd("N");
    txt.setOvtValueTxt("RECOMMENDED IN SUCH INSTANCES.");

    writer.persistText(List.of(txt));

    // Update text data
    txt.setBatchId(16L);
    txt.setOvtTxtTypeCd("J");
    txt.setOvtValueTxt("UPDATED VALUE");

    writer.persistText(List.of(txt));

    // Verify data is as expected
    Integer count =
        client
            .sql(
                "SELECT COUNT(*) FROM nrt_observation_txt WHERE observation_uid = 15 AND ovt_seq = 2")
            .query(Integer.class)
            .single();

    assertThat(count).isEqualTo(1);

    Map<String, Object> data =
        client
            .sql("SELECT * FROM nrt_observation_txt WHERE observation_uid = 15 AND ovt_seq = 2")
            .query()
            .singleRow();

    String actual = mapper.writeValueAsString(data);
    String expected = mapper.writeValueAsString(txt);
    JSONAssert.assertEquals(
        expected,
        actual,
        new CustomComparator(
            JSONCompareMode.LENIENT, new Customization("refresh_datetime", (a, b) -> true)));
  }
}
