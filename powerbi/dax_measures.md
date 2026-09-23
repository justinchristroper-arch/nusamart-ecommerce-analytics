# DAX Measures — NusaMart Dashboard

File ini berisi **semua measure** yang dibutuhkan 3 halaman dashboard, beserta alasan di balik rumusnya. Urutan langkah membangun dashboard (koneksi, model, halaman, rekonsiliasi) ada di [`dashboard_build_guide.md`](dashboard_build_guide.md). Kerjakan bagian 1–3 panduan itu **sebelum** menempel measure di sini.

Semua angka harus identik dengan `sql/05_kpi_reference.sql` dan query `sql/02`–`04` (checklist ada di panduan bagian 10).

---

## Cara menempel measure (baca dulu)

1. Di panel **Data**, klik tabel `fact_sales` → ribbon **Table tools** → **New measure**. Semua measure disimpan di `fact_sales`.
2. **Satu blok kode = satu measure.** Salin *seluruh* isi satu blok, mulai dari nama measure. Tempel di formula bar, lalu tekan **Enter**.
3. Di dalam blok **tidak ada komentar** (`--` atau `//`), jadi aman ditempel utuh. Semua penjelasan ditulis di luar blok.
4. **Buat berurutan dari atas ke bawah.** Banyak measure memakai measure sebelumnya, misalnya `AOV` memakai `Total Revenue`. Kalau measure yang dirujuk belum ada, Power BI akan menampilkan error.
5. **Nama harus persis sama**, termasuk spasi, `%`, dan `(proxy)`. Measure lain memanggil nama ini.
6. Setelah measure dibuat, atur formatnya di ribbon **Measure tools** sesuai baris *Format* di bawah blok.
7. *(Opsional, tapi rapi)* Di **Model view**, pilih measure → panel **Properties** → isi **Display folder** sesuai nama bagian (A, B, C, D) supaya daftar measure tidak berantakan.

Syarat nama tabel: `fact_sales`, `dim_date`, `dim_customer`, `dim_product`, persis seperti ini. Kalau setelah Load muncul nama seperti `public dim_date`, ganti namanya dulu (panduan bagian 1).

---

## Filter jendela analisis (`is_analysis_month`) di level report

Semua angka proyek ini memakai **jendela analisis 2017-01 s/d 2018-07**, sama dengan `WHERE d.is_analysis_month = TRUE` di SQL. Di Power BI, filter ini dipasang **satu kali** di level report, bukan di setiap measure.

**Cara memasang:**

1. Klik area kosong di kanvas (tidak ada visual yang terpilih), lalu buka panel **Filters**.
2. Tarik kolom `dim_date[is_analysis_month]` ke kotak **Filters on all pages**. Jangan ke *Filters on this page* atau *Filters on this visual*.
3. Pilih **Basic filtering**, lalu centang **True** saja.
4. Klik ikon **gembok** (Lock filter) supaya filter tidak terhapus tanpa sengaja.

**Kenapa di level report:**

- Filter ini otomatis berlaku untuk semua visual di ketiga halaman, termasuk halaman yang dibuat belakangan.
- Tidak ada measure yang "lupa" diberi filter.
- Satu penanda yang sama dipakai di notebook, SQL, dan Power BI, sehingga angka tidak bisa berbeda hanya karena filter.

**Satu pengecualian: measure pembanding periode (PM dan PY).** Setelah `dim_date` di-*Mark as date table*, fungsi waktu seperti `DATEADD` dan `SAMEPERIODLASTYEAR` otomatis **menghapus semua filter di `dim_date`**, termasuk filter jendela dari level report.

Akibatnya, tanpa penanganan khusus:

- "Revenue bulan lalu" untuk Januari 2017 akan diam-diam mengambil Desember 2016.
- "Revenue tahun lalu" untuk 2017 akan mengambil 2016.

