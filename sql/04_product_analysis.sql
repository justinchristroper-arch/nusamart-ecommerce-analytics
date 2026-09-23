-- =====================================================================
-- 04_product_analysis.sql
-- Business questions: produk teratas, kategori (Q2), volume vs nilai (Q6),
-- dan proxy biaya: freight burden (Q7, pengganti profit).
-- Freight burden = total ongkir / total revenue produk.
-- INI PROXY, BUKAN PROFIT. Dataset tidak memiliki data cost produk.
-- =====================================================================

-- ---------------------------------------------------------------------
-- P1: Top 10 produk berdasarkan revenue
-- ---------------------------------------------------------------------
SELECT
    f.product_id,
    p.category_en,
    COUNT(*)                    AS units_sold,
    ROUND(SUM(f.price), 2)      AS revenue,
    ROUND(AVG(f.price), 2)      AS avg_price
FROM fact_sales f
JOIN dim_product p USING (product_id)
GROUP BY f.product_id, p.category_en
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- P2: Top 10 produk berdasarkan unit terjual
-- (1 baris order item = 1 unit)
-- ---------------------------------------------------------------------
SELECT
    f.product_id,
    p.category_en,
    COUNT(*)                    AS units_sold,
    ROUND(SUM(f.price), 2)      AS revenue,
    ROUND(AVG(f.price), 2)      AS avg_price
FROM fact_sales f
JOIN dim_product p USING (product_id)
GROUP BY f.product_id, p.category_en
ORDER BY units_sold DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Q6: Volume vs nilai per kategori
-- Kategori dengan unit tinggi tapi harga rata-rata rendah (atau sebaliknya)
-- ---------------------------------------------------------------------
WITH cat AS (
    SELECT
        p.category_en,
        COUNT(*)            AS units_sold,
        SUM(f.price)        AS revenue,
        SUM(f.freight_value) AS freight
    FROM fact_sales f
    JOIN dim_product p USING (product_id)
    GROUP BY p.category_en
)
SELECT
    category_en,
    units_sold,
    ROUND(revenue, 2)                                           AS revenue,
    ROUND(revenue / units_sold, 2)                              AS avg_item_price,
    RANK() OVER (ORDER BY units_sold DESC)                      AS rank_by_units,
    RANK() OVER (ORDER BY revenue DESC)                         AS rank_by_revenue,
    ROUND(freight / revenue * 100, 2)                           AS freight_burden_pct
FROM cat
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- Q7: Kategori dengan revenue besar TETAPI freight burden di atas rata-rata
-- (versi jujur dari "revenue tinggi belum tentu menguntungkan")
-- ---------------------------------------------------------------------
WITH cat AS (
    SELECT
        p.category_en,
        SUM(f.price)          AS revenue,
        SUM(f.freight_value)  AS freight
    FROM fact_sales f
    JOIN dim_product p USING (product_id)
    GROUP BY p.category_en
),
overall AS (
    SELECT
        SUM(revenue) / COUNT(*)      AS avg_category_revenue,
        SUM(freight) / SUM(revenue)  AS overall_burden
    FROM cat
)
SELECT
    c.category_en,
    ROUND(c.revenue, 2)                                  AS revenue,
    ROUND(c.freight / c.revenue * 100, 2)                AS freight_burden_pct,
    ROUND(o.overall_burden * 100, 2)                     AS overall_burden_pct
FROM cat c
CROSS JOIN overall o
WHERE c.revenue > o.avg_category_revenue
  AND c.freight / c.revenue > o.overall_burden
ORDER BY c.revenue DESC;
