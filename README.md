<div align="center">

# PostgreSQL Superstore Data Warehouse

**Advanced SQL · Data Warehousing · Business Analytics**

<img src="ERD%20Diagram.png" alt="Entity Relationship Diagram" width="900">

*A star-schema data warehouse built with PostgreSQL and Superstore sales data.*

</div>

---

## Project Overview

This project transforms Superstore sales records into a dimensional data warehouse and uses SQL to analyze sales, profit, customers, products, shipping, and time-based trends.

## Data Model

The warehouse uses a star schema centered on `FactSales`, connected to five dimension tables:

- `DimCustomer`
- `DimProduct`
- `DimLocation`
- `DimShipMod`
- `DimDate`

`DimDate` is linked to `FactSales` twice: through `OrderDateKey` and `ShipDateKey`. `StagingSuperstore` holds source-shaped records before the ETL process.

For the editable ERD definition, see [`ERD.md`](ERD.md).

## Tech Stack

- **Database:** PostgreSQL
- **Language:** SQL
- **Source data:** Excel / Superstore dataset
- **Workflow:** Staging, dimensional modeling, ETL, analytics, and query optimization

## Repository Structure

```text
postgresql-superstore-data-warehouse/
├── ERD Diagram.png
├── ERD.md
├── MIni-Project-SQl.sql
└── README.md
```

## What This Project Covers

- Designing a star schema with fact and dimension tables
- Loading and joining dimension keys during ETL
- Building analytical queries using joins, subqueries, CTEs, `CASE`, and window functions
- Reporting sales, profit, order, product, customer, and shipping KPIs
- Creating a KPI view and a reusable yearly KPI function
- Comparing query execution timing before and after adding an index

## Key Findings

The project documentation reports the following results for the analyzed data:

| KPI | Reported value |
|---|---:|
| Total sales | 501,239.89 |
| Total profit | 39,706.36 |
| Distinct orders | 1,175 |
| Units sold | 8,780 |
| Profit margin | 7.92% |

- Technology was the leading category by reported sales and profit.
- Furniture recorded a negative total profit despite substantial sales.
- The available records cover the Central region only, so they do not support comparisons across regions.

*Revalidate these figures if the source data or database changes.*

## How to Run

1. Create a PostgreSQL database.
2. Open `MIni-Project-SQl.sql` and execute the table-creation statements.
3. Import the source records into `StagingSuperstore`.
4. Run the dimension-loading and fact-loading statements.
5. Execute the validation queries, analytical queries, view, function, and index evaluation.

The source data must be imported into the staging table before the ETL statements can run.

## Notes

- The yearly KPI function is active in the supplied SQL script; the stored-procedure definition is commented out.
- The reported index timing difference comes from a small dataset and should not be treated as a reliable prediction of performance at larger scale.
- The source records contain Central-region data only.

---

<div align="center">

**Built as a PostgreSQL and advanced SQL data warehousing project.**

</div>
