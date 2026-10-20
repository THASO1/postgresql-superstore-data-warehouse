-- Star Schema Design Note:
-- Dimension tables use auto-generated integer Surrogate Keys as Primary Keys to:
-- - Optimize JOIN performance and indexing across dimension and fact tables.
-- - Isolate the Data Warehouse from source key changes and handle SCD (history tracking).

-- ===================================================== DIMENSION TABLES ===========================================================
-- CREATE TABLES

CREATE TABLE DimCustomer(
    Customerkey INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CustomerID VARCHAR(20) NOT NULL UNIQUE,
    CustomerName VARCHAR(150) NOT NULL,
    Segment VARCHAR(30) NOT NULL
);

CREATE TABLE DimProduct(
    ProductKey INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ProductID VARCHAR(30) NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    SubCategory VARCHAR(50) NOT NULL,
    CONSTRAINT UQ_DimProduct_SourceProduct
    UNIQUE (ProductID, ProductName)  -- we will use ProductID and ProductName to Identify the Product 
);

CREATE TABLE DimLocation(
    LocationKey INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Country VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    PostalCode VARCHAR(15),
    Region VARCHAR(50) NOT NULL,
    CONSTRAINT UQ_DimLocation_Address
    UNIQUE (Country, City, State, PostalCode, Region) -- Address will identify with Country, City, State, PostalCode, Region
);

-- Standardize PostalCode from VARCHAR to INTEGER
ALTER TABLE DimLocation
ALTER COLUMN PostalCode TYPE INTEGER
USING PostalCode::INTEGER;


CREATE TABLE DimShipMod(
    ShipModKey INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ShipMode VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE DimDate(
    DateKey INTEGER PRIMARY KEY,
    FullDate DATE NOT NULL UNIQUE,
    CalendarYear SMALLINT NOT NULL,
    QuarterNumber SMALLINT NOT NULL CHECK (QuarterNumber BETWEEN 1 AND 4),
    MonthNumber SMALLINT NOT NULL CHECK (MonthNumber BETWEEN 1 AND 12),
    MonthName VARCHAR(20) NOT NULL,
    DayOfMonth SMALLINT NOT NULL CHECK (DayOfMonth BETWEEN 1 AND 31),
    DayOfWeek SMALLINT NOT NULL CHECK (DayOfWeek BETWEEN 1 AND 7)
);

-- ===================================================== FACT TABLE ===========================================================

CREATE TABLE FactSales(
    SalesKey BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    SourceRowID INTEGER NOT NULL UNIQUE,
    OrderID VARCHAR(30) NOT NULL,
    OrderDateKey INTEGER NOT NULL,
    ShipDateKey INTEGER NOT NULL,
    CustomerKey INTEGER NOT NULL,
    ProductKey INTEGER NOT NULL,
    LocationKey INTEGER NOT NULL,
    ShipModKey INTEGER NOT NULL,
    SalesAmount NUMERIC(14,4) NOT NULL CHECK (SalesAmount >= 0),
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    DiscountRate NUMERIC(5,4) NOT NULL CHECK (DiscountRate BETWEEN 0 AND 1),
    ProfitAmount NUMERIC(14,4) NOT NULL,

    CONSTRAINT FK_Factsales_OrderDate 
    FOREIGN KEY (OrderDateKey) REFERENCES DimDate(DateKey),
    
    CONSTRAINT FK_FactSales_ShipDate
    FOREIGN KEY (ShipDateKey) REFERENCES DimDate(DateKey),

    CONSTRAINT FK_FactSales_Customer
    FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),

    CONSTRAINT FK_FactSales_Product
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),

    CONSTRAINT FK_FactSales_Location
    FOREIGN KEY (LocationKey) REFERENCES DimLocation(LocationKey),

    CONSTRAINT FK_FactSales_ShipMode
    FOREIGN KEY (ShipModKey) REFERENCES DimShipMod(ShipModKey)
);


