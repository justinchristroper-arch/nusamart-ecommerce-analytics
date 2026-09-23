-- =====================================================================
-- 02_sales_analysis.sql
-- Business questions: KPI utama, tren (Q1), kategori (Q2), wilayah (Q3)
-- Jalankan satu query per satu di pgAdmin (blok query, lalu F5).
-- SEMUA query di file ini di-JOIN ke dim_date dan difilter
-- is_analysis_month = TRUE, supaya angkanya identik dengan notebook &
-- Power BI. Bulan yang datanya tidak lengkap (lihat notebook bagian 6)
-- otomatis TIDAK ikut muncul sama sekali, tidak perlu diabaikan manual.
-- =====================================================================

-- ---------------------------------------------------------------------
-- KPI-01: KPI utama (angka referensi, harus sama dengan notebook & Power BI)
-- ---------------------------------------------------------------------
SELECT
    ROUND(SUM(f.price), 2)                                    AS total_revenue,
    COUNT(DISTINCT f.order_id)                                AS total_orders,
    COUNT(DISTINCT f.customer_unique_id)                      AS total_customers,
    COUNT(*)                                                  AS units_sold,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2)       AS aov,
    ROUND(SUM(f.freight_value) / SUM(f.price) * 100, 2)       AS freight_burden_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date = d.date_key
WHERE d.is_analysis_month = TRUE;

-- ---------------------------------------------------------------------
-- Q1: Tren bulanan + dekomposisi growth
-- Pertanyaan: apakah pertumbuhan revenue datang dari lebih banyak order,
-- atau dari nilai order (AOV) yang lebih besar?
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', f.order_date)::date  AS month,
        SUM(f.price)                              AS revenue,
        COUNT(DISTINCT f.order_id)                AS orders
    FROM fact_sales f
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
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
-- Hanya terisi untuk bulan yang bulan-pasangannya di tahun sebelumnya
-- JUGA termasuk is_analysis_month. Karena itu, 2017-09 s/d 2017-12 akan
-- punya revenue_last_year kosong (NULL): bulan pasangannya di 2016 memang
-- sengaja dikecualikan (data tidak lengkap), jadi tidak dipakai sebagai
-- pembanding YoY -- ini konsisten dengan keputusan, bukan bug.
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', f.order_date)::date AS month, SUM(f.price) AS revenue
    FROM fact_sales f
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
    GROUP BY 1
)
SELECT
    cur.month,
    ROUND(cur.revenue, 2)                                         AS revenue,
    ROUND(prev.revenue, 2)                                        AS revenue_last_year,
    ROUND((cur.revenue - prev.revenue) / prev.revenue * 100, 1)   AS yoy_pct
FROM monthly cur
LEFT JOIN monthly prev
  ON prev.month = (cur.month - INTERVAL '1 year')::date
ORDER BY cur.month;

-- ---------------------------------------------------------------------
-- Q1c: Perbandingan periode sebanding -- Jan-Agu 2017 vs Jan-Agu 2018
-- Q1b (YoY per bulan kalender) membandingkan bulan yang sama, tapi total
-- setahun 2017 vs 2018 tidak adil dibandingkan langsung karena 2018 di
-- jendela analisis cuma sampai Agustus. Query ini membatasi KEDUA tahun
-- ke bulan Januari-Agustus saja supaya perbandingan growth setara.
-- ---------------------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM f.order_date)::int                    AS year,
    ROUND(SUM(f.price), 2)                                  AS revenue,
    COUNT(DISTINCT f.order_id)                              AS orders,
    COUNT(DISTINCT f.customer_unique_id)                    AS customers,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2)     AS aov
FROM fact_sales f
JOIN dim_date d ON f.order_date = d.date_key
WHERE d.is_analysis_month = TRUE
  AND EXTRACT(MONTH FROM f.order_date) BETWEEN 1 AND 8
GROUP BY 1
ORDER BY 1;

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
JOIN dim_date d ON f.order_date = d.date_key
WHERE d.is_analysis_month = TRUE
GROUP BY p.category_en
ORDER BY revenue DESC
LIMIT 15;

