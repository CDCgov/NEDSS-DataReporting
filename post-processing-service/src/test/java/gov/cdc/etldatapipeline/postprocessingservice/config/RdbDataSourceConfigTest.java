package gov.cdc.etldatapipeline.postprocessingservice.config;

import com.zaxxer.hikari.HikariDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import javax.sql.DataSource;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RdbDataSourceConfigTest {

    private RdbDataSourceConfig config;

    @BeforeEach
    void setUp() {
        config = new RdbDataSourceConfig();
        // Set test properties using reflection
        ReflectionTestUtils.setField(config, "driverClassName", "com.microsoft.sqlserver.jdbc.SQLServerDriver");
        ReflectionTestUtils.setField(config, "dbUrl", "jdbc:sqlserver://localhost:1433;databaseName=rdbdb");
        ReflectionTestUtils.setField(config, "dbUserName", "rdbuser");
        ReflectionTestUtils.setField(config, "dbUserPassword", "rdbpass");
    }

    @Test
    void testConfigurationAnnotations() {
        // Test that the class has the correct annotations
        assertTrue(RdbDataSourceConfig.class.isAnnotationPresent(org.springframework.context.annotation.Configuration.class));
        assertTrue(RdbDataSourceConfig.class.isAnnotationPresent(org.springframework.transaction.annotation.EnableTransactionManagement.class));
        assertTrue(RdbDataSourceConfig.class.isAnnotationPresent(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class));
        
        org.springframework.data.jpa.repository.config.EnableJpaRepositories enableJpaRepositories = 
                RdbDataSourceConfig.class.getAnnotation(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class);
        
        assertEquals("gov.cdc.etldatapipeline.postprocessingservice.repository.rdb", enableJpaRepositories.basePackages()[0]);
        assertEquals("rdbEntityManagerFactory", enableJpaRepositories.entityManagerFactoryRef());
        assertEquals("rdbTransactionManager", enableJpaRepositories.transactionManagerRef());
    }

    @Test
    void testConfigurationPropertiesInjection() {
        // Test that configuration properties are properly injected
        String driverClassName = (String) ReflectionTestUtils.getField(config, "driverClassName");
        String dbUrl = (String) ReflectionTestUtils.getField(config, "dbUrl");
        String dbUserName = (String) ReflectionTestUtils.getField(config, "dbUserName");
        String dbUserPassword = (String) ReflectionTestUtils.getField(config, "dbUserPassword");
        
        assertEquals("com.microsoft.sqlserver.jdbc.SQLServerDriver", driverClassName);
        assertEquals("jdbc:sqlserver://localhost:1433;databaseName=rdbdb", dbUrl);
        assertEquals("rdbuser", dbUserName);
        assertEquals("rdbpass", dbUserPassword);
    }

    @Test
    void testDbConfigProviderIntegration() {
        // Test integration with DbConfigProvider using mocked static methods
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            // Mock the buildHikari method
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildHikari(anyString(), anyString(), anyString(), anyString()))
                    .thenReturn(mockDataSource);
            
            // Mock the buildEmf method
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean mockEmf = mock(org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean.class);
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildEmf(any(DataSource.class), anyString(), anyString()))
                    .thenReturn(mockEmf);
            
            // Test rdbDataSource method
            DataSource resultDataSource = config.rdbDataSource();
            assertEquals(mockDataSource, resultDataSource);
            
            // Verify buildHikari was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildHikari(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "jdbc:sqlserver://localhost:1433;databaseName=rdbdb",
                    "rdbuser",
                    "rdbpass"
            ));
            
            // Test rdbEntityManagerFactory method
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean resultEmf = config.rdbEntityManagerFactory(mockDataSource);
            assertEquals(mockEmf, resultEmf);
            
            // Verify buildEmf was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildEmf(
                    mockDataSource,
                    "gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model",
                    "rdb"
            ));
        }
    }

    @Test
    void testRdbDataSourceMethod() {
        // Test that the rdbDataSource method calls DbConfigProvider correctly
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildHikari(anyString(), anyString(), anyString(), anyString()))
                    .thenReturn(mockDataSource);
            
            DataSource result = config.rdbDataSource();
            
            assertNotNull(result);
            assertEquals(mockDataSource, result);
            
            // Verify the method was called with the injected properties
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildHikari(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "jdbc:sqlserver://localhost:1433;databaseName=rdbdb",
                    "rdbuser",
                    "rdbpass"
            ));
        }
    }

    @Test
    void testRdbEntityManagerFactoryMethod() {
        // Test that the rdbEntityManagerFactory method calls DbConfigProvider correctly
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean mockEmf = mock(org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean.class);
            
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildEmf(any(DataSource.class), anyString(), anyString()))
                    .thenReturn(mockEmf);
            
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean result = config.rdbEntityManagerFactory(mockDataSource);
            
            assertNotNull(result);
            assertEquals(mockEmf, result);
            
            // Verify the method was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildEmf(
                    mockDataSource,
                    "gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model",
                    "rdb"
            ));
        }
    }

    @Test
    void testRdbTransactionManagerMethod() {
        // Test that the rdbTransactionManager method creates a JpaTransactionManager correctly
        jakarta.persistence.EntityManagerFactory mockEmf = mock(jakarta.persistence.EntityManagerFactory.class);
        
        // Test the method
        org.springframework.transaction.PlatformTransactionManager result = config.rdbTransactionManager(mockEmf);
        
        assertNotNull(result);
        assertTrue(result instanceof org.springframework.orm.jpa.JpaTransactionManager);
    }

    @Test
    void testBeanMethodNames() {
        // Test that the @Bean methods have the correct names
        try {
            java.lang.reflect.Method rdbDataSourceMethod = RdbDataSourceConfig.class.getMethod("rdbDataSource");
            java.lang.reflect.Method rdbEntityManagerFactoryMethod = RdbDataSourceConfig.class.getMethod("rdbEntityManagerFactory", DataSource.class);
            java.lang.reflect.Method rdbTransactionManagerMethod = RdbDataSourceConfig.class.getMethod("rdbTransactionManager", jakarta.persistence.EntityManagerFactory.class);
            
            // Check @Bean annotations
            assertTrue(rdbDataSourceMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            assertTrue(rdbEntityManagerFactoryMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            assertTrue(rdbTransactionManagerMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            
            // Check bean names
            org.springframework.context.annotation.Bean dataSourceBean = rdbDataSourceMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            org.springframework.context.annotation.Bean emfBean = rdbEntityManagerFactoryMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            org.springframework.context.annotation.Bean tmBean = rdbTransactionManagerMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            
            assertEquals("rdbDataSource", dataSourceBean.name()[0]);
            assertEquals("rdbEntityManagerFactory", emfBean.name()[0]);
            assertEquals("rdbTransactionManager", tmBean.name()[0]);
            
        } catch (NoSuchMethodException e) {
            fail("Expected methods not found: " + e.getMessage());
        }
    }

    @Test
    void testPrimaryAnnotations() {
        // Test that the @Primary annotations are present on the correct methods
        try {
            java.lang.reflect.Method rdbEntityManagerFactoryMethod = RdbDataSourceConfig.class.getMethod("rdbEntityManagerFactory", DataSource.class);
            java.lang.reflect.Method rdbTransactionManagerMethod = RdbDataSourceConfig.class.getMethod("rdbTransactionManager", jakarta.persistence.EntityManagerFactory.class);
            
            // Check @Primary annotations
            assertTrue(rdbEntityManagerFactoryMethod.isAnnotationPresent(org.springframework.context.annotation.Primary.class));
            assertTrue(rdbTransactionManagerMethod.isAnnotationPresent(org.springframework.context.annotation.Primary.class));
            
            // Verify rdbDataSource method does NOT have @Primary annotation
            java.lang.reflect.Method rdbDataSourceMethod = RdbDataSourceConfig.class.getMethod("rdbDataSource");
            assertFalse(rdbDataSourceMethod.isAnnotationPresent(org.springframework.context.annotation.Primary.class));
            
        } catch (NoSuchMethodException e) {
            fail("Expected methods not found: " + e.getMessage());
        }
    }

    @Test
    void testConstructor() {
        // Test that the constructor works correctly
        RdbDataSourceConfig newConfig = new RdbDataSourceConfig();
        assertNotNull(newConfig);
        
        // Verify fields are initialized (should be null initially)
        String driverClassName = (String) ReflectionTestUtils.getField(newConfig, "driverClassName");
        String dbUrl = (String) ReflectionTestUtils.getField(newConfig, "dbUrl");
        String dbUserName = (String) ReflectionTestUtils.getField(newConfig, "dbUserName");
        String dbUserPassword = (String) ReflectionTestUtils.getField(newConfig, "dbUserPassword");
        
        // These should be null until properties are injected by Spring
        assertNull(driverClassName);
        assertNull(dbUrl);
        assertNull(dbUserName);
        assertNull(dbUserPassword);
    }

    @Test
    void testValueAnnotations() {
        // Test that the @Value annotations are present on the fields
        try {
            java.lang.reflect.Field driverClassNameField = RdbDataSourceConfig.class.getDeclaredField("driverClassName");
            java.lang.reflect.Field dbUrlField = RdbDataSourceConfig.class.getDeclaredField("dbUrl");
            java.lang.reflect.Field dbUserNameField = RdbDataSourceConfig.class.getDeclaredField("dbUserName");
            java.lang.reflect.Field dbUserPasswordField = RdbDataSourceConfig.class.getDeclaredField("dbUserPassword");
            
            assertTrue(driverClassNameField.isAnnotationPresent(org.springframework.beans.factory.annotation.Value.class));
            assertTrue(dbUrlField.isAnnotationPresent(org.springframework.beans.factory.annotation.Value.class));
            assertTrue(dbUserNameField.isAnnotationPresent(org.springframework.beans.factory.annotation.Value.class));
            assertTrue(dbUserPasswordField.isAnnotationPresent(org.springframework.beans.factory.annotation.Value.class));
            
            // Check the specific values
            org.springframework.beans.factory.annotation.Value driverValue = driverClassNameField.getAnnotation(org.springframework.beans.factory.annotation.Value.class);
            org.springframework.beans.factory.annotation.Value urlValue = dbUrlField.getAnnotation(org.springframework.beans.factory.annotation.Value.class);
            org.springframework.beans.factory.annotation.Value usernameValue = dbUserNameField.getAnnotation(org.springframework.beans.factory.annotation.Value.class);
            org.springframework.beans.factory.annotation.Value passwordValue = dbUserPasswordField.getAnnotation(org.springframework.beans.factory.annotation.Value.class);
            
            assertEquals("${spring.datasource.driver-class-name}", driverValue.value());
            assertEquals("${spring.datasource.url-rdb}", urlValue.value());
            assertEquals("${spring.datasource.username}", usernameValue.value());
            assertEquals("${spring.datasource.password}", passwordValue.value());
            
        } catch (NoSuchFieldException e) {
            fail("Expected fields not found: " + e.getMessage());
        }
    }

    @Test
    void testQualifierAnnotations() {
        // Test that the @Qualifier annotations are present on method parameters
        try {
            java.lang.reflect.Method emfMethod = RdbDataSourceConfig.class.getMethod("rdbEntityManagerFactory", DataSource.class);
            java.lang.reflect.Method tmMethod = RdbDataSourceConfig.class.getMethod("rdbTransactionManager", jakarta.persistence.EntityManagerFactory.class);
            
            // Check @Qualifier on rdbEntityManagerFactory parameter
            java.lang.reflect.Parameter dataSourceParam = emfMethod.getParameters()[0];
            assertTrue(dataSourceParam.isAnnotationPresent(org.springframework.beans.factory.annotation.Qualifier.class));
            org.springframework.beans.factory.annotation.Qualifier dataSourceQualifier = dataSourceParam.getAnnotation(org.springframework.beans.factory.annotation.Qualifier.class);
            assertEquals("rdbDataSource", dataSourceQualifier.value());
            
            // Check @Qualifier on rdbTransactionManager parameter
            java.lang.reflect.Parameter emfParam = tmMethod.getParameters()[0];
            assertTrue(emfParam.isAnnotationPresent(org.springframework.beans.factory.annotation.Qualifier.class));
            org.springframework.beans.factory.annotation.Qualifier emfQualifier = emfParam.getAnnotation(org.springframework.beans.factory.annotation.Qualifier.class);
            assertEquals("rdbEntityManagerFactory", emfQualifier.value());
            
        } catch (NoSuchMethodException e) {
            fail("Expected methods not found: " + e.getMessage());
        }
    }

    @Test
    void testConfigurationDifferencesFromModern() {
        // Test that this configuration is different from the modern one
        // This helps ensure the two configurations don't conflict
        
        // Check different base packages
        org.springframework.data.jpa.repository.config.EnableJpaRepositories rdbEnableJpaRepositories = 
                RdbDataSourceConfig.class.getAnnotation(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class);
        org.springframework.data.jpa.repository.config.EnableJpaRepositories modernEnableJpaRepositories = 
                RdbModernDataSourceConfig.class.getAnnotation(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class);
        
        assertEquals("gov.cdc.etldatapipeline.postprocessingservice.repository.rdb", rdbEnableJpaRepositories.basePackages()[0]);
        assertEquals("gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern", modernEnableJpaRepositories.basePackages()[0]);
        
        // Check different entity manager factory references
        assertEquals("rdbEntityManagerFactory", rdbEnableJpaRepositories.entityManagerFactoryRef());
        assertEquals("modernEntityManagerFactory", modernEnableJpaRepositories.entityManagerFactoryRef());
        
        // Check different transaction manager references
        assertEquals("rdbTransactionManager", rdbEnableJpaRepositories.transactionManagerRef());
        assertEquals("modernTransactionManager", modernEnableJpaRepositories.transactionManagerRef());
    }

    @Test
    void testBeanMethodReturnTypes() {
        // Test that the bean methods return the correct types
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            // Mock dependencies
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean mockEmf = mock(org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean.class);
            jakarta.persistence.EntityManagerFactory mockEntityManagerFactory = mock(jakarta.persistence.EntityManagerFactory.class);
            
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildHikari(anyString(), anyString(), anyString(), anyString()))
                    .thenReturn(mockDataSource);
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildEmf(any(DataSource.class), anyString(), anyString()))
                    .thenReturn(mockEmf);
            
            // Test return types
            DataSource dataSourceResult = config.rdbDataSource();
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean emfResult = config.rdbEntityManagerFactory(mockDataSource);
            org.springframework.transaction.PlatformTransactionManager tmResult = config.rdbTransactionManager(mockEntityManagerFactory);
            
            assertTrue(dataSourceResult instanceof DataSource);
            assertTrue(emfResult instanceof org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean);
            assertTrue(tmResult instanceof org.springframework.transaction.PlatformTransactionManager);
            assertTrue(tmResult instanceof org.springframework.orm.jpa.JpaTransactionManager);
        }
    }

    @Test
    void testFieldAccessibility() {
        // Test that the fields are properly accessible via reflection
        // This ensures the @Value annotations can inject values
        
        RdbDataSourceConfig testConfig = new RdbDataSourceConfig();
        
        // Test that we can set and get fields using reflection
        ReflectionTestUtils.setField(testConfig, "driverClassName", "test.driver");
        ReflectionTestUtils.setField(testConfig, "dbUrl", "test.url");
        ReflectionTestUtils.setField(testConfig, "dbUserName", "test.user");
        ReflectionTestUtils.setField(testConfig, "dbUserPassword", "test.pass");
        
        String driverClassName = (String) ReflectionTestUtils.getField(testConfig, "driverClassName");
        String dbUrl = (String) ReflectionTestUtils.getField(testConfig, "dbUrl");
        String dbUserName = (String) ReflectionTestUtils.getField(testConfig, "dbUserName");
        String dbUserPassword = (String) ReflectionTestUtils.getField(testConfig, "dbUserPassword");
        
        assertEquals("test.driver", driverClassName);
        assertEquals("test.url", dbUrl);
        assertEquals("test.user", dbUserName);
        assertEquals("test.pass", dbUserPassword);
    }
}
