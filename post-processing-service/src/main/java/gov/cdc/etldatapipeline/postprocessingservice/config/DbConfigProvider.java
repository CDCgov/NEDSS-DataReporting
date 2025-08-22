package gov.cdc.etldatapipeline.postprocessingservice.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;

import javax.sql.DataSource;
import java.util.HashMap;

final class DbConfigProvider {

    private DbConfigProvider() {}

    static DataSource buildHikari(String driverClassName, String jdbcUrl, String username, String password) {
        HikariConfig cfg = new HikariConfig();
        cfg.setDriverClassName(driverClassName);
        cfg.setJdbcUrl(jdbcUrl);
        cfg.setUsername(username);
        cfg.setPassword(password);
        return new HikariDataSource(cfg);
    }

    static LocalContainerEntityManagerFactoryBean buildEmf(
            DataSource dataSource,
            String packagesToScan,
            String persistenceUnitName
    ) {
        var vendorAdapter = new HibernateJpaVendorAdapter();
        vendorAdapter.setShowSql(false);
        vendorAdapter.setGenerateDdl(false);

        var props = new HashMap<String, Object>();
        props.put("hibernate.dialect", "org.hibernate.dialect.SQLServerDialect");

        var emf = new LocalContainerEntityManagerFactoryBean();
        emf.setDataSource(dataSource);
        emf.setJpaVendorAdapter(vendorAdapter);
        emf.setPackagesToScan(packagesToScan);
        emf.setJpaPropertyMap(props);
        emf.setPersistenceUnitName(persistenceUnitName);
        return emf;
    }
}
