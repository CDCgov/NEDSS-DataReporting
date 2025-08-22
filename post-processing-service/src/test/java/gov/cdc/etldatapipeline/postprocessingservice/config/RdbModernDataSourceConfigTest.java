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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;

@ExtendWith(MockitoExtension.class)
class RdbModernDataSourceConfigTest {

    private RdbModernDataSourceConfig config;

    @BeforeEach
    void setUp() {
        config = new RdbModernDataSourceConfig();
        // Set test properties using reflection
        ReflectionTestUtils.setField(config, "driverClassName", "com.microsoft.sqlserver.jdbc.SQLServerDriver");
        ReflectionTestUtils.setField(config, "dbUrl", "jdbc:sqlserver://localhost:1433;databaseName=testdb");
        ReflectionTestUtils.setField(config, "dbUserName", "testuser");
        ReflectionTestUtils.setField(config, "dbUserPassword", "testpass");
    }

    @Test
    void testConfigurationAnnotations() {
        // Test that the class has the correct annotations
        assertTrue(RdbModernDataSourceConfig.class.isAnnotationPresent(org.springframework.context.annotation.Configuration.class));
        assertTrue(RdbModernDataSourceConfig.class.isAnnotationPresent(org.springframework.transaction.annotation.EnableTransactionManagement.class));
        assertTrue(RdbModernDataSourceConfig.class.isAnnotationPresent(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class));
        
        org.springframework.data.jpa.repository.config.EnableJpaRepositories enableJpaRepositories = 
                RdbModernDataSourceConfig.class.getAnnotation(org.springframework.data.jpa.repository.config.EnableJpaRepositories.class);
        
        assertEquals("gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern", enableJpaRepositories.basePackages()[0]);
        assertEquals("modernEntityManagerFactory", enableJpaRepositories.entityManagerFactoryRef());
        assertEquals("modernTransactionManager", enableJpaRepositories.transactionManagerRef());
    }

