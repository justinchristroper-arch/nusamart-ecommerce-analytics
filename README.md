# NusaMart — E-Commerce Sales & Customer Analytics

> End-to-end business analysis project: dari data transaksi mentah menjadi dashboard, insight, dan rekomendasi bisnis untuk manajemen.

**Live dashboard:** [link — diisi setelah publish] · **Case study:** [link — diisi setelah deploy] · **Executive summary:** [PDF — diisi]

![Dashboard](screenshots/executive_overview.png)

## Business problem

NusaMart (perusahaan fiktif) memiliki data transaksi dalam jumlah besar, tetapi manajemen belum dapat menjawab pertanyaan dasar secara konsisten: dari mana pertumbuhan berasal, kategori mana yang dominan, seberapa loyal customer, dan di mana beban biaya pengiriman paling tinggi.

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

*Diisi setelah analisis selesai: 3–5 temuan terpenting, masing-masing satu kalimat + angka.*

## Keputusan data yang penting

- Revenue hanya dari order `delivered`, tanpa ongkir.
- Customer diidentifikasi dengan `customer_unique_id` (bukan `customer_id`, yang berbeda di setiap order).
- Dataset tidak memiliki cost, sehingga **profit tidak dianalisis**; sebagai gantinya dipakai proxy *freight burden* (ongkir / revenue).
- Bulan awal/akhir yang datanya tidak lengkap dikecualikan dari analisis tren.

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
