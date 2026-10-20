# Entity Relationship Diagram (ERD)

The warehouse follows a star schema. `FactSales` is the central fact table and links to five dimensions. `DimDate` has two separate relationships to the fact table: order date and ship date. `StagingSuperstore` is the pre-ETL source-shaped table and is not directly related by foreign keys to the star schema.

```mermaid
erDiagram
    DIM_CUSTOMER ||--o{ FACT_SALES : "customer"
    DIM_PRODUCT ||--o{ FACT_SALES : "product"
    DIM_LOCATION ||--o{ FACT_SALES : "location"
    DIM_SHIPMOD ||--o{ FACT_SALES : "ship mode"
    DIM_DATE ||--o{ FACT_SALES : "order date"
    DIM_DATE ||--o{ FACT_SALES : "ship date"

    DIM_CUSTOMER {
        int CustomerKey PK
        varchar CustomerID UK
        varchar CustomerName
        varchar Segment
    }

    DIM_PRODUCT {
        int ProductKey PK
        varchar ProductID
        varchar ProductName
        varchar Category
        varchar SubCategory
        "UNIQUE(ProductID, ProductName)" UK
    }

    DIM_LOCATION {
        int LocationKey PK
        varchar Country
        varchar City
        varchar State
        int PostalCode
        varchar Region
        "UNIQUE(Country, City, State, PostalCode, Region)" UK
    }

    DIM_SHIPMOD {
        int ShipModKey PK
        varchar ShipMode UK
    }

    DIM_DATE {
        int DateKey PK
        date FullDate UK
        smallint CalendarYear
        smallint QuarterNumber
        smallint MonthNumber
        varchar MonthName
        smallint DayOfMonth
        smallint DayOfWeek
    }

    FACT_SALES {
        bigint SalesKey PK
        int SourceRowID UK
        varchar OrderID
        int OrderDateKey FK
        int ShipDateKey FK
        int CustomerKey FK
        int ProductKey FK
        int LocationKey FK
        int ShipModKey FK
        numeric SalesAmount
        int Quantity
        numeric DiscountRate
        numeric ProfitAmount
    }

    STAGING_SUPERSTORE {
        int RowID
        varchar OrderID
        date OrderDate
        date ShipDate
        varchar ShipMode
        varchar CustomerID
        varchar CustomerName
        varchar Segment
        varchar Country
        varchar City
        varchar State
        int PostalCode
        varchar Region
        varchar ProductID
        varchar Category
        varchar SubCategory
        varchar ProductName
        numeric Sales
        int Quantity
        numeric Discount
        numeric Profit
    }

```