Padahal 2016 sengaja dikecualikan. Karena itu, measure PM dan PY di bagian B **memasang ulang** filter jendela di dalam rumusnya (`dim_date[is_analysis_month] = TRUE ()`). Hasilnya sama dengan SQL Q1 dan Q1b: MoM Januari 2017 kosong, dan YoY seluruh 2017 kosong.

---

## Kenapa New Customers tetap memakai `first_order_date` dari seluruh histori

`dim_customer[first_order_date]` dihitung dari **seluruh** histori order delivered, termasuk 2016. Kolom ini **tidak boleh** ikut terpotong filter jendela. Kalau terpotong, customer yang order pertamanya Desember 2016 lalu belanja lagi Januari 2017 akan salah dihitung sebagai customer *baru*, padahal seharusnya *returning*.

Ada tiga lapis pengaman:

1. **Filter jendela dipasang di `dim_date`.** Relasi `dim_date → fact_sales` hanya satu arah (*Single*), jadi filter itu **tidak mengalir ke `dim_customer`**.
2. **Measure memakai `ALL ( dim_customer[first_order_date] )`.** Semua tanggal order pertama dibaca utuh, lalu dibandingkan dengan periode yang sedang dilihat. Filter apa pun yang tidak sengaja menempel di kolom itu diabaikan.
3. **Aturan model** (panduan bagian 2):
   - **Jangan** membuat relasi antara `dim_date` dan `dim_customer[first_order_date]`.
   - **Jangan** mengubah arah relasi menjadi *Both*.

**Tes cepat:** di visual per bulan, Januari 2017 harus menunjukkan **New Customers 717 dan Returning Customers 1**. Customer returning itu order pertamanya di 2016, dengan revenue R$ 10,90 di Januari 2017 (sumber: `results/03_q4c_new_vs_returning.csv`).

Kalau yang muncul Returning **0**, berarti `first_order_date` ikut terpotong. Periksa relasi model.

---

## A. KPI dasar (9 measure)

Definisi mengikuti `docs/business_requirements.md` bagian 8. `DIVIDE` dipakai (bukan `/`) karena otomatis menghasilkan kosong, bukan error, saat pembaginya nol atau kosong.

```DAX
Total Revenue = SUM ( fact_sales[price] )
```
Format: Currency, simbol **R$** (Portuguese (Brazil)), 2 desimal. Revenue = Σ harga barang pada order delivered. **Ongkir tidak termasuk.**

```DAX
Total Orders = DISTINCTCOUNT ( fact_sales[order_id] )
```
Format: Whole number, pemisah ribuan aktif.

```DAX
Total Customers = DISTINCTCOUNT ( fact_sales[customer_unique_id] )
```
Format: Whole number, pemisah ribuan. Customer = `customer_unique_id`, bukan `customer_id`.

```DAX
AOV = DIVIDE ( [Total Revenue], [Total Orders] )
```
Format: Currency R$, 2 desimal.

```DAX
Units Sold = COUNTROWS ( fact_sales )
```
Format: Whole number, pemisah ribuan. 1 baris `fact_sales` = 1 unit.

```DAX
Total Freight = SUM ( fact_sales[freight_value] )
```
Format: Currency R$, 2 desimal. `freight_value` adalah ongkir yang **dibayar customer**, bukan biaya perusahaan atau seller.

```DAX
Freight Burden % (proxy) = DIVIDE ( [Total Freight], [Total Revenue] )
```
Format: Percentage, 2 desimal.

**Freight burden adalah proxy**: Σ ongkir yang dibayar customer ÷ Σ harga barang. Artinya beban ongkir yang ditanggung customer relatif terhadap harga barang. Ini **bukan profit** dan **bukan biaya perusahaan**; dataset tidak punya data cost sama sekali.

Rasio dihitung dari **total** (Σ ongkir ÷ Σ harga), bukan rata-rata rasio per baris, sama seperti SQL. Setiap judul visual yang memakai measure ini wajib memuat kata **"(proxy)"**.

