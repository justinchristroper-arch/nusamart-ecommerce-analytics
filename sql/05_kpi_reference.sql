-- =====================================================================
-- 05_kpi_reference.sql
-- SATU-SATUNYA kunci jawaban rekonsiliasi. Hasil di sini HARUS SAMA
-- dengan angka referensi notebook (notebooks/01_data_cleaning.ipynb,
-- bagian 11) dan dengan KPI card di Power BI (filter jendela analisis
-- yang sama). Jika beda, cari penyebabnya sebelum lanjut.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Jumlah baris per tabel (bandingkan dengan output notebook)
-- ---------------------------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM fact_sales
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_product',  COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_date',     COUNT(*) FROM dim_date;

-- ---------------------------------------------------------------------
-- KPI TOTAL -- jendela analisis (2017-01 s/d 2018-07)
-- Ini angka acuan utama. Harus identik dengan KPI referensi di
-- notebook bagian 11 dan dengan KPI card Power BI.
-- ---------------------------------------------------------------------
WITH per_customer AS (
    SELECT f.customer_unique_id, COUNT(DISTINCT f.order_id) AS n_orders
    FROM fact_sales f
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
    GROUP BY f.customer_unique_id
)
SELECT
    (SELECT ROUND(SUM(f.price), 2)
     FROM fact_sales f JOIN dim_date d ON f.order_date = d.date_key
     WHERE d.is_analysis_month = TRUE)                                   AS total_revenue,
    (SELECT COUNT(DISTINCT f.order_id)
     FROM fact_sales f JOIN dim_date d ON f.order_date = d.date_key
     WHERE d.is_analysis_month = TRUE)                                   AS total_orders,
    (SELECT COUNT(*) FROM per_customer)                                  AS total_customers,
    (SELECT COUNT(*)
     FROM fact_sales f JOIN dim_date d ON f.order_date = d.date_key
     WHERE d.is_analysis_month = TRUE)                                   AS units_sold,
    (SELECT ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2)
     FROM fact_sales f JOIN dim_date d ON f.order_date = d.date_key
     WHERE d.is_analysis_month = TRUE)                                   AS aov,
    (SELECT ROUND(SUM(f.freight_value) / SUM(f.price) * 100, 2)
     FROM fact_sales f JOIN dim_date d ON f.order_date = d.date_key
     WHERE d.is_analysis_month = TRUE)                                   AS freight_burden_pct,
    (SELECT ROUND(COUNT(*) FILTER (WHERE n_orders >= 2) * 100.0
            / COUNT(*), 2) FROM per_customer)                            AS repeat_rate_pct;

-- ---------------------------------------------------------------------
-- KPI TOTAL -- pembanding TANPA filter jendela (seluruh delivered)
-- Dipakai untuk memahami dampak pengecualian bulan tidak lengkap,
-- BUKAN angka yang dipakai di dashboard/insight.
-- ---------------------------------------------------------------------
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS n_orders
    FROM fact_sales
    GROUP BY customer_unique_id
)
SELECT
    (SELECT ROUND(SUM(price), 2) FROM fact_sales)                        AS total_revenue,
    (SELECT COUNT(DISTINCT order_id) FROM fact_sales)                    AS total_orders,
    (SELECT COUNT(*) FROM per_customer)                                  AS total_customers,
    (SELECT COUNT(*) FROM fact_sales)                                    AS units_sold,
    (SELECT ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)
     FROM fact_sales)                                                    AS aov,
    (SELECT ROUND(SUM(freight_value) / SUM(price) * 100, 2)
     FROM fact_sales)                                                    AS freight_burden_pct,
    (SELECT ROUND(COUNT(*) FILTER (WHERE n_orders >= 2) * 100.0
            / COUNT(*), 2) FROM per_customer)                            AS repeat_rate_pct;

-- ---------------------------------------------------------------------
-- KPI per tahun, DIFILTER jendela analisis (untuk cek filter tahun di
-- Power BI). 2016 tidak akan muncul karena seluruhnya di luar jendela,
-- dan 2018 hanya berisi Januari-Juli.
-- ---------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM f.order_date)::int                    AS year,
    ROUND(SUM(f.price), 2)                                  AS total_revenue,
    COUNT(DISTINCT f.order_id)                              AS total_orders,
    COUNT(DISTINCT f.customer_unique_id)                    AS total_customers,
    COUNT(*)                                                AS units_sold,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2)     AS aov,
    ROUND(SUM(f.freight_value) / SUM(f.price) * 100, 2)     AS freight_burden_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date = d.date_key
WHERE d.is_analysis_month = TRUE
GROUP BY 1
ORDER BY 1;
