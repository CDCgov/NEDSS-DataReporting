/*
    This file is a DTS1 ONLY Script and should NOT be checked into the Liquibase Changelog
*/

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_DATAMART_TABLE_REF' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[LDF_DATAMART_TABLE_REF](
        [LDF_DATAMART_TABLE_REF_UID] [bigint] IDENTITY(1,1) NOT NULL,
        [CONDITION_CD] [varchar](30) NULL,
        [CONDITION_DESC] [varchar](100) NULL,
        [LDF_GROUP_ID] [int] NOT NULL,
        [DATAMART_NAME] [varchar](30) NOT NULL,
        [LINKED_FACT_TABLE] [varchar](50) NOT NULL,
        [ENTITY_DESC] [varchar](50) NULL
    ) ON [PRIMARY]
END

IF NOT EXISTS(SELECT 1 FROM [dbo].[LDF_DATAMART_TABLE_REF])
BEGIN
    --insert catalog 
    INSERT INTO [dbo].[LDF_DATAMART_TABLE_REF](
        CONDITION_CD,
        CONDITION_DESC,
        LDF_GROUP_ID,
        DATAMART_NAME,
        LINKED_FACT_TABLE,
        ENTITY_DESC
    )
    VALUES
    ('10650','Bacterial meningitis, other', 1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11710','Group A Streptococcus, invasive',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11715','Group B Streptococcus, invasive',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('10590','Haemophilus influenzae, invasive',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('10150','Neisseria meningitidis, invasive ',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11700','Streptococcal toxic-shock syndrome',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11716','Strep, other, invasive, beta-hem (non-A nonB)',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11717','Strep pneumoniae, invasive',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('11720','Strep pneumoniae, drug resistant, invasive',1,'LDF_BMIRD','BMIRD_CASE',null),
    ('10110','Hepatitis A, acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10100','Hepatitis B, acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10104','Hepatitis B Viral Infection, Perinatal',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10105','Hepatitis B virus infection, Chronic',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10101','Hepatitis C, acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10106','Hepatitis C Virus Infection, chronic or resolved',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10102','Hepatitis Delta co- or super-infection, acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10103','Hepatitis E, acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('10481','Hepatitis Non-ABC, Acute',2,'LDF_HEPATITIS','HEPATITIS_CASE',null),
    ('11040','Amebiasis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DD-95930','Amnesic shellfish poisoning ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DE-60046','Anisakiasis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10530','Botulism, foodborne',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10540','Botulism, infant',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10550','Botulism, other (includes wound)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10548','Botulism, other/unspecified',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10549','Botulism, wound',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10020','Brucellosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11020','Campylobacteriosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10470','Cholera',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DD-8480F','Ciguatera fish poisoning',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11580','Cryptosporidiosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11575','Cyclosporiasis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('D5-41655','Diarrheal disease, not otherwise specified',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DE-64010','Diphyllobothrium latum ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DD-80300','Foodborne illness, not otherwise specified',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11570','Giardiasis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10640','Listeriosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DE-38090','Norovirus ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DD-95910','Paralytic shellfish poisoning ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DE-35700','Rotovirus',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11000','Salmonellosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DD-95820','Scombroid fish poisoning ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11563','Shiga toxin-producing Escherichia coli (STEC)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11010','Shigellosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('DE-11340','Staphylococcal enterotoxin ',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('12020','Toxoplasmosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10270','Trichinosis (Trichinellosis)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10240','Typhoid fever (Salmonella typhi)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11541','Vibrio parahaemolyticus',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11540','Vibrio spp., non-toxigenic, other or unspecified',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11542','Vibrio vulnificus infection',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('11565','Yersiniosis',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('10245','African Tick Bite Fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11090','Anaplasma phagocytophilum',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10350','Anthrax',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10010','Aseptic meningitis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('12010','Babesiosis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11820','Cat scratch fever (Bartonellosis)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11900','Coccidioidomycosis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10093','Colorado tick fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10680','Dengue Fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10685','Dengue hemorrhagic fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10040','Diphtheria',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11088','Ehrlichiosis, chaffeensis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11089','Ehrlichiosis, ewingii',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11085','Ehrlichiosis, Human granulocytic',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11086','Ehrlichiosis, Human monocytic',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11087','Ehrlichiosis, Human, Other&unspec',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11091','Ehrlichiosis/Anaplasmosis, undetermined',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10058','Encephalitis, Cache Valley',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10053','Encephalitis, Eastern equine',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10070','Encephalitis, post-chickenpox',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10080','Encephalitis, post-mumps',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10057','Encephalitis, Powassan',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10051','Encephalitis, St. Louis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10055','Encephalitis, Venezuelan equine',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10056','Encephalitis, West Nile',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10052','Encephalitis, Western equine',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10054','Encephalitis/meningitis, Calif serogroup viral',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10570','Flu activity code (Influenza)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('9110000','Glanders',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10380','Hansen disease (Leprosy)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11610','Hantavirus infection',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11590','Hantavirus pulmonary syndrome',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11550','Hemolytic uremic synd,postdiarrheal',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11070','Influenza, animal isolates',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11060','Influenza, human isolates',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('50000','Kawasaki disease',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10490','Legionellosis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10390','Leptospirosis',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11080','Lyme disease',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10130','Malaria',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11062','Novel Influenza A Virus Infections',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('42060','Other injury',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10440','Plague',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10410','Poliomyelitis, Paralytic',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10405','Poliovirus infection nonparalytic',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10450','Psittacosis (Ornithosis)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10255','Q fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10257','Q fever, Acute',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10258','Q fever, Chronic',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10460','Rabies, human',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11030','Reye syndrome',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11050','Rheumatic fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10250','Rocky Mountain spotted fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11661','S. aureus, coag+, meth- or oxi- resistant (MRSA)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11665','S. aureus, coag-pos, vancomycin-resistant (VRSA)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11663','S. aureus, vancomycin intermediate susc (VISA)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11581','Scarlet fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11800','Smallpox',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('50010','Sudden infant death syndrome',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10520','Toxic-shock syndrome,staphylococcal',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10230','Tularemia',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10265','Typhus fever, (epidemic louseborne R. prowazekii)',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10260','Typhus fever-fleaborne, murine',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('11645','Vancomycin-Resistant Enterococcus',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('DE-11308','Verotoxigenic E. coli',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10049','West Nile Fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10660','Yellow fever',4,'LDF_GENERIC','GENERIC_CASE',null),
    ('10140','Measles (Rubeola)',5,'LDF_VACCINE_PREVENT_DISEASES','MEASLES_CASE',null),
    ('10180','Mumps',6,'LDF_MUMPS','GENERIC_CASE',null),
    ('10190','Pertussis',5,'LDF_VACCINE_PREVENT_DISEASES','PERTUSSIS_CASE',null),
    ('10200','Rubella',5,'LDF_VACCINE_PREVENT_DISEASES','RUBELLA_CASE',null),
    ('10370','Rubella, Congenital Syndrome (CRS)',5,'LDF_VACCINE_PREVENT_DISEASES','CRS_CASE',null),
    ('10210','Tetanus',7,'LDF_TETANUS','GENERIC_CASE',null),
    ('50242','Salmonellosis (excluding paratyphoid and typhoid)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('50236','Paratyphoid fever',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('50265','Salmonellosis (excluding S. typhi/paratyphi)',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('50266','Salmonella Paratyphi A/B/C',3,'LDF_FOODBORNE','GENERIC_CASE',null),
    ('50267','Typhoid Fever (S. typhi)',3,'LDF_FOODBORNE','GENERIC_CASE',null);

    delete ldf from dbo.LDF_DATAMART_TABLE_REF ldf with (nolock)
    left join dbo.nrt_datamart_metadata d with (nolock)
        on ldf.CONDITION_CD = d.condition_cd
    where d.condition_cd is null;

    /* Insert Tetanus & Mumps into LDF_DATAMART_TABLE_REF for testing*/
    INSERT INTO [dbo].[LDF_DATAMART_TABLE_REF](
        CONDITION_CD,
        CONDITION_DESC,
        LDF_GROUP_ID,
        DATAMART_NAME,
        LINKED_FACT_TABLE,
        ENTITY_DESC
    )
    VALUES
        ('10210','Tetanus',7,'LDF_TETANUS','GENERIC_CASE',null),
            ('10180','Mumps',6,'LDF_MUMPS','GENERIC_CASE',null);

    INSERT INTO [dbo].[LDF_DATAMART_TABLE_REF](
        CONDITION_CD,
        CONDITION_DESC,
        LDF_GROUP_ID,
        DATAMART_NAME,
        LINKED_FACT_TABLE,
        ENTITY_DESC
    )
    VALUES
        ('999999','Hepatitis',2,'LDF_HEPATITIS','HEPATITIS_CASE',null);

    
    /* Added this new CC for BMIRD specifically for the INT1 Environment.*/
    INSERT INTO [dbo].[LDF_DATAMART_TABLE_REF](
        CONDITION_CD,
        CONDITION_DESC,
        LDF_GROUP_ID,
        DATAMART_NAME,
        LINKED_FACT_TABLE,
        ENTITY_DESC
    )
    VALUES
        ('11723','Streptococcus pneumoniae, invasive disease (IPD) (all ages)',1,'LDF_BMIRD','BMIRD_CASE',null);
END