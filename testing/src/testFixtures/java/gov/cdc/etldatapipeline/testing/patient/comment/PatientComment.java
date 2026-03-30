package gov.cdc.etldatapipeline.testing.patient.comment;

import java.time.LocalDateTime;

/**
 * Contains the data necessary for setting a comment on a patient profile. This comment is stored on
 * the Person table
 */
public record PatientComment(LocalDateTime asOf, String comment) {}
