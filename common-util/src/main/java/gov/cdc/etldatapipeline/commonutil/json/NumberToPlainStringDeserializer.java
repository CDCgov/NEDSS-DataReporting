package gov.cdc.etldatapipeline.commonutil.json;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.math.BigDecimal;

public class NumberToPlainStringDeserializer extends JsonDeserializer<String> {
    @Override
    public String deserialize(JsonParser p, DeserializationContext ctx) throws IOException {
        JsonToken t = p.getCurrentToken();
        if (t == JsonToken.VALUE_NUMBER_INT || t == JsonToken.VALUE_NUMBER_FLOAT) {
            // Use BigDecimal to avoid scientific notation
            BigDecimal bd = p.getDecimalValue();
            return bd.toPlainString(); // preserves non-sci; scale preserved if available
        } else if (t == JsonToken.VALUE_STRING) {
            return p.getText();
        }
        // fallback
        return ctx.handleUnexpectedToken(String.class, p).toString();
    }
}