-- For Import Data IN My DataBase will add the Orginal Table 
-- ===================================================== STAGING TABLE ===========================================================
CREATE TABLE StagingSuperstore (
    RowID INTEGER,
    OrderID VARCHAR(30),
    OrderDate DATE,
    ShipDate DATE,
    ShipMode VARCHAR(30),
    CustomerID VARCHAR(20),
    CustomerName VARCHAR(150),
    Segment VARCHAR(30),
    Country VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    PostalCode VARCHAR(15),
    Region VARCHAR(50),
    ProductID VARCHAR(30),
    Category VARCHAR(50),
    SubCategory VARCHAR(50),
    ProductName VARCHAR(200),
    Sales NUMERIC(14,4),
    Quantity INTEGER,
    Discount NUMERIC(5,4),
    Profit NUMERIC(14,4)
);
-- Standardize PostalCode from VARCHAR to INTEGER
ALTER TABLE StagingSuperstore
ALTER COLUMN PostalCode TYPE INTEGER
USING PostalCode::INTEGER;

-- We Will Import The data From the Xls. File With DBCODE EXT. in VSCODE 

-- ===================================================== INSERT DATA ===========================================================

INSERT INTO dimdate (datekey,fulldate,calendaryear,quarternumber,monthnumber,monthname,dayofmonth,dayofweek)
SELECT
TO_CHAR(d,'YYYYMMDD')::INTEGER AS datekey,
d AS fulldate,
EXTRACT(YEAR FROM d)::SMALLINT AS calendaryear,
EXTRACT(QUARTER FROM d)::SMALLINT AS quarternumber,
EXTRACT(MONTH FROM d)::SMALLINT AS monthnumber,
TO_CHAR(d,'Month') AS monthname,
EXTRACT(DAY FROM d):: SMALLINT AS dayofmonth,
EXTRACT(ISODOW FROM d):: SMALLINT AS dayofweek
FROM(
    SELECT OrderDate AS d FROM StagingSuperstore
    UNION
    SELECT ShipDate AS d FROM StagingSuperstore
) AS AllDates
ON CONFLICT (DateKey) DO Nothing;

-- CHECK THE INSERT 
-- SELECT * FROM dimdate LIMIT 5;

INSERT INTO dimcustomer(customerID, customername, segment)
SELECT DISTINCT
        customerID,
        CustomerName,
        segment
FROM stagingsuperstore
ON CONFLICT (CustomerID) DO Nothing; 

-- CHECK THE INSERT 
-- SELECT * FROM dimcustomer LIMIT 5;


INSERT INTO Dimproduct(productid, productname, category, subcategory)
SELECT DISTINCT
        productid,
        productname,
        category,
        subcategory
FROM stagingsuperstore
ON CONFLICT (ProductID, ProductName) DO NOTHING;        

-- CHECK THE INSERT 
-- SELECT * FROM dimproduct LIMIT 5;

INSERT INTO dimlocation(country, city, state, postalcode, region)
SELECT DISTINCT
        Country,
        city,
        state,
        postalcode,
        region
FROM stagingsuperstore
ON CONFLICT(country, city, state, postalcode, region) DO NOTHING;     

-- CHECK THE INSERT
-- SELECT * FROM dimlocation LIMIT 5;

INSERT INTO dimshipmod(shipmode)
SELECT DISTINCT
        shipmode
FROM stagingsuperstore
ON CONFLICT (ShipMode) DO NOTHING;

-- CHECK THE INSERT
 SELECT * FROM dimshipmod LIMIT 5;

INSERT INTO factsales(sourcerowid, orderid, orderdatekey, shipdatekey, customerkey, productkey, locationkey, shipmodkey,salesamount, quantity, discountrate, profitamount)
SELECT 
        s.RowID AS sourcerowid,
        s.orderid AS OrderID,
        od.datekey AS OrderDateKey,
        sd.DateKey AS shipdatekey,
        c.CustomerKey AS CustomerKey,
        p.productkey AS ProductKey,
        l.LocationKey AS LocationKey,
        sm.ShipModKey AS ShipModKey,
        s.sales AS SalesAmount,
        s.Quantity AS Quantity,
        s.Discount AS DiscountRate,
        s.Profit AS ProfitAmount
