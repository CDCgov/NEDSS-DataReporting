package gov.cdc.etldatapipeline.postprocessingservice.service;

import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.DatamartKey;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.CASE_LAB_DATAMART;
import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.HEPATITIS_DATAMART;

@Component
@RequiredArgsConstructor
public class ProcessDatamartData {
    private static final Logger logger = LoggerFactory.getLogger(ProcessDatamartData.class);

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private final ModelMapper modelMapper = new ModelMapper();

    @Value("${spring.kafka.topic.datamart}")
    public String datamartTopic;

    public void process(List<DatamartData> data) {
        if (Objects.nonNull(data) && !data.isEmpty()) {
            data = reduce(data);
            try {
                for (DatamartData datamartData : data) {
                    if (Objects.isNull(datamartData.getPatientUid())) continue; // skipping now for unprocessed patients

                    Datamart dmart = modelMapper.map(datamartData, Datamart.class);
                    DatamartKey dmKey = new DatamartKey();
                    dmKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());
                    String jsonKey = jsonGenerator.generateStringJson(dmKey);
                    String jsonMessage = jsonGenerator.generateStringJson(dmart);

                    kafkaTemplate.send(datamartTopic, jsonKey, jsonMessage);
                    logger.info("Datamart data: PHC uid={}, datamart={} sent to {} topic", dmart.getPublicHealthCaseUid(), dmart.getDatamart(), datamartTopic);
                }
            } catch (Exception e) {
                String msg = "Error processing Datamart JSON array from investigation result data: " + e.getMessage();
                throw new RuntimeException(msg, e);
            }
        }
    }

    private List<DatamartData> reduce(List<DatamartData> dmData) {
        List<Long> hepUidsAlreadyInDmData =
                dmData.stream()
                        .filter(Objects::nonNull)
                        .filter(d -> HEPATITIS_DATAMART.getEntityName().equals(d.getDatamart()))
                        .map(DatamartData::getPublicHealthCaseUid).toList();

        return dmData.stream()
                .filter(Objects::nonNull)
                .filter(d -> {
                    boolean isCaseLab = CASE_LAB_DATAMART.getEntityName().equals(d.getDatamart());
                    boolean hasHepAlready = hepUidsAlreadyInDmData.contains(d.getPublicHealthCaseUid());
                    // If it's Case_Lab_Datamart AND we already have that UID in Hepatitis_Datamart -> exclude
                    return !(isCaseLab && hasHepAlready);
                }).toList();
    }
}
