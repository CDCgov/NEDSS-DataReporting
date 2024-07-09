package gov.cdc.etldatapipeline.observation;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"gov.cdc.etldatapipeline"})
public class ObservationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(ObservationServiceApplication.class, args);
    }

}
