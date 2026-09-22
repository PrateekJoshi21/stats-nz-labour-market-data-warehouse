/*
========================================================================================
STEP 1: CREATE GOLD DATA WAREHOUSE & STAR SCHEMA TABLES
Database: StatsNZ_LabourMarket_DW
========================================================================================
*/

/*-- 1. Create the target Data Warehouse Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'StatsNZ_LabourMarket_MaskedDW')
BEGIN
    CREATE DATABASE [StatsNZ_LabourMarket_MaskedDW];
END
GO*/

USE [StatsNZ_LabourMarket_MaskedDW];
GO

IF OBJECT_ID('dbo.FactLabourMarket', 'U') IS NOT NULL DROP TABLE dbo.FactLabourMarket;
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimSeries', 'U') IS NOT NULL DROP TABLE dbo.DimSeries;
IF OBJECT_ID('dbo.DimGroup', 'U') IS NOT NULL DROP TABLE dbo.DimGroup;
IF OBJECT_ID('dbo.DimUnitStatus', 'U') IS NOT NULL DROP TABLE dbo.DimUnitStatus;
IF OBJECT_ID('dbo.DimDataset', 'U') IS NOT NULL DROP TABLE dbo.DimDataset;
GO

CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    [Year] VARCHAR(4) NOT NULL,
    Quarter VARCHAR(2) NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(15) NOT NULL
);

CREATE TABLE dbo.DimDataset (
    DatasetKey INT IDENTITY(1,1) PRIMARY KEY,
    DatasetCode VARCHAR(20) NOT NULL,
    DatasetName VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.DimSeries (
    SeriesKey INT IDENTITY(1,1) PRIMARY KEY,
    SeriesReference VARCHAR(100) NOT NULL,
    Title1 NVARCHAR(255) NULL,
    Title2 NVARCHAR(255) NULL
);

CREATE TABLE dbo.DimGroup (
    GroupKey INT IDENTITY(1,1) PRIMARY KEY,
    Subject NVARCHAR(255) NULL,
    [Group] NVARCHAR(255) NULL
);

CREATE TABLE dbo.DimUnitStatus (
    UnitStatusKey INT IDENTITY(1,1) PRIMARY KEY,
    Units NVARCHAR(100) NULL,
    [Status] NVARCHAR(50) NULL
);

CREATE TABLE dbo.FactLabourMarket (
    FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dbo.DimDate(DateKey),
    DatasetKey INT NOT NULL FOREIGN KEY REFERENCES dbo.DimDataset(DatasetKey),
    SeriesKey INT NOT NULL FOREIGN KEY REFERENCES dbo.DimSeries(SeriesKey),
    GroupKey INT NOT NULL FOREIGN KEY REFERENCES dbo.DimGroup(GroupKey),
    UnitStatusKey INT NOT NULL FOREIGN KEY REFERENCES dbo.DimUnitStatus(UnitStatusKey),
    DataValue REAL NOT NULL
);
GO