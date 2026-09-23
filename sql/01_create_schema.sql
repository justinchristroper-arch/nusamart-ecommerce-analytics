-- =====================================================================
-- 01_create_schema.sql
-- Membuat star schema NusaMart di PostgreSQL.
-- Jalankan di pgAdmin (Query Tool) pada database "nusamart".
-- Aman dijalankan ulang: tabel lama dihapus lalu dibuat lagi.
-- =====================================================================

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_date;

-- Kalender harian (dipakai untuk analisis waktu di SQL & Power BI)
CREATE TABLE dim_date (
    date_key     DATE PRIMARY KEY,
    year         INT  NOT NULL,
    quarter      INT  NOT NULL,
    month        INT  NOT NULL,
    month_name   TEXT NOT NULL,
    year_month   TEXT NOT NULL,       -- contoh: '2017-11'
    day_of_week  INT  NOT NULL,       -- 1 = Senin ... 7 = Minggu
    -- TRUE = tanggal ini masuk bulan yang datanya lengkap (2017-01 s/d 2018-07).
    -- Keputusan dari notebook bagian 6. Dipakai sebagai filter standar di SQL &
    -- Power BI supaya angka di semua tool identik.
    is_analysis_month BOOLEAN NOT NULL
);

-- Satu baris per customer unik (customer_unique_id, BUKAN customer_id)
CREATE TABLE dim_customer (
    customer_unique_id  TEXT PRIMARY KEY,
    customer_city       TEXT,
    customer_state      CHAR(2),
    first_order_date    DATE NOT NULL  -- dasar penentuan new vs returning
);

-- Satu baris per produk
CREATE TABLE dim_product (
    product_id   TEXT PRIMARY KEY,
    category_en  TEXT NOT NULL,
    category_pt  TEXT NOT NULL
);

-- Grain: 1 baris = 1 item (1 unit) dalam 1 order berstatus delivered
CREATE TABLE fact_sales (
    order_id            TEXT          NOT NULL,
    order_item_id       INT           NOT NULL,
    customer_unique_id  TEXT          NOT NULL REFERENCES dim_customer (customer_unique_id),
    product_id          TEXT          NOT NULL REFERENCES dim_product (product_id),
    order_date          DATE          NOT NULL REFERENCES dim_date (date_key),
    customer_state      CHAR(2),
    price               NUMERIC(10,2) NOT NULL,   -- revenue (tanpa ongkir)
    freight_value       NUMERIC(10,2) NOT NULL,   -- ongkir dibayar customer (bukan biaya perusahaan)
    PRIMARY KEY (order_id, order_item_id)
);

-- Index untuk kolom yang sering dipakai JOIN / GROUP BY
CREATE INDEX idx_fact_customer ON fact_sales (customer_unique_id);
CREATE INDEX idx_fact_product  ON fact_sales (product_id);
CREATE INDEX idx_fact_date     ON fact_sales (order_date);
