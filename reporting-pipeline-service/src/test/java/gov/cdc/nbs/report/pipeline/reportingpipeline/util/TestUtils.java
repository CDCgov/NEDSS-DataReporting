package gov.cdc.nbs.report.pipeline.reportingpipeline.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import java.io.File;
import java.io.IOException;
import org.testcontainers.utility.DockerImageName;

public class TestUtils {

  private static final String COMPOSE_PATH = "../docker-compose.yaml";

  /**
   * Extracts the image name for a given service from the root docker-compose.yaml file.
   *
   * @param serviceName The name of the service (e.g., "kafka", "nbs-mssql")
   * @return DockerImageName parsed from the compose file.
   * @throws RuntimeException if the file cannot be read or the service/image is missing.
   */
  public static DockerImageName getComposeImageName(String serviceName) {
    try {
      ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
      JsonNode root = mapper.readTree(new File(COMPOSE_PATH));
      JsonNode service = root.path("services").path(serviceName);

      if (service.isMissingNode()) {
        throw new RuntimeException("Service '" + serviceName + "' not found in " + COMPOSE_PATH);
      }

      String image = service.path("image").asText();
      if (image == null || image.isEmpty()) {
        throw new RuntimeException(
            "Image not defined for service '" + serviceName + "' in " + COMPOSE_PATH);
      }

      return DockerImageName.parse(image);
    } catch (IOException e) {
      throw new RuntimeException("Failed to parse " + COMPOSE_PATH, e);
    }
  }
}