```DAX
Avg Item Price = DIVIDE ( [Total Revenue], [Units Sold] )
```
Format: Currency R$, 2 desimal. Harga rata-rata per unit, sama dengan kolom `avg_item_price` di Q6.

```DAX
Freight per Unit = DIVIDE ( [Total Freight], [Units Sold] )
```
Format: Currency R$, 2 desimal. Ongkir rata-rata yang dibayar customer per unit. Dipakai di tabel Q7 untuk melihat apakah beban tinggi karena ongkirnya mahal atau karena harga barangnya murah (Insight 4).

---

## B. Pertumbuhan (14 measure)

Polanya sama untuk setiap KPI:

| Measure | Isi |
|---|---|
| **PM / PY** | nilai bulan lalu / periode yang sama tahun lalu, **dengan filter jendela dipasang ulang** |
| **MoM % / YoY %** | perubahan persen. Dikunci dengan `HASONEVALUE` supaya hanya dihitung di konteks yang masuk akal |
| **YoY Label** | teks untuk KPI card: `YoY +161,6%` atau `YoY tidak tersedia` |

**Kenapa ada kunci `HASONEVALUE`:**

- **MoM** hanya masuk akal kalau yang dilihat tepat **satu bulan**.
- **YoY** hanya masuk akal kalau yang dilihat tepat **satu tahun**. Contohnya Jan–Jul 2018 dibandingkan dengan Jan–Jul 2017, persis seperti Q1c.
- Kalau seluruh jendela dilihat sekaligus (2017 dan 2018), tidak ada "tahun lalu" yang adil. Measure lalu sengaja mengembalikan kosong, dan label menampilkan "YoY tidak tersedia", daripada menampilkan angka yang menyesatkan.
- Untuk tahun 2017 pun YoY kosong, karena 2016 berada di luar jendela.

**Kenapa KPI card memakai YoY, bukan MoM:** revenue sangat musiman (November 2017 adalah puncak Black Friday). Membandingkan dengan periode yang sama tahun lalu menghindari distorsi musim. Selain itu, saat satu tahun dipilih, `SAMEPERIODLASTYEAR` otomatis membandingkan Jan–Jul 2018 dengan **Jan–Jul 2017**, bukan dengan 2017 setahun penuh.

```DAX
Revenue PM =
CALCULATE (
    [Total Revenue],
    DATEADD ( dim_date[date_key], -1, MONTH ),
    dim_date[is_analysis_month] = TRUE ()
)
```
Format: Currency R$, 2 desimal.

```DAX
Revenue MoM % =
IF (
    HASONEVALUE ( dim_date[year_month] ),
    DIVIDE ( [Total Revenue] - [Revenue PM], [Revenue PM] )
)
```
Format: Percentage, **1 desimal**, supaya sama dengan pembulatan SQL Q1.

```DAX
Revenue PY =
CALCULATE (
    [Total Revenue],
    SAMEPERIODLASTYEAR ( dim_date[date_key] ),
    dim_date[is_analysis_month] = TRUE ()
)
```
Format: Currency R$, 2 desimal.

```DAX
Revenue YoY % =
IF (
    HASONEVALUE ( dim_date[year] ),
    DIVIDE ( [Total Revenue] - [Revenue PY], [Revenue PY] )
)
```
Format: Percentage, **1 desimal**, sama dengan pembulatan SQL Q1b.

```DAX
Revenue YoY Label =
VAR Chg = [Revenue YoY %]
RETURN
    IF ( ISBLANK ( Chg ), "YoY tidak tersedia", "YoY " & FORMAT ( Chg, "+0.0%;-0.0%" ) )
```
Format: teks (tidak perlu diatur). Pemisah desimal mengikuti pengaturan bahasa Power BI Anda.

