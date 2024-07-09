package gov.cdc.etldatapipeline.commonutil.json;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.google.common.base.CaseFormat;

import java.lang.reflect.Field;

public class CustomJsonGeneratorImpl {

    public String generateStringJson(Object model) {
        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            ObjectNode root = objectMapper.createObjectNode();
            ObjectNode schemaNode = root.putObject("schema");
            schemaNode.put("type", "struct");
            schemaNode.set("fields", generateFieldsArray(model));
            ObjectNode payloadNode = root.putObject("payload");
            payloadNode = generatePayloadNode(payloadNode, model);
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    private static ArrayNode generateFieldsArray(Object model) {
        ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        ArrayNode fieldsArray = objectMapper.createArrayNode();

        try {
            Class<?> modelClass = model.getClass();
            for (Field field : modelClass.getDeclaredFields()) {
                ObjectNode fieldNode = objectMapper.createObjectNode();

                String fieldName = getFieldName(field);

                fieldNode.put("type", getType(field.getType().getSimpleName().toLowerCase()));
                fieldNode.put("optional", (!fieldName.equals("public_health_case_uid")
                        && !fieldName.equals("observation_uid") && !fieldName.equals("organization_uid")
                        && !fieldName.equals("patient_uid") && !fieldName.equals("provider_uid")));
                fieldNode.put("field", fieldName);
                fieldsArray.add(fieldNode);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return fieldsArray;
    }

    private static ObjectNode generatePayloadNode(ObjectNode payloadNode, Object model) {
        ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

        try {
            Class<?> modelClass = model.getClass();
            for (java.lang.reflect.Field field : modelClass.getDeclaredFields()) {
                field.setAccessible(true);
                String fieldName = getFieldName(field);

                payloadNode.put(fieldName, objectMapper.valueToTree(field.get(model)));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return payloadNode;
    }

    private static String getFieldName(Field field) {
        if (field.isAnnotationPresent(JsonProperty.class)) {
            return field.getAnnotation(JsonProperty.class).value();
        } else {
            return CaseFormat.LOWER_CAMEL.to(CaseFormat.LOWER_UNDERSCORE, field.getName());
        }
    }

    private static String getType(String javaType) {
        return switch (javaType.toLowerCase()) {
            case "long" -> "int64";
            case "integer", "int" -> "int32";
            case "instant" -> "string";
            default -> javaType.toLowerCase();
        };
    }
}
