USE StatsNZ_LabourMarket_SSIS_DW;
GO

WITH DateSequence AS (
    SELECT CAST('1980-01-01' AS DATE) AS CalendarDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateSequence
    WHERE CalendarDate < '2030-12-31'
)
INSERT INTO dbo.DimDate (DateKey, FullDate, [Year], Quarter, QuarterName, [Month], MonthName)
SELECT 
    CAST(CONVERT(VARCHAR(8), CalendarDate, 112) AS INT) AS DateKey,
    CalendarDate AS FullDate,
    CAST(YEAR(CalendarDate) AS VARCHAR(10)) AS [Year],
    'Q' + CAST(DATEPART(QUARTER, CalendarDate) AS VARCHAR(2)) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, CalendarDate) AS VARCHAR(2)) + ' ' + CAST(YEAR(CalendarDate) AS VARCHAR(4)) AS QuarterName,
    MONTH(CalendarDate) AS [Month],
    DATENAME(MONTH, CalendarDate) AS MonthName
FROM DateSequence
OPTION (MAXRECURSION 0);
GO