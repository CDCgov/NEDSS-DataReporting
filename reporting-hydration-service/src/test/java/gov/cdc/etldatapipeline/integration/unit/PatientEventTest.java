package gov.cdc.etldatapipeline.integration.unit;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import gov.cdc.etldatapipeline.integration.support.data.patient.PatientManager;
import gov.cdc.etldatapipeline.integration.support.data.patient.address.PatientAddress;
import gov.cdc.etldatapipeline.integration.support.data.patient.birth.PatientSexAndBirth;
import gov.cdc.etldatapipeline.integration.support.data.patient.birth.PatientSexAndBirth.MultipleBirth;
import gov.cdc.etldatapipeline.integration.support.data.patient.birth.PatientSexAndBirth.Sex;
import gov.cdc.etldatapipeline.integration.support.data.patient.ethnicity.PatientEthnicity;
import gov.cdc.etldatapipeline.integration.support.data.patient.ethnicity.PatientEthnicity.Ethnicity;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo.Education;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo.Language;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo.MaritalStatus;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo.Occupation;
import gov.cdc.etldatapipeline.integration.support.data.patient.general.PatientGeneralInfo.SpeaksEnglish;
import gov.cdc.etldatapipeline.integration.support.data.patient.identification.PatientIdentification;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientName;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientName.Degree;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientName.Prefix;
import gov.cdc.etldatapipeline.integration.support.data.patient.name.PatientName.Suffix;
import gov.cdc.etldatapipeline.integration.support.data.patient.phone.PatientPhoneAndEmail;
import gov.cdc.etldatapipeline.integration.support.data.patient.race.PatientRace;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.GeneratedId;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.Address;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.EntityData;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.Name;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.Phone;
import gov.cdc.etldatapipeline.person.model.dto.persondetail.Race;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

/** Validates the sp_patient_event stored procedure */
@SpringBootTest
class PatientEventTest extends UnitTest {

  private final PatientRepository patientRepository;
  private final PatientManager patientManager;

  private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.S");
  private final DateTimeFormatter format2 = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
  private final ObjectMapper mapper = new ObjectMapper();

  PatientEventTest(
      @Autowired final PatientRepository patientRepository,
      @Qualifier("odseClient") JdbcClient odseClient) {
    this.patientRepository = patientRepository;
    this.patientManager = new PatientManager(odseClient);
  }

