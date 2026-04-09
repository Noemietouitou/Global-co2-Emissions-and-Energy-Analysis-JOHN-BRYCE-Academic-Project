# 🌍 Global Energy Transition & CO2 Emissions Analysis (1900–Present)
JOHN BRYCE Academic Project - 2026


## 🎯 Project Overview
This project investigates the historical correlation between **global energy consumption patterns** and **carbon dioxide (CO2) emissions**. Using data from *Our World in Data (OWID)*, I built a relational database to analyze how the shift from fossil fuels to renewable energy impacts national carbon footprints across **200+ countries**.

---

## 🛠️ Technical Stack
*   **Data Sourcing:** OWID Energy & CO2 Datasets (CSV)
*   **ETL & Cleaning:** Excel, Power Query
*   **Database Management:** SQL Server (SSMS) - T-SQL
*   **Analytics & Visualization:** Python (Pandas, Seaborn), Power BI 

---

## 📈 Project Workflow

### 1. Extraction & Profiling (ETL)
*   Standardized country naming conventions and handled missing historical values (1900–Present) using **Power Query**.
*   Cleaned and transformed flat CSV files into structured formats ready for relational mapping.

### 2. Schema Design & Data Ingestion
*   **Relational Model:** Developed an optimized **star schema** in SSMS to transition from flat files to structured tables.
*   **Data Integrity:** Engineered the SQL Import/Export Wizard to map cleaned data, ensuring strict data type integrity and primary key constraints.
*   **Modeling:** Established relationships between `Energy_Consumption` and `CO2_Emissions` tables to facilitate multi-dimensional analysis.

---

## 💡 Key Insights & Data Findings

*   **🚀 Decoupling Growth:** Identified a **15% decrease** in Carbon Intensity (CO2 per unit of GDP) in European regions over the last decade, despite steady economic growth.
*   **🌱 Renewable Energy Impact:** Data reveals that countries with **>30% renewable energy** in their mix show a non-linear drop in per-capita emissions, suggesting a "tipping point" for environmental impact.
*   **🔌 Fossil Fuel Dependency:** Mapped a direct correlation between coal consumption and emission spikes in emerging markets.
*   **📊 Regional Leaders:** Visualized that while total emissions are rising in Asia, per-capita emissions in several G20 nations have successfully plateaued since 2018.


---
*Developed by **Noemie** – Data Analyst*
