package gov.cdc.etldatapipeline.integration.support.data.patient.address;

import org.springframework.jdbc.core.simple.JdbcClient;

import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.EntityType;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.GeneratedId;

public class PatientAddressManager {

  private JdbcClient client;
  private IdGenerator idGenerator;

  public PatientAddressManager(final JdbcClient client, final IdGenerator idGenerator) {
    this.client = client;
    this.idGenerator = idGenerator;
  }

  private static final String ADD_ADDRESS = """
      --- Entity Participation
      insert into Entity_locator_participation (
            version_ctrl_nbr,
            entity_uid,
            locator_uid,
            add_time,
            last_chg_time,
            record_status_cd,
            record_status_time,
            status_cd,
            status_time,
            as_of_date,
            use_cd,
            cd,
            class_cd,
            locator_desc_txt
        ) values (
            1,
            :patient,
            :locator,
            getDate(),
            getDate(),
            'ACTIVE',
            getDate(),
            'A',
            getDate(),
            :asOf,
            :use,
            :type,
            'PST',
            :comment
        );

        insert into dbo.Postal_locator (
            postal_locator_uid,
            street_addr1,
            street_addr2,
            city_desc_txt,
            cnty_cd,
            state_cd,
            zip_cd,
            census_tract,
            cntry_cd,
            add_time,
            last_chg_time,
            record_status_cd,
            record_status_time
        ) values (
            :locator,
            :address1,
            :address2,
            :city,
            :countyCode,
            :stateCode,
            :zip,
            :censusTract,
            :countryCode,
            getDate(),
            getDate(),
            'ACTIVE',
            getDate()
        );
        """;

  public void add(final long patient, final PatientAddress address) {
    GeneratedId addressId = idGenerator.next(EntityType.NBS);

    this.client
        .sql(ADD_ADDRESS)
        .param("patient", patient)
        .param("locator", addressId.id())
        .param("asOf", address.asOf())
        .param("use", address.use().code())
        .param("type", address.type().code())
        .param("address1", address.address1())
        .param("address2", address.address2())
        .param("city", address.city())
        .param("stateCode", address.stateCode())
        .param("zip", address.zip())
        .param("countyCode", address.countyCode())
        .param("censusTract", address.censusTract())
        .param("countryCode", address.countryCode())
        .param("comment", address.comment())
        .update();
  }
}