    @Test
    void testConfigurationPropertiesInjection() {
        // Test that configuration properties are properly injected
        String driverClassName = (String) ReflectionTestUtils.getField(config, "driverClassName");
        String dbUrl = (String) ReflectionTestUtils.getField(config, "dbUrl");
        String dbUserName = (String) ReflectionTestUtils.getField(config, "dbUserName");
        String dbUserPassword = (String) ReflectionTestUtils.getField(config, "dbUserPassword");
        
        assertEquals("com.microsoft.sqlserver.jdbc.SQLServerDriver", driverClassName);
        assertEquals("jdbc:sqlserver://localhost:1433;databaseName=testdb", dbUrl);
        assertEquals("testuser", dbUserName);
        assertEquals("testpass", dbUserPassword);
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
            
            // Test modernDataSource method
            DataSource resultDataSource = config.modernDataSource();
            assertEquals(mockDataSource, resultDataSource);
            
            // Verify buildHikari was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildHikari(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "jdbc:sqlserver://localhost:1433;databaseName=testdb",
                    "testuser",
                    "testpass"
            ));
            
            // Test modernEntityManagerFactory method
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean resultEmf = config.modernEntityManagerFactory(mockDataSource);
            assertEquals(mockEmf, resultEmf);
            
            // Verify buildEmf was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildEmf(
                    mockDataSource,
                    "gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.model",
                    "rdbModern"
            ));
        }
    }

    @Test
    void testModernDataSourceMethod() {
        // Test that the modernDataSource method calls DbConfigProvider correctly
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildHikari(anyString(), anyString(), anyString(), anyString()))
                    .thenReturn(mockDataSource);
            
            DataSource result = config.modernDataSource();
            
            assertNotNull(result);
            assertEquals(mockDataSource, result);
            
            // Verify the method was called with the injected properties
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildHikari(
                    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
                    "jdbc:sqlserver://localhost:1433;databaseName=testdb",
                    "testuser",
                    "testpass"
            ));
        }
    }

    @Test
    void testModernEntityManagerFactoryMethod() {
        // Test that the modernEntityManagerFactory method calls DbConfigProvider correctly
        try (MockedStatic<DbConfigProvider> mockedDbConfigProvider = Mockito.mockStatic(DbConfigProvider.class)) {
            HikariDataSource mockDataSource = mock(HikariDataSource.class);
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean mockEmf = mock(org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean.class);
            
            mockedDbConfigProvider.when(() -> DbConfigProvider.buildEmf(any(DataSource.class), anyString(), anyString()))
                    .thenReturn(mockEmf);
            
            org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean result = config.modernEntityManagerFactory(mockDataSource);
            
            assertNotNull(result);
            assertEquals(mockEmf, result);
            
            // Verify the method was called with correct parameters
            mockedDbConfigProvider.verify(() -> DbConfigProvider.buildEmf(
                    mockDataSource,
                    "gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.model",
                    "rdbModern"
            ));
        }
    }

    @Test
    void testModernTransactionManagerMethod() {
        // Test that the modernTransactionManager method creates a JpaTransactionManager correctly
        jakarta.persistence.EntityManagerFactory mockEmf = mock(jakarta.persistence.EntityManagerFactory.class);
        
        // Test the method
        org.springframework.transaction.PlatformTransactionManager result = config.modernTransactionManager(mockEmf);
        
        assertNotNull(result);
        assertTrue(result instanceof org.springframework.orm.jpa.JpaTransactionManager);
    }

    @Test
    void testBeanMethodNames() {
        // Test that the @Bean methods have the correct names
        try {
            java.lang.reflect.Method modernDataSourceMethod = RdbModernDataSourceConfig.class.getMethod("modernDataSource");
            java.lang.reflect.Method modernEntityManagerFactoryMethod = RdbModernDataSourceConfig.class.getMethod("modernEntityManagerFactory", DataSource.class);
            java.lang.reflect.Method modernTransactionManagerMethod = RdbModernDataSourceConfig.class.getMethod("modernTransactionManager", jakarta.persistence.EntityManagerFactory.class);
            
            // Check @Bean annotations
            assertTrue(modernDataSourceMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            assertTrue(modernEntityManagerFactoryMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            assertTrue(modernTransactionManagerMethod.isAnnotationPresent(org.springframework.context.annotation.Bean.class));
            
            // Check bean names
            org.springframework.context.annotation.Bean dataSourceBean = modernDataSourceMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            org.springframework.context.annotation.Bean emfBean = modernEntityManagerFactoryMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            org.springframework.context.annotation.Bean tmBean = modernTransactionManagerMethod.getAnnotation(org.springframework.context.annotation.Bean.class);
            
            assertEquals("modernDataSource", dataSourceBean.name()[0]);
            assertEquals("modernEntityManagerFactory", emfBean.name()[0]);
            assertEquals("modernTransactionManager", tmBean.name()[0]);
            
        } catch (NoSuchMethodException e) {
            fail("Expected methods not found: " + e.getMessage());
        }
    }

    @Test
    void testConstructor() {
        // Test that the constructor works correctly
        RdbModernDataSourceConfig newConfig = new RdbModernDataSourceConfig();
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
            java.lang.reflect.Field driverClassNameField = RdbModernDataSourceConfig.class.getDeclaredField("driverClassName");
            java.lang.reflect.Field dbUrlField = RdbModernDataSourceConfig.class.getDeclaredField("dbUrl");
            java.lang.reflect.Field dbUserNameField = RdbModernDataSourceConfig.class.getDeclaredField("dbUserName");
            java.lang.reflect.Field dbUserPasswordField = RdbModernDataSourceConfig.class.getDeclaredField("dbUserPassword");
            
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
            assertEquals("${spring.datasource.url-rdb-modern}", urlValue.value());
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
            java.lang.reflect.Method emfMethod = RdbModernDataSourceConfig.class.getMethod("modernEntityManagerFactory", DataSource.class);
            java.lang.reflect.Method tmMethod = RdbModernDataSourceConfig.class.getMethod("modernTransactionManager", jakarta.persistence.EntityManagerFactory.class);
            
            // Check @Qualifier on modernEntityManagerFactory parameter
            java.lang.reflect.Parameter dataSourceParam = emfMethod.getParameters()[0];
            assertTrue(dataSourceParam.isAnnotationPresent(org.springframework.beans.factory.annotation.Qualifier.class));
            org.springframework.beans.factory.annotation.Qualifier dataSourceQualifier = dataSourceParam.getAnnotation(org.springframework.beans.factory.annotation.Qualifier.class);
            assertEquals("modernDataSource", dataSourceQualifier.value());
            
            // Check @Qualifier on modernTransactionManager parameter
            java.lang.reflect.Parameter emfParam = tmMethod.getParameters()[0];
            assertTrue(emfParam.isAnnotationPresent(org.springframework.beans.factory.annotation.Qualifier.class));
            org.springframework.beans.factory.annotation.Qualifier emfQualifier = emfParam.getAnnotation(org.springframework.beans.factory.annotation.Qualifier.class);
            assertEquals("modernEntityManagerFactory", emfQualifier.value());
            
        } catch (NoSuchMethodException e) {
            fail("Expected methods not found: " + e.getMessage());
        }
    }
}
