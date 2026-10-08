USE StatsNZ_LabourMarket_SSIS_DW;
GO

-- 1. Delete all records from the Fact Table first (removes Foreign Key blocks)
DELETE FROM dbo.FactLabourMarket;
-- Reset auto-increment counter (FactID) back to 0 so the next row starts at 1
DBCC CHECKIDENT ('dbo.FactLabourMarket', RESEED, 0);
GO

-- 2. Delete all records from Dimension Tables with IDENTITY columns
DELETE FROM dbo.DimUnitStatus;
DBCC CHECKIDENT ('dbo.DimUnitStatus', RESEED, 0);

DELETE FROM dbo.DimGroup;
DBCC CHECKIDENT ('dbo.DimGroup', RESEED, 0);

DELETE FROM dbo.DimSeries;
DBCC CHECKIDENT ('dbo.DimSeries', RESEED, 0);

DELETE FROM dbo.DimDataset;
DBCC CHECKIDENT ('dbo.DimDataset', RESEED, 0);
GO

-- 3. Delete records from DimDate (no IDENTITY seed to reset since DateKey is manual, e.g. YYYYMMDD)
DELETE FROM dbo.DimDate;
GO