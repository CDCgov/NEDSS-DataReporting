package gov.cdc.etldatapipeline.organization.model.dto.place;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Place {
    @Id
    @Column(name = "place_uid")
    private Long placeUid;

    @Column(name = "cd")
    private String cd;

    @Column(name = "place_type_description")
    private String placeTypeDescription;

    @Column(name = "place_local_id")
    private String placeLocalId;

    @Column(name = "place_name")
    private String placeName;

    @Column(name = "place_general_comments")
    private String placeGeneralComments;

    @Column(name = "place_add_time")
    private String placeAddTime;

    @Column(name = "place_add_user_id")
    private Long placeAddUserId;

    @Column(name = "place_last_change_time")
    private String placeLastChangeTime;

    @Column(name = "place_last_chg_user_id")
    private Long placeLastChgUserId;

    @Column(name = "place_record_status")
    private String placeRecordStatus;

    @Column(name = "place_record_status_time")
    private String placeRecordStatusTime;

    @Column(name = "place_status_cd")
    private String placeStatusCd;

    @Column(name = "place_status_time")
    private String placeStatusTime;

    @Column(name = "place_entity")
    private String placeEntity;

    @Column(name = "place_address")
    private String placeAddress;

    @Column(name = "place_tele")
    private String placeTele;
}
