package gov.cdc.etldatapipeline.postprocessingservice.config;

import jakarta.persistence.EntityManagerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        basePackages = "gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern",
        entityManagerFactoryRef = "modernEntityManagerFactory",
        transactionManagerRef = "modernTransactionManager"
)
public class RdbModernDataSourceConfig {

    @Value("${spring.datasource.driver-class-name}")
    private String driverClassName;
    @Value("${spring.datasource.url-rdb-modern}")
    private String dbUrl;
    @Value("${spring.datasource.username}")
    private String dbUserName;
    @Value("${spring.datasource.password}")
    private String dbUserPassword;


    @Bean(name = "modernDataSource")
    public DataSource modernDataSource() {
        return DbConfigProvider.buildHikari(driverClassName, dbUrl, dbUserName, dbUserPassword);
    }

    @Bean(name = "modernEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean modernEntityManagerFactory(
            @Qualifier("modernDataSource") DataSource dataSource) {

        return DbConfigProvider.buildEmf(
                dataSource,
                "gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.model",
                "rdbModern"
        );
    }

    @Bean(name = "modernTransactionManager")
    public PlatformTransactionManager modernTransactionManager(
            @Qualifier("modernEntityManagerFactory") EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }
}