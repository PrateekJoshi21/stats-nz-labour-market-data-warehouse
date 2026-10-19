# 📊 New Zealand Labour Market Data Analysis & ETL Pipeline

An end-to-end data engineering and analytics project consolidating over **2.98 million rows** of disparate SQL-style employment datasets into a single, highly performant Excel Data Model for executive-level reporting and analytics.

---

## 📌 Project Overview

This project demonstrates an enterprise-grade ETL (Extract, Transform, Load) workflow designed in Microsoft Excel and Power Query. Raw staging datasets covering employment indicators, household labor force metrics, labor cost indices, labor market statistics, and quarterly employment surveys were transformed, standardized, and modeled into a consolidated architecture.

By leveraging **Power Pivot (Data Model)**, this solution completely circumvents Excel’s native 1,048,576-row worksheet limitation, providing smooth analytical queries across nearly 3 million rows without performance degradation.

---

## 🚀 Key Technical Highlights & Skills Demonstrated

### 1. Basic & Intermediate ETL Operations (Power Query)
* **Multi-Source Data Ingestion**: Imported five separate raw staging datasets (`stg_employment_indicators_raw`, `stg_hlfs_raw`, `stg_lci_raw`, `stg_lms_raw`, and `stg_qes_raw`).
* **Text & Data Hygiene**: Cleaned text columns using `Trim` and `Capitalize Each Word` functions; purged null, missing, and row-level calculation error values.
* **Schema Standardization**: Mapped all five tables to a uniform 6-column structure:
  * `Series_reference`
  * `Year`
  * `Monthly_Quarter`
  * `Data_value`
  * `UNITS`
  * `Group` / `Series_title_1`
* **Parsing & Transformation**: Split composite temporal string codes into distinct integer columns (`Year` and `Monthly_Quarter`) and converted raw string numbers into strict Decimal/Double data types for correct numerical aggregation.
* **Dataset Appending**: Stacked all cleaned staging queries into a single master query (`master_employment_data`).

### 2. Advanced Data Modeling & Optimization (Power Pivot / Data Model)
* **High-Volume Data Load**: Bypassed standard sheet limits by loading **2,986,555 rows** directly into the xVelocity Data Model memory engine.
* **File Size & Memory Optimization**: Utilized **Excel Binary Workbook (`.xlsb`)** format to compress storage footprint, optimize cache structures, and enable rapid loading/saving speeds.
* **DAX & Aggregations**: Configured custom measures and aggregations to ensure accurate rollups across varying metric categories (`Dollars`, `Index`, `Number`, `Percent`).

### 3. Interactive Analytics & Dashboard Visualization
* **Dynamic PivotTables**: Structured multi-dimensional analytical views grouped by Year, Quarter, and Industry Group.
* **PivotCharts**: Built dynamic time-series charts formatted with thousands separators to analyze macro-economic employment trends while eliminating scientific notation artifacts ($4\text{E}+09$).
* **Slicers & Metadata Control**: Added interactive slicers filtering by `UNITS` and `Group` to allow users to dynamically isolate specific financial and headcount indicators.

---

## 🛠️ Data Pipeline Architecture