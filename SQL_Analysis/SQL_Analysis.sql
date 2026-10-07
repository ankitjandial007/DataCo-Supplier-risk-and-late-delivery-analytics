/* =====================================================================
   DELIVERY RISK ANALYTICS — SQL ANALYSIS (SQL Server / T-SQL)
   Author: Ankit Jandial

   What this file does
     Part 0  Create the database and the table
     Part 1  Check the data loaded correctly
     Part 2  Build an order-level view (one row per order)
     Part 3  Re-check the Python EDA numbers in SQL
     Part 4  New questions: lane ranking, trends, Pareto, profit
     Part 5  Views for the risk score and the dashboard

   How to run it
     1. Run Part 0 (creates the database and an empty table).
     2. Load the data with load_to_sql.py (fills the table from dataco_clean.csv).
     3. Run the rest of the file one query at a time, top to bottom,
        and compare each result with your Python notebook.

   "GO" splits the file into batches. SQL Server needs it because
   CREATE DATABASE, USE and CREATE VIEW must each start their own batch.
   ===================================================================== */


/* =====================================================================
   PART 0 — CREATE THE DATABASE AND TABLE
   ===================================================================== */

-- Create the database only if it doesn't exist yet, so the file can be re-run safely
USE DataCoDB;


-- Drop the table first so re-running Part 0 starts clean.
-- WARNING: this deletes loaded data. Re-run load_to_sql.py afterwards.

TRUNCATE TABLE dbo.orders_clean;

-- One row per ORDER ITEM, exactly like dataco_clean.csv.
-- Only the columns the analysis needs are kept.

BULK INSERT dbo.orders_clean
FROM '/tmp/orders_for_sql.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    TABLOCK
);

SELECT COUNT(*) AS item_rows, COUNT(DISTINCT order_id) AS orders FROM dbo.orders_clean;

SELECT DISTINCT TOP 10 order_city FROM dbo.orders_clean WHERE order_city LIKE 'S%o Paulo' OR order_city LIKE '%é%';


/*  >>> STOP HERE. Run load_to_sql.py now to fill the table, then continue. <<<  */


/* =====================================================================
   PART 1 — DATA CHECKS (did everything load correctly?)
   ===================================================================== */

-- 1.1 Row and order counts. Should match the Python output:
--     172,765 item rows and 62,897 orders.
SELECT
    COUNT(*)                 AS item_rows,
    COUNT(DISTINCT order_id) AS orders
FROM dbo.orders_clean;

-- 1.2 Date range of the data
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM dbo.orders_clean;

-- 1.3 Missing values in the columns we rely on (all should be 0)
SELECT
    SUM(CASE WHEN shipping_mode IS NULL THEN 1 ELSE 0 END)               AS missing_mode,
    SUM(CASE WHEN order_region  IS NULL THEN 1 ELSE 0 END)               AS missing_region,
    SUM(CASE WHEN days_for_shipping_real IS NULL THEN 1 ELSE 0 END)      AS missing_actual_days,
    SUM(CASE WHEN days_for_shipment_scheduled IS NULL THEN 1 ELSE 0 END) AS missing_promised_days,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END)                       AS missing_sales
FROM dbo.orders_clean;

-- 1.4 No cancelled shipments should be left (Python set them aside)
SELECT delivery_status, COUNT(*) AS item_rows
FROM dbo.orders_clean
GROUP BY delivery_status
ORDER BY item_rows DESC;


/* =====================================================================
   PART 2 — ORDER-LEVEL VIEW
   The table has one row per ITEM. Delivery questions are about ORDERS,
   so this view collapses the items of each order into one row.
   Shipping fields are the same for every item in an order, so MAX()
   just picks that one value. Sales and profit are added up.
   ===================================================================== */

CREATE OR ALTER VIEW dbo.vw_orders AS
SELECT
    order_id,
    MIN(order_date)                   AS order_date,
    MAX(market)                       AS market,
    MAX(order_region)                 AS order_region,
    MAX(order_country)                AS order_country,
    MAX(order_city)                   AS order_city,
    MAX(shipping_mode)                AS shipping_mode,
    MAX(lane)                         AS lane,
    MAX(customer_segment)             AS customer_segment,
    MAX(days_for_shipment_scheduled)  AS promised_days,
    MAX(days_for_shipping_real)       AS actual_days,
    MAX(delay_days)                   AS delay_days,
    MAX(is_late)                      AS is_late,
    SUM(sales)                        AS order_sales,
    SUM(order_profit_per_order)       AS order_profit
