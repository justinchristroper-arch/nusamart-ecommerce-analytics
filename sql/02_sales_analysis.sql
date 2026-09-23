-- =====================================================================
-- 02_sales_analysis.sql
-- Business questions: KPI utama, tren (Q1), kategori (Q2), wilayah (Q3)
-- Jalankan satu query per satu di pgAdmin (blok query, lalu F5).
-- CATATAN: bulan awal/akhir yang tidak lengkap (lihat notebook bagian 6)
-- akan membuat angka growth ekstrem. Abaikan/keluarkan bulan itu saat
-- membaca hasil tren.
-- =====================================================================

-- ---------------------------------------------------------------------
-- KPI-01: KPI utama (angka referensi, harus sama dengan notebook & Power BI)
-- ---------------------------------------------------------------------
SELECT
    ROUND(SUM(price), 2)                                    AS total_revenue,
    COUNT(DISTINCT order_id)                                AS total_orders,
    COUNT(DISTINCT customer_unique_id)                      AS total_customers,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)         AS aov,
    ROUND(SUM(freight_value) / SUM(price) * 100, 2)         AS freight_burden_pct
FROM fact_sales;

-- ---------------------------------------------------------------------
-- Q1: Tren bulanan + dekomposisi growth
-- Pertanyaan: apakah pertumbuhan revenue datang dari lebih banyak order,
-- atau dari nilai order (AOV) yang lebih besar?
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::date  AS month,
        SUM(price)                              AS revenue,
        COUNT(DISTINCT order_id)                AS orders
    FROM fact_sales
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2)                                                   AS revenue,
    orders,
    ROUND(revenue / orders, 2)                                          AS aov,
    ROUND((revenue - LAG(revenue) OVER w)
          / NULLIF(LAG(revenue) OVER w, 0) * 100, 1)                    AS revenue_mom_pct,
    ROUND((orders - LAG(orders) OVER w)::numeric
          / NULLIF(LAG(orders) OVER w, 0) * 100, 1)                     AS orders_mom_pct,
    ROUND((revenue / orders - LAG(revenue / orders) OVER w)
          / NULLIF(LAG(revenue / orders) OVER w, 0) * 100, 1)           AS aov_mom_pct
FROM monthly
WINDOW w AS (ORDER BY month)
ORDER BY month;

-- ---------------------------------------------------------------------
-- Q1b: Year-over-Year per bulan (bulan yang sama tahun sebelumnya)
-- Hanya terisi untuk bulan yang punya data di tahun sebelumnya.
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month, SUM(price) AS revenue
    FROM fact_sales
    GROUP BY 1
)
SELECT
    cur.month,
    ROUND(cur.revenue, 2)                                         AS revenue,
    ROUND(prev.revenue, 2)                                        AS revenue_last_year,
    ROUND((cur.revenue - prev.revenue) / prev.revenue * 100, 1)   AS yoy_pct
FROM monthly cur
JOIN monthly prev
  ON prev.month = (cur.month - INTERVAL '1 year')::date
ORDER BY cur.month;

-- ---------------------------------------------------------------------
-- Q2: Revenue per kategori + kontribusi (%)
-- ---------------------------------------------------------------------
SELECT
    p.category_en,
    ROUND(SUM(f.price), 2)                                          AS revenue,
    COUNT(*)                                                        AS units_sold,
    COUNT(DISTINCT f.order_id)                                      AS orders,
    ROUND(SUM(f.price) / SUM(SUM(f.price)) OVER () * 100, 2)        AS revenue_share_pct
FROM fact_sales f
JOIN dim_product p USING (product_id)
GROUP BY p.category_en
ORDER BY revenue DESC
LIMIT 15;

-- ---------------------------------------------------------------------
-- Q2b: Apakah kontribusi kategori stabil antar-tahun?
-- (share dihitung dalam masing-masing tahun)
-- ---------------------------------------------------------------------
WITH cat_year AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date)::int AS year,
        p.category_en,
        SUM(f.price)                         AS revenue
    FROM fact_sales f
    JOIN dim_product p USING (product_id)
    GROUP BY 1, 2
)
SELECT
    year,
    category_en,
    ROUND(revenue, 2)                                                        AS revenue,
    ROUND(revenue / SUM(revenue) OVER (PARTITION BY year) * 100, 2)          AS share_in_year_pct,
    RANK() OVER (PARTITION BY year ORDER BY revenue DESC)                    AS rank_in_year
FROM cat_year
ORDER BY year, rank_in_year;

-- ---------------------------------------------------------------------
-- Q3: Performa per wilayah (state customer)
-- ---------------------------------------------------------------------
SELECT
    customer_state,
    ROUND(SUM(price), 2)                                        AS revenue,
    COUNT(DISTINCT order_id)                                    AS orders,
    COUNT(DISTINCT customer_unique_id)                          AS customers,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)             AS aov,
    ROUND(SUM(freight_value) / SUM(price) * 100, 2)             AS freight_burden_pct,
    ROUND(SUM(price) / SUM(SUM(price)) OVER () * 100, 2)        AS revenue_share_pct
FROM fact_sales
GROUP BY customer_state
ORDER BY revenue DESC;
