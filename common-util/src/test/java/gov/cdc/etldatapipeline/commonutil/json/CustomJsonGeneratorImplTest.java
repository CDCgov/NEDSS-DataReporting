package gov.cdc.etldatapipeline.commonutil.json;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

class CustomJsonGeneratorImplTest {
    private CustomJsonGeneratorImpl jsonGenerator = null;

    @BeforeEach
    void setUp() {
        jsonGenerator = new CustomJsonGeneratorImpl();
    }

    @AfterEach
    void tearDown() {
    }

    private static class TestBean {
        private String attr1;
        public TestBean(String attr1) {
            this.attr1 = attr1;
        }
    }
    private static class ComplexTestBean {
        private String stringField;
        private int intField;
        private long longField;
        private Instant instantField;
        @JsonProperty("custom_name")
        private String annotatedField;

        public ComplexTestBean(String stringField, int intField, long longField, Instant instantField, String annotatedField) {
            this.stringField = stringField;
            this.intField = intField;
            this.longField = longField;
            this.instantField = instantField;
            this.annotatedField = annotatedField;
        }
    }

    @Test
    void testGenerateStringJson() {
        TestBean testBean = new TestBean( "value1");
        /**
         * {
         *      "schema":{
         *          "type":"struct",
         *          "fields":[{"type":"string","optional":true,"field":"attr1"}]
         *       },
         *       "payload":{"attr1":"value1"}
         * }
         */
        String actualVal = """
        {"schema":{"type":"struct","fields":[{"type":"string","optional":true,"field":"attr1"}]},"payload":{"attr1":"value1"}}
        """.replace("\n","");
        String jsonVal = jsonGenerator.generateStringJson(testBean);
        assertEquals(actualVal, jsonVal);
    }


    @Test
    void testGenerateStringJson_ComplexObject() {
        ComplexTestBean testBean = new ComplexTestBean("test", 42, 1234L, Instant.ofEpochSecond(1001), "annotated");
        String jsonVal = jsonGenerator.generateStringJson(testBean);
        
        assertTrue(jsonVal.contains("\"string_field\":\"test\""));
        assertTrue(jsonVal.contains("\"int_field\":42"));
        assertTrue(jsonVal.contains("\"long_field\":1234"));
        assertTrue(jsonVal.contains("\"instant_field\":1001"));
        assertTrue(jsonVal.contains("\"custom_name\":\"annotated\""));
        assertTrue(jsonVal.contains("\"type\":\"int32\""));
        assertTrue(jsonVal.contains("\"type\":\"int64\""));
    }

    @Test
    void testGenerateStringJson_WithOverrideKeys() {
        ComplexTestBean testBean = new ComplexTestBean("test", 42, 1234L, Instant.ofEpochSecond(1001),"annotated");
        String jsonVal = jsonGenerator.generateStringJson(testBean, "string_field", "custom_name");
        
        assertTrue(jsonVal.contains("\"optional\":false") && 
                  jsonVal.contains("\"field\":\"string_field\""));
        assertTrue(jsonVal.contains("\"optional\":false") && 
                  jsonVal.contains("\"field\":\"custom_name\""));
        assertTrue(jsonVal.contains("\"optional\":true") &&
                  jsonVal.contains("\"field\":\"int_field\""));
    }

    @Test
    void testGenerateStringJson_NullModel() {
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> jsonGenerator.generateStringJson(null));

        assertTrue(ex.getMessage().contains("Cannot invoke \"Object.getClass()\" because \"model\" is null"));
    }

    @Test
    void testTypeMapping() {
        class TypeTestBean {
            private long longVal;
            private int intVal;
            private String stringVal;
        }
        
        TypeTestBean testBean = new TypeTestBean();
        String jsonVal = jsonGenerator.generateStringJson(testBean);
        
        assertTrue(jsonVal.contains("\"type\":\"int64\""));
        assertTrue(jsonVal.contains("\"type\":\"int32\""));
        assertTrue(jsonVal.contains("\"type\":\"string\""));
    }

    @Test 
    void testSchemaStructure() {
        TestBean testBean = new TestBean("test");
        String jsonVal = jsonGenerator.generateStringJson(testBean);
        
        assertTrue(jsonVal.contains("\"schema\":{"));
        assertTrue(jsonVal.contains("\"type\":\"struct\""));
        assertTrue(jsonVal.contains("\"fields\":["));
        assertTrue(jsonVal.contains("\"payload\":{"));
    }


}