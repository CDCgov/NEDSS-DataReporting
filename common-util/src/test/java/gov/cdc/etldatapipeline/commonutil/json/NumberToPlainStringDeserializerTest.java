package gov.cdc.etldatapipeline.commonutil.json;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class NumberToPlainStringDeserializerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    static class Wrapper {
        @JsonDeserialize(using = NumberToPlainStringDeserializer.class)
        public String value;
    }

    @ParameterizedTest
    @CsvSource(
            value = {
                    "{\"value\": 1.23E+7}|12300000",
                    "{\"value\": 10000000}|10000000",
                    "{\"value\": \"1.23E+7\"}|1.23E+7"
            },
            delimiter = '|'
    )
    void shouldDeserializeToPlainString(String json, String expected) throws Exception {
        Wrapper wrapper = objectMapper.readValue(json, Wrapper.class);
        assertThat(wrapper.value).isEqualTo(expected);
    }

    @Test
    void shouldHandleNullValue() throws Exception {
        Wrapper wrapper = objectMapper.readValue("{\"value\": null}", Wrapper.class);
        assertThat(wrapper.value).isNull();
    }

    @Test
    void shouldFailOnUnexpectedType() {
        assertThatThrownBy(() -> objectMapper.readValue("{\"value\": {\"nested\":1}}", Wrapper.class))
                .isInstanceOf(Exception.class);
    }
}
