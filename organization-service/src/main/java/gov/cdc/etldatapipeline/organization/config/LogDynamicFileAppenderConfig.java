package gov.cdc.etldatapipeline.organization.config;

import ch.qos.logback.core.FileAppender;
import lombok.Setter;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

public class LogDynamicFileAppenderConfig<E> extends FileAppender<E> {

    /**
     *  Helper method used by Logback
     *  Reading logFilePatch tag from logback-config.xml and return value
     */
    @Setter
    private String logFilePath;

    /**
     * Purpose: Dynamically create log file if not exist
     */
    @Override
    public void start() {
        if (logFilePath == null) {
            addError("Log file path is not configured");
            return;
        }

        // Handle date formatting in the log file path
        if (logFilePath.contains("%d{")) {
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
            dateFormat.setTimeZone(TimeZone.getDefault());
            String formattedDate = dateFormat.format(new Date());
            logFilePath = logFilePath.replace("%d{yyyy-MM-dd_HH-mm-ss}", formattedDate);
        }

        // Normalize and validate the log file path
        Path logDir = Paths.get(System.getProperty("user.dir")); // Define a safe directory for logs
        Path normalizedPath;
        try {
            // Resolve and normalize the logFilePath to ensure it's within the safe directory
            normalizedPath = logDir.resolve(logFilePath).normalize();
            if (!normalizedPath.startsWith(logDir)) {
                addError("Log file path is outside the allowed directory");
                return;
            }
        } catch (Exception e) {
            addError("Failed to resolve log file path", e);
            return;
        }

        // Create a File object using the validated and normalized path
        File logFile = normalizedPath.toFile();

        try {
            if (!logFile.exists()) {
                Path parentDir = logFile.toPath().getParent();
                if (parentDir != null && !Files.exists(parentDir)) {
                    Files.createDirectories(parentDir);
                }
                Files.createFile(logFile.toPath());
            }
        } catch (IOException e) {
            addError("Failed to create log file: " + logFile.getAbsolutePath(), e);
            return;
        }

        setFile(logFile.getAbsolutePath()); // Set the File property with the log file path

        super.start();
    }
}