FROM dbo.orders_clean
GROUP BY order_id;
GO

-- Quick look at the view
SELECT TOP 10 * FROM dbo.vw_orders ORDER BY order_id;


/* =====================================================================
   PART 3 — RE-CHECK THE PYTHON EDA NUMBERS IN SQL
   If these match your notebook, your SQL logic is right.
   CAST(... AS FLOAT) stops SQL Server doing whole-number division
   (in SQL Server, 1/2 = 0, but 1.0/2 = 0.5).
   ===================================================================== */

-- 3.1 Headline KPIs. Expected: 62,897 orders, 57.3% late,
--     1.62 days average delay, 57.2% of sales on late orders, 10.8% margin.
SELECT
    COUNT(*)                                                         AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)                      AS late_rate_pct,
    ROUND(AVG(CASE WHEN is_late = 1
                   THEN CAST(delay_days AS FLOAT) END), 2)           AS avg_delay_of_late_orders,
    ROUND(SUM(order_sales), 0)                                       AS total_sales,
    ROUND(SUM(CASE WHEN is_late = 1 THEN order_sales ELSE 0 END)
          * 100.0 / SUM(order_sales), 1)                             AS pct_sales_on_late_orders,
    ROUND(SUM(order_profit) * 100.0 / SUM(order_sales), 1)           AS profit_margin_pct
FROM dbo.vw_orders;

-- 3.2 Late rate by shipping mode.
--     Expected: First Class 100%, Second Class 80%, Same Day 48%, Standard 40%.
SELECT
    shipping_mode,
    COUNT(*)                                     AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)  AS late_rate_pct
FROM dbo.vw_orders
GROUP BY shipping_mode
ORDER BY late_rate_pct DESC;

-- 3.3 Planning or execution? Promised vs actual days by shipping mode.
--     The key finding: Second Class takes as long as Standard Class.
SELECT
    shipping_mode,
    ROUND(AVG(CAST(promised_days AS FLOAT)), 2)                 AS avg_promised_days,
    ROUND(AVG(CAST(actual_days   AS FLOAT)), 2)                 AS avg_actual_days,
    ROUND(AVG(CAST(actual_days - promised_days AS FLOAT)), 2)   AS avg_gap_days
FROM dbo.vw_orders
GROUP BY shipping_mode
ORDER BY avg_promised_days;

-- 3.4 How late is late? Share of orders by days of delay
--     (negative = early, 0 = on time, positive = late).
--     SUM(COUNT(*)) OVER () is the total across all rows, so each row
--     can be shown as a share of the whole.
SELECT
    delay_days,
    COUNT(*)                                           AS orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM dbo.vw_orders
GROUP BY delay_days
ORDER BY delay_days;

-- 3.5 Late rate by market
SELECT
    market,
    COUNT(*)                                                            AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)                         AS late_rate_pct,
    ROUND(SUM(CASE WHEN is_late = 1 THEN order_sales ELSE 0 END), 0)    AS sales_on_late_orders
FROM dbo.vw_orders
GROUP BY market
ORDER BY late_rate_pct DESC;


/* =====================================================================
   PART 4 — NEW QUESTIONS (CTEs and window functions)
   ===================================================================== */

-- 4.1 Regions compared with the company average.
--     A CTE (WITH ...) is a named temporary result you can reuse below.
--     CROSS JOIN attaches the one-row company average to every region.
WITH company AS (
    SELECT AVG(CAST(is_late AS FLOAT)) AS avg_late_rate
    FROM dbo.vw_orders
),
regions AS (
    SELECT
        order_region,
        COUNT(*)                    AS orders,
        AVG(CAST(is_late AS FLOAT)) AS late_rate
    FROM dbo.vw_orders
    GROUP BY order_region
)
SELECT
    r.order_region,
    r.orders,
    ROUND(r.late_rate * 100, 1)                        AS late_rate_pct,
    ROUND((r.late_rate - c.avg_late_rate) * 100, 1)    AS points_vs_company_avg,
    RANK() OVER (ORDER BY r.late_rate DESC)            AS worst_rank
