![Superstore Data Warehouse ERD](diagrams/erd-preview.png)

# PostgreSQL Advanced SQL Data Warehouse & Business Analytics

A PostgreSQL data warehouse mini-project built around Superstore sales data. The project stages the source records, transforms them into a star schema, validates the loaded data, and uses analytical SQL to investigate sales, profit, customers, products, shipping, and time trends.

## Project Overview

The warehouse uses a central `FactSales` table connected to five dimensions:

- `DimCustomer`
- `DimProduct`
- `DimLocation`
- `DimShipMod`
- `DimDate`

`StagingSuperstore` holds the source-shaped data before dimensional loading.

## Tech Stack

- PostgreSQL
- SQL
- VS Code with a database extension
- Excel source data

## Repository Structure

```text
superstore-data-warehouse/
├── README.md
├── sql/
│   └── Mini-Project-SQL.sql
├── diagrams/
│   └── ERD.mmd
└── docs/
    └── project-documentation.md
```

## Data Warehouse Design

The project follows a star-schema design. `FactSales` stores the sales measures and foreign keys to the dimensions. `DimDate` is referenced twice by the fact table: once for the order date and once for the ship date.

See [`diagrams/ERD.mmd`](diagrams/ERD.mmd) for the Mermaid ERD source. GitHub can render Mermaid diagrams in Markdown when the diagram is placed in a Markdown file; if the `.mmd` file does not render inline in your view, copy its contents into a fenced `mermaid` block in this README or add a `diagrams/ERD.md` file.

## ETL Workflow

1. Import the original Superstore records into `StagingSuperstore`.
2. Standardize the postal-code data type.
3. Populate the date, customer, product, location, and shipping-mode dimensions.
4. Load `FactSales` by joining staging rows to dimension members and resolving surrogate keys.
5. Validate the staging/fact row counts and check for unresolved dimension references.

## Analytical SQL

The SQL script includes analyses for:

- Total sales, total profit, order count, and average order value
- Sales and profit by category and region
- Monthly and yearly sales trends
- Top customers and customers above average sales
- Customer profitability and spending segments
- Top-selling, most-profitable, and loss-making products
- Sales, profit, and average delivery time by shipping mode
- Top category per region
- Year-over-year sales growth

It also creates the `vw_Sales_KPI` KPI view, a `FUNC_GetYearlySalesKPI` function, and an index on `FactSales(ProductKey)` for a basic before/after query-plan timing comparison.

> Note: The `GetYearlySalesKPI` stored-procedure definition in the supplied SQL script is commented out. The active reusable yearly KPI object is a PostgreSQL function, `FUNC_GetYearlySalesKPI`.

## Reported Results

The accompanying project documentation reports these results for the supplied data:

| KPI | Reported value |
|---|---:|
| Total sales | 501,239.89 |
| Total profit | 39,706.36 |
| Distinct orders | 1,175 |
| Units sold | 8,780 |
| Profit margin | 7.92% |

### Selected Findings

- Technology led the reported categories in sales and profit.
- Furniture had a negative total profit despite substantial sales.
- The available records contain the Central region only, so the analysis cannot support comparisons between regions.
- The recorded category-query execution time decreased from 1.203 ms to 1.089 ms after adding the product-key index. This small-data timing difference should not be treated as a reliable prediction of performance at larger scale.

These figures are taken from the supplied project documentation and should be revalidated if the database or source data changes.

## How to Run

1. Create a PostgreSQL database.
2. Open `sql/Mini-Project-SQL.sql` and execute the table-creation section.
3. Import the source Excel records into `StagingSuperstore` using your preferred PostgreSQL import workflow.
4. Execute the dimension-loading and fact-loading statements.
5. Run the validation queries, analytical queries, view, function, and index evaluation.

The script is a project workflow rather than a fully automated one-click import: the source file must be imported into the staging table before the ETL statements can run.

## Data Model Notes

- Dimension tables use surrogate integer keys.
- `FactSales.SourceRowID` is unique to prevent the same source row from being loaded more than once.
- `OrderDateKey` and `ShipDateKey` both reference `DimDate.DateKey`.
- Product uniqueness is defined by the combination of `ProductID` and `ProductName`.
- Location uniqueness is defined by the country, city, state, postal code, and region combination.

## Limitations

- The supplied data contains Central-region records only.
- The index timing comparison is based on a small dataset and one analytical query.
- The analysis identifies associations and outliers; it does not establish causal explanations for business outcomes.

## Files

- SQL implementation: [`sql/Mini-Project-SQL.sql`](sql/Mini-Project-SQL.sql)
- ERD source: [`diagrams/ERD.mmd`](diagrams/ERD.mmd)
- Project report: [`docs/project-documentation.md`](docs/project-documentation.md)