FROM stagingsuperstore s
JOIN dimdate od ON od.fulldate = s.orderdate
JOIN dimdate sd ON sd.fulldate = s.shipdate
JOIN dimcustomer c ON c.customerid = s.customerid
JOIN dimProduct p ON p.ProductID = s.productid
                  AND p.productname = s.productname
JOIN dimlocation l ON l.country = s.country
                   AND l.city = s.city
                   AND l.state = s.state
                   AND l.postalcode = s.postalcode
                   AND l.region = s.region
JOIN dimshipmod sm ON sm.shipmode = s.shipmode
ON CONFLICT (SourceRowID) DO NOTHING;                    

-- CHECK THE INSERT
-- SELECT * FROM factsales LIMIT 5;

-- ===================================================== DATA VALIDATION ===========================================================

SELECT
    (SELECT COUNT(*) FROM StagingSuperstore) AS StagingRows,
    (SELECT COUNT(*) FROM FactSales) AS FactRows;


SELECT COUNT(*)
FROM FactSales
WHERE CustomerKey IS NULL
   OR ProductKey IS NULL
   OR LocationKey IS NULL
   OR ShipModKey IS NULL
   OR OrderDateKey IS NULL
   OR ShipDateKey IS NULL;    


SELECT COUNT(*)
FROM FactSales f
LEFT JOIN DimDate d
    ON d.DateKey = f.OrderDateKey
WHERE d.DateKey IS NULL;   

-- ===================================================== Analytical Queries ===========================================================

-- Total sales
SELECT SUM(salesAmount) AS TotalSales
FROM factsales;

-- TOTAL PROFIT
SELECT SUM(profitamount) AS TotalProfit
FROM factsales;

-- TOTAL ORDERS AND AVG ORDER VALUE
SELECT  COUNT(DISTINCT orderid) AS TotalOrders,
        ROUND(SUM(salesamount) / COUNT(DISTINCT orderid),2) AS AVG_OrderValue
FROM factsales;

-- Sales AND Profit by Category
SELECT category, SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit 
FROM factsales f
JOIN dimproduct d ON f.productkey = d.productkey
GROUP BY category;

-- Sales & Profit by Region
SELECT region ,SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit 
FROM factsales f
JOIN dimlocation l ON f.locationkey = l.locationkey
GROUP BY region;

-- Monthly Sales Trend
WITH MonthlySales AS (
    SELECT  CalendarYear,
            MonthNumber,
            MonthName,
            Sum(SalesAmount) AS TotalSales
    FROM factsales f
    JOIN dimdate d ON d.datekey = f.OrderDateKey
    GROUP BY CalendarYear,
             MonthNumber,
             MonthName
)
SELECT  CalendarYear,
        MonthNumber,
        MonthName,
        TotalSales
    FROM MonthlySales
    ORDER BY CalendarYear, MonthNumber;   

-- Yealry Sales Performance
SELECT calendaryear , SUM(salesamount) AS TotalSales
FROM factsales f
JOIN dimdate d ON f.orderdatekey = d.datekey
GROUP BY calendaryear
Order BY calendaryear;

-- Top 10 Customers by Sales
SELECT customerid , customername, segment , SUM(salesamount) AS TotalSales
FROM factsales f
JOIN dimcustomer c ON f.customerkey = c.customerkey
GROUP BY customerid, customername, segment
ORDER BY TotalSales DESC LIMIT 10;

-- Customers Above AVG_Sales
SELECT customerid , customername, segment , SUM(salesamount) AS TotalSales
FROM factsales f 
JOIN dimcustomer c ON f.customerkey = c.customerkey
GROUP BY customerid , customername, segment
HAVING SUM(salesamount) > (
    SELECT AVG(CustomerSales) 
    FROM(
        SELECT SUM(salesamount) AS CustomerSales
        FROM factsales
        GROUP BY customerkey
    ) AS CustomerTable
)
ORDER BY TotalSales DESC;