FROM regions r
CROSS JOIN company c
ORDER BY worst_rank;

-- 4.2 Rank every shipping lane (region + mode) from worst to best.
--     Lanes with fewer than 200 orders are left out because their rates are unreliable.
--     RANK() gives tied lanes the same rank and then skips numbers (1, 1, 3);
--     DENSE_RANK() doesn't skip (1, 1, 2); ROW_NUMBER() never ties (1, 2, 3).
WITH lane_stats AS (
    SELECT
        lane,
        order_region,
        shipping_mode,
        COUNT(*)                                                    AS orders,
        AVG(CAST(is_late AS FLOAT))                                 AS late_rate,
        SUM(CASE WHEN is_late = 1 THEN order_sales ELSE 0 END)      AS late_sales
    FROM dbo.vw_orders
    GROUP BY lane, order_region, shipping_mode
    HAVING COUNT(*) >= 200
)
SELECT
    lane,
    orders,
    ROUND(late_rate * 100, 1)                                AS late_rate_pct,
    ROUND(late_sales, 0)                                     AS late_sales,
    ROUND(late_sales * 100.0 / SUM(late_sales) OVER (), 2)   AS pct_of_all_late_sales,
    RANK()       OVER (ORDER BY late_rate DESC)              AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY late_rate DESC)              AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY late_rate DESC, late_sales DESC) AS row_num
FROM lane_stats
ORDER BY late_rate DESC, late_sales DESC;

-- 4.3 Worst lane within each region.
--     PARTITION BY restarts the ranking for every region.
WITH lane_stats AS (
    SELECT
        order_region,
        shipping_mode,
        COUNT(*)                    AS orders,
        AVG(CAST(is_late AS FLOAT)) AS late_rate
    FROM dbo.vw_orders
    GROUP BY order_region, shipping_mode
    HAVING COUNT(*) >= 100
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_region
                              ORDER BY late_rate DESC, orders DESC) AS rn
    FROM lane_stats
)
SELECT
    order_region,
    shipping_mode               AS worst_mode,
    orders,
    ROUND(late_rate * 100, 1)   AS late_rate_pct
FROM ranked
WHERE rn = 1
ORDER BY late_rate_pct DESC;

-- 4.4 Monthly trend: late rate, change from last month (LAG),
--     and a 3-month moving average to smooth out noise.
WITH monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
        COUNT(*)                                              AS orders,
        AVG(CAST(is_late AS FLOAT)) * 100                     AS late_rate_pct
    FROM dbo.vw_orders
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT
    month_start,
    orders,
    ROUND(late_rate_pct, 1)                                                    AS late_rate_pct,
    ROUND(late_rate_pct - LAG(late_rate_pct) OVER (ORDER BY month_start), 1)   AS change_vs_last_month,
    ROUND(AVG(late_rate_pct) OVER (ORDER BY month_start
                                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3m
FROM monthly
ORDER BY month_start;

-- 4.5 Category late rate.
--     Categories live on items, and one order can contain several categories,
--     so we count DISTINCT orders per category and use the order-level late flag.
WITH order_category AS (
    SELECT DISTINCT order_id, category_name, is_late
    FROM dbo.orders_clean
)
SELECT
    category_name,
    COUNT(*)                                     AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)  AS late_rate_pct
FROM order_category
GROUP BY category_name
HAVING COUNT(*) >= 500
ORDER BY late_rate_pct DESC;

-- 4.6 Category Pareto (ABC analysis): which categories make up most of the sales?
--     The running total is a SUM() OVER with ORDER BY.
--     A = first 80% of sales, B = next 15%, C = last 5%.
WITH category_sales AS (
    SELECT category_name, SUM(sales) AS sales
    FROM dbo.orders_clean
    GROUP BY category_name
),
running AS (
    SELECT
        category_name,
        sales,
        SUM(sales) OVER (ORDER BY sales DESC
                         ROWS UNBOUNDED PRECEDING) * 100.0
            / SUM(sales) OVER ()                       AS cumulative_pct
    FROM category_sales
)
SELECT
    category_name,
    ROUND(sales, 0)            AS sales,
    ROUND(cumulative_pct, 1)   AS cumulative_pct,
    CASE
        WHEN cumulative_pct - sales * 100.0 / SUM(sales) OVER () < 80 THEN 'A'
        WHEN cumulative_pct - sales * 100.0 / SUM(sales) OVER () < 95 THEN 'B'
        ELSE 'C'
    END                        AS abc_class      -- based on where the category STARTS in the running total
FROM running
ORDER BY sales DESC;

-- 4.7 Do late orders hurt profit?
--     Expected: margin about the same (10.6% late vs 11.0% on time).
SELECT
    CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time / early' END     AS status,
    COUNT(*)                                                          AS orders,
    ROUND(SUM(order_sales), 0)                                        AS sales,
    ROUND(SUM(order_profit), 0)                                       AS profit,
    ROUND(SUM(order_profit) * 100.0 / SUM(order_sales), 1)            AS margin_pct,
    ROUND(AVG(CASE WHEN order_profit < 0 THEN 1.0 ELSE 0 END) * 100, 1) AS pct_loss_making
FROM dbo.vw_orders
GROUP BY CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time / early' END;

-- 4.8 Customer segment: does customer type matter?
SELECT
    customer_segment,
    COUNT(*)                                     AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)  AS late_rate_pct
