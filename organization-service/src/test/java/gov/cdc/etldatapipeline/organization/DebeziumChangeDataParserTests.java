package gov.cdc.etldatapipeline.organization;

import gov.cdc.etldatapipeline.organization.model.odse.Organization;
import gov.cdc.etldatapipeline.organization.utils.UtilHelper;
import org.junit.jupiter.api.Test;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class DebeziumChangeDataParserTests {

    @Test
    public void parseDebeziumValueTest() {
        Organization org = UtilHelper.getInstance().deserializePayload(
                readFileData("orgcdc/OrgChangeData.json"),
                "/payload/after",
                Organization.class);
        assertEquals("10036000", org.getOrganizationUid());
        assertEquals(1712340933654L, org.getTs_ms());
        assertEquals("u", org.getOp());
    }
}