  @Test
  @SuppressWarnings("java:S5961") // assertion count
  void validatePatientEvent() throws JsonProcessingException {
    // Create a patient with data
    LocalDateTime now = LocalDateTime.of(2026, 03, 31, 12, 26);
    GeneratedId generatedId = patientManager.create(now);

    // Name
    PatientName patientName = new PatientName(
        now,
        PatientName.Type.LEGAL,
        Prefix.MR,
        "John",
        "B",
        null,
        "Doe",
        null,
        Suffix.JUNIOR,
        Degree.PHD);
    patientManager.addName(generatedId.id(), patientName);

    // Address
    PatientAddress patientAddress = new PatientAddress(
        now,
        PatientAddress.Type.HOUSE,
        PatientAddress.Use.HOME,
        "123 Main Street",
        null,
        "Atlanta",
        "13",
        "30033",
        "13121",
        "1234",
        "840",
        "Address Comment");

    patientManager.addAddress(generatedId.id(), patientAddress);

    // Ethnicity
    PatientEthnicity patientEthnicity = new PatientEthnicity(now, Ethnicity.NOT_HISPANIC_OR_LATINO, null, null);

    patientManager.addEthnicity(generatedId.id(), patientEthnicity);

    // Phone
    PatientPhoneAndEmail patientPhone = new PatientPhoneAndEmail(
        now,
        PatientPhoneAndEmail.Type.PHONE,
        PatientPhoneAndEmail.Use.HOME,
        "1",
        "234-555-1212",
        null,
        null,
        null,
        "last known contact");

    patientManager.addPhoneAndEmail(generatedId.id(), patientPhone);

    // Race
    PatientRace patientRace = new PatientRace(now, PatientRace.Race.WHITE, null);

    patientManager.addRace(generatedId.id(), patientRace);

    // Identification
    PatientIdentification patientIdentification = new PatientIdentification(
        now,
        PatientIdentification.Type.DRIVERS_LICENSE_NUMBER,
        PatientIdentification.AssigningAuthority.GA,
        "1234567890");
    patientManager.addIdentification(generatedId.id(), patientIdentification);

    // General Info
    PatientGeneralInfo patientGeneralInfo = new PatientGeneralInfo(
        now,
        MaritalStatus.MARRIED,
        "Does",
        1,
        2,
        Occupation.CONSTRUCTION,
        Education.BACHELORS_DEGREE,
        Language.ENGLISH,
        SpeaksEnglish.YES,
        null);

    patientManager.setGeneralInfo(generatedId.id(), patientGeneralInfo);

    // Sex and Birth Info
    PatientSexAndBirth patientSexAndBirthInfo = new PatientSexAndBirth(
        now,
        now.minusYears(24),
        Sex.MALE,
        null,
        null,
        "AdditionalGender Value",
        Sex.MALE,
        MultipleBirth.NO,
        null,
        "Atlanta",
        "13",
        "13121",
        "840");

    patientManager.setSexAndBirthInfo(generatedId.id(), patientSexAndBirthInfo);

    // Call stored procedure to collect data
    List<PatientSp> patientDataList = patientRepository.computePatients(String.valueOf(generatedId.id()));

    // Validate data
    String expectedAsOf = now.format(formatter);
    assertThat(patientDataList).isNotNull().isNotEmpty();
    PatientSp data = patientDataList.get(0);

    assertThat(data.getPersonUid()).isEqualTo(generatedId.id());
    assertThat(data.getAgeReported()).isNull();
    assertThat(data.getAgeReportedUnitCd()).isNull();
    assertThat(data.getAgeReportedUnit()).isNull();
    assertThat(data.getAdditionalGenderCd()).isEqualTo(patientSexAndBirthInfo.additionalGender());
    assertThat(data.getAddUserId()).isEqualTo(9999);
    assertThat(data.getAddUserName()).isNull();
    assertThat(data.getAdultsInHouseNbr()).isEqualTo("1");
    assertThat(data.getAsOfDateEthnicity()).isEqualTo(expectedAsOf);
    assertThat(data.getAsOfDateGeneral()).isEqualTo(expectedAsOf);
    assertThat(data.getAsOfDateMorbidity()).isNull();
    assertThat(data.getAsOfDateSex()).isEqualTo(expectedAsOf);
    assertThat(data.getBirthGenderCd()).isEqualTo(patientSexAndBirthInfo.birthSex().code());
    assertThat(data.getBirthSex()).isEqualTo("Male");
    assertThat(data.getBirthOrderNbr()).isNull();
    assertThat(data.getBirthTime()).isEqualTo(now.minusYears(24).format(formatter));
    assertThat(data.getCd()).isEqualTo("PAT");
    assertThat(data.getChildrenInHouseNbr()).isEqualTo("2");
    assertThat(data.getCurrSexCd()).isEqualTo(patientSexAndBirthInfo.currentSex().code());
    assertThat(data.getCurrentSex()).isEqualTo("Male");
    assertThat(data.getDeceasedIndCd()).isNull();
    assertThat(data.getDeceasedInd()).isNull();
    assertThat(data.getDeceasedTime()).isNull();
    assertThat(data.getDedupMatchInd()).isNull();
    assertThat(data.getDescription()).isNull();
    assertThat(data.getEducationLevelCd())
        .isEqualTo(patientGeneralInfo.highestLevelOfEducation().code());
    assertThat(data.getEthnicGroupInd()).isEqualTo(patientEthnicity.ethnicity().code());
    assertThat(data.getEthnicity()).isEqualTo("Not Hispanic or Latino");
    assertThat(data.getEthnicUnkReasonCd()).isNull();
    assertThat(data.getEthnicUnkReason()).isNull();
    assertThat(data.getLastChgUserId()).isEqualTo(9999);
    assertThat(data.getLastChgUserName()).isNull();
    assertThat(data.getLocalId()).isEqualTo(generatedId.toLocalId());
    assertThat(data.getMaritalStatusCd()).isEqualTo(patientGeneralInfo.maritalStatus().code());
    assertThat(data.getMaritalStatus()).isEqualTo("Married");
    assertThat(data.getMultipleBirthInd()).isEqualTo(patientSexAndBirthInfo.multipleBirth().code());
    assertThat(data.getOccupationCd()).isEqualTo(patientGeneralInfo.occupation().code());
    assertThat(data.getPrimaryOccupation()).isEqualTo("Construction");
    assertThat(data.getPersonParentUid()).isEqualTo(generatedId.id());
    assertThat(data.getPersonFirstNm()).isNull();
    assertThat(data.getPersonLastNm()).isNull();
    assertThat(data.getPersonMiddleNm()).isNull();
    assertThat(data.getPersonNmSuffix()).isNull();
    assertThat(data.getPreferredGenderCd()).isNull();
    assertThat(data.getPreferredGender()).isNull();
    assertThat(data.getPrimLang()).isEqualTo("English");
    assertThat(data.getRecordStatusCd()).isEqualTo("ACTIVE");
    assertThat(data.getStatusCd()).isEqualTo("A");
    assertThat(data.getSpeaksEnglishCd()).isEqualTo(patientGeneralInfo.speaksEnglish().code());
    assertThat(data.getSpeaksEnglish()).isEqualTo("Yes");
    assertThat(data.getSexUnkReasonCd()).isNull();
    assertThat(data.getVersionCtrlNbr()).isEqualTo("1");
    assertThat(data.getLastChgTime()).isEqualTo(expectedAsOf);
    assertThat(data.getRecordStatusTime()).isEqualTo(expectedAsOf);
    assertThat(data.getStatusTime()).isEqualTo(expectedAsOf);

    // Names validation
    List<Name> names = mapper.readValue(data.getNameNested(), new TypeReference<List<Name>>() {
    });
    assertThat(names).hasSize(1);
    Name nameValue = names.get(0);

    assertThat(nameValue.getFirstNm()).isEqualTo(patientName.first());
    assertThat(nameValue.getFirstNmSndx()).isEqualTo("J500");
    assertThat(nameValue.getMiddleNm()).isEqualTo(patientName.middle());
    assertThat(nameValue.getLastNm()).isEqualTo(patientName.last());
    assertThat(nameValue.getLastNmSndx()).isEqualTo("D000");
    assertThat(nameValue.getPersonUid()).isEqualTo(generatedId.id());
    assertThat(nameValue.getNmUseCd()).isEqualTo(patientName.type().code());
    assertThat(nameValue.getStatusNameCd()).isEqualTo("A");
    assertThat(nameValue.getNameSuffix()).isEqualTo("Jr.");
    assertThat(nameValue.getNmSuffix()).isEqualTo(patientName.suffix().code());
    assertThat(nameValue.getNmDegree()).isEqualTo(patientName.degree().code());
    assertThat(nameValue.getPersonNmSeq()).isEqualTo("1");
    assertThat(nameValue.getLastChgTime()).isEqualTo(now.format(format2));

    // Address validation
    List<Address> addresses = mapper.readValue(data.getAddressNested(), new TypeReference<List<Address>>() {
    });
    assertThat(addresses).hasSize(2);
    Address postalAddress = addresses.get(0);

    assertThat(postalAddress.getCd()).isEqualTo(patientAddress.type().code());
    assertThat(postalAddress.getUseCd()).isEqualTo(patientAddress.use().code());
    assertThat(postalAddress.getStreetAddr1()).isEqualTo(patientAddress.address1());
    assertThat(postalAddress.getStreetAddr2()).isEqualTo(patientAddress.address2());
    assertThat(postalAddress.getCity()).isEqualTo(patientAddress.city());
    assertThat(postalAddress.getState()).isEqualTo(patientAddress.stateCode());
    assertThat(postalAddress.getStateDesc()).isEqualTo("Georgia");
    assertThat(postalAddress.getZip()).isEqualTo(patientAddress.zip());
    assertThat(postalAddress.getCntyCd()).isEqualTo(patientAddress.countyCode());
    assertThat(postalAddress.getCounty()).isEqualTo("Fulton County");
    assertThat(postalAddress.getCntryCd()).isEqualTo(patientAddress.countryCode());
    assertThat(postalAddress.getHomeCountry()).isEqualTo("United States");
    assertThat(postalAddress.getCensusTract()).isEqualTo(patientAddress.censusTract());
    assertThat(postalAddress.getBirthCountry()).isNull();

    Address birthAddress = addresses.get(1);
    assertThat(birthAddress.getCd()).isNull();
    assertThat(birthAddress.getUseCd()).isEqualTo("BIR");
    assertThat(birthAddress.getStreetAddr1()).isNull();
    assertThat(birthAddress.getStreetAddr2()).isNull();
    assertThat(birthAddress.getCity()).isEqualTo(patientSexAndBirthInfo.birthCity());
    assertThat(birthAddress.getState()).isEqualTo(patientSexAndBirthInfo.birthStateCode());
    assertThat(birthAddress.getStateDesc()).isEqualTo("Georgia");
    assertThat(birthAddress.getZip()).isNull();
    assertThat(birthAddress.getCntyCd()).isEqualTo(patientSexAndBirthInfo.birthCountyCode());
    assertThat(birthAddress.getCounty()).isEqualTo("Fulton County");
    assertThat(birthAddress.getCntryCd()).isEqualTo(patientSexAndBirthInfo.birthCountryCode());
    assertThat(birthAddress.getHomeCountry()).isNull();
    assertThat(birthAddress.getCensusTract()).isNull();
    // Other country is not all caps, intentional?
    assertThat(birthAddress.getBirthCountry()).isEqualTo("UNITED STATES");

    // Telephone validation
    List<Phone> phones = mapper.readValue(data.getTelephoneNested(), new TypeReference<List<Phone>>() {
    });
    assertThat(phones).hasSize(1);
    Phone phone = phones.get(0);

    assertThat(phone.getCd()).isEqualTo(patientPhone.type().code());
    assertThat(phone.getUseCd()).isEqualTo(patientPhone.use().code());
    assertThat(phone.getTelephoneNbr()).isEqualTo(patientPhone.phoneNumber());
    assertThat(phone.getExtensionTxt()).isEqualTo(patientPhone.extension());

    // Race validation
    List<gov.cdc.etldatapipeline.person.model.dto.persondetail.Race> races = mapper.readValue(data.getRaceNested(),
        new TypeReference<List<Race>>() {
        });
    assertThat(races).hasSize(1);
    Race race = races.get(0);

    assertThat(race.getPersonUid()).isEqualTo(generatedId.id());
    assertThat(race.getRaceCd()).isEqualTo(patientRace.race().code());
    assertThat(race.getRaceDescTxt()).isNull();
    assertThat(race.getRaceCategoryCd()).isEqualTo(patientRace.race().code());
    assertThat(race.getSrteCodeDescTxt()).isEqualTo("White");
    assertThat(race.getRaceCalculated()).isEqualTo("White");
    assertThat(race.getRaceCalcDetails()).isEqualTo("White");
    assertThat(race.getRaceAll()).isEqualTo("White");

    // Email validation
    assertThat(data.getEmailNested()).isNull();

    // Identification validation
    List<EntityData> identifications = mapper.readValue(data.getEntityDataNested(),
        new TypeReference<List<EntityData>>() {
        });
    assertThat(identifications).hasSize(1);
    EntityData identification = identifications.get(0);

    assertThat(identification.getEntityUid()).isEqualTo(generatedId.id());
    assertThat(identification.getTypeCd()).isEqualTo(patientIdentification.type().code());
    assertThat(identification.getRecordStatusCd()).isEqualTo("ACTIVE");
    assertThat(identification.getRootExtensionTxt()).isEqualTo(patientIdentification.value());
    assertThat(identification.getEntityIdSeq()).isEqualTo(1);
    assertThat(identification.getAssigningAuthorityCd())
        .isEqualTo(patientIdentification.assigningAuthority().code());
  }
}
