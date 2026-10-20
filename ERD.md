# Entity Relationship Diagram (ERD)

![Superstore Data Warehouse ERD](ERD%20Diagram.png)

The warehouse follows a star schema. `FactSales` is the central fact table and links to five dimensions. `DimDate` has two relationships to the fact table: one for the order date and one for the ship date. `StagingSuperstore` contains source-shaped records before ETL and is not directly connected to the dimensional model by foreign keys.

## Main Tables

- `FactSales` — sales measures and foreign keys to the dimensions.
- `DimCustomer` — customer attributes.
- `DimProduct` — product, category, and subcategory attributes.
- `DimLocation` — country, city, state, postal code, and region.
- `DimShipMod` — shipping mode.
- `DimDate` — calendar attributes used for order and ship dates.
- `StagingSuperstore` — source data before ETL.

## Relationship Notes

- `FactSales.OrderDateKey` and `FactSales.ShipDateKey` both reference `DimDate.DateKey`.
- `FactSales` references the customer, product, location, and shipping-mode dimensions through their surrogate keys.
- Product and location composite uniqueness constraints are defined in the SQL schema.
