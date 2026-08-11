package gov.cdc.nbs.report.pipeline.ldfdata.repository;

import gov.cdc.nbs.report.pipeline.ldfdata.model.dto.LdfData;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface LdfDataRepository extends JpaRepository<LdfData, Long> {

  @Query(
      nativeQuery = true,
      value =
          "execute sp_ldf_data_event @bus_obj_nm = :bus_obj_nm, @ldf_uid = :ldf_uid, "
              + "@bus_obj_uid_list = :bus_obj_uids, @debug_logging = :debugLogging")
  Optional<LdfData> computeLdfData(
      @Param("bus_obj_nm") String busObjNm,
      @Param("ldf_uid") String ldfUid,
      @Param("bus_obj_uids") String busObjUids,
      @Param("debugLogging") boolean debugLogging);
}