-- Customer Profitability
SELECT customerid, customername, segment, SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit, ((SUM(profitamount) / SUM(salesamount)) * 100) AS ProfitMargin
FROM factsales f
JOIN dimcustomer c ON f.customerkey = c.customerkey
GROUP BY  customerid, customername, segment;

-- Customer Segmentation by Spending
SELECT  customerid, customername , SUM(salesamount) AS TotalSales,
CASE
    WHEN  SUM(salesAmount) < 1000 THEN 'Low-Value'
    WHEN  SUM(salesAmount) < 5000 THEN 'mid-Value'
    WHEN  SUM(salesAmount) < 10000 THEN 'High-Value'
    ELSE 'Premium'
END AS CustomerValuesSegment    
FROM factsales f
JOIN dimcustomer c ON f.customerkey = c.customerkey
GROUP BY customerid, customername
ORDER BY TotalSales DESC;

-- TOP 10 Product by Sales
SELECT productid, productname, SUM(salesamount) AS TotalSales
FROM factsales f 
JOIN dimproduct p ON f.productkey = p.productkey
GROUP BY productid, productname
ORDER BY TotalSales DESC LIMIT 10;

-- MOST Profitable Products
SELECT productid, productname, SUM(profitamount) AS TotalProfit
FROM factsales f
JOIN dimproduct d ON f.productkey = d.productkey
GROUP BY productid, productname
ORDER BY TotalProfit DESC;

-- Products with Negative Profit
SELECT productid, productname, SUM(profitamount) AS TotalProfit
FROM factsales f
JOIN dimproduct d ON f.productkey = d.productkey
GROUP BY productid, productname
HAVING SUM(profitamount) < 0;

-- Sales & Profit ShipMode
SELECT shipmode, SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit
FROM factsales f
JOIN dimshipmod sh ON f.shipmodkey = sh.shipmodkey
GROUP BY shipmode;

-- AVG_ShippingTime By ShipMode
SELECT shipmode , ROUND(AVG(sd.fulldate - od.fulldate),2)  AS AVGShippingDays
FROM factsales f 
JOIN dimshipmod sh ON f.shipmodkey = sh.shipmodkey
JOIN dimdate od ON f.orderdatekey = od.datekey
JOIN dimdate sd ON f.shipdatekey = sd.datekey
GROUP BY shipmode
ORDER BY AVGShippingDays;

-- Top Category per Region
WITH CategorySales AS (
    SELECT region, category, SUM(salesAmount) AS TotalSales
    FROM factsales f
    JOIN dimproduct p ON f.ProductKey = p.ProductKey
    JOIN dimlocation l ON f.LocationKey = l.locationkey
    GROUP BY region, category
),
RanekedCategories AS (
    SELECT region, category, TotalSales,
    RANK() OVER(PARTITION BY region ORDER BY TotalSales DESC) AS CategoryRank
FROM CategorySales )
SELECT region, category, TotalSales
FROM ranekedcategories
WHERE CategoryRank = 1
ORDER BY region; 

-- Year-over-Year Sales Growth
WITH Yearlysales AS (
    SELECT  CalendarYear, SUM(SalesAmount) AS TotalSales
    FROM factsales f
    JOIN dimdate d ON  f.orderdatekey = d.datekey 
    GROUP BY CalendarYear
),
SalesWithPreviousYear AS (
    SELECT calendarYear, TotalSales,
    LAG(TotalSales) OVER(ORDER BY CalendarYear) AS PreviousYearSales
FROM YearlySales )
SELECT  calendarYear, TotalSales, PreviousYearSales,
        ROUND(((TotalSales - PreviousYearSales) / NULLIF(PreviousYearSales,0)) * 100,2) AS YoYGrowthPercentage
FROM saleswithpreviousyear  
ORDER BY CalendarYear;

-- ===================================================== VIEW ===========================================================
            -- The View provides a summary of the main 5 business KPIs.
