# Panduan Membangun Dashboard NusaMart di Power BI Desktop (Fase 6)

Panduan ini Anda kerjakan sendiri di Power BI Desktop, langkah demi langkah. Claude tidak bisa mengoperasikan Power BI. Di setiap **Checkpoint**, kirim screenshot supaya kita cek bersama sebelum lanjut. Menemukan kesalahan di awal jauh lebih murah daripada membongkar dashboard yang sudah jadi.

File pendamping: [`dax_measures.md`](dax_measures.md) berisi semua measure dan alasan rumusnya. Buka kedua file berdampingan.

| Bagian | Isi | Checkpoint |
|---|---|---|
| 0 | Persiapan | – |
| 1 | Koneksi ke PostgreSQL (mode **Import**) | 1: jumlah baris |
| 2 | Model: relasi, date table, urutan bulan | 2: Model view |
| 3 | Filter jendela analisis di level report | – |
| 4 | Measure + halaman Rekonsiliasi | 3: tabel rekonsiliasi |
| 5 | Tabel desil customer (native query) | – |
| 6 | Aturan tampilan untuk ketiga halaman | – |
| 7–9 | Executive Overview · Customer Analysis · Product & Category | 4: screenshot tiap halaman |
| 10 | Checklist rekonsiliasi (angka yang wajib sama) | – |
| 11 | Dua laporan: WORKING dan PORTFOLIO | 5: sebelum publish |
| 12 | Troubleshooting | – |

---

## 0. Persiapan