-- ---------------------------------------------------------------------
-- Q2b: Apakah kontribusi kategori stabil antar-tahun?
-- (share dihitung dalam masing-masing tahun; 2016 tidak akan muncul
-- karena seluruh bulan 2016 di luar jendela analisis, dan 2018 hanya
-- berisi Jan-Agu)
-- ---------------------------------------------------------------------
WITH cat_year AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date)::int AS year,
        p.category_en,
        SUM(f.price)                         AS revenue
    FROM fact_sales f
    JOIN dim_product p USING (product_id)
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
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
-- Q2c: Pergeseran kategori dengan periode sebanding (Jan-Agu 2017 vs Jan-Agu 2018)
-- Q2b membandingkan 2017 SETAHUN PENUH dengan 2018 yang hanya Jan-Agu.
-- Padahal 2017 memuat November (Black Friday, bulan revenue tertinggi) dan
-- Desember, sehingga kategori musiman bisa tampak "turun" di 2018 hanya
-- karena bulan-bulan itu belum ada. Query ini membatasi KEDUA tahun ke
-- Januari-Agustus (sama seperti Q1c) supaya pergeseran share adil.
-- Kolom terakhir menunjukkan porsi revenue 2017 tiap kategori yang jatuh
-- di Nov-Des, untuk melihat kategori mana yang musiman.
-- ---------------------------------------------------------------------
WITH base AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date)::int   AS year,
        EXTRACT(MONTH FROM f.order_date)::int  AS month,
        p.category_en,
        f.price
    FROM fact_sales f
    JOIN dim_product p USING (product_id)
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
),
jan_aug AS (
    SELECT year, category_en, SUM(price) AS revenue
    FROM base
    WHERE month BETWEEN 1 AND 8
    GROUP BY 1, 2
),
shares AS (
    SELECT
        year,
        category_en,
        revenue,
        revenue / SUM(revenue) OVER (PARTITION BY year) * 100  AS share_pct,
        RANK() OVER (PARTITION BY year ORDER BY revenue DESC)  AS rank_in_year
    FROM jan_aug
),
musim_2017 AS (
    SELECT
        category_en,
        SUM(price) FILTER (WHERE month IN (11, 12)) / SUM(price) * 100  AS pct_in_nov_dec
    FROM base
    WHERE year = 2017
    GROUP BY category_en
)
SELECT
    category_en,
    ROUND(a.revenue, 2)                   AS revenue_2017_jan_aug,
    ROUND(b.revenue, 2)                   AS revenue_2018_jan_aug,
    ROUND(a.share_pct, 2)                 AS share_2017_pct,
    ROUND(b.share_pct, 2)                 AS share_2018_pct,
    ROUND(b.share_pct - a.share_pct, 2)   AS share_change_pp,
    a.rank_in_year                        AS rank_2017,
    b.rank_in_year                        AS rank_2018,
    ROUND(m.pct_in_nov_dec, 2)            AS pct_2017_revenue_in_nov_dec
FROM (SELECT * FROM shares WHERE year = 2017) a
FULL OUTER JOIN (SELECT * FROM shares WHERE year = 2018) b USING (category_en)
LEFT JOIN musim_2017 m USING (category_en)
ORDER BY revenue_2018_jan_aug DESC NULLS LAST;

-- ---------------------------------------------------------------------
-- Q3: Performa per wilayah (state customer)
-- ---------------------------------------------------------------------
SELECT
    f.customer_state,
    ROUND(SUM(f.price), 2)                                      AS revenue,
    COUNT(DISTINCT f.order_id)                                  AS orders,
    COUNT(DISTINCT f.customer_unique_id)                        AS customers,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2)         AS aov,
    ROUND(SUM(f.freight_value) / SUM(f.price) * 100, 2)         AS freight_burden_pct,
    ROUND(SUM(f.price) / SUM(SUM(f.price)) OVER () * 100, 2)    AS revenue_share_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date = d.date_key
WHERE d.is_analysis_month = TRUE
GROUP BY f.customer_state
ORDER BY revenue DESC;
