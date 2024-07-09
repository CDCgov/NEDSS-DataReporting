package gov.cdc.etldatapipeline.ldfdata.repository;

import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LdfDataRepository extends JpaRepository<LdfData, Long> {

    @Query(nativeQuery = true, value = "execute sp_ldf_data_event :bus_obj_nm, :ldf_uid, :bus_obj_uids")
    Optional<LdfData> computeLdfData(@Param("bus_obj_nm") String busObjNm, @Param("ldf_uid") String ldfUid, @Param("bus_obj_uids") String busObjUids);
}
