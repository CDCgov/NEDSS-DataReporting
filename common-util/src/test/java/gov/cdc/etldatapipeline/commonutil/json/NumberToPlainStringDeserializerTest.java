package gov.cdc.etldatapipeline.commonutil.json;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NumberToPlainStringDeserializerTest {

    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
    }

    static class Wrapper {
        @JsonDeserialize(using = NumberToPlainStringDeserializer.class)
        public String value;
    }

    @Test
    void shouldDeserializeNumericValueAsPlainString() throws Exception {
        String json = "{\"value\": 1.23E+7}";
        Wrapper wrapper = objectMapper.readValue(json, Wrapper.class);

        assertThat(wrapper.value).isEqualTo("12300000");
    }

    @Test
    void shouldKeepStringValueAsIs() throws Exception {
        String json = "{\"value\": \"1.23E+7\"}";
        Wrapper wrapper = objectMapper.readValue(json, Wrapper.class);

        assertThat(wrapper.value).isEqualTo("1.23E+7");
    }

    @Test
    void shouldHandleNullValue() throws Exception {
        String json = "{\"value\": null}";
        Wrapper wrapper = objectMapper.readValue(json, Wrapper.class);

        assertThat(wrapper.value).isNull();
    }

    @Test
    void shouldFailOnUnexpectedType() {
        String json = "{\"value\": true}";
        assertThrows(JsonProcessingException.class,
                () -> objectMapper.readValue(json, Wrapper.class));
    }
}