FROM dbo.vw_orders
GROUP BY customer_segment
ORDER BY late_rate_pct DESC;

-- 4.9 Order weekday: are orders placed on some days later than others?
--     DATENAME gives "Monday"; the CASE sorts Monday to Sunday.
SELECT
    DATENAME(WEEKDAY, order_date)                AS weekday,
    COUNT(*)                                     AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)  AS late_rate_pct
FROM dbo.vw_orders
GROUP BY DATENAME(WEEKDAY, order_date)
ORDER BY CASE DATENAME(WEEKDAY, order_date)
             WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
             WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
             ELSE 7 END;

-- 4.10 Top 10 cities by revenue on late orders (where to act first)
SELECT TOP 10
    order_city,
    order_country,
    COUNT(*)                                                          AS orders,
    ROUND(AVG(CAST(is_late AS FLOAT)) * 100, 1)                       AS late_rate_pct,
    ROUND(SUM(CASE WHEN is_late = 1 THEN order_sales ELSE 0 END), 0)  AS sales_on_late_orders
FROM dbo.vw_orders
GROUP BY order_city, order_country
ORDER BY sales_on_late_orders DESC;

-- 4.11 Lanes worse than the company average, with the revenue that would
--      stop being late if the lane matched the average ("recoverable sales").
--      This is an estimate: it assumes the lane's sales stay the same.
WITH company AS (
    SELECT AVG(CAST(is_late AS FLOAT)) AS avg_late_rate FROM dbo.vw_orders
),
lane_stats AS (
    SELECT
        lane,
        COUNT(*)                    AS orders,
        SUM(order_sales)            AS sales,
        AVG(CAST(is_late AS FLOAT)) AS late_rate
    FROM dbo.vw_orders
    GROUP BY lane
    HAVING COUNT(*) >= 200
)
SELECT
    l.lane,
    l.orders,
    ROUND(l.late_rate * 100, 1)                              AS late_rate_pct,
    ROUND(c.avg_late_rate * 100, 1)                          AS company_avg_pct,
    ROUND((l.late_rate - c.avg_late_rate) * l.sales, 0)      AS recoverable_sales
FROM lane_stats l
CROSS JOIN company c
WHERE l.late_rate > c.avg_late_rate
ORDER BY recoverable_sales DESC;

-- 4.12 Total recoverable sales across all lanes above average (one number for the README)
WITH company AS (
    SELECT AVG(CAST(is_late AS FLOAT)) AS avg_late_rate FROM dbo.vw_orders
),
lane_stats AS (
    SELECT lane, SUM(order_sales) AS sales, AVG(CAST(is_late AS FLOAT)) AS late_rate
    FROM dbo.vw_orders
    GROUP BY lane
    HAVING COUNT(*) >= 200
)
SELECT
    COUNT(*)                                                 AS lanes_above_average,
    ROUND(SUM((l.late_rate - c.avg_late_rate) * l.sales), 0) AS total_recoverable_sales
