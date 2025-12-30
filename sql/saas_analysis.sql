-- IDENTIFYING REVENUE TRENDS

UPDATE fact_sales
SET Order_Date = str_to_date(Order_Date, '%Y-%m-%d');

ALTER TABLE fact_sales
MODIFY COLUMN Order_Date DATE;

SELECT round(sum(Sales),2)
FROM fact_sales;

SELECT AVG(Discount)
FROM fact_sales;

-- 1. Revenue per Month

SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
ROUND(SUM(Sales),2) AS TotalSales
FROM fact_sales
GROUP BY YearMonth
ORDER BY YearMonth;

-- 2. Revenue per Year

SELECT YEAR(Order_Date) AS `year`,
ROUND(SUM(sales),2) AS TotalSales
FROM fact_sales
GROUP BY `year`
ORDER BY `year`;

-- 3. Profit per Month

SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
ROUND(SUM(Profit),2) AS TotalProfit
FROM fact_sales
GROUP BY YearMonth
ORDER BY YearMonth;

-- 4. Profit per Year

SELECT YEAR(Order_Date) AS `year`,
ROUND(SUM(Profit),2) AS TotalProfit
FROM fact_sales
GROUP BY `year`
ORDER BY `year`;

-- 5. Revenue and Profit per Month

SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
ROUND(SUM(Sales),2) AS TotalSales,
ROUND(SUM(Profit),2) AS TotalProfit
FROM fact_sales
GROUP BY YearMonth
ORDER BY YearMonth;

-- 6. Month over Month Revenue Growth

WITH monthly AS
(SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
ROUND(SUM(Sales),2) AS TotalSales
FROM fact_sales
GROUP BY YearMonth),
mom AS
(SELECT *, LAG(TotalSales, 1) OVER(ORDER BY YearMonth) AS PrevSales
FROM monthly)
SELECT YearMonth, TotalSales, ROUND((TotalSales - PrevSales)/PrevSales * 100, 2) AS MoM_Change
FROM mom;

-- 7. Year over Year Revenue Growth

WITH yearly AS
(select YEAR(Order_Date) AS `year`,
ROUND(SUM(Sales),2) AS TotalSales
FROM fact_sales
GROUP BY `year`),
yoy AS
(SELECT *, LAG(TotalSales, 1) OVER(ORDER BY `year`) AS PrevSales
FROM yearly)
SELECT `year`, TotalSales, ROUND((TotalSales - PrevSales)/PrevSales * 100,2) AS YoY_Change
FROM yoy;

-- 8. Month over Month Profit Growth

WITH monthly AS
(SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
ROUND(SUM(Profit),2) AS TotalProfit
FROM fact_sales
GROUP BY YearMonth),
mom AS
(SELECT *, LAG(TotalProfit, 1) OVER(ORDER BY YearMonth) AS PrevProfit
FROM monthly)
SELECT YearMonth, TotalProfit, ROUND((TotalProfit - PrevProfit)/PrevProfit * 100,2) AS MoM_Change
FROM mom;

-- 9. Year over Year profit growth

WITH yearly AS
(SELECT YEAR(Order_Date) AS `year`,
ROUND(SUM(Profit),2) AS TotalProfit
FROM fact_sales
GROUP BY `year`),
yoy AS
(SELECT *, LAG(TotalProfit, 1) OVER(ORDER BY `year`) AS PrevProfit
FROM yearly)
SELECT `year`, TotalProfit, ROUND((TotalProfit - PrevProfit)/PrevProfit * 100,2) AS YoY_Change
FROM yoy;

-- IMPACT OF DISCOUNT

WITH buckets AS (
    SELECT
        CASE
    WHEN Discount > 0 AND Discount <= 0.1 THEN '0-10%'
    WHEN Discount > 0.1 AND Discount <= 0.2 THEN '10-20%'
    WHEN Discount > 0.2 AND Discount <= 0.3 THEN '20-30%'
    WHEN Discount > 0.3 AND Discount <= 0.5 THEN '30-50%'
    WHEN Discount > 0.5 THEN '50%+'
END AS Discount_Bucket,
        Sales,
        Profit,
        Order_ID,
        Quantity
    FROM fact_sales
)
SELECT
    Discount_Bucket,
    ROUND(SUM(Sales), 2) AS TotalSales,
    ROUND(SUM(Profit), 2) AS TotalProfit,
    COUNT(Order_ID) AS TotalOrders,
    SUM(Quantity) AS TotalQuantity, 
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin
FROM buckets
WHERE Discount_Bucket IS NOT NULL
GROUP BY Discount_Bucket
ORDER BY Discount_Bucket;

-- REVENUE BY SEGMENTS, INDUSTRY, REGION

-- 1. Total Revenue by Segment

