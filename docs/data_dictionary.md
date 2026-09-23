# Data Dictionary — NusaMart (Star Schema)

Sumber: *Brazilian E-Commerce Public Dataset by Olist* (Kaggle). Dibangun oleh `notebooks/01_data_cleaning.ipynb`.

```
            dim_date
               │ date_key
               │
dim_customer ──┼── fact_sales ──── dim_product
 customer_unique_id        product_id
```

## fact_sales
Grain: 1 baris = 1 item (1 unit) dalam 1 order berstatus `delivered`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| order_id | TEXT | ID order (PK bersama order_item_id) |
| order_item_id | INT | Urutan item dalam order |
| customer_unique_id | TEXT | FK → dim_customer |
| product_id | TEXT | FK → dim_product |
| order_date | DATE | Tanggal pembelian; FK → dim_date |
| customer_state | CHAR(2) | State customer saat order dibuat |
| price | NUMERIC | Harga item = revenue (tanpa ongkir) |
| freight_value | NUMERIC | Ongkir item, **dibayar oleh customer** (bukan biaya perusahaan/seller). Dipakai sebagai proxy "freight burden" (Σ freight_value / Σ price) — beban ongkir yang ditanggung customer relatif terhadap harga barang, bukan profit dan bukan biaya perusahaan |

## dim_customer

| Kolom | Tipe | Keterangan |
|---|---|---|
| customer_unique_id | TEXT | PK. Identitas customer sebenarnya (bukan `customer_id`) |
| customer_city | TEXT | Kota pada order pertama |
| customer_state | CHAR(2) | State pada order pertama |
| first_order_date | DATE | Tanggal order delivered pertama; dasar new vs returning |

## dim_product

| Kolom | Tipe | Keterangan |
|---|---|---|
| product_id | TEXT | PK |
| category_en | TEXT | Kategori (Inggris); jika tidak ada terjemahan, memakai nama Portugis |
| category_pt | TEXT | Kategori asli (Portugis); `unknown` jika kosong |

## dim_date

| Kolom | Tipe | Keterangan |
|---|---|---|
| date_key | DATE | PK, satu baris per hari. Kalender dibuat **tahun penuh** (2016-01-01 s/d 2018-12-31), bukan hanya sepanjang rentang transaksi, agar fungsi waktu Power BI (`DATEADD`, `SAMEPERIODLASTYEAR`) menghitung bulan secara utuh |
| year, quarter, month | INT | Komponen tanggal |
| month_name | TEXT | Jan, Feb, ... (sort by `month` di Power BI) |
| year_month | TEXT | Format `YYYY-MM` |
| day_of_week | INT | 1 = Senin ... 7 = Minggu |
| is_analysis_month | BOOLEAN | `TRUE` jika tanggal ini masuk bulan yang datanya lengkap (2017-01 s/d 2018-08) |

> **Jendela analisis.** Bulan di kedua ujung dataset datanya tidak lengkap: 2016-09 (1 order delivered), 2016-10 (265), 2016-11 (tidak ada order sama sekali), 2016-12 (1), serta 2018-09 dan 2018-10 (ada order, tetapi nol delivered karena data ditarik 17 Oktober 2018 sehingga order-nya belum selesai). Karena itu seluruh analisis memakai jendela **2017-01 s/d 2018-08** lewat filter `dim_date.is_analysis_month = TRUE`. Yang dikecualikan hanya **267 dari 96.478 order delivered (0,28%)**. Dasar angkanya ada di `notebooks/01_data_cleaning.ipynb` bagian 6.