- [ ] **PostgreSQL menyala.** Service `postgresql-x64-17` berjalan otomatis saat Windows start. Database `nusamart` ada di **port 5433**.
- [ ] **Buat folder untuk file Power BI di luar folder repo**, misalnya `Documents\NusaMart-PowerBI\`.
  - Alasannya: file `.pbix` dalam mode Import menyimpan **salinan data**. Folder repo tidak boleh berisi data yang bisa ikut ter-commit.
  - Keputusan apakah `.pbix` ikut masuk GitHub kita ambil di Fase 7.
- [ ] Buka Power BI Desktop → **Blank report** → **File → Save as** → `NusaMart - WORKING.pbix` di folder tadi.
- [ ] **Matikan Auto date/time.** Buka **File → Options and settings → Options → CURRENT FILE: Data Load**, lalu di bagian *Time intelligence* hilangkan centang **Auto date/time**.
  - Alasannya: kita sudah punya tabel tanggal sendiri (`dim_date`). Auto date/time akan membuat tabel tanggal tersembunyi untuk setiap kolom tanggal. Tabel itu tidak dipakai dan membuat daftar field membingungkan.

---

## 1. Koneksi ke PostgreSQL — WAJIB mode Import

**Kenapa Import:**

- Dashboard akan dipublikasikan dengan *Publish to web*. Laporan publik ditampilkan oleh **Power BI Service**, yaitu server Microsoft di cloud. Server cloud **tidak bisa menjangkau `localhost:5433`** di laptop Anda.
- **Import** menyalin data ke dalam file `.pbix`. Saat publish, salinan itu ikut ter-upload, sehingga dashboard publik tetap tampil walaupun laptop mati.
- **DirectQuery** tidak menyimpan data. Setiap klik penonton akan mencoba query ke database di laptop Anda dan gagal. Alternatifnya butuh *gateway*, dan itu di luar stack project.
- Data project ini historis (2016–2018) dan tidak berubah, jadi salinan sudah cukup. Kalau database dimuat ulang, cukup **Refresh** lalu publish ulang.

**Langkah:**

1. **Home → Get data → More…** → cari **PostgreSQL database** → **Connect**.
2. **Server:** `localhost:5433`. Port wajib ditulis. Port 5432 adalah database Docker milik project lain; kalau port lupa ditulis, koneksi bisa nyasar ke sana.
3. **Database:** `nusamart`.
4. **Data Connectivity mode:** pilih **Import**. *Advanced options* biarkan kosong (baru dipakai di bagian 5). Klik **OK**.
5. **Kredensial**, jika diminta: pilih tab **Database**, User name `postgres`, lalu ketik password sendiri.
   - Power BI menyimpan kredensial dalam bentuk terenkripsi di profil pengguna Windows Anda, **bukan** di file `.pbix` dan bukan di repo.
   - Jangan menulis password di file mana pun, dan pastikan password tidak ikut terlihat di screenshot.
6. **Pesan enkripsi.** Jika muncul pesan bahwa koneksi terenkripsi tidak bisa dibuat (*"unable to connect … using an encrypted connection"*), klik **OK** untuk lanjut tanpa enkripsi. Ini aman karena koneksinya hanya di dalam laptop (`localhost`), dan datanya tidak lewat internet.
7. Di **Navigator**, centang 4 tabel: `dim_customer`, `dim_date`, `dim_product`, `fact_sales` (tertulis dengan awalan `public.`). Klik **Load**, jangan *Transform Data*.
8. **Cek nama tabel** di panel **Data** (kanan). Namanya harus persis `dim_customer`, `dim_date`, `dim_product`, `fact_sales`. Jika ada awalan seperti `public dim_date`, klik kanan → **Rename** → hapus awalannya. Semua measure memakai nama tanpa awalan.
9. **Ctrl+S.**

Jika Power BI meminta komponen tambahan untuk PostgreSQL, **jangan install apa pun dulu**. Kirim screenshot pesannya. Power BI Desktop versi baru sudah menyertakan driver PostgreSQL.

> **Checkpoint 1.** Buka **Table view** (ikon tabel di bilah kiri) dan klik tiap tabel. Jumlah baris tampil di kiri bawah:
>
> | Tabel | Jumlah baris |
> |---|---|
> | fact_sales | 110.197 |
> | dim_customer | 93.358 |
> | dim_product | 32.951 |
> | dim_date | 1.096 |
>
> Ini isi penuh database (filter jendela belum dipasang), dan sudah dicek langsung ke database. Kirim screenshot, terutama jika ada yang berbeda.

---

## 2. Model (Model view)

### 2.1 Relasi

Buka **Model view** (ikon diagram di bilah kiri). Power BI mungkin sudah membuat sebagian relasi secara otomatis. Pastikan ada **tepat 3 relasi** berikut:

| Tabel dimensi (sisi "1") | Tabel fakta (sisi "banyak") | Cardinality | Cross filter direction |
|---|---|---|---|
| `dim_date[date_key]` | `fact_sales[order_date]` | One to many (1:\*) | **Single** |
| `dim_customer[customer_unique_id]` | `fact_sales[customer_unique_id]` | One to many (1:\*) | **Single** |
| `dim_product[product_id]` | `fact_sales[product_id]` | One to many (1:\*) | **Single** |

- **Membuat relasi yang belum ada:** tarik `date_key` dari kotak `dim_date`, lalu lepas di `order_date` pada kotak `fact_sales`.
- **Memeriksa relasi:** klik dua kali garis relasi, lalu cek *Cardinality* dan *Cross filter direction*. Tertulis *Many to one (\*:1)* juga benar; itu relasi yang sama dilihat dari arah sebaliknya.

**Larangan (penting untuk angka new vs returning):**

- Jangan membuat relasi apa pun ke `dim_customer[first_order_date]`.
- Jangan mengubah arah relasi menjadi **Both**.

Alasannya ada di `dax_measures.md` bagian *"Kenapa New Customers tetap memakai first_order_date dari seluruh histori"*.

### 2.2 Mark as date table

1. Di panel **Data**, klik kanan `dim_date` → **Mark as date table**.
2. Pilih kolom **`date_key`** → **OK**.

Power BI memeriksa bahwa tanggal unik, tidak kosong, dan berurutan tanpa lubang. `dim_date` memenuhi semuanya: 1.096 hari, 1 Januari 2016 s/d 31 Desember 2018, tahun penuh. Tanpa langkah ini, measure pembanding (bulan lalu dan tahun lalu) tidak bekerja dengan benar.

### 2.3 Urutkan `month_name` berdasarkan `month`

1. Buka **Table view** → tabel `dim_date` → klik kolom `month_name`.
2. **Column tools → Sort by column → `month`**.

Isi `month_name` adalah `Jan`, `Feb`, …, `Dec`. Tanpa langkah ini, slicer akan mengurutkan bulan secara alfabet (Apr, Aug, Dec, …).

### 2.4 Kolom angka yang tidak boleh dijumlah

Untuk kolom `dim_date[year]`, `[month]`, `[quarter]`, dan `[day_of_week]`: klik kolomnya → **Column tools → Summarization → Don't summarize**.

Tanpa ini, Power BI bisa menjumlahkan tahun, misalnya 2017 + 2018 = 4035, kalau kolom itu tidak sengaja ditaruh sebagai nilai.

> **Checkpoint 2.** Kirim screenshot **Model view** yang memperlihatkan ketiga relasi.

---

## 3. Filter jendela analisis (Filters on all pages)

Semua angka project memakai **jendela analisis 2017-01 s/d 2018-07**. Filter ini dipasang **satu kali** untuk seluruh report.

1. Klik area kosong di kanvas, lalu buka panel **Filters**.
2. Tarik `dim_date[is_analysis_month]` ke kotak **Filters on all pages**.
3. Pilih **Basic filtering** → centang **True** saja.
4. Klik ikon **gembok** supaya filter terkunci.

Penjelasan lengkapnya ada di `dax_measures.md` bagian *"Filter jendela analisis"*. Termasuk di situ: kenapa measure bulan lalu dan tahun lalu memasang ulang filter ini di dalam rumusnya.

---

## 4. Measure dan halaman Rekonsiliasi

1. Buat **36 measure** dari `dax_measures.md`, urut dari bagian A sampai D, lalu atur format tiap measure.
2. Buat halaman baru bernama **Rekonsiliasi**. Halaman ini **hanya ada di laporan WORKING** dan dipakai untuk mencocokkan angka sebelum membangun halaman dashboard.
   - **Tabel 1** (visual *Table*): `dim_date[year]`, Total Revenue, Total Orders, Total Customers, Units Sold, AOV, Freight Burden % (proxy), Repeat Rate %, Revenue YoY %, Orders YoY %, Customers YoY %, AOV YoY %.
     - Baris 2017 dan 2018 = angka per tahun.
     - Baris **Total** = seluruh jendela.
     - *(Opsional)* Tambahkan juga Revenue PY, Orders PY, Customers PY, dan AOV PY untuk mencocokkan kolom PY di checklist C.
   - **Tabel 2** (visual *Table*): `dim_date[year_month]`, Total Revenue, Total Orders, AOV, Revenue MoM %, Revenue YoY %, New Customers, Returning Customers, Returning Revenue % (monthly basis).
3. Bandingkan dengan checklist di **bagian 10** (A, B, C, dan D1–D4, D6–D7).

Tabel menampilkan angka lengkap, tanpa singkatan seperti "12,34M", sehingga paling mudah untuk dicocokkan.

> **Checkpoint 3.** Kirim screenshot kedua tabel. Kalau ada satu angka pun yang berbeda, **berhenti dulu**. Sesuai aturan rekonsiliasi project, penyebabnya dicari sebelum lanjut.

---

## 5. Tabel desil customer (native SQL query)

Grafik konsentrasi revenue (Q5) memakai hasil SQL Q5a, bukan DAX. Alasannya ada di `dax_measures.md` bagian *"Yang sengaja tidak dibuat dengan DAX"*.

1. **Home → Get data → PostgreSQL database.**
2. Server `localhost:5433`, Database `nusamart`, mode **Import**.
3. Buka **Advanced options** dan tempel query di bawah ini ke kotak **SQL statement**.
   - Query ini identik dengan Q5a di `sql/03_customer_analysis.sql`, hanya tanpa komentar dan tanpa titik koma di akhir.
   - Query sudah dites ke database; hasilnya sama persis dengan `results/03_q5a_decile.csv`.
4. Klik **OK**. Jika muncul peringatan *Native Database Query*, klik **Run**.
5. Preview harus berisi **10 baris** (desil 1–10) → **Load**.
6. Tabel baru biasanya bernama `Query1`. Rename menjadi **`q5a_decile`**.
7. Kolom `q5a_decile[decile]` → **Summarization: Don't summarize**.
8. **Jangan** membuat relasi apa pun ke tabel ini.

```sql
WITH customer_revenue AS (
    SELECT f.customer_unique_id, SUM(f.price) AS revenue
    FROM fact_sales f
    JOIN dim_date d ON f.order_date = d.date_key
    WHERE d.is_analysis_month = TRUE
    GROUP BY f.customer_unique_id
),
ranked AS (
    SELECT revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM customer_revenue
)
SELECT
    decile,
    COUNT(*) AS customers,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / SUM(SUM(revenue)) OVER () * 100, 2) AS revenue_share_pct,
    ROUND(SUM(SUM(revenue)) OVER (ORDER BY decile) / SUM(SUM(revenue)) OVER () * 100, 2) AS cumulative_share_pct
