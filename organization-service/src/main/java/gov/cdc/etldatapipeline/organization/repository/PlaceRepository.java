package gov.cdc.etldatapipeline.organization.repository;

import gov.cdc.etldatapipeline.organization.model.dto.place.Place;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PlaceRepository extends JpaRepository<Place, String> {

    @Query(nativeQuery = true, value = "execute sp_place_event :place_uids")
    Optional<List<Place>> computeAllPlaces(@Param("place_uids") String placeUids);

}
