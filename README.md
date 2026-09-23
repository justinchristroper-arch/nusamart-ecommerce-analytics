# NusaMart — E-Commerce Sales & Customer Analytics

> End-to-end business analysis project: dari data transaksi mentah menjadi dashboard, insight, dan rekomendasi bisnis untuk manajemen.

**Live dashboard:** [link — diisi setelah publish] · **Case study:** [link — diisi setelah deploy] · **Executive summary:** [PDF — diisi]

![Dashboard](screenshots/executive_overview.png)

## Business problem

NusaMart (perusahaan fiktif) memiliki data transaksi dalam jumlah besar, tetapi manajemen belum dapat menjawab pertanyaan dasar secara konsisten: dari mana pertumbuhan berasal, kategori mana yang dominan, seberapa loyal customer, dan di mana beban ongkir yang ditanggung customer paling tinggi.

Project ini membangun satu sumber angka yang konsisten dan menerjemahkannya menjadi rekomendasi. Detail lengkap: [Business Requirements Document](docs/business_requirements.md).

## Pendekatan

```
Raw CSV (Olist) → Python/Pandas → PostgreSQL (star schema) → SQL analysis → Power BI → Insight & rekomendasi
```

| Tahap | Tool | Output |
|---|---|---|
| Data understanding & cleaning | Python, Pandas | [`notebooks/01_data_cleaning.ipynb`](notebooks/01_data_cleaning.ipynb) |
| Data model | PostgreSQL | [`sql/01_create_schema.sql`](sql/01_create_schema.sql) |
| Analisis | SQL | [`sql/`](sql/) — satu query per business question |
| Dashboard | Power BI | 3 halaman: Executive, Customer, Product & Category |
| Rekomendasi | — | [`docs/insights_and_recommendations.md`](docs/insights_and_recommendations.md) |

## Key insights

Jendela analisis 2017-01 s/d 2018-08. Bukti lengkap, hipotesis, dan rekomendasi: [`docs/insights_and_recommendations.md`](docs/insights_and_recommendations.md).

- **Pertumbuhan hampir seluruhnya dari volume:** revenue Jan–Agu 2018 naik 141,1% dibanding Jan–Agu 2017, tetapi AOV hanya +0,5%.
- **Retensi sangat rendah, dan bukan karena customer belum sempat kembali:** 97,0% customer hanya belanja sekali, dan dari kohort Jan–Jun 2017 yang diamati penuh 12 bulan, hanya 3,32% yang order lagi di hari lain.
- **Revenue terkonsentrasi pada pembelian besar sekali jalan:** 10% customer teratas menyumbang 41,10% revenue, tetapi 91,97% revenue kelompok ini berasal dari customer yang hanya belanja sekali.
- **Ongkir yang dibayar customer membebani secara tidak merata:** sembilan kategori besar (36,24% revenue) punya freight burden di atas rata-rata 16,63%, dan di beberapa state utara/timur laut bebannya mencapai 24–28%, jauh di atas SP (13,85%).
- **Mix kategori bergeser** (periode sebanding Jan–Agu): `watches_gifts` naik dari peringkat #6 ke #2, sementara porsi `cool_stuff` turun dari 6,89% ke 3,16%.

## Keputusan data yang penting

- Revenue hanya dari order `delivered`, tanpa ongkir.
- Customer diidentifikasi dengan `customer_unique_id` (bukan `customer_id`, yang berbeda di setiap order).
- Dataset tidak memiliki cost, sehingga **profit tidak dianalisis**. Sebagai gantinya dipakai proxy *freight burden* = Σ ongkir ÷ Σ harga barang. Ongkir (`freight_value`) di dataset ini **dibayar oleh customer**, jadi freight burden mengukur **beban ongkir yang ditanggung customer** relatif terhadap harga barang — bukan profit, dan bukan biaya perusahaan.
- Analisis memakai **jendela 2017-01 s/d 2018-08**. Bulan di kedua ujung dataset yang datanya tidak lengkap ditandai lewat kolom `dim_date.is_analysis_month` dan dikecualikan secara konsisten di SQL maupun dashboard. Perbandingan antartahun memakai periode sebanding Jan–Agu.

## Cara menjalankan ulang

1. Download dataset dari Kaggle ([Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)), taruh 5 CSV di `data/raw/`.
2. `pip install -r requirements.txt`
3. Jalankan `notebooks/01_data_cleaning.ipynb`.
4. Buat database `nusamart` di PostgreSQL, jalankan `sql/01_create_schema.sql`.
5. Set `NUSAMART_DB_URL`, lalu `python src/load_to_postgres.py`.
6. Jalankan query di `sql/02`–`05`.
7. Buka Power BI Desktop → Get Data → PostgreSQL; measure ada di [`powerbi/dax_measures.md`](powerbi/dax_measures.md).

## Struktur repository

```
├── data/            # raw & processed (tidak di-upload)
├── notebooks/       # data understanding & cleaning
├── src/             # script load ke PostgreSQL
├── sql/             # schema + analisis
├── powerbi/         # file .pbix + DAX measures
├── screenshots/
└── docs/            # BRD, data dictionary, insights
```

## Data & atribusi

Data: *Brazilian E-Commerce Public Dataset by Olist*, Kaggle. [Cantumkan lisensi sesuai halaman dataset.] NusaMart adalah nama fiktif untuk keperluan studi kasus; wilayah asli (state Brasil) dipertahankan.
