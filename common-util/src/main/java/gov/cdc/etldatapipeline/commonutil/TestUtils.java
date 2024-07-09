package gov.cdc.etldatapipeline.commonutil;

import org.apache.commons.io.FileUtils;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.nio.charset.Charset;

public class TestUtils {

    public static String readFileData(String fileName) {
        try {
            return FileUtils.readFileToString(
                    new ClassPathResource(fileName).getFile(),
                    Charset.defaultCharset());
        } catch (IOException e) {
            throw new RuntimeException("File Read failed : " + fileName);
        }
    }
}
