package gov.cdc.etldatapipeline.person;

import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.*;
import org.junit.jupiter.api.Test;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class PersonDetailsDeserializationTests {
    private static final String FILE_PREFIX = "rawDataFiles/person/";

    @Test
    void testPersonAddressDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .addressNested(readFileData(FILE_PREFIX + "PersonAddress.json"))
                .build();

        Address[] addr = deserializePayload(perOp.getAddressNested(), Address[].class);
        Address expected = Address.builder()
                .streetAddr1("123 Main St.")
                .streetAddr2("")
                .city("Atlanta")
                .zip("30025")
                .cntyCd("13135")
                .state("13")
                .cntryCd("840")
                .stateDesc("Georgia")
                .county("Gwinnett County")
                .withinCityLimitsInd("Y")
                .country("United States")
                .homeCountry("United States")
                .useCd("H")
                .cd("H")
                .postalLocatorUid(10000010L)
                .censusTract("3389.45")
                .build();

        assertNotNull(addr);
        assertEquals(5, addr.length);
        assertEquals(expected.toString(), addr[1].toString());
    }

    @Test
    void testPersonEmailDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .emailNested(readFileData(FILE_PREFIX + "PersonEmail.json"))
                .build();

        Email[] email = deserializePayload(perOp.getEmailNested(), Email[].class);
        Email expected = Email.builder()
                .emailAddress("someone1@email.com")
                .useCd("H")
                .cd("PH")
                .teleLocatorUid(10000009L)
                .build();

        assertNotNull(email);
        assertEquals(3, email.length);
        assertEquals(expected.toString(), email[0].toString());
    }

    @Test
    void testPersonEntityDataDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .entityDataNested(readFileData(FILE_PREFIX + "PersonEntityData.json"))
                .build();

        EntityData[] entityData = deserializePayload(perOp.getEntityDataNested(), EntityData[].class);
        EntityData expected = EntityData.builder()
                .entityUid(242790990L)
                .typeCd("MR")
                .recordStatusCd("ACTIVE")
                .rootExtensionTxt("1113111")
                .entityIdSeq(1)
                .assigningAuthorityCd("2.16.840.1.113883.3.1147.1.1001")
                .build();

        assertNotNull(entityData);
        assertEquals(11, entityData.length);
        assertEquals(expected.toString(), entityData[0].toString());
    }

    @Test
    void testPersonNameDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .nameNested(readFileData(FILE_PREFIX + "PersonName.json"))
                .build();

        Name[] name = deserializePayload(perOp.getNameNested(), Name[].class);
        Name expected = Name.builder()
                .lastNm("Singgh")
                .lastNmSndx("S520")
                .middleNm("Js")
                .firstNm("Suurma")
                .firstNmSndx("S750")
                .nmUseCd("L")
                .nmSuffix("Jr")
                .nmDegree("MD")
                .personUid(10000009L)
                .personNmSeq("2")
                .build();

        assertNotNull(name);
        assertEquals(3, name.length);
        assertEquals(expected.toString(), name[1].toString());
    }

    @Test
    void testPersonPhoneDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .telephoneNested(readFileData(FILE_PREFIX + "PersonTelephone.json"))
                .build();

        Phone[] phones = deserializePayload(perOp.getTelephoneNested(), Phone[].class);
        Phone expected = Phone.builder()
                .telephoneNbr("4562323422")
                .extensionTxt("201")
                .useCd("H")
                .cd("PH")
                .teleLocatorUid(10000009L)
                .build();

        assertNotNull(phones);
        assertEquals(8, phones.length);
        assertEquals(expected.toString(), phones[0].toString());
    }

    @Test
    void testPersonRaceDeserialization() {
        PatientSp perOp = PatientSp.builder()
                .personUid(10000001L)
                .raceNested(readFileData(FILE_PREFIX + "PersonRace.json"))
                .build();

        Race[] race = deserializePayload(perOp.getRaceNested(), Race[].class);
        Race expected = Race.builder()
                .raceCd("2028-9")
                .raceCategoryCd("2028-9")
                .srteCodeDescTxt("Asian")
                .srteParentIsCd("ROOT")
                .personUid(10000008L)
                .raceCalculated("Asian")
                .raceCalcDetails("Asian")
                .raceAll("Asian").build();

        assertNotNull(race);
        assertEquals(5, race.length);
        assertEquals(expected.toString(), race[1].toString());
    }
}
