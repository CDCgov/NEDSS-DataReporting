package gov.cdc.etldatapipeline.person;

import gov.cdc.etldatapipeline.person.model.odse.Person;
import gov.cdc.etldatapipeline.person.utils.UtilHelper;
import org.junit.jupiter.api.Test;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class DebeziumChangeDataParserTests {

    @Test
    public void parseDebeziumPrimaryKeyNodeTest() {
        Person personId = UtilHelper.getInstance().parseJsonNode(
                readFileData("rawDataFiles/person/Person.json"),
                "/payload",
                Person.class);
        assertEquals("10000001", personId.getPersonUid());
    }

    @Test
    public void parseDebeziumValueTest() {
        Person person = UtilHelper.getInstance().deserializePayload(
                readFileData("rawDataFiles/person/PersonPatientChangeData.json"),
                "/payload/after",
                Person.class);
        assertEquals("9005400", person.getPersonUid());
        assertEquals("PAT", person.getCd());
        assertEquals(1708702633619L, person.getTs_ms());
        assertEquals("u", person.getOp());
    }
}
