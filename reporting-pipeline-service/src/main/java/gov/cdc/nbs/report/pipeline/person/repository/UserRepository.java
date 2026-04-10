package gov.cdc.nbs.report.pipeline.person.repository;

import gov.cdc.nbs.report.pipeline.person.model.dto.user.AuthUser;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<AuthUser, String> {
  @Query(nativeQuery = true, value = "execute sp_auth_user_event :user_uids")
  Optional<List<AuthUser>> computeAuthUsers(@Param("user_uids") String userUids);
}
