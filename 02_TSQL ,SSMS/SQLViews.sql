USE [StatsNZ_LabourMarket_MaskedDW];
GO

-- 1. View for FactLabourMarket
CREATE OR ALTER VIEW dbo.vw_FactLabourMarket
AS
SELECT 
    FactID,
    DateKey,
    DatasetKey,
    SeriesKey,
    GroupKey,
    UnitStatusKey,
    DataValue
FROM dbo.FactLabourMarket;
GO

-- 2. View for DimDate
CREATE OR ALTER VIEW dbo.vw_DimDate
AS
SELECT 
    DateKey,
    FullDate,
    [Year],
    Quarter,
    QuarterName,
    [Month],
    MonthName
FROM dbo.DimDate;
GO

-- 3. View for DimDataset
CREATE OR ALTER VIEW dbo.vw_DimDataset
AS
SELECT 
    DatasetKey,
    DatasetCode,
    DatasetName
FROM dbo.DimDataset;
GO

-- 4. View for DimSeries
CREATE OR ALTER VIEW dbo.vw_DimSeries
AS
SELECT 
    SeriesKey,
    SeriesReference,
    ISNULL(Title1, 'N/A') AS SeriesTitle1,
    ISNULL(Title2, 'N/A') AS SeriesTitle2
FROM dbo.DimSeries;
GO

-- 5. View for DimGroup
CREATE OR ALTER VIEW dbo.vw_DimGroup
AS
SELECT 
    GroupKey,
    ISNULL(Subject, 'Uncategorized') AS Subject,
    ISNULL([Group], 'Uncategorized') AS [Group]
FROM dbo.DimGroup;
GO

-- 6. View for DimUnitStatus
CREATE OR ALTER VIEW dbo.vw_DimUnitStatus
AS
SELECT 
    UnitStatusKey,
    ISNULL(Units, 'Not Specified') AS Units,
    ISNULL([Status], 'Unknown') AS [Status]
FROM dbo.DimUnitStatus;
GO