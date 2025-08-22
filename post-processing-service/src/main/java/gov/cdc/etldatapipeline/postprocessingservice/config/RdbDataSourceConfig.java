package gov.cdc.etldatapipeline.postprocessingservice.config;

import jakarta.persistence.EntityManagerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        basePackages = "gov.cdc.etldatapipeline.postprocessingservice.repository.rdb",
        entityManagerFactoryRef = "rdbEntityManagerFactory",
        transactionManagerRef = "rdbTransactionManager"
)
public class RdbDataSourceConfig {

    @Value("${spring.datasource.driver-class-name}")
    private String driverClassName;
    @Value("${spring.datasource.url-rdb}")
    private String dbUrl;
    @Value("${spring.datasource.username}")
    private String dbUserName;
    @Value("${spring.datasource.password}")
    private String dbUserPassword;



    @Bean(name = "rdbDataSource")
    public DataSource rdbDataSource() {
        return DbConfigProvider.buildHikari(driverClassName, dbUrl, dbUserName, dbUserPassword);
    }

    @Primary
    @Bean(name = "rdbEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean rdbEntityManagerFactory(
            @Qualifier("rdbDataSource") DataSource dataSource) {

        return DbConfigProvider.buildEmf(
                dataSource,
                "gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model",
                "rdb"
        );
    }

    @Primary
    @Bean(name = "rdbTransactionManager")
    public PlatformTransactionManager rdbTransactionManager(
            @Qualifier("rdbEntityManagerFactory") EntityManagerFactory emf) {
        return new JpaTransactionManager(emf);
    }
}