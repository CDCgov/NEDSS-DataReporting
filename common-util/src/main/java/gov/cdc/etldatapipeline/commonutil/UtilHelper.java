package gov.cdc.etldatapipeline.commonutil;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.extern.slf4j.Slf4j;

import java.util.NoSuchElementException;

@Slf4j
public class UtilHelper {
    private static final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule());

    private static final String PAYLOAD_KEY = "payload";
    private static final String DEFAULT_PATH = "after";

    private UtilHelper() {
        throw new IllegalStateException("Utility class");
    }

    public static <T> T deserializePayload(String jsonString, Class<T> type) {
        try {
            if (jsonString == null) return null;
            return objectMapper.readValue(jsonString, type);
        } catch (JsonProcessingException e) {
            log.error("JsonProcessingException: ", e);
        }
        return null;
    }

    public static String extractUid(String value, String uidName, String... overridePath) throws JsonProcessingException {
        JsonNode jsonNode = objectMapper.readTree(value);
        JsonNode payloadNode = jsonNode.get(PAYLOAD_KEY);

        String path = overridePath.length > 0 ? overridePath[0] : DEFAULT_PATH;
        JsonNode dataNode = jsonNode.get(PAYLOAD_KEY).path(path);
        payloadNode = dataNode.isMissingNode() ? payloadNode : dataNode;
        if (payloadNode.has(uidName)) {
            return payloadNode.get(uidName).asText();
        } else {
            throw new NoSuchElementException("The " + uidName + " field is missing in the message payload.");
        }
    }

    public static String extractValue(String message, String fieldName, String... overridePath) throws JsonProcessingException {
        JsonNode jsonNode = objectMapper.readTree(message);
        String nodePath = overridePath.length > 0 ? overridePath[0] : DEFAULT_PATH;
        return jsonNode.get(PAYLOAD_KEY).path(nodePath).path(fieldName).asText();
    }

    public static String extractChangeDataCaptureOperation(String message) throws JsonProcessingException {
        JsonNode jsonNode = objectMapper.readTree(message);
        return jsonNode.get(PAYLOAD_KEY).path("op").asText();
    }

    public static String errorMessage(String entityName, String ids, Exception e) {
        String base = "Error processing " + entityName + " data";
        if (ids != null && !ids.isEmpty()) {
            base += " with ids '" + ids + "'";
        }
        return base + ": " + e.getMessage();
    }
}