FROM ranked
GROUP BY decile
ORDER BY decile
```

**Catatan:**

- Tabel ini sudah difilter jendela analisis di dalam SQL-nya, dan tidak terhubung ke tabel lain. Akibatnya, grafik desil **tidak ikut berubah saat slicer diubah**. Hal ini ditulis di subjudul visualnya.
- Angka persen di tabel ini sudah dalam satuan persen (41,09 artinya 41,09%). Jangan diformat sebagai *Percentage*, karena akan menjadi 4109%.

---

## 6. Aturan tampilan (berlaku untuk ketiga halaman)

### Kerangka halaman (kanvas 16:9)

```
┌───────────────────────────────────────────────────────────────────┐
│ Judul halaman + subjudul           [Periode ▼] [Kategori ▼] [State ▼]│ ← header
├───────────────────────────────────────────────────────────────────┤
│  KPI card   │  KPI card   │  KPI card   │  (KPI card)             │ ← baris KPI
├───────────────────────────────────────────────────────────────────┤
│                    2–3 grafik / tabel                              │
├───────────────────────────────────────────────────────────────────┤
│ Definisi KPI + sumber data (teks kecil)                            │ ← footer
└───────────────────────────────────────────────────────────────────┘
```

### Aturan

1. **Batas isi per halaman:**
   - Maksimal **4 KPI card + 3 grafik/tabel**, ditambah 3 slicer, judul, dan footer.
   - Jika terasa sesak, kurangi isinya. Jangan memperkecil visual sampai tidak terbaca.
2. **Slicer global (FR-01).** Buat ketiga slicer di halaman 1, lalu **copy–paste** ke halaman 2 dan 3. Saat Power BI bertanya, pilih **Sync**, supaya pilihan slicer berlaku sama di semua halaman.

   | Slicer | Field | Pengaturan |
   |---|---|---|
   | Periode | `dim_date[year]` lalu `dim_date[month_name]` di kotak *Field* yang sama | Menjadi hierarki tahun → bulan. Style: **Dropdown** |
   | Kategori | `dim_product[category_en]` | Style: Dropdown, aktifkan **Search** |
   | State | **`fact_sales[customer_state]`**, bukan `dim_customer` | Style: Dropdown. Kolom ini dipakai supaya angkanya sama persis dengan Q3 (state pada saat order) |

   - Biarkan slicer kosong sebagai tampilan awal. Kosong berarti semua data dalam jendela.
   - Slicer Periode hanya menampilkan 2017 (Jan–Des) dan 2018 (Jan–Jul), karena filter jendela ikut membatasi isinya.
   - Jika dialog *Sync* tidak muncul, buka **View → Sync slicers** dan centang ketiga halaman untuk tiap slicer.
3. **KPI card (FR-02).**
   - Pakai visual **Card** versi baru (di sebagian versi bernama *Card (new)*).
   - Masukkan measure utama ke **Data**, dan measure `… YoY Label` ke **Reference labels**.
   - Perbandingannya adalah **terhadap periode yang sama tahun sebelumnya**. Alasannya dijelaskan di `dax_measures.md` bagian B.
   - Kalau tidak menemukan *Reference labels*, lihat bagian 12.
4. **Judul dan subjudul.**
   - Isi lewat **Format → General → Title** (Title dan Subtitle).
   - Subjudul menyebut kode pertanyaan bisnis (Q1–Q7), sehingga setiap visual bisa ditelusuri ke BRD dan ke query SQL-nya.
5. **Istilah wajib:**
   - Setiap judul yang memuat freight burden ditulis **"freight burden (proxy)"**.
   - Mata uang ditulis **R$** (Real Brasil), bukan Rp. Atur lewat format measure: *Currency → R$ Portuguese (Brazil)*.
6. **Warna:**
   - Satu warna utama untuk revenue, order, dan customer.
   - Satu warna kontras (misalnya oranye) **khusus freight burden (proxy)**, dipakai konsisten di semua halaman.
7. **Footer (FR-04).** Text box kecil (font 9–10) berisi definisi KPI di halaman itu dan sumber data. Teks lengkapnya disediakan di setiap bagian halaman di bawah.

---

## 7. Halaman 1 — Executive Overview

**Untuk:** CEO/Management, Head of Commercial, Operations/Logistics.
**Target (BRD):** kondisi bisnis dipahami dalam kurang dari 1 menit.

```
┌───────────────────────────────────────────────────────────────────┐
│ Executive Overview                  [Periode ▼][Kategori ▼][State ▼]│
├────────────────┬────────────────┬────────────────┬────────────────┤
│ E1 Revenue     │ E2 Order       │ E3 AOV         │ E4 Freight     │
│ YoY …          │ YoY …          │ YoY …          │ burden (proxy) │
├────────────────┴────────────────┴────────────────┴────────────────┤
│ E5 Revenue dan AOV per bulan                                       │
├───────────────────────────────────────────────────────────────────┤
│ E6 Revenue dan freight burden (proxy) per state                    │
├───────────────────────────────────────────────────────────────────┤
│ footer                                                             │
└───────────────────────────────────────────────────────────────────┘
```

| ID | Visual | Field / measure | Judul | Subjudul (pertanyaan bisnis) |
|---|---|---|---|---|
| E1 | Card | Data: `Total Revenue` · Reference label: `Revenue YoY Label` | Revenue | BR-01 · Berapa revenue periode ini, dan berapa pertumbuhannya dibanding periode yang sama tahun lalu? |
| E2 | Card | Data: `Total Orders` · Reference label: `Orders YoY Label` | Order | Q1 · Apakah jumlah order ikut tumbuh? |
| E3 | Card | Data: `AOV` · Reference label: `AOV YoY Label` | AOV (nilai rata-rata per order) | Q1 · Apakah nilai belanja per order naik? |
| E4 | Card | Data: `Freight Burden % (proxy)` | Freight burden (proxy) | BR-06 · Berapa ongkir yang ditanggung customer relatif terhadap harga barang? |
| E5 | Line and clustered column chart | X-axis: `dim_date[year_month]` · Column y-axis: `Total Revenue` · Line y-axis: `AOV` · Tooltips: `Total Orders`, `Revenue MoM %`, `Revenue YoY %` | Revenue dan AOV per bulan | Q1 · Revenue tumbuh karena jumlah order atau karena AOV? Arahkan kursor untuk melihat MoM dan YoY |
| E6 | Line and clustered column chart | X-axis: `fact_sales[customer_state]` · Column y-axis: `Total Revenue` · Line y-axis: `Freight Burden % (proxy)` · Tooltips: `State Revenue Share %`, `Total Orders`, `AOV` | Revenue dan freight burden (proxy) per state | Q3 · Wilayah mana yang besar dari sisi revenue, order, dan AOV? Garis = ongkir dibayar customer ÷ harga barang |

**Pengaturan:**

- **E5:**
  - Urutkan sumbu berdasarkan bulan: klik **… (More options) → Sort axis → `year_month`**, lalu **Sort ascending**. Grafik kombinasi defaultnya mengurutkan berdasarkan nilai, bukan waktu.
  - Di panel **Format**, buka bagian **Secondary y-axis** (sumbu AOV), lalu atur **Range → Minimum = 0**. Skala AOV yang dimulai dari nol menunjukkan dengan jujur bahwa AOV hampir datar. Kalau skalanya dimulai dari 120, selisih kecil akan tampak seperti naik-turun besar.
- **E6:**
  - Urutkan berdasarkan `Total Revenue`, dari besar ke kecil.
  - Beri judul sumbu kedua: "Freight burden (proxy)".
- **E4** sengaja tanpa YoY (alasan di `dax_measures.md`, bagian akhir).

**Cara membaca (bahan interview).**

- **Pilih Periode = 2018.** Card akan menunjukkan revenue **+161,6%**, order **+160,8%**, dan AOV hanya **+0,3%** dibanding Jan–Jul 2017. Artinya, pertumbuhan datang dari jumlah order, bukan dari nilai per order (Insight 1).
- **Tanpa pilihan periode.** Label YoY menampilkan "YoY tidak tersedia". Ini disengaja: tidak ada "tahun lalu" yang adil untuk seluruh jendela sekaligus.

**Footer:**

> Revenue = Σ harga barang pada order delivered (ongkir tidak termasuk) · AOV = revenue ÷ jumlah order · Freight burden (proxy) = Σ ongkir yang dibayar customer ÷ Σ harga barang — bukan profit dan bukan biaya perusahaan · YoY = dibanding periode yang sama tahun sebelumnya; hanya tersedia jika satu tahun dipilih dan pembandingnya ada di jendela analisis · Periode: Jan 2017 – Jul 2018 · NusaMart adalah nama fiktif; data: Brazilian E-Commerce Public Dataset by Olist (Kaggle), mata uang R$.

---

## 8. Halaman 2 — Customer Analysis

**Untuk:** CRM/Marketing Manager, untuk keputusan budget akuisisi vs retensi.

```
┌───────────────────────────────────────────────────────────────────┐
│ Customer Analysis                   [Periode ▼][Kategori ▼][State ▼]│
├──────────────────────┬──────────────────────┬─────────────────────┤
│ C1 Customer          │ C2 Repeat rate       │ C3 Revenue dari     │
│ YoY …                │                      │ customer returning  │
├──────────────────────┴───────────────┬──────┴─────────────────────┤
│ C4 Customer baru vs returning         │ C5 Porsi revenue per       │
│    per bulan (± 60% lebar)            │    desil customer          │
├───────────────────────────────────────┴────────────────────────────┤
│ footer                                                             │
└───────────────────────────────────────────────────────────────────┘
```

| ID | Visual | Field / measure | Judul | Subjudul (pertanyaan bisnis) |
|---|---|---|---|---|
| C1 | Card | Data: `Total Customers` · Reference label: `Customers YoY Label` | Customer | BR-03 · Berapa customer yang belanja di periode ini? |
| C2 | Card | Data: `Repeat Rate %` | Repeat rate | Q4 · Berapa persen customer yang order 2 kali atau lebih di periode ini? |
| C3 | Card | Data: `Returning Revenue % (monthly basis)` | Revenue dari customer returning | Q4 · Berapa kontribusi revenue dari customer yang sudah pernah belanja sebelumnya? |
| C4 | Line and stacked column chart | X-axis: `dim_date[year_month]` · Column y-axis: `New Customers`, `Returning Customers` · Line y-axis: `Returning Revenue % (monthly basis)` · Tooltips: `Returning Customer %`, `New Customer Revenue`, `Returning Customer Revenue` | Customer baru vs returning per bulan | Q4 · Berapa porsi customer returning dan kontribusi revenue-nya? Garis = % revenue dari customer returning |
| C5 | Line and clustered column chart | X-axis: `q5a_decile[decile]` · Column y-axis: `revenue_share_pct` · Line y-axis: `cumulative_share_pct` | Porsi revenue per desil customer (%) | Q5 · Seberapa terkonsentrasi revenue? Desil 1 = 10% customer dengan belanja terbesar · Jan 2017–Jul 2018 · tidak ikut slicer |

**Pengaturan:**

- **C4:**
  - Urutkan sumbu berdasarkan `year_month`, ascending.
  - Batang *returning* akan sangat tipis (sekitar 1–190 per bulan, dibanding ratusan sampai sekitar 7.000 customer baru). Itulah temuannya, jadi **jangan diubah skalanya**.
- **C5:**
  - Di **Format → X-axis**, ubah **Type** menjadi **Categorical**, lalu urutkan berdasarkan `decile` ascending.
  - Aktifkan data label pada kolom.
  - Power BI akan menamai field "Sum of revenue_share_pct". Klik dua kali nama field di kotak *Build*, lalu rename untuk visual ini menjadi "% revenue" dan "% kumulatif".

**Cara membaca (bahan interview).**

- **Tanpa slicer:**
  - Repeat rate hanya **3,00%**.
  - Hanya **1,76%** revenue berasal dari customer returning.
  - **10% customer teratas** menyumbang **41,09%** revenue.
- Insight 3 menunjukkan bahwa kelompok teratas itu hampir seluruhnya pembeli sekali. Hubungkan temuan ini dengan Insight 2 dan 3.

**Footer:**

> Customer = customer_unique_id · Baru = order pertamanya (dihitung dari seluruh histori, termasuk 2016) jatuh di bulan atau periode tersebut · Returning = sudah pernah order sebelumnya · Repeat rate = customer dengan ≥ 2 order di periode terpilih ÷ total customer · Revenue returning dihitung per bulan lalu dijumlahkan · Desil customer dihitung di SQL (Q5a) untuk seluruh periode Jan 2017 – Jul 2018 · NusaMart fiktif; data: Olist (Kaggle), R$.

---

## 9. Halaman 3 — Product & Category

**Untuk:** Category Manager (fokus assortment) dan Operations/Logistics (beban ongkir per kategori).

```
┌───────────────────────────────────────────────────────────────────┐
│ Product & Category                  [Periode ▼][Kategori ▼][State ▼]│
├──────────────────────┬──────────────────────┬─────────────────────┤
│ P1 Unit terjual      │ P2 Harga rata-rata   │ P3 Freight burden   │
│                      │ per unit             │ (proxy)             │
├──────────────────────┴───────────┬──────────┴─────────────────────┤
│ P4 Top 15 kategori berdasarkan    │ P5 Volume vs harga rata-rata   │
│    revenue (bar, drill-down)      │    per kategori (scatter)      │
│                                   ├────────────────────────────────┤
│                                   │ P6 Tabel Q7                    │
├───────────────────────────────────┴────────────────────────────────┤
│ footer                                                             │
└───────────────────────────────────────────────────────────────────┘
```

| ID | Visual | Field / measure | Judul | Subjudul (pertanyaan bisnis) |
|---|---|---|---|---|
| P1 | Card | Data: `Units Sold` | Unit terjual | BR-05 · Berapa unit yang terjual? |
| P2 | Card | Data: `Avg Item Price` | Harga rata-rata per unit | Q6 · Berapa harga rata-rata barang yang dibeli? |
| P3 | Card | Data: `Freight Burden % (proxy)` | Freight burden (proxy) | Q7 · Beban ongkir customer relatif terhadap harga barang |
| P4 | Clustered bar chart | Y-axis: `dim_product[category_en]` lalu `dim_product[product_id]` (hierarki untuk drill-down) · X-axis: `Total Revenue` · Tooltips: `Category Revenue Share %`, `Units Sold`, `Freight Burden % (proxy)` | Top 15 kategori berdasarkan revenue | Q2 & FR-03 · Kategori mana yang dominan? Klik panah ↓ (drill mode), lalu klik bar untuk melihat produknya |
| P5 | Scatter chart | Values: `dim_product[category_en]` · X-axis: `Units Sold` · Y-axis: `Avg Item Price` · Size: `Total Revenue` · Tooltips: `Freight Burden % (proxy)` | Volume vs harga rata-rata per kategori | Q6 · Kanan bawah = laku banyak tapi murah; kiri atas = sedikit tapi mahal; ukuran titik = revenue |
| P6 | Table | `dim_product[category_en]`, `Total Revenue`, `Category Revenue Share %`, `Freight Burden % (proxy)`, `Avg Item Price`, `Freight per Unit` | Kategori besar dengan freight burden (proxy) di atas rata-rata | Q7 · Revenue di atas rata-rata kategori DAN freight burden (proxy) di atas rata-rata keseluruhan |

**Pengaturan:**

- **P4:**
  - **Filter Top 15.** Di panel Filters bagian visual ini, buka `category_en` → *Filter type*: **Top N** → Show items: **Top 15** → *By value*: `Total Revenue` → **Apply filter**. Ini sama dengan `LIMIT 15` di Q2.
  - **Jangan memberi filter Top N pada `product_id`.** Filter itu ikut berlaku di level kategori, sehingga revenue kategori akan terpotong.
  - **Level produk.** Di level ini bar berisi **ID produk anonim** (32 karakter), karena dataset tidak punya nama produk. Arahkan kursor ke bar untuk melihat ID lengkapnya.
- **P5:**
  - Pastikan `category_en` ada di kotak **Values**. Tanpa itu, scatter hanya menampilkan satu titik.
  - Tanpa slicer harus muncul **74 titik**, satu per kategori.
- **P6:**
  - **Filter Q7.** Di panel Filters bagian visual ini, tarik measure `Q7 High Burden Flag` → pilih **is** `1` → **Apply filter**.
  - Urutkan berdasarkan `Total Revenue`, dari besar ke kecil, dan biarkan baris **Total** aktif.
  - *(Opsional)* Beri warna latar pada kolom Freight Burden % (proxy) lewat *Conditional formatting*.

**Cara membaca (bahan interview).**

- **Tabel Q7 tanpa slicer** berisi **9 kategori** dengan total **36,18%** revenue.
- Dari kolom *Avg Item Price* dan *Freight per Unit* terlihat pola Insight 4: kebanyakan bebannya tinggi karena **harga barangnya murah**, bukan karena ongkirnya mahal.
- **Hati-hati membandingkan tahun.** Memilih 2017 lalu 2018 di slicer berarti membandingkan 2017 **setahun penuh** dengan 2018 yang hanya **Jan–Jul**. Perbandingan porsi kategori yang adil ada di Q2c dan Insight 6.

**Footer:**

> 1 unit = 1 baris order item · Harga rata-rata per unit = revenue ÷ unit · Freight burden (proxy) = Σ ongkir yang dibayar customer ÷ Σ harga barang — bukan profit, bukan biaya perusahaan/seller · Produk hanya berupa ID anonim (dataset tidak memuat nama produk) · Periode: Jan 2017 – Jul 2018 · NusaMart fiktif; data: Olist (Kaggle), R$.

---

## 10. Checklist rekonsiliasi (FR-05)

**Aturan project:** angka Power BI harus **identik** dengan SQL. Semua angka di bawah diambil langsung dari file di `results/`.

**Tips mengecek:**

- **Gunakan laporan WORKING.** Paling mudah lewat tabel di halaman Rekonsiliasi (bagian 4). Kalau mengecek di card, atur dulu **Callout value → Display units: None**.
- **Tampilan pemisah bisa beda.** Power BI mungkin menulis `12,342,450.49` sesuai pengaturan bahasa, sedangkan dokumen ini menulis `12.342.450,49`. Yang harus sama adalah **digitnya**.
- **Jangan abaikan selisih**, termasuk selisih 0,01. Kirim screenshot dan kita cari penyebabnya.

### A. Tanpa pilihan slicer (seluruh jendela) — sumber `results/05_kpi_total_filtered.csv`

| # | Di mana | Measure | Harus sama dengan |
|---|---|---|---|
| A1 | E1 | Total Revenue | **R$ 12.342.450,49** |
| A2 | E2 | Total Orders | **89.860** |
| A3 | E3 | AOV | **R$ 137,35** |
| A4 | E4 dan P3 | Freight Burden % (proxy) | **16,57%** |
| A5 | C1 | Total Customers | **86.960** |
| A6 | C2 | Repeat Rate % | **3,00%** (SQL menulis `3.0`; 2.609 ÷ 86.960) |
| A7 | P1 | Units Sold | **102.738** |
| A8 | P2 | Avg Item Price | **R$ 120,14** (turunan: 12.342.450,49 ÷ 102.738) |
| A9 | C3 | Returning Revenue % (monthly basis) | **1,76%** (turunan `03_q4c_new_vs_returning.csv`: R$ 217.797,09 ÷ R$ 12.342.450,49) |
| A10 | E1–E3, C1 | YoY Label | **"YoY tidak tersedia"** (memang seharusnya) |

### B. Periode = 2017 — sumber `results/05_kpi_per_year_filtered.csv`

| Revenue | Order | Customer | Unit | AOV | Freight burden (proxy) | YoY Label | Revenue returning (monthly basis) |
|---|---|---|---|---|---|---|---|
| R$ 5.962.902,01 | 43.428 | 42.136 | 49.556 | R$ 137,31 | 16,08% | "YoY tidak tersedia" (2016 di luar jendela) | 1,34% (turunan Q4c) |

### C. Periode = 2018 (Jan–Jul) — sumber `05_kpi_per_year_filtered.csv` dan `02_q1c_fair_period_comparison.csv`

| KPI | Nilai 2018 | YoY Label | PY (Jan–Jul 2017, Q1c) |
|---|---|---|---|
| Revenue | R$ 6.379.548,48 | YoY +161,6% | R$ 2.438.756,43 |
| Order | 46.432 | YoY +160,8% | 17.805 |
| Customer | 45.414 | YoY +161,8% | 17.347 |
| AOV | R$ 137,40 | YoY +0,3% | R$ 136,97 |
| Unit | 53.182 | – | – |
| Freight burden (proxy) | 17,03% | – | – |
| Revenue returning (monthly basis) | 2,17% (turunan Q4c) | – | – |

### D. Cek visual — sumber: file `results/` yang disebut di kolom terakhir

| # | Visual | Yang dicek | Harus sama dengan | Sumber |
|---|---|---|---|---|
| D1 | E5, Jan 2017 | Revenue · order · AOV · MoM · YoY | R$ 111.798,36 · 750 · R$ 149,06 · **kosong** · **kosong** | Q1, Q1b |
| D2 | E5, Nov 2017 (puncak) | Revenue · order | R$ 987.765,37 · 7.289 | Q1 |
| D3 | E5, Jul 2018 | Revenue · order · AOV · MoM · YoY | R$ 867.953,46 · 6.159 · R$ 140,92 · +1,4% · +80,2% | Q1, Q1b |
| D4 | E5 / Tabel 2 | Bulan yang punya YoY | Hanya 2018-01 s/d 2018-07; **seluruh 2017 kosong** | Q1b |
| D5 | E6, state SP | Revenue · share · order · AOV · freight burden (proxy) | R$ 4.667.853,42 · 37,82% · 37.242 · R$ 125,34 · 13,80% | Q3 |
| D6 | C4, Jan 2017 | New · Returning | **717 · 1** (tes `first_order_date`) | Q4c |
| D7 | C4, Jun 2018 | New · Returning · % revenue returning | 5.878 · 183 · 2,96% | Q4c |
| D8 | C5 | Desil 1 · kumulatif s/d desil 2 · desil 10 | 41,09 · 56,62 · 1,31 | Q5a |
| D9 | P4 | Peringkat 1 dan 15 | health_beauty R$ 1.110.166,49 (8,99%) · office_furniture R$ 260.094,56 (2,11%) | Q2 |
| D10 | P5 | Jumlah titik | 74 kategori | Q6 |
| D11 | P6 | Isi tabel | 9 kategori: bed_bath_table, sports_leisure, furniture_decor, housewares, garden_tools, telephony, office_furniture, stationery, pet_shop · baris Total R$ 4.465.407,00 · 36,18% | Q7 |

### E. Kalau angka berbeda — diagnosa cepat

| Gejala | Penyebab paling mungkin | Perbaikan |
|---|---|---|
| Revenue R$ 13.221.498,11 · order 96.478 · customer 93.358 · unit 110.197 · AOV R$ 137,04 · freight burden 16,63% | Filter jendela belum terpasang. Ini angka **seluruh data**, sudah dicek ke database | Bagian 3 |
| Returning Jan 2017 = **0**, bukan 1 | `first_order_date` ikut terpotong | Cek bahwa tidak ada filter pada `dim_customer` di panel Filters, rumus New Customers persis seperti di `dax_measures.md`, dan tidak ada relasi ke `first_order_date` |
| MoM Jan 2017 terisi (angka sangat besar), atau YoY 2017 terisi | Filter jendela tidak dipasang ulang di measure PM/PY | Salin ulang measure PM/PY, termasuk baris `dim_date[is_analysis_month] = TRUE ()` |
| Porsi kategori di P4 berjumlah 100% di 15 kategori | Memakai *Quick measure* atau `ALLSELECTED` | Pakai `Category Revenue Share %` dari `dax_measures.md` |
| P6 menampilkan semua kategori | Filter visual Q7 belum dipasang | Filter `Q7 High Burden Flag` is 1 |
| Urutan bulan di slicer: Apr, Aug, Dec, … | *Sort by column* belum diatur | Bagian 2.3 |
| Card menampilkan "12,34M" atau "12,34 Jt" | *Display units* masih Auto | Callout value → Display units: None (untuk mengecek) |

---

## 11. Dua laporan: NusaMart - WORKING dan NusaMart - PORTFOLIO

| | **NusaMart - WORKING** | **NusaMart - PORTFOLIO** |
|---|---|---|
| Fungsi | Tempat membangun, bereksperimen, dan merekonsiliasi | Versi bersih untuk publik (recruiter, case study) |
| Halaman | 3 halaman dashboard + **Rekonsiliasi** (+ halaman coba-coba bila perlu) | **Hanya 3 halaman**: Executive Overview, Customer Analysis, Product & Category |
| Filter jendela | Terlihat dan dikunci | Dikunci **dan disembunyikan**; panel Filters disembunyikan dari penonton |
| Format angka | Display units *None* supaya mudah dicek | Display units *Auto* boleh di card |
| Perubahan | **Semua perubahan dibuat di sini dulu**, lalu dicek ulang dengan checklist | Tidak diedit langsung; dibuat ulang dari WORKING (lihat langkah di bawah) |
| Publish to web | **Tidak pernah** | Ya, hanya setelah checklist lolos dan Anda memutuskan untuk publish |
| Lokasi file | Folder di luar repo | Folder di luar repo |

**Membuat PORTFOLIO (setiap kali WORKING berubah):**

1. Pastikan WORKING lolos checklist bagian 10 → **Save**.
2. **File → Save as** → `NusaMart - PORTFOLIO.pbix`, lalu timpa file lama jika ada.
3. Hapus halaman **Rekonsiliasi** dan halaman coba-coba.
4. Di panel Filters, filter `is_analysis_month`:
   - klik **gembok** supaya terkunci,
   - klik **mata** supaya tersembunyi,
   - klik ikon mata di kepala panel Filters supaya seluruh panel tidak terlihat oleh penonton.
5. Rapikan tampilan:
   - display units card (boleh Auto),
   - judul dan subjudul sesuai tabel di bagian 7–9,
   - kata "(proxy)" di setiap judul freight burden,
   - mata uang R$,
   - footer di setiap halaman.
6. Cek ulang cepat: Revenue R$ 12.342.450,49, Order 89.860, Customer 86.960 (dengan display units None sementara).
7. **Save.**

**Aturan Publish to web:**

- **Publik penuh.** Siapa pun yang punya link bisa melihat laporan tanpa login. Link bisa tersebar dan terindeks mesin pencari, dan tidak bisa dibatasi.
- **Hanya PORTFOLIO** yang boleh di-publish to web. WORKING tidak pernah.
- **Tidak ada data per customer.** Pastikan tidak ada visual yang menampilkan data per customer (misalnya `customer_unique_id` atau kota).
- **Update:** setiap perubahan harus dibuat ulang dari WORKING, lalu di-publish ulang (*Replace*). Data publik adalah salinan saat publish, dan tidak ter-refresh otomatis karena service tidak bisa menjangkau database lokal. Itu memang sesuai rencana.
- **Kapan:** publish dilakukan setelah semua checklist lolos. Langkah publish dan pengambilan link embed kita kerjakan bersama di akhir Fase 6, lalu link-nya dipakai di case study (Fase 8).

> **Checkpoint 5.** Sebelum publish, kirim screenshot ketiga halaman PORTFOLIO dan konfirmasi bahwa checklist A–D sudah lolos.

---

## 12. Troubleshooting

| Masalah | Solusi |
|---|---|
| Tidak menemukan **Reference labels** di Card | Kirim screenshot panel *Visualizations*. Sementara, pakai alternatif: Card untuk angka utama + Card kedua yang kecil tepat di bawahnya berisi measure `… YoY Label` (matikan label kategorinya) |
| Error *"Cannot find table …"* atau *"Column … cannot be found"* saat membuat measure | Nama tabel masih berawalan `public` (bagian 1 langkah 8), atau measure yang dirujuk belum dibuat (buat berurutan) |
| Error sintaks saat menempel measure | Pastikan hanya **satu blok** yang ditempel, lengkap dari nama measure sampai kurung tutup terakhir |
| Kredensial salah atau ingin mengganti password | **File → Options and settings → Data source settings** → pilih `localhost:5433;nusamart` → **Edit Permissions → Credentials → Edit**. Ketik password sendiri |
| Dialog *Sync* slicer tidak muncul saat paste | **View → Sync slicers** → centang ketiga halaman untuk tiap slicer |
| Peringatan *Native Database Query* muncul lagi saat Refresh | Normal untuk tabel `q5a_decile`; klik **Run** |
| Scatter P5 hanya menampilkan satu titik | `category_en` belum masuk kotak **Values** |
| Grafik bulanan urutannya acak | **… → Sort axis → `year_month` → Sort ascending** |

---

## Ringkasan checkpoint (yang dikirim ke Claude)

1. **Checkpoint 1** — jumlah baris 4 tabel setelah Load (bagian 1).
2. **Checkpoint 2** — Model view dengan 3 relasi (bagian 2).
3. **Checkpoint 3** — dua tabel di halaman Rekonsiliasi (bagian 4). Semua harus cocok **sebelum** membangun halaman dashboard.
4. **Checkpoint 4** — screenshot tiap halaman (bagian 7–9), dua kali: tanpa slicer dan dengan Periode = 2018.
5. **Checkpoint 5** — ketiga halaman PORTFOLIO sebelum publish (bagian 11).
