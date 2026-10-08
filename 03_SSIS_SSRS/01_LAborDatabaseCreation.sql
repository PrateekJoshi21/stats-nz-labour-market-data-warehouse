/*******************************************************************************
  Database & Data Warehouse Setup Script (SSIS-Compatible Version)
  Database: StatsNZ_LabourMarket_SSIS_DW
*******************************************************************************/

-- 1. Create Target Database (if it doesn't already exist)
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'StatsNZ_LabourMarket_SSIS_DW')
BEGIN
    CREATE DATABASE StatsNZ_LabourMarket_SSIS_DW;
END
GO

USE StatsNZ_LabourMarket_SSIS_DW;
GO

-- 2. Clean Up Existing Objects (Drop Views and Fact Table First due to Foreign Keys)
DROP VIEW IF EXISTS dbo.v_audit_dataset_summary;
DROP VIEW IF EXISTS dbo.v_yearly_labour_trends;
DROP TABLE IF EXISTS dbo.FactLabourMarket;
DROP TABLE IF EXISTS dbo.DimUnitStatus;
DROP TABLE IF EXISTS dbo.DimGroup;
DROP TABLE IF EXISTS dbo.DimSeries;
DROP TABLE IF EXISTS dbo.DimDataset;
DROP TABLE IF EXISTS dbo.DimDate;
GO

-- 3. Create Target Dimension Tables (Using NVARCHAR to match SSIS DT_WSTR types)
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,               -- YYYYMMDD
    FullDate DATE NOT NULL,
    [Year] NVARCHAR(10) NOT NULL,
    Quarter NVARCHAR(10) NOT NULL,          -- e.g., 'Q1'
    QuarterName NVARCHAR(20) NOT NULL,      -- e.g., 'Q1 2020'
    [Month] INT NOT NULL,                  -- 1 to 12
    MonthName NVARCHAR(20) NOT NULL         -- e.g., 'January'
);

CREATE TABLE dbo.DimDataset (
    DatasetKey INT IDENTITY(1,1) PRIMARY KEY,
    DatasetCode NVARCHAR(50) NOT NULL UNIQUE,
    DatasetName NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.DimSeries (
    SeriesKey INT IDENTITY(1,1) PRIMARY KEY,
    SeriesReference NVARCHAR(255) NOT NULL, -- Matched to NVARCHAR(255)
    Title1 NVARCHAR(500) NULL,
    Title2 NVARCHAR(500) NULL
);

CREATE TABLE dbo.DimGroup (
    GroupKey INT IDENTITY(1,1) PRIMARY KEY,
    Subject NVARCHAR(255) NOT NULL,
    [Group] NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.DimUnitStatus (
    UnitStatusKey INT IDENTITY(1,1) PRIMARY KEY,
    Units NVARCHAR(100) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL
);
GO

-- 4. Pre-Populate DimDataset (Prevents SSIS Lookup Unmatched Drops)
INSERT INTO dbo.DimDataset (DatasetCode, DatasetName)
VALUES 
    ('MEI', 'Employment Indicators'),
    ('HLFS', 'Household Labour Force Survey'),
    ('LCI', 'Labour Cost Index'),
    ('LMS', 'Labour Market Statistics'),
    ('QES', 'Quarterly Employment Survey');
GO

-- 5. Create Target Fact Table (Allows NULL for DataValue)
CREATE TABLE dbo.FactLabourMarket (
    FactID BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    DatasetKey INT NOT NULL,
    SeriesKey INT NOT NULL,
    GroupKey INT NOT NULL,
    UnitStatusKey INT NOT NULL,
    DataValue FLOAT NULL,                  -- Changed NOT NULL to NULL
    
    CONSTRAINT PK_FactLabourMarket PRIMARY KEY CLUSTERED (FactID),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (DateKey) REFERENCES dbo.DimDate(DateKey),
    CONSTRAINT FK_Fact_Dataset FOREIGN KEY (DatasetKey) REFERENCES dbo.DimDataset(DatasetKey),
    CONSTRAINT FK_Fact_Series FOREIGN KEY (SeriesKey) REFERENCES dbo.DimSeries(SeriesKey),
    CONSTRAINT FK_Fact_Group FOREIGN KEY (GroupKey) REFERENCES dbo.DimGroup(GroupKey),
    CONSTRAINT FK_Fact_UnitStatus FOREIGN KEY (UnitStatusKey) REFERENCES dbo.DimUnitStatus(UnitStatusKey)
);
GO

-- 6. Create Audit and Analysis Views
CREATE VIEW dbo.v_audit_dataset_summary AS
SELECT 
    d.DatasetCode,
    d.DatasetName,
    COUNT(f.FactID) AS DW_Total_Rows,
    ROUND(SUM(f.DataValue), 2) AS DW_Sum_DataValue,
    MIN(dt.FullDate) AS Earliest_Date,
    MAX(dt.FullDate) AS Latest_Date
FROM dbo.FactLabourMarket f
JOIN dbo.DimDataset d ON f.DatasetKey = d.DatasetKey
JOIN dbo.DimDate dt ON f.DateKey = dt.DateKey
GROUP BY d.DatasetCode, d.DatasetName;
GO

CREATE VIEW dbo.v_yearly_labour_trends AS
SELECT 
    dt.[Year],
    ds.DatasetCode,
    COUNT(f.FactID) AS Total_Records,
    ROUND(SUM(f.DataValue), 2) AS Total_Value,
    ROUND(AVG(f.DataValue), 2) AS Average_Value
FROM dbo.FactLabourMarket f
JOIN dbo.DimDate dt ON f.DateKey = dt.DateKey
JOIN dbo.DimDataset ds ON f.DatasetKey = ds.DatasetKey
GROUP BY dt.[Year], ds.DatasetCode;
GO