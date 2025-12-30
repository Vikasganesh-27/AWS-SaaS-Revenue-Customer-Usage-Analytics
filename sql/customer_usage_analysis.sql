
ALTER TABLE fact_usage
MODIFY COLUMN Event_Timestamp DATETIME;

-- Event Date

SELECT DATE(Event_Timestamp)
FROM fact_usage;

-- Event Month

SELECT DATE_FORMAT(Event_Timestamp, '%Y-%m')
FROM fact_usage;

-- 1. Daily Active Customers (DAC)

SELECT DATE(Event_Timestamp) AS event_date,
COUNT(DISTINCT Customer_ID) AS daily_active_customers
FROM fact_usage
WHERE Event_Type IN ('login')
GROUP BY event_date
ORDER BY event_date;

-- 2. Monthly Active Customers (MAC)

SELECT DATE_FORMAT(Event_Timestamp, '%Y-%m') AS event_month,
COUNT(DISTINCT Customer_ID) AS monthly_active_customers
FROM fact_usage
WHERE Event_Type IN ('login')
GROUP BY event_month
ORDER BY event_month;

-- 3. Active Days per Customer

SELECT Customer_ID, 
COUNT(DISTINCT DATE(Event_Timestamp)) AS Active_Days_Per_Customer
FROM fact_usage
WHERE Event_Type IN ('dashboard_viewed', 'report_downloaded' ,'feature_used')
GROUP BY Customer_ID
ORDER BY Customer_ID;

-- 4. Usage Frequency per Customer

SELECT Customer_ID, COUNT(*) AS num_customers
FROM fact_usage
WHERE Event_Type IN ('dashboard_viewed', 'report_downloaded','feature_used')
GROUP BY Customer_ID
ORDER BY Customer_ID ;

-- 5. Event Type Distribution

SELECT Customer_ID, Event_Type, COUNT(*) AS Event_Count
FROM fact_usage
GROUP BY Customer_ID, Event_Type
ORDER BY Customer_ID, Event_Type;

-- 6. Product Usage

select Customer_ID, Product_ID, count(*) as Event_Count
from fact_usage
WHERE Event_Type IN ('dashboard_viewed', 'report_downloaded','feature_used')
group by Customer_ID, Product_ID
order by Customer_ID, Product_ID;

-- 7. Recency (Days Since Last Event)

SELECT
    u.Customer_ID,
    u.Last_Event,
    DATEDIFF(
        (SELECT DATE(MAX(Event_Timestamp)) FROM fact_usage),
        u.Last_Event
    ) AS Recency_Days
FROM (
    SELECT 
        Customer_ID,
        DATE(MAX(Event_Timestamp)) AS Last_Event
    FROM fact_usage
    GROUP BY Customer_ID
) AS u
ORDER BY Customer_ID;

-- 8. Rolling 7-day/30-day frequency

-- 7 days

WITH daily_events AS (
    SELECT
        Customer_ID,
        DATE(Event_Timestamp) AS Event_Date,
        COUNT(*) AS Events
    FROM fact_usage
    GROUP BY Customer_ID, DATE(Event_Timestamp)
)
SELECT
    de.Customer_ID,
    de.Event_Date,
    SUM(de.Events) OVER (
        PARTITION BY de.Customer_ID
        ORDER BY de.Event_Date
        RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW
    ) AS Events_Last_7_Days
FROM daily_events de
ORDER BY de.Customer_ID, de.Event_Date;

-- 30 days

WITH daily_events AS (
    SELECT
        Customer_ID,
        DATE(Event_Timestamp) AS Event_Date,
        COUNT(*) AS Events
    FROM fact_usage
    GROUP BY Customer_ID, DATE(Event_Timestamp)
)
SELECT
    de.Customer_ID,
    de.Event_Date,
    SUM(de.Events) OVER (
        PARTITION BY de.Customer_ID
        ORDER BY de.Event_Date
        RANGE BETWEEN INTERVAL 29 DAY PRECEDING AND CURRENT ROW
    ) AS Events_Last_30_Days
FROM daily_events de
ORDER BY de.Customer_ID, de.Event_Date;


























