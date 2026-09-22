# Stats NZ Labour Market Data Warehouse & Analytics Platform

## Executive Summary
This project delivers an enterprise-grade data warehouse and reporting platform engineered on official Statistics New Zealand (Stats NZ) labour market time-series datasets. The platform ingests heterogeneous raw CSVs, transforms and standardizes schema variations across multi-year survey updates, structures data into a Production Gold Star Schema, and serves live, low-latency DirectQuery reporting in Power BI.

---

## Technical Architecture & Pipeline Topology

```
[ Raw Stats NZ CSV Data ]
           │
           ▼
[ Staging DB: StatsNZ_LabourMarket_DW ]
  ├─ Raw Ingestion Tables
  └─ T-SQL Cleaning & Dynamic NULL Casting
           │
           ▼
[ Gold DW: StatsNZ_LabourMarket_MaskedDW ]
  ├─ Fact Table: FactLabourMarket (~8M Rows)
  └─ Dimension Tables: DimDate, DimDataset, DimSeries, DimGroup, DimUnitStatus
           │
           ▼
[ Abstraction Layer: T-SQL Views ]
  └─ vw_FactLabourMarket, vw_Dim*
           │
           ▼
[ Analytics Layer: Power BI DirectQuery ]
  └─ KPI Cards, Time-Series Line Charts, Subject Bar Charts, Granular Matrix
```

---

## Database Architecture & T-SQL Implementation

### 1. Multi-Database Layout
* **Staging Database (`StatsNZ_LabourMarket_DW`):** Serves as a landing zone for automated CSV imports. Data cleansing, schema alignment, and initial data type parsing (`TRY_CAST`) are performed here.
* **Production Gold Database (`StatsNZ_LabourMarket_MaskedDW`):** Houses the analytical Star Schema designed for OLAP queries and Power BI integration.

### 2. Schema Alignment & Transformation Strategy
* **Dynamic Column Handling:** Schema misalignments (e.g., missing or renamed `Series_title` columns across historical releases) were resolved by dynamically casting missing columns to `NULL` prior to Star Schema loading.
* **Database Abstraction via SQL Views:** Secured, highly optimized views were built on top of Gold tables to decouple the Power BI reporting layer from physical storage structures:

```sql
USE [StatsNZ_LabourMarket_MaskedDW];
GO

-- 1. Optimized Fact View
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

-- 2. Optimized Date View
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

-- 3. DimDataset View
CREATE OR ALTER VIEW dbo.vw_DimDataset
AS
SELECT 
    DatasetKey,
    DatasetCode,
    DatasetName
FROM dbo.DimDataset;
GO

-- 4. DimSeries View
CREATE OR ALTER VIEW dbo.vw_DimSeries
AS
SELECT 
    SeriesKey,
    SeriesReference,
    ISNULL(Title1, 'N/A') AS SeriesTitle1,
    ISNULL(Title2, 'N/A') AS SeriesTitle2
FROM dbo.DimSeries;
GO

-- 5. DimGroup View
CREATE OR ALTER VIEW dbo.vw_DimGroup
AS
SELECT 
    GroupKey,
    ISNULL(Subject, 'Uncategorized') AS Subject,
    ISNULL([Group], 'Uncategorized') AS [Group]
FROM dbo.DimGroup;
GO

-- 6. DimUnitStatus View
CREATE OR ALTER VIEW dbo.vw_DimUnitStatus
AS
SELECT 
    UnitStatusKey,
    ISNULL(Units, 'Not Specified') AS Units,
    ISNULL([Status], 'Unknown') AS [Status]
FROM dbo.DimUnitStatus;
GO
```

---

## Gold Star Schema Design

The target model follows Kimball dimensional modeling principles, structured around a central fact table and five dimension tables:

```
                  ┌──────────────────┐
                  │    DimDataset    │
                  └────────┬─────────┘
                           │ 1
                           │
                           │ *
┌──────────────────┐     ┌─┴──────────────────┐     ┌──────────────────┐
│     DimDate      ├────>│  FactLabourMarket  │<────┤    DimSeries     │
└──────────────────┘ 1   │  (~8M Records)     │   * └──────────────────┘
                         └─┬──────────────────┬┘
                           │ *              │ *
                           │                │
                         1 │              1 │
                  ┌────────┴─────────┐   ┌──┴───────────────┐
                  │     DimGroup     │   │   DimUnitStatus  │
                  └──────────────────┘   └──────────────────┘
```

