package gov.cdc.etldatapipeline.commonutil;

public class NoDataException extends RuntimeException {
    public NoDataException(String message) {
        super(message);
    }
}
