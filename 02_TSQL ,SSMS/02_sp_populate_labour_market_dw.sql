USE [StatsNZ_LabourMarket_MaskedDW];
GO

CREATE OR ALTER PROCEDURE dbo.sp_PopulateLabourMarketDW
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==================================================';
    PRINT 'STARTING ETL TRANSFORM & CONVERSION PROCESS';
    PRINT '==================================================';

    ------------------------------------------------------------------------------------
    -- 0. CLEAN SLATE
    ------------------------------------------------------------------------------------
    PRINT 'Clearing existing records...';
    DELETE FROM dbo.FactLabourMarket;
    DELETE FROM dbo.DimDataset;
    DELETE FROM dbo.DimSeries;
    DELETE FROM dbo.DimGroup;
    DELETE FROM dbo.DimUnitStatus;

    ------------------------------------------------------------------------------------
    -- 1. POPULATE DIMDATASET
    ------------------------------------------------------------------------------------
    PRINT '1. Populating DimDataset...';
    INSERT INTO dbo.DimDataset (DatasetCode, DatasetName)
    VALUES 
        ('MEI', 'Monthly Employment Indicators'),
        ('HLFS', 'Household Labour Force Survey'),
        ('HLFS_POP', 'HLFS Population Estimates'),
        ('LCI', 'Labour Cost Index'),
        ('LMS', 'Labour Market Statistics Overview'),
        ('QES', 'Quarterly Employment Survey');

    ------------------------------------------------------------------------------------
    -- 2. POPULATE DIMDATE (1980 to 2030)
    ------------------------------------------------------------------------------------
    PRINT '2. Populating DimDate...';
    IF NOT EXISTS (SELECT 1 FROM dbo.DimDate)
    BEGIN
        DECLARE @StartDate DATE = '1980-01-01';
        DECLARE @EndDate DATE = '2030-12-31';

        WHILE @StartDate <= @EndDate
        BEGIN
            INSERT INTO dbo.DimDate (DateKey, FullDate, [Year], Quarter, QuarterName, [Month], MonthName)
            VALUES (
                CAST(CONVERT(VARCHAR(8), @StartDate, 112) AS INT),
                @StartDate,
                CAST(YEAR(@StartDate) AS VARCHAR(4)),
                'Q' + CAST(DATEPART(QUARTER, @StartDate) AS VARCHAR(1)),
                CAST(YEAR(@StartDate) AS VARCHAR(4)) + ' Q' + CAST(DATEPART(QUARTER, @StartDate) AS VARCHAR(1)),
                MONTH(@StartDate),
                DATENAME(MONTH, @StartDate)
            );
            SET @StartDate = DATEADD(DAY, 1, @StartDate);
        END;
    END;

    ------------------------------------------------------------------------------------
    -- 3. POPULATE DIMSERIES
    ------------------------------------------------------------------------------------
    PRINT '3. Populating DimSeries...';
    INSERT INTO dbo.DimSeries (SeriesReference, Title1, Title2)
    SELECT DISTINCT 
        TRIM(Series_reference),
        NULLIF(TRIM(Title1), ''),
        NULLIF(TRIM(Title2), '')
    FROM (
        SELECT Series_reference, Series_title_1 AS Title1, Series_title_2 AS Title2 
        FROM StatsNZ_LabourMarket_DW.stg._employment_indicators_raw
        UNION ALL
        SELECT Series_reference, Series_title_1, Series_title_2 
        FROM StatsNZ_LabourMarket_DW.stg._lci_raw
        UNION ALL
        SELECT Series_reference, Series_title_1, Series_title_2 
        FROM StatsNZ_LabourMarket_DW.stg._lms_raw
        UNION ALL
        SELECT Series_reference, Series_title_1, Series_title_2 
        FROM StatsNZ_LabourMarket_DW.stg._qes_raw
        UNION ALL
        SELECT Series_reference, NULL AS Title1, NULL AS Title2 
        FROM StatsNZ_LabourMarket_DW.stg._hlfs_raw
        UNION ALL
        SELECT Series_reference, NULL AS Title1, NULL AS Title2 
        FROM StatsNZ_LabourMarket_DW.stg._household_labour_force_survey_population_raw
    ) CombinedSeries
    WHERE Series_reference IS NOT NULL 
      AND TRIM(Series_reference) <> '';

    ------------------------------------------------------------------------------------
    -- 4. POPULATE DIMGROUP
    ------------------------------------------------------------------------------------
    PRINT '4. Populating DimGroup...';
    INSERT INTO dbo.DimGroup (Subject, [Group])
    SELECT DISTINCT 
        NULLIF(TRIM(Subject), ''),
        NULLIF(TRIM([Group]), '')
    FROM (
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._employment_indicators_raw
        UNION
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._hlfs_raw
        UNION
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._household_labour_force_survey_population_raw
        UNION
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._lci_raw
        UNION
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._lms_raw
        UNION
        SELECT Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._qes_raw
    ) CombinedGroups;

    ------------------------------------------------------------------------------------
    -- 5. POPULATE DIMUNITSTATUS
    ------------------------------------------------------------------------------------
    PRINT '5. Populating DimUnitStatus...';
    INSERT INTO dbo.DimUnitStatus (Units, [Status])
    SELECT DISTINCT 
        NULLIF(TRIM(UNITS), ''),
        NULLIF(TRIM(STATUS), '')
    FROM (
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._employment_indicators_raw
        UNION
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._hlfs_raw
        UNION
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._household_labour_force_survey_population_raw
        UNION
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._lci_raw
        UNION
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._lms_raw
        UNION
        SELECT UNITS, STATUS FROM StatsNZ_LabourMarket_DW.stg._qes_raw
    ) CombinedUnits;

    ------------------------------------------------------------------------------------
    -- 6. POPULATE FACTLABOURMARKET
    ------------------------------------------------------------------------------------
    PRINT '6. Populating FactLabourMarket...';
    
    WITH RawConsolidated AS (
        SELECT 'MEI' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._employment_indicators_raw
        UNION ALL
        SELECT 'HLFS' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._hlfs_raw
        UNION ALL
        SELECT 'HLFS_POP' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._household_labour_force_survey_population_raw
        UNION ALL
        SELECT 'LCI' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._lci_raw
        UNION ALL
        SELECT 'LMS' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._lms_raw
        UNION ALL
        SELECT 'QES' AS DatasetCode, Series_reference, Period, Data_value, STATUS, UNITS, Subject, [Group] FROM StatsNZ_LabourMarket_DW.stg._qes_raw
    ),
    ParsedPeriods AS (
        SELECT 
            r.*,
            -- Split 'YYYY.MM' or 'YYYY.Q'
            LEFT(CAST(r.Period AS VARCHAR(20)), 4) AS YYYY,
            SUBSTRING(CAST(r.Period AS VARCHAR(20)), CHARINDEX('.', CAST(r.Period AS VARCHAR(20))) + 1, 5) AS SubPart
        FROM RawConsolidated r
        WHERE CHARINDEX('.', CAST(r.Period AS VARCHAR(20))) > 0
    ),
    MappedDates AS (
        SELECT 
            p.*,
            -- Derive Month (1-12) based on whether Dataset is Monthly or Quarterly
            CASE 
                -- Monthly indicator: Subpart is direct Month (e.g., .01 -> 1, .12 -> 12)
                WHEN p.DatasetCode = 'MEI' THEN TRY_CAST(p.SubPart AS INT)
                -- Quarterly indicator: Subpart is Quarter 1..4 -> Maps to End-of-Quarter Month (3, 6, 9, 12)
                WHEN TRY_CAST(p.SubPart AS INT) BETWEEN 1 AND 4 THEN TRY_CAST(p.SubPart AS INT) * 3
                -- Fallback for 2-digit month formats in quarterly tables
                ELSE TRY_CAST(p.SubPart AS INT)
            END AS CalculatedMonth
        FROM ParsedPeriods p
    )
    INSERT INTO dbo.FactLabourMarket (DateKey, DatasetKey, SeriesKey, GroupKey, UnitStatusKey, DataValue)
    SELECT 
        -- Creates accurate YYYYMM01 DateKey integers matching DimDate
        CAST(
            m.YYYY + 
            RIGHT('0' + CAST(m.CalculatedMonth AS VARCHAR(2)), 2) + 
            '01' AS INT
        ) AS DateKey,
        ds.DatasetKey,
        s.SeriesKey,
        g.GroupKey,
        u.UnitStatusKey,
        TRY_CAST(REPLACE(m.Data_value, ',', '') AS REAL) AS DataValue
    FROM MappedDates m
    JOIN dbo.DimDate d ON d.DateKey = CAST(m.YYYY + RIGHT('0' + CAST(m.CalculatedMonth AS VARCHAR(2)), 2) + '01' AS INT)
    JOIN dbo.DimDataset ds ON ds.DatasetCode = m.DatasetCode
    JOIN dbo.DimSeries s ON s.SeriesReference = TRIM(m.Series_reference)
    LEFT JOIN dbo.DimGroup g ON ISNULL(g.Subject, '') = ISNULL(TRIM(m.Subject), '') AND ISNULL(g.[Group], '') = ISNULL(TRIM(m.[Group]), '')
    LEFT JOIN dbo.DimUnitStatus u ON ISNULL(u.Units, '') = ISNULL(TRIM(m.UNITS), '') AND ISNULL(u.[Status], '') = ISNULL(TRIM(m.STATUS), '')
    WHERE TRY_CAST(REPLACE(m.Data_value, ',', '') AS REAL) IS NOT NULL;

    PRINT '==================================================';
    PRINT 'ETL PROCESS COMPLETED SUCCESSFULLY!';
    PRINT '==================================================';
END;
GO