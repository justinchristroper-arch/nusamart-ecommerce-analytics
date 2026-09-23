-- =====================================================================
-- 05_kpi_reference.sql
-- Angka referensi untuk rekonsiliasi: hasil di sini HARUS SAMA dengan
-- KPI card di Power BI (filter tahun yang sama). Jika beda, ada bug.
-- =====================================================================

-- Jumlah baris per tabel (bandingkan dengan output notebook)
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM fact_sales
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_product',  COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_date',     COUNT(*) FROM dim_date;

-- KPI per tahun (untuk cek filter tahun di Power BI)
SELECT
    EXTRACT(YEAR FROM order_date)::int                      AS year,
    ROUND(SUM(price), 2)                                    AS total_revenue,
    COUNT(DISTINCT order_id)                                AS total_orders,
    COUNT(DISTINCT customer_unique_id)                      AS total_customers,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)         AS aov,
    ROUND(SUM(freight_value) / SUM(price) * 100, 2)         AS freight_burden_pct
FROM fact_sales
GROUP BY 1
ORDER BY 1;