* **`FactLabourMarket`**: Stores numerical observations (`DataValue`) associated with foreign surrogate keys pointing to dimensions.
* **`DimDate`**: Date key (`DateKey` formatted as `YYYYMMDD`), full date, year, quarter, month, and calendar labels.
* **`DimDataset`**: Surveys included (**HLFS** - Household Labour Force Survey, **LCI** - Labour Cost Index, **QES** - Quarterly Employment Survey, **MEI** - Monthly Employment Indicators, etc.).
* **`DimSeries`**: Unique time-series codes (`SeriesReference`) mapped to detailed breakdowns (`Title1`, `Title2` like Gender, Industry, or Employment Status).
* **`DimGroup`**: Hierarchical economic subjects and survey classification groups.
* **`DimUnitStatus`**: Observational units (e.g., *Dollars*, *Index*, *Percent*) and Stats NZ revision flags (`P`, `R`, `F`, `FINAL`, `REVISED`).

---

## Power BI & DirectQuery Optimization

To eliminate memory buffer pool bottlenecks (`insufficient system memory in resource pool 'default'`) during multi-million-row extraction, the engine was configured as follows:

1. **DirectQuery Connection:** Bypasses local RAM constraints by executing queries directly against the SQL Server instance on demand.
2. **Parallel Evaluation Controls:** Configured Power BI engine execution limits to sequential single-task evaluation (`One (disable parallel loading)`).
3. **SQL Server Resource Allocation:** Configured SQL Server's memory ceiling and memory pool thresholds:

```sql
USE master;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'max server memory (MB)', 8192;
RECONFIGURE WITH OVERRIDE;
GO
```

---

## DAX Measures Reference

All measures are created in Power BI Desktop for KPI tracking and analytical dynamic aggregations:

```dax
// 1. Total Metric Value
Total Value = SUM(vw_FactLabourMarket[DataValue])

// 2. Average Metric Value
Average Value = AVERAGE(vw_FactLabourMarket[DataValue])

// 3. Total Data Points (Row Count)
Total Observations = COUNTROWS(vw_FactLabourMarket)

// 4. Previous Quarter Value (Time Intelligence)
Previous Quarter Value = 
CALCULATE(
    [Total Value],
    DATEADD(vw_DimDate[FullDate], -1, QUARTER)
)

// 5. Quarter-over-Quarter Growth %
QoQ Growth % = 
VAR CurrentVal = [Total Value]
VAR PrevVal = [Previous Quarter Value]
RETURN
IF(
    NOT ISBLANK(PrevVal) && PrevVal <> 0,
    DIVIDE(CurrentVal - PrevVal, PrevVal, 0),
    BLANK()
)
```

---

## Dashboard Visualizations & Layout

The dashboard features a high-density, executive-themed interface designed for high-level oversight and deep-dive analysis:

| Canvas Zone | Visual Type | Source Fields / Measures | Functionality |
| :--- | :--- | :--- | :--- |
| **Top Header** | Header Panel | Dashboard Banner | Executive Summary Title Bar |
| **Left Navigation** | Slicer & KPI Panel | `vw_DimDate[Year]`, `[Total Value]`, `[Average Value]`, `[Total Observations]`, `[QoQ Growth %]` | Dynamic slicers and KPI summary cards (`1.76T` total, `8M` rows) |
| **Center Main** | Line Chart | `X`: `vw_DimDate[QuarterName]`, `Y`: `[Total Value]`, `Legend`: `vw_DimDataset[DatasetCode]` | Multi-decade historical time-series trajectory by dataset |
| **Right Section** | Horizontal Bar Chart | `Y`: `vw_DimGroup[Subject]`, `X`: `[Total Value]` | Economic subject distribution (QES, MEI, HLFS, LCI) |
| **Bottom Matrix** | Data Grid Matrix | `Rows`: `vw_DimSeries[SeriesReference]`, `Cols`: `vw_DimDate[Year]`, `Values`: `[Total Value]` | Granular yearly observation matrix with historical drill-down |