CREATE VIEW vw_Sales_KPI AS 
SELECT  SUM(SalesAmount) AS TotalSales,
        SUM(ProfitAmount) AS TotalProfit,
        COUNT(DISTINCT OrderId) AS TotalOrders,
        SUM(Quantity) AS TotalQuantity,
        ROUND((SUM(ProfitAmount) / SUM(SalesAmount))* 100, 2) AS ProfitMargin
FROM factsales;
SELECT * FROM vw_sales_kpi;

-- ===================================================== PROCEDURE ===========================================================
-- CREATE PROCEDURE GetYearlySalesKPI(
--     IN p_year INTEGER 
-- )
-- LANGUAGE plpgsql
-- AS $$ 
-- DECLARE 
--         v_Total_Sales NUMERIC(14,2);
--         v_Total_Profit NUMERIC(14,2);
--         v_Total_Orders INTEGER;
--         v_Profit_Margin NUMERIC(10,2);
-- BEGIN
-- SELECT  
--         SUM(SalesAmount) AS TotalSales,
--         SUM(ProfitAmount) AS TotalProfit,
--         COUNT(DISTINCT OrderID)
-- INTO    
--         v_Total_Sales,
--         v_Total_Profit,
--         v_Total_Orders
-- FROM FactSales f
-- JOIN DimDate d ON f.OrderDateKey = d.DateKey
-- WHERE CalendarYear = p_year;

-- IF v_Total_Sales = 0 THEN v_Profit_Margin := 0;
-- ELSE v_profit_Margin := ROUND((v_Total_Profit / v_total_Sales) * 100 , 2);
-- END IF;

-- RAISE NOTICE 'Year: %', p_year;
-- RAISE NOTICE 'Total sales: %', v_Total_Sales;
-- RAISE NOTICE 'Total Profit: %', v_Total_Profit;
-- RAISE NOTICE 'Total Orders: %', v_Total_Orders;
-- RAISE NOTICE 'Profit Margin: %%%', v_Profit_Margin;
-- END;
-- $$;

-- -- The Procedure Will Give you
--                 -- The Year:
--                 -- Total Sales -> (sum(SalesAmount)) For this Year
--                 -- Total Profit -> (sum(ProfitAmount)) For this Year
--                 -- Total Orders -> (sum(DISTINCT OrderId)) For this Year
--                 -- Profit Margin -> ((Total Profit / Total Sales) * 100) For this Year

-- CALL GetYearlySalesKPI(2015); -- this for year = 2015
-- CALL GetYearlySalesKPI(2014); -- this for year = 2014
-- ================================================= FUNCTION ==========================================================
-- I will Add Function After The Procedure 
CREATE OR REPLACE FUNCTION FUNC_GetYearlySalesKPI(
    P_Year INTEGER 
)
RETURNS TABLE (
    Total_Sales NUMERIC(14,2),
    Total_Profit NUMERIC(14,2),
    TOtal_Orders BIGINT,
    Profit_Margin NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$ 
BEGIN 
RETURN QUERY 
SELECT  SUM(f.SalesAmount),
        SUM(f.ProfitAmount),
        COUNT(DISTINCT f.OrderID),
        ROUND(SUM(f.ProfitAmount) / SUM(SalesAmount) *100,2)
FROM FactSales f
JOIN DimDate d ON f.OrderDateKey = d.DateKey
WHERE d.CalendarYear = P_Year;
END;
$$;


SELECT * FROM FUNC_GetYearlySalesKPI(2016);


-- ===================================================== Query Optimization ===========================================================
-- BEFORE THE INDEX
EXPLAIN ANALYZE
SELECT category, SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit 
FROM factsales f
JOIN dimproduct d ON f.productkey = d.productkey
GROUP BY category
ORDER BY TotalSales DESC; -- Execution Time: 1.203 ms

CREATE INDEX idx_factsales_productkey
ON FactSales(ProductKey);

-- AFTER THE INDEX
EXPLAIN ANALYZE
SELECT category, SUM(salesamount) AS TotalSales, SUM(profitamount) AS TotalProfit 
FROM factsales f
JOIN dimproduct d ON f.productkey = d.productkey
GROUP BY category
ORDER BY TotalSales DESC; -- Execution Time: 1.089 ms