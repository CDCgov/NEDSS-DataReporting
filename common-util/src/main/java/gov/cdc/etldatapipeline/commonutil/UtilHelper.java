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

    public static String extractUid(String value, String uidName) throws JsonProcessingException {
        JsonNode jsonNode = objectMapper.readTree(value);
        JsonNode payloadNode = jsonNode.get("payload").path("after");
        if (!payloadNode.isMissingNode() && payloadNode.has(uidName)) {
            return payloadNode.get(uidName).asText();
        } else {
            throw new NoSuchElementException("The " + uidName + " field is missing in the message payload.");
        }
    }

    public static String extractValue(String message, String fieldName) throws JsonProcessingException {
        JsonNode jsonNode = objectMapper.readTree(message);
        return jsonNode.get("payload").path("after").path(fieldName).asText();
    }

    public static String errorMessage(String entityName, String ids, Exception e) {
        return "Error processing " + entityName + " data" +
                (!ids.isEmpty() ? " with ids '" + ids + "': " : ": " + e.getMessage());
    }
}