```DAX
Orders PY =
CALCULATE (
    [Total Orders],
    SAMEPERIODLASTYEAR ( dim_date[date_key] ),
    dim_date[is_analysis_month] = TRUE ()
)
```
Format: Whole number, pemisah ribuan.

```DAX
Orders YoY % =
IF (
    HASONEVALUE ( dim_date[year] ),
    DIVIDE ( [Total Orders] - [Orders PY], [Orders PY] )
)
```
Format: Percentage, 1 desimal.

```DAX
Orders YoY Label =
VAR Chg = [Orders YoY %]
RETURN
    IF ( ISBLANK ( Chg ), "YoY tidak tersedia", "YoY " & FORMAT ( Chg, "+0.0%;-0.0%" ) )
```

```DAX
Customers PY =
CALCULATE (
    [Total Customers],
    SAMEPERIODLASTYEAR ( dim_date[date_key] ),
    dim_date[is_analysis_month] = TRUE ()
)
```
Format: Whole number, pemisah ribuan.

```DAX
Customers YoY % =
IF (
    HASONEVALUE ( dim_date[year] ),
    DIVIDE ( [Total Customers] - [Customers PY], [Customers PY] )
)
```
Format: Percentage, 1 desimal.

```DAX
Customers YoY Label =
VAR Chg = [Customers YoY %]
RETURN
    IF ( ISBLANK ( Chg ), "YoY tidak tersedia", "YoY " & FORMAT ( Chg, "+0.0%;-0.0%" ) )
```

```DAX
AOV PY =
CALCULATE (
    [AOV],
    SAMEPERIODLASTYEAR ( dim_date[date_key] ),
    dim_date[is_analysis_month] = TRUE ()
)
```
Format: Currency R$, 2 desimal. AOV tahun lalu dihitung ulang sebagai revenue ÷ order **di periode tahun lalu**, bukan rata-rata AOV bulanan.

```DAX
AOV YoY % =
IF (
    HASONEVALUE ( dim_date[year] ),
    DIVIDE ( [AOV] - [AOV PY], [AOV PY] )
)
```
Format: Percentage, 1 desimal.

```DAX
AOV YoY Label =
VAR Chg = [AOV YoY %]
RETURN
    IF ( ISBLANK ( Chg ), "YoY tidak tersedia", "YoY " & FORMAT ( Chg, "+0.0%;-0.0%" ) )
```

---

## C. Customer (8 measure)

**Definisi (BRD bagian 8):**

- **New** = customer yang order pertamanya jatuh di periode yang sedang dilihat.
- **Returning** = customer yang order di periode itu dan sudah pernah order sebelumnya.

"Periode" mengikuti konteks visual. Di grafik per bulan, periodenya adalah bulan itu, dan angkanya harus sama dengan Q4c.

```DAX
New Customers =
VAR MinDate = MIN ( dim_date[date_key] )
VAR MaxDate = MAX ( dim_date[date_key] )
RETURN
    CALCULATE (
        [Total Customers],
        FILTER (
            ALL ( dim_customer[first_order_date] ),
            dim_customer[first_order_date] >= MinDate
                && dim_customer[first_order_date] <= MaxDate
        )
    )
```
Format: Whole number, pemisah ribuan.

`MinDate` dan `MaxDate` adalah tanggal awal dan akhir periode yang sedang dilihat, misalnya 1–30 Juni 2018. Measure ini menghitung customer periode itu yang order pertamanya jatuh di antara dua tanggal tersebut. `first_order_date` dibaca dari seluruh histori (lihat penjelasan di atas).

```DAX
Returning Customers = [Total Customers] - [New Customers]
```
Format: Whole number, pemisah ribuan.

```DAX
Returning Customer % = DIVIDE ( [Returning Customers], [Total Customers] )
```
Format: Percentage, 2 desimal. Porsi customer returning. Dipakai sebagai tooltip di grafik per bulan.

