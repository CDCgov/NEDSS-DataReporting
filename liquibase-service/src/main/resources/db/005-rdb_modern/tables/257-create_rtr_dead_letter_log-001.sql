IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'rtr_dead_letter_log' and xtype = 'U')
CREATE TABLE rtr_dead_letter_log (
                                     id UNIQUEIDENTIFIER PRIMARY KEY,
                                     origin_topic NVARCHAR(255) NOT NULL,
                                     payload_key NVARCHAR(MAX) NOT NULL,
                                     payload NVARCHAR(MAX) NOT NULL,
                                     original_consumer_group NVARCHAR(255) NOT NULL,
                                     exception_stack_trace NVARCHAR(MAX) NULL,
                                     exception_message NVARCHAR(MAX) NULL,
                                     exception_fqcn NVARCHAR(255) NULL,
                                     exception_cause_fqcn NVARCHAR(255) NULL,
                                     received_at  datetime2 NOT NULL,
);
