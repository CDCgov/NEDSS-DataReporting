package gov.cdc.etldatapipeline.commonutil.json;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CustomJsonGeneratorImplTest {
    private CustomJsonGeneratorImpl jsonGenerator = null;
    private static class TestBean {
        private String attr1;
    }
    @BeforeEach
    void setUp() {
        jsonGenerator = new CustomJsonGeneratorImpl();

    }

    @AfterEach
    void tearDown() {
    }

    @Test
    void testGenerateStringJson() {
        TestBean testBean = new TestBean();
        testBean.attr1 = "value1";
        String actualVal = """
{"schema":{"type":"struct","fields":[{"type":"string","optional":true,"field":"attr1"}]},"payload":{"attr1":"value1"}}
        """.replace("\n","");
        String jsonVal = jsonGenerator.generateStringJson(testBean);
        assertEquals(actualVal, jsonVal);
    }



}