```DAX
New Customer Revenue =
VAR MinDate = MIN ( dim_date[date_key] )
VAR MaxDate = MAX ( dim_date[date_key] )
RETURN
    CALCULATE (
        [Total Revenue],
        FILTER (
            ALL ( dim_customer[first_order_date] ),
            dim_customer[first_order_date] >= MinDate
                && dim_customer[first_order_date] <= MaxDate
        )
    )
```
Format: Currency R$, 2 desimal.

```DAX
Returning Customer Revenue = [Total Revenue] - [New Customer Revenue]
```
Format: Currency R$, 2 desimal.

```DAX
Returning Revenue % (monthly basis) =
DIVIDE (
    SUMX ( VALUES ( dim_date[year_month] ), [Returning Customer Revenue] ),
    [Total Revenue]
)
```
Format: Percentage, 2 desimal.

**Kenapa "monthly basis":** status new/returning di Q4c ditentukan **per bulan**. Customer yang order pertama di Februari 2018 lalu belanja lagi di Mei 2018 dihitung *returning* di bulan Mei.

Kalau KPI card langsung memakai `Returning Customer Revenue` untuk seluruh jendela, customer itu malah dihitung *new*, karena order pertamanya masih di dalam jendela. Karena itu measure ini menghitung revenue returning **bulan per bulan** (`SUMX` atas `year_month`), menjumlahkannya, lalu membaginya dengan total revenue.

Hasilnya sama dengan menjumlahkan kolom Q4c:

| Konteks | Nilai |
|---|---|
| Tanpa slicer (seluruh jendela) | 1,76% |
| Tahun 2018 | 2,17% |
| Satu bulan | sama dengan `returning_revenue_pct` di Q4c |

```DAX
Repeat Customers =
COUNTROWS (
    FILTER (
        VALUES ( fact_sales[customer_unique_id] ),
        [Total Orders] >= 2
    )
)
```
Format: Whole number, pemisah ribuan. Customer dengan minimal 2 order di periode yang sedang dilihat.

```DAX
Repeat Rate % = DIVIDE ( [Repeat Customers], [Total Customers] )
```
Format: Percentage, 2 desimal. Tanpa slicer harus **3,00%** (2.609 ÷ 86.960; SQL menulis `3.0` karena nol di belakang koma tidak ditampilkan).

---

## D. Kategori & wilayah (5 measure)

```DAX
Category Revenue Share % =
DIVIDE (
    [Total Revenue],
    CALCULATE ( [Total Revenue], REMOVEFILTERS ( dim_product ) )
)
```
Format: Percentage, 2 desimal.

Porsi revenue kategori (atau produk) terhadap **total semua kategori**, sama dengan `revenue_share_pct` di Q2. Pembaginya memakai `REMOVEFILTERS`, bukan `ALLSELECTED`. Alasannya: grafik kategori memakai filter Top 15, dan dengan `ALLSELECTED` porsinya akan dihitung terhadap 15 kategori saja, sehingga tidak cocok dengan SQL.

```DAX
State Revenue Share % =
DIVIDE (
    [Total Revenue],
    CALCULATE ( [Total Revenue], REMOVEFILTERS ( fact_sales[customer_state] ) )
)
```
Format: Percentage, 2 desimal. Porsi revenue state terhadap total semua state, sama dengan `revenue_share_pct` di Q3. State diambil dari `fact_sales[customer_state]`, persis seperti Q3.

```DAX
Overall Freight Burden % (proxy) =
CALCULATE ( [Freight Burden % (proxy)], REMOVEFILTERS ( dim_product ) )
```
Format: Percentage, 2 desimal. Freight burden (proxy) seluruh kategori sebagai garis pembanding, sama dengan `overall_burden_pct` di Q7. Tanpa slicer nilainya 16,57%.