FROM lane_stats l
CROSS JOIN company c
WHERE l.late_rate > c.avg_late_rate;


/* =====================================================================
   PART 5 — VIEWS FOR THE RISK SCORE AND THE DASHBOARD
   Views save a query under a name, so Python and the dashboard
   can read the result like a table.
   ===================================================================== */

-- 5.1 Lane metrics: the inputs to the risk score
CREATE OR ALTER VIEW dbo.vw_lane_metrics AS
SELECT
    lane,
    order_region,
    shipping_mode,
    COUNT(*)                                                         AS orders,
    SUM(order_sales)                                                 AS sales,
    AVG(CAST(is_late AS FLOAT))                                      AS late_rate,
    SUM(CASE WHEN is_late = 1 THEN order_sales ELSE 0 END)           AS late_sales,
    AVG(CASE WHEN is_late = 1 THEN CAST(delay_days AS FLOAT) END)    AS avg_delay_when_late,
    AVG(CASE WHEN is_late = 1 AND order_profit < 0 THEN 1.0 ELSE 0 END) AS late_and_loss_share
FROM dbo.vw_orders
GROUP BY lane, order_region, shipping_mode
HAVING COUNT(*) >= 200;
GO

-- 5.2 First version of the lane risk score (0-100).
--     Each input is rescaled to 0-1 with min-max:
--         (value - smallest) / (largest - smallest)
--     then weighted: late rate 40%, share of late revenue 30%,
--     delay when late 20%, late-and-loss-making share 10%.
--     NULLIF stops a divide-by-zero if every lane has the same value.
CREATE OR ALTER VIEW dbo.vw_lane_risk AS
WITH base AS (
    SELECT
        lane, order_region, shipping_mode, orders, sales, late_rate, late_sales,
        late_sales / SUM(late_sales) OVER ()   AS late_sales_share,
        ISNULL(avg_delay_when_late, 0)         AS avg_delay_when_late,
        late_and_loss_share
    FROM dbo.vw_lane_metrics
),
scaled AS (
    SELECT *,
        (late_rate - MIN(late_rate) OVER ())
            / NULLIF(MAX(late_rate) OVER () - MIN(late_rate) OVER (), 0)                     AS s_late_rate,
        (late_sales_share - MIN(late_sales_share) OVER ())
            / NULLIF(MAX(late_sales_share) OVER () - MIN(late_sales_share) OVER (), 0)       AS s_exposure,
        (avg_delay_when_late - MIN(avg_delay_when_late) OVER ())
            / NULLIF(MAX(avg_delay_when_late) OVER () - MIN(avg_delay_when_late) OVER (), 0) AS s_delay,
        (late_and_loss_share - MIN(late_and_loss_share) OVER ())
            / NULLIF(MAX(late_and_loss_share) OVER () - MIN(late_and_loss_share) OVER (), 0) AS s_loss
    FROM base
)
SELECT
    lane, order_region, shipping_mode, orders, sales, late_rate, late_sales,
    ROUND(100 * (0.4 * ISNULL(s_late_rate, 0) + 0.3 * ISNULL(s_exposure, 0)
               + 0.2 * ISNULL(s_delay, 0)     + 0.1 * ISNULL(s_loss, 0)), 1) AS risk_score
FROM scaled;
GO

-- 5.3 Read the risk score with a High / Medium / Low tier
SELECT
    lane,
    orders,
    ROUND(late_rate * 100, 1)  AS late_rate_pct,
    ROUND(late_sales, 0)       AS late_sales,
    risk_score,
    CASE WHEN risk_score >= 70 THEN 'High'
         WHEN risk_score >= 40 THEN 'Medium'
         ELSE 'Low' END        AS risk_tier
FROM dbo.vw_lane_risk
ORDER BY risk_score DESC;

/* ============================ END OF FILE ============================ */
