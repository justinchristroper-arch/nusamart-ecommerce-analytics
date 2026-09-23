-- =====================================================================
-- 03_customer_analysis.sql
-- Business questions: retensi (Q4) & konsentrasi revenue customer (Q5)
-- Definisi: customer = customer_unique_id; hanya order delivered.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q4a: Repeat purchase rate (sepanjang periode data)
-- ---------------------------------------------------------------------
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS n_orders
    FROM fact_sales
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                                    AS total_customers,
    COUNT(*) FILTER (WHERE n_orders >= 2)                       AS repeat_customers,
    ROUND(COUNT(*) FILTER (WHERE n_orders >= 2) * 100.0
          / COUNT(*), 2)                                        AS repeat_rate_pct
FROM per_customer;

-- ---------------------------------------------------------------------
-- Q4b: Distribusi jumlah order per customer
-- ---------------------------------------------------------------------
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS n_orders
    FROM fact_sales
    GROUP BY customer_unique_id
)
SELECT
    n_orders,
    COUNT(*)                                                    AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)          AS pct_customers
FROM per_customer
GROUP BY n_orders
ORDER BY n_orders;

-- ---------------------------------------------------------------------
-- Q4c: New vs returning customer per bulan (jumlah & revenue)
-- New       = bulan ini adalah bulan order pertamanya
-- Returning = sudah pernah order di bulan sebelumnya
-- ---------------------------------------------------------------------
WITH customer_month AS (
    SELECT
        DATE_TRUNC('month', f.order_date)::date        AS month,
        f.customer_unique_id,
        DATE_TRUNC('month', c.first_order_date)::date  AS first_month,
        SUM(f.price)                                   AS revenue
    FROM fact_sales f
    JOIN dim_customer c USING (customer_unique_id)
    GROUP BY 1, 2, 3
)
SELECT
    month,
    COUNT(*) FILTER (WHERE month = first_month)                 AS new_customers,
    COUNT(*) FILTER (WHERE month > first_month)                 AS returning_customers,
    ROUND(SUM(revenue) FILTER (WHERE month = first_month), 2)   AS new_revenue,
    ROUND(SUM(revenue) FILTER (WHERE month > first_month), 2)   AS returning_revenue,
    ROUND(COALESCE(SUM(revenue) FILTER (WHERE month > first_month), 0)
          / SUM(revenue) * 100, 2)                              AS returning_revenue_pct
FROM customer_month
GROUP BY month
ORDER BY month;

-- ---------------------------------------------------------------------
-- Q5a: Konsentrasi revenue per desil customer
-- Desil 1 = 10% customer dengan revenue tertinggi
-- ---------------------------------------------------------------------
WITH customer_revenue AS (
    SELECT customer_unique_id, SUM(price) AS revenue
    FROM fact_sales
    GROUP BY customer_unique_id
),
ranked AS (
    SELECT revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM customer_revenue
)
SELECT
    decile,
    COUNT(*)                                                             AS customers,
    ROUND(SUM(revenue), 2)                                               AS revenue,
    ROUND(SUM(revenue) / SUM(SUM(revenue)) OVER () * 100, 2)             AS revenue_share_pct,
    ROUND(SUM(SUM(revenue)) OVER (ORDER BY decile)
          / SUM(SUM(revenue)) OVER () * 100, 2)                          AS cumulative_share_pct
FROM ranked
GROUP BY decile
ORDER BY decile;

-- ---------------------------------------------------------------------
-- Q5b: Top 10 customer berdasarkan revenue
-- (ID sudah dianonimkan oleh Olist; tampilkan versi pendek di dashboard)
-- ---------------------------------------------------------------------
SELECT
    f.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT f.order_id)      AS orders,
    ROUND(SUM(f.price), 2)          AS revenue
FROM fact_sales f
JOIN dim_customer c USING (customer_unique_id)
GROUP BY f.customer_unique_id, c.customer_state
ORDER BY revenue DESC
LIMIT 10;
