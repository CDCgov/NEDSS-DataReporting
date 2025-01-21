package gov.cdc.etldatapipeline.person.repository;

import gov.cdc.etldatapipeline.person.model.dto.user.AuthUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<AuthUser, String> {
    @Query(nativeQuery = true, value = "execute sp_auth_user_event :user_uids")
    Optional<List<AuthUser>> computeAuthUsers(@Param("user_uids") String userUids);
}
