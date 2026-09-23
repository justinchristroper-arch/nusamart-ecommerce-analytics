# Business Requirements Document — NusaMart Sales & Customer Analytics

| | |
|---|---|
| Versi | 1.0 |
| Status | Disetujui untuk pengembangan |
| Penyusun | [Nama kamu] — Business/Data Analyst |

> **Catatan konteks.** NusaMart adalah perusahaan fiktif. Data berasal dari *Brazilian E-Commerce Public Dataset by Olist* (Kaggle). Wilayah asli (state Brasil) dipertahankan. Bagian latar belakang dan As-Is adalah **skenario kasus**, bukan fakta tentang perusahaan nyata.

## 1. Latar belakang & masalah

NusaMart adalah marketplace multi-kategori dengan pelanggan di banyak wilayah. Data transaksi tersedia, tetapi manajemen belum memiliki ringkasan performa yang konsisten. Keputusan tentang fokus kategori, retensi customer, dan prioritas wilayah masih didasarkan pada laporan ad-hoc dengan definisi metrik yang berbeda antar-tim *(skenario)*.

## 2. Tujuan

1. Menyediakan satu sumber angka KPI dengan definisi yang disepakati.
2. Manajemen dapat memahami kondisi bisnis dalam < 1 menit dari halaman Executive Overview.
3. Menghasilkan 5–7 temuan yang dapat ditindaklanjuti, masing-masing dengan bukti data dan rekomendasi.

## 3. Scope

**In scope:** analisis historis penjualan, customer, produk/kategori, dan wilayah; dashboard Power BI 3 halaman; rekomendasi bisnis.

**Out of scope:** profit & margin (dataset tidak memiliki data cost; diganti proxy *freight burden*), forecasting, machine learning, data real-time, analisis channel marketing, klaim sebab-akibat.

## 4. Stakeholder

| Stakeholder | Kepentingan | Keputusan yang dibantu | Halaman |
|---|---|---|---|
| CEO / Management | Kesehatan bisnis keseluruhan | Prioritas strategis | Executive |
| Head of Commercial | Tren revenue & growth | Target penjualan, timing promo | Executive |
| Category Manager | Kinerja kategori & produk | Fokus assortment | Product |
| CRM / Marketing Manager | Retensi & nilai customer | Budget akuisisi vs retensi | Customer |
| Operations / Logistics | Beban ongkir per wilayah & kategori | Strategi pengiriman, subsidi ongkir | Executive, Product |

## 5. As-Is vs To-Be (skenario)

| | As-Is | To-Be |
|---|---|---|
| Sumber angka | Tiap tim menarik data sendiri | Satu database + definisi KPI baku |
| Definisi metrik | Berbeda antar-laporan | Terdokumentasi di BRD & data dictionary |
| Frekuensi | Laporan manual ad-hoc | Dashboard yang selalu tersedia |
| Output | Tabel angka | Insight + rekomendasi yang bisa ditindaklanjuti |

## 6. Business requirements

| ID | Requirement | Prioritas |
|---|---|---|
| BR-01 | Melihat KPI utama dan tren bulanannya | Must |
| BR-02 | Membandingkan kontribusi revenue antar-kategori dan antar-wilayah | Must |
| BR-03 | Melihat proporsi dan kontribusi revenue customer baru vs returning | Must |
| BR-04 | Melihat seberapa terkonsentrasi revenue pada customer teratas | Must |
| BR-05 | Mengidentifikasi produk/kategori teratas berdasarkan revenue dan unit | Must |
| BR-06 | Mengidentifikasi kategori/wilayah dengan beban ongkir tinggi | Should |

## 7. Functional requirements (dashboard)

| ID | Requirement |
|---|---|
| FR-01 | Filter global: tahun/bulan, kategori, state |
| FR-02 | KPI card menampilkan nilai periode terpilih + perubahan vs periode sebelumnya |
| FR-03 | Drill-down kategori → produk |
| FR-04 | Definisi KPI tersedia di dashboard (tooltip/catatan) |
| FR-05 | Angka dashboard identik dengan hasil SQL referensi (`sql/05_kpi_reference.sql`) |

**Non-functional:** setiap halaman terbaca dalam satu layar; dashboard dapat dipahami tanpa penjelasan lisan; seluruh pipeline dapat direproduksi dari repository.

## 8. Definisi KPI

| KPI | Definisi |
|---|---|
| Total Revenue | Σ `price` dari item pada order berstatus `delivered` (ongkir tidak termasuk) |
| Total Orders | Jumlah `order_id` unik berstatus `delivered` |
| Total Customers | Jumlah `customer_unique_id` unik dengan ≥ 1 order delivered |
| AOV | Total Revenue / Total Orders |
| Units Sold | Jumlah baris order item (1 baris = 1 unit) |
| Revenue MoM / YoY | Perubahan revenue vs bulan sebelumnya / bulan yang sama tahun lalu |
| New Customer | Customer yang order pertamanya jatuh di periode tersebut |
| Returning Customer | Customer yang order di periode tersebut dan sudah pernah order sebelumnya |
| Repeat Rate | Customer dengan ≥ 2 order / Total Customers |
| Revenue Concentration | % revenue dari 10% customer teratas |
| Freight Burden (proxy) | Σ `freight_value` / Σ `price` — **proxy biaya, bukan profit** |

## 9. Business questions

| # | Pertanyaan | Keputusan yang dilayani | Query |
|---|---|---|---|
| Q1 | Bagaimana tren revenue, dan apakah growth berasal dari jumlah order atau AOV? | Strategi growth | `02` Q1, Q1b |
| Q2 | Kategori mana yang dominan, dan apakah kontribusinya stabil? | Fokus assortment | `02` Q2, Q2b |
| Q3 | Wilayah mana yang besar dari sisi revenue, order, dan AOV? | Prioritas wilayah | `02` Q3 |
| Q4 | Berapa porsi customer returning dan kontribusi revenue-nya? | Akuisisi vs retensi | `03` Q4a–c |
| Q5 | Seberapa terkonsentrasi revenue pada customer teratas? | Program loyalitas | `03` Q5a–b |
| Q6 | Kategori mana yang tinggi volumenya tetapi rendah nilainya (atau sebaliknya)? | Pricing & bundling | `04` Q6 |
| Q7 | Kategori mana yang revenue-nya besar tetapi beban ongkirnya tinggi? | Strategi pengiriman | `04` Q7 |

## 10. Asumsi & batasan

- Semua penjelasan penyebab di dokumen insight adalah **hipotesis**, karena dataset tidak memuat konteks bisnis (promo, kompetitor, dll.).
- Dampak rekomendasi tidak dikuantifikasi tanpa eksperimen; ditulis sebagai arah dampak.
- Bulan awal/akhir dataset yang tidak lengkap dikecualikan dari analisis tren (lihat notebook bagian 6).
