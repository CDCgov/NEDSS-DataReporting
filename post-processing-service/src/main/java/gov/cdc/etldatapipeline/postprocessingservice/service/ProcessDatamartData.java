package gov.cdc.etldatapipeline.postprocessingservice.service;

import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.DatamartKey;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class ProcessDatamartData {
    private static final Logger logger = LoggerFactory.getLogger(ProcessDatamartData.class);

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private final ModelMapper modelMapper = new ModelMapper();

    @Value("${spring.kafka.topic.datamart}")
    public String datamartTopic;

    public void process(List<InvestigationResult> data) {
        try {
            for (InvestigationResult invResult : data) {
                if (invResult.getPatientKey().equals(1L)) continue; // skipping now for unprocessed patients

                Datamart dmart = modelMapper.map(invResult, Datamart.class);
                String jsonKey = jsonGenerator.generateStringJson(DatamartKey.builder().publicHealthCaseUid(invResult.getPublicHealthCaseUid()).build());
                String jsonMessage = jsonGenerator.generateStringJson(dmart);

                kafkaTemplate.send(datamartTopic, jsonKey, jsonMessage);
            }
        } catch (Exception e) {
            logger.error("Error processing Datamart JSON array from investigation result data: {}", e.getMessage());
            throw new RuntimeException(e);
        }
    }
}