```DAX
Avg Revenue per Category =
VAR TotalAllCategories =
    CALCULATE ( [Total Revenue], REMOVEFILTERS ( dim_product ) )
VAR CategoriesWithSales =
    CALCULATE (
        COUNTROWS ( FILTER ( VALUES ( dim_product[category_en] ), [Total Revenue] > 0 ) ),
        REMOVEFILTERS ( dim_product )
    )
RETURN
    DIVIDE ( TotalAllCategories, CategoriesWithSales )
```
Format: Currency R$, 2 desimal.

Rata-rata revenue per kategori = total revenue ÷ jumlah kategori **yang benar-benar terjual** di periode itu. Ini sama dengan `avg_category_revenue` di Q7. Tanpa slicer: 74 kategori, rata-rata R$ 166.789,87.

Kategori dihitung dari penjualan, bukan dari isi `dim_product`, karena jumlahnya bisa berubah. Contohnya, di tahun 2018 hanya 73 kategori yang terjual (dicek langsung ke database saat file ini disusun).

```DAX
Q7 High Burden Flag =
IF (
    [Total Revenue] > [Avg Revenue per Category]
        && [Freight Burden % (proxy)] > [Overall Freight Burden % (proxy)],
    1
)
```
Format: Whole number.

Bernilai **1** untuk kategori yang memenuhi **dua syarat sekaligus**, persis logika Q7:

1. Revenue di atas rata-rata kategori.
2. Freight burden (proxy) di atas rata-rata keseluruhan.

Di luar itu nilainya kosong. Measure ini dipakai sebagai filter visual tabel Q7. Tanpa slicer hasilnya **9 kategori**.

---

## Ringkasan: measure dipakai di mana

| Measure | Dipakai di |
|---|---|
| Total Revenue, Total Orders, AOV, Freight Burden % (proxy) | KPI card Executive Overview; tooltip grafik |
| Revenue / Orders / AOV YoY Label | Reference label KPI card Executive Overview |
| Total Customers, Customers YoY Label | KPI card Customer Analysis |
| Revenue MoM %, Revenue YoY % | Tooltip grafik bulanan (Executive Overview) |
| Revenue PM, Revenue PY, Orders PY, Customers PY, AOV PY, Orders/Customers/AOV YoY % | Langkah antara (dipakai measure lain) dan pengecekan di halaman Rekonsiliasi |
| State Revenue Share % | Tooltip grafik per state |
| New / Returning Customers, Returning Customer %, New / Returning Customer Revenue | Grafik new vs returning per bulan |
| Returning Revenue % (monthly basis), Repeat Rate % | KPI card dan grafik Customer Analysis |
| Repeat Customers | Langkah antara Repeat Rate % |
| Units Sold, Avg Item Price | KPI card Product & Category; scatter Q6 |
| Category Revenue Share %, Freight per Unit | Grafik kategori dan tabel Q7 |
| Total Freight, Overall Freight Burden % (proxy), Avg Revenue per Category | Langkah antara Q7 |
| Q7 High Burden Flag | Filter tabel Q7 |

---

## Yang sengaja tidak dibuat dengan DAX

**Desil customer (Q5a)** diambil langsung dari SQL lewat *native query* (panduan bagian 5), bukan dihitung dengan DAX.

- SQL memakai `NTILE(10)`, yang membagi customer tepat 10% per desil, termasuk saat banyak customer punya revenue sama persis di batas desil.
- Meniru perilaku itu di DAX rumit dan rawan selisih.
- Konsekuensinya, grafik desil **tidak ikut slicer**. Hal ini ditulis di subjudul visualnya.

**Kohort 12 bulan (Q4d) dan pergeseran kategori periode sebanding (Q2c)** tetap di SQL dan dokumen insight. Keduanya butuh logika periode khusus yang tidak dibutuhkan visual dashboard.

**YoY untuk freight burden** tidak dibuat. Belum ada angka SQL pembanding untuk freight burden Jan–Jul 2017, sehingga hasilnya tidak bisa direkonsiliasi. KPI card freight burden hanya menampilkan nilai periode terpilih; perbandingannya bisa dilihat per state dan per kategori.