SELECT d.Segment, ROUND(SUM(f.Sales),2) AS TotalRevenue
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY d.Segment
ORDER BY TotalRevenue;

-- 2. Total Revenue by Industry

SELECT d.Industry, ROUND(SUM(f.Sales),2) AS TotalRevenue
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY d.Industry
ORDER BY TotalRevenue;

-- 3. Total Revenue by Region

SELECT d.Region, ROUND(SUM(f.Sales),2) AS TotalRevenue
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY .Region
ORDER BY TotalRevenue;

-- 4. Top 10 Underperformers customer groups

SELECT d.Customer, 
ROUND(SUM(f.Sales), 2) AS TotalSales,
ROUND(SUM(f.Profit), 2) AS TotalProfit,
COUNT(f.Order_ID) AS TotalOrders,
SUM(f.Quantity) AS TotalQuantity
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY d.Customer
ORDER BY TotalSales, TotalProfit
limit 10;

-- EVALUATE PRODUCT LEVEL CONTRIBUTION

-- 1. Total revenue, Total Profit and Avg Discount BY PRODUCTS
SELECT p.Product, 
ROUND(SUM(f.Sales),2) AS TotalSales,
ROUND(SUM(f.Profit),2) AS TotalProfit,
ROUND(AVG(f.Discount),2) AS AvgDiscount
FROM fact_sales f
LEFT JOIN dim_product p
	ON f.Product_ID = p.Product_ID
GROUP BY p.Product
ORDER BY TotalSales DESC, TotalProfit DESC, AvgDiscount DESC;

-- 2. NEGATIVE PROFIT OF PRODUCTS

SELECT p.Product, ROUND(SUM(f.Profit),2) AS TotalProfit
FROM fact_sales f
JOIN dim_product p
	ON f.Product_ID = p.Product_ID
GROUP BY p.Product
HAVING TotalProfit < 0;

-- 3. Bottom 20% Profit

WITH dist AS
(SELECT p.Product, ROUND(SUM(f.Profit),2) AS TotalProfit
FROM fact_sales f
JOIN dim_product p
	ON f.Product_ID = p.Product_ID
GROUP BY p.Product),
percent AS
(SELECT *, ROUND(CUME_DIST() OVER(ORDER BY TotalProfit),2) AS profit_percent
FROM dist)
SELECT Product, TotalProfit
FROM percent
WHERE profit_percent <= 0.20;

-- 4. High Discount Products

WITH dist AS
(SELECT p.Product, ROUND(AVG(f.Discount),2) AS AvgDiscount
FROM fact_sales f
JOIN dim_product p
	ON f.Product_ID = p.Product_ID
GROUP BY p.Product),
percent AS
(SELECT *, ROUND(CUME_DIST() OVER(ORDER BY AvgDiscount),2) AS discount_percent
FROM dist)
SELECT Product, AvgDiscount
FROM percent
WHERE discount_percent >= 0.80;

-- Customer-Level Revenue Distribution

-- 1. Customer Driven Revenue

SELECT d.Customer, ROUND(SUM(f.Sales),2) AS TotalSales
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY d.Customer
ORDER BY TotalSales DESC
LIMIT 10;

-- 2. Customer Lifetime Revenue

SELECT d.Customer, 
ROUND(SUM(f.Sales),2) AS TotalSales,
MIN(f.Order_Date) AS min_date,
MAX(f.Order_Date) AS max_date,
COUNT(DISTINCT f.Order_Date) AS uniqueorderdays
FROM fact_sales f
JOIN dim_customer d
	ON f.Customer_ID = d.Customer_ID
GROUP BY d.Customer
ORDER BY TotalSales DESC
LIMIT 10;

-- 3. New vs Returning Customers

WITH first_orders AS (
    SELECT
        Customer_ID,
        MIN(Order_Date) AS FirstOrderDate
    FROM fact_sales
    GROUP BY Customer_ID
),
monthly_orders AS (
    SELECT
        Customer_ID,
        DATE_FORMAT(Order_Date, '%Y-%m') AS YearMonth,
        SUM(Sales) AS TotalSales
    FROM fact_sales
    GROUP BY Customer_ID, YearMonth
)
SELECT
    mo.YearMonth,
    COUNT(CASE WHEN fo.FirstOrderDate >= STR_TO_DATE(CONCAT(mo.YearMonth,'-01'), '%Y-%m-%d') THEN 1 END) AS NewCustomers,
    COUNT(CASE WHEN fo.FirstOrderDate < STR_TO_DATE(CONCAT(mo.YearMonth,'-01'), '%Y-%m-%d') THEN 1 END) AS ReturningCustomers
FROM monthly_orders mo
JOIN first_orders fo
    ON mo.Customer_ID = fo.Customer_ID
GROUP BY mo.YearMonth
ORDER BY mo.YearMonth;
































