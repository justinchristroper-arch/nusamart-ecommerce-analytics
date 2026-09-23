# Key Insights & Recommendations — NusaMart

> **Aturan penulisan**
> - *Finding* dan *Evidence* hanya berisi fakta dari hasil query, lengkap dengan angka dan file sumbernya.
> - *Possible explanation* selalu ditandai sebagai **hipotesis**, dengan label keyakinan dan data yang dibutuhkan untuk membuktikannya.
> - *Recommendation* hanya memakai tuas yang dikendalikan platform (subsidi ongkir platform, voucher platform, insentif seller, fitur platform), karena di marketplace harga dan ongkir ditentukan seller dan kurir.
> - *Expected impact* ditulis sebagai arah dampak, tanpa angka.
> - Target: 5–7 insight. Kualitas lebih penting dari jumlah.

## Cara membaca dokumen ini

- Semua angka berasal dari file di folder `results/`, yaitu hasil query di `sql/` (dan satu script pemeriksa di `src/`). Setiap angka menyebut file sumbernya. Angka yang dihitung dari kolom sebuah file (bukan dibaca langsung) diberi keterangan cara hitungnya.
- Periode: **jendela analisis 2017-01 s/d 2018-07** (19 bulan yang datanya lengkap), kecuali disebut lain. Perbandingan antartahun memakai **periode sebanding Jan–Jul**, karena 2018 di jendela analisis hanya sampai Juli. Kenapa Agustus 2018 tidak dipakai dijelaskan di bagian *Catatan metodologi*.
- Mata uang: Real Brasil (R$). *pp* = poin persentase.
- *Freight burden* = Σ ongkir ÷ Σ harga barang. Ongkir di dataset ini **dibayar oleh customer**, sehingga angka ini mengukur beban ongkir yang ditanggung customer relatif terhadap harga barang. Ini **proxy** — bukan profit, dan bukan biaya perusahaan.

---

## Insight 1 — Pertumbuhan hampir seluruhnya dari volume, sementara nilai per order tidak ikut naik

**Finding:** Revenue Jan–Jul 2018 naik 161,6% dibanding Jan–Jul 2017, tetapi nilai rata-rata per order (AOV) nyaris tidak berubah (+0,3%). Pertumbuhan datang dari bertambahnya order dan customer, bukan dari belanja yang lebih besar per order. Laju pertumbuhan YoY melambat tajam sepanjang 2018, tetapi data yang ada belum cukup untuk menyimpulkan apakah volume order sudah mendatar.

**Evidence:**

- Perbandingan periode sebanding — `results/02_q1c_fair_period_comparison.csv` (Q1c):

  | | Jan–Jul 2017 | Jan–Jul 2018 | Perubahan |
  |---|---|---|---|
  | Revenue | R$ 2.438.756,43 | R$ 6.379.548,48 | +161,6% |
  | Order | 17.805 | 46.432 | +160,8% |
  | Customer | 17.347 | 45.414 | +161,8% |
  | AOV | R$ 136,97 | R$ 137,40 | +0,3% |

- Revenue (+161,6%) dan customer (+161,8%) tumbuh hampir sama karena revenue per customer praktis tidak berubah: R$ 140,59 (Jan–Jul 2017) vs R$ 140,48 (Jan–Jul 2018), selisih 11 sen (revenue ÷ customer dari file yang sama). Karena revenue = customer × revenue per customer, keduanya otomatis tumbuh hampir sama.
- Pertumbuhan YoY per bulan melambat tajam: **+727,1% (Januari 2018) → +80,2% (Juli 2018)** — `results/02_q1b_yoy.csv` (Q1b).
- **Cek right-censoring** — `results/02_q1d_orders_all_status_monthly.csv`. Order non-delivered tidak dimuat ke star schema, jadi hitungan ini dibuat dari file order mentah lewat `src/right_censoring_check.py`:
  - Order **semua status** juga tidak naik dari Januari ke Juli 2018 (7.269 → 6.292), sejalan dengan order delivered (7.069 → 6.159).
  - Order yang belum final (masih diproses atau dikirim) hanya 0,75%–2,29% per bulan di Jan–Jul 2018 (46–165 order). Jadi bulan-bulan akhir tidak tampak lebih kecil karena ordernya belum sempat delivered.
- Laju order harian 2018 (semua status; order per bulan ÷ jumlah hari, dari `02_q1d`): 231–240 order per hari di Jan–Apr, 222 di Mei, dan 203–206 di Jun–Jul. Di luar jendela analisis, laju 1–21 Agustus justru mencapai 277 order per hari (`results/02_q1e_orders_daily_aug_sep_2018.csv`) sebelum data terpotong. Volume turun di pertengahan tahun lalu naik lagi — bukan pola mendatar yang jelas.
- AOV bulanan hanya bergerak di rentang R$ 124,38–149,06 (2017) dan R$ 126,08–144,84 (2018), tanpa tren naik — `results/02_q1_monthly.csv`.

**Possible explanation (hipotesis):**

- Angka +161,6% sebagian besar mencerminkan fase awal bisnis, bukan percepatan di 2018. Januari 2017 baru berisi 750 order (`results/02_q1_monthly.csv`), sehingga pembanding 2017 masih sangat kecil. [High confidence — basis yang kecil dan YoY yang terus melambat terlihat langsung di data.]
- Turunnya laju harian di Jun–Jul dan lonjakan di awal Agustus bisa jadi pola musiman, misalnya menjelang Hari Ayah di Brasil (Minggu kedua Agustus, yaitu 12 Agustus 2018), bukan perubahan tren. [Low confidence — hanya ada satu periode 2018 dan tidak ada data kalender promo.] *Data yang dibutuhkan:* minimal dua tahun penuh dan kalender kampanye.
- AOV mungkin datar karena belum ada mekanisme di tingkat platform yang mendorong belanja lebih besar per order, seperti rekomendasi produk pelengkap atau voucher untuk keranjang multi-item. [Low confidence — dataset tidak memuat data promo atau fitur apa pun.] *Data yang dibutuhkan:* histori promo platform dan log fitur rekomendasi.

**Recommendation:** **Head of Commercial**, bersama tim produk platform, membuka pengungkit pertumbuhan kedua selain volume dengan tuas yang dikendalikan platform, diuji sebagai eksperimen terkontrol: (1) fitur rekomendasi produk pelengkap ("sering dibeli bersama") di halaman produk dan keranjang; (2) voucher platform untuk keranjang berisi beberapa item; (3) ambang gratis ongkir yang disubsidi platform; (4) insentif bagi seller yang menawarkan paket produk, misalnya potongan komisi. *Metrik keberhasilan:* AOV (baseline jendela analisis R$ 137,35) dan unit per order (baseline 1,14 = 102.738 unit ÷ 89.860 order, `results/02_kpi01.csv`) di grup eksperimen dibanding grup kontrol, sambil memastikan jumlah order tidak ikut turun.

**Expected impact:** Arah: nilai per order naik, sehingga pertumbuhan tidak lagi bergantung sepenuhnya pada penambahan order dan customer baru. Risiko: voucher, subsidi ongkir, dan potongan komisi adalah biaya atau pengurangan pendapatan bagi platform yang tidak bisa diukur dengan dataset ini (tidak ada data cost maupun komisi), dan ambang gratis ongkir bisa membuat customer menunda pembelian kecil.

---

## Insight 2 — 97% customer hanya belanja sekali, dan bahkan dengan pengamatan penuh 12 bulan hanya sekitar 3% yang kembali

**Finding:** Dari 86.960 customer di jendela analisis, 97,0% hanya pernah order satu kali, dan customer yang kembali (*returning*) hanya menyumbang 1,76% revenue. Rendahnya angka ini bukan sekadar karena customer belum sempat kembali: dari 13.592 customer yang order pertamanya Jan–Jun 2017 — semuanya bisa diamati penuh 12 bulan — hanya 3,32% yang order lagi di hari lain dalam 12 bulan.

**Evidence:**

- Repeat rate **3,0%**: hanya 2.609 dari 86.960 customer yang order dua kali atau lebih — `results/03_q4a_repeat_rate.csv` (Q4a).
- Distribusi order per customer: 84.351 customer (**97,0%**) order satu kali, 2.399 order dua kali, dan hanya 210 customer (0,24%) yang order tiga kali atau lebih. Maksimum 12 order oleh satu customer — `results/03_q4b_order_distribution.csv` (Q4b).
- **Kohort 12 bulan** — `results/03_q4d_cohort_12m_repeat.csv` (Q4d):
  - 13.592 customer dengan order pertama Jan–Jun 2017; jumlah ini sama dengan total customer baru Jan–Jun 2017 di Q4c. Order pertama paling lambat 30 Juni 2017, sehingga masa 12 bulan setiap customer berakhir paling lambat 30 Juni 2018 — masih di dalam jendela analisis.
  - Hanya 451 customer (**3,32%**) yang order lagi di hari berbeda dalam 12 bulan. Per bulan kohort, angkanya stabil di 2,70%–3,62%.
  - Jika order tambahan di hari yang sama dengan order pertama ikut dihitung — definisi yang sama dengan Q4a — angkanya 4,53%. Artinya lebih dari 95% customer tidak order lagi dalam setahun.
- Porsi revenue dari customer returning — `results/03_q4c_new_vs_returning.csv` (Q4c):
  - Seluruh jendela analisis: **1,76%** (R$ 217.797,09 dari R$ 12.342.450,49; jumlah kolom `returning_revenue` ÷ jumlah revenue new + returning).
  - Jan–Jul 2018: **2,17%**. Per bulan berkisar 1,62% (Februari 2018) s/d 2,96% (Juni 2018), dan 2,96% adalah angka tertinggi di seluruh jendela.
  - Setiap bulan di 2018 ada 5.878–6.842 customer baru, tetapi hanya 112–187 customer returning.

**Possible explanation (hipotesis):**

- Hipotesis "customer belum sempat kembali" sudah diuji dengan kohort di atas, dan hanya menjelaskan sebagian kecil. Waktu pengamatan memang menurunkan angka Q4a (3,0% untuk seluruh customer, dibanding 4,53% untuk kohort yang diamati penuh dengan definisi yang sama), tetapi levelnya tetap sangat rendah. [High confidence — diuji langsung dengan Q4d.]
- Banyak kategori besar adalah barang yang jarang dibeli ulang (misalnya `bed_bath_table`, `furniture_decor`, `watches_gifts`), sehingga siklus beli ulangnya bisa lebih panjang dari 12 bulan. Namun kategori dengan revenue terbesar, `health_beauty` (`results/02_q2_category.csv`), adalah barang habis pakai yang seharusnya sering dibeli ulang — jadi hipotesis ini tidak menjelaskan semuanya. [Low confidence — repeat rate per kategori belum dianalisis.] *Data yang dibutuhkan:* repeat rate per kategori pembelian pertama (bisa dihitung dari data yang sudah ada).
- Customer mungkin tidak punya alasan untuk kembali ke platform: mereka menemukan produk lewat pencarian harga, bukan karena hubungan dengan NusaMart, dan tidak ada program platform yang mengajak mereka kembali. [Low confidence — tidak ada data channel akuisisi maupun CRM.] *Data yang dibutuhkan:* channel akuisisi dan riwayat email/notifikasi.
- Pengalaman pengiriman yang buruk, misalnya keterlambatan, bisa menurunkan niat belanja lagi. [Low confidence] *Data yang dibutuhkan:* tanggal terima aktual vs estimasi (tersedia di tabel orders mentah, tetapi belum dimodelkan) dan data review (di luar scope).

**Recommendation:** **CRM / Marketing Manager** menjalankan program pembelian kedua dengan tuas platform — voucher platform yang berlaku untuk seller mana pun, notifikasi dan email dari platform, serta rekomendasi produk berdasarkan pembelian pertama — sebagai eksperimen: sebagian customer baru menerima program, sebagian lagi menjadi kelompok kontrol. **Head of Commercial** memakai hasilnya untuk menimbang ulang pembagian budget akuisisi vs retensi. *Metrik keberhasilan:* persentase customer baru yang order lagi di hari berbeda dalam periode tertentu setelah order pertamanya, dihitung per kohort dan dibanding kontrol (baseline 12 bulan: 3,32%, kohort Jan–Jun 2017), serta porsi revenue returning per bulan (baseline Jan–Jul 2018: 2,17%).

**Expected impact:** Arah: lebih banyak customer baru yang kembali dan porsi revenue returning naik, sehingga pertumbuhan tidak lagi hampir sepenuhnya bergantung pada akuisisi customer baru. Risiko: biaya voucher ditanggung platform dan tidak terukur tanpa data cost, dan insentif bisa saja hanya dinikmati customer yang sebenarnya akan kembali tanpa insentif.

---

## Insight 3 — 10% customer teratas menyumbang 41% revenue, tetapi hampir seluruhnya dari pembelian besar sekali jalan

**Finding:** Revenue sangat terkonsentrasi: 10% customer dengan belanja terbesar menyumbang 41,09% revenue. Namun kelompok ini bukan pelanggan setia — 91,99% revenue mereka berasal dari customer yang hanya belanja satu kali.

**Evidence:**

- Desil 1 (8.696 customer) = R$ 5.071.238,77 = **41,09%** revenue. 20% customer teratas menyumbang 56,62%, sedangkan separuh customer terbawah (desil 6–10) hanya 16,69% — `results/03_q5a_decile.csv` (Q5a).
- Rata-rata belanja per customer di desil 1 adalah R$ 583,17, sekitar 4,1× rata-rata seluruh customer (R$ 141,93 = total revenue ÷ total customer, `results/02_kpi01.csv`) — `results/03_q5c_decile_repeat.csv` (Q5c).
- Repeat rate desil 1 hanya **8,61%** (749 customer), dan **91,99%** revenue desil 1 berasal dari pembeli sekali. Di desil 10, repeat rate-nya 0,16% — Q5c.
- Pola yang sama terlihat di 10 customer terbesar: 9 dari 10 hanya punya satu order, dan yang terbesar belanja R$ 13.440,00 dalam satu order — `results/03_q5b_top_customers.csv` (Q5b).

**Possible explanation (hipotesis):**

- Konsentrasi kemungkinan didorong oleh produk berharga tinggi yang dibeli sekali, bukan oleh customer yang sering kembali. Sebagai gambaran di level kategori, harga rata-rata `computers` adalah R$ 1.122,85 per unit (`results/04_q6_volume_vs_value.csv`). [Medium confidence — konsisten dengan 91,99% revenue desil 1 yang berasal dari pembeli sekali, tetapi komposisi kategori per desil belum dianalisis.] *Data yang dibutuhkan:* revenue per kategori untuk setiap desil (bisa dihitung dari data yang sudah ada).
- Repeat rate desil 1 (8,61%) lebih tinggi daripada rata-rata (3,0%) sebagian karena efek mekanis: belanja dua kali otomatis menambah total revenue seseorang, sehingga pembeli berulang lebih mungkin masuk desil atas. [High confidence — konsekuensi dari cara desil dihitung, yaitu berdasarkan total revenue per customer.]

**Recommendation:** **CRM / Marketing Manager** bersama **Category Manager** memakai pembelian pertama yang bernilai tinggi sebagai pemicu kampanye pembelian kedua dengan tuas platform: fitur rekomendasi produk pelengkap (misalnya aksesori untuk barang yang baru dibeli, dari seller mana pun) dan voucher platform untuk pembelian berikutnya — alih-alih program poin loyalitas umum, karena kelompok bernilai tinggi justru belum loyal. Category Manager menyusun pemetaan kategori pelengkap yang dipakai fitur rekomendasi tersebut. *Metrik keberhasilan:* repeat rate desil 1 (baseline 8,61%) dan porsi revenue desil 1 yang berasal dari pembeli sekali (baseline 91,99%, arah yang diharapkan: turun), sambil memantau porsi revenue desil 1 (baseline 41,09%).

**Expected impact:** Arah: sebagian pembelian besar sekali jalan berubah menjadi hubungan berulang, sehingga ketergantungan revenue pada transaksi besar yang tidak berulang berkurang. Risiko: untuk barang tahan lama, customer mungkin memang tidak membutuhkan pembelian lanjutan, dan voucher untuk customer bernilai tinggi menjadi biaya platform yang bisa mahal.

---

## Insight 4 — Sembilan kategori besar (36% revenue) membebani customer dengan ongkir di atas rata-rata, kebanyakan karena harga barangnya murah, bukan karena ongkirnya mahal

**Finding:** Sembilan kategori yang revenue-nya di atas rata-rata kategori juga membebani customer dengan ongkir di atas rata-rata (freight burden di atas 16,57%), dan bersama-sama menyumbang 36,18% revenue. Pada delapan di antaranya, ongkir per unit sebenarnya tidak jauh dari rata-rata; bebannya menjadi tinggi karena harga barangnya di bawah rata-rata. Hanya `office_furniture` yang ongkir per unitnya memang mahal, sekitar 2× rata-rata.

**Evidence:**

- Q7 memilih kategori yang memenuhi **dua syarat sekaligus**: revenue di atas rata-rata kategori (≈ R$ 166.789,87 = total revenue ÷ 74 kategori, dari `results/02_kpi01.csv` dan `results/04_q6_volume_vs_value.csv`) **dan** freight burden di atas rata-rata keseluruhan 16,57%:

  | Kategori | Revenue | Freight burden | Harga rata-rata per unit | Ongkir per unit (≈) |
  |---|---|---|---|---|
  | bed_bath_table | R$ 962.064,68 | 19,49% | R$ 93,50 | R$ 18,22 |
  | sports_leisure | R$ 901.980,22 | 17,09% | R$ 113,56 | R$ 19,41 |
  | furniture_decor | R$ 665.068,62 | 23,55% | R$ 86,77 | R$ 20,43 |
  | housewares | R$ 555.578,26 | 23,17% | R$ 90,09 | R$ 20,87 |
  | garden_tools | R$ 452.820,70 | 20,45% | R$ 109,72 | R$ 22,44 |
  | telephony | R$ 273.059,03 | 23,58% | R$ 65,78 | R$ 15,51 |
  | office_furniture | R$ 260.094,56 | 25,05% | R$ 159,37 | R$ 39,92 |
  | stationery | R$ 208.343,04 | 20,34% | R$ 90,70 | R$ 18,45 |
  | pet_shop | R$ 186.397,89 | 18,75% | R$ 108,25 | R$ 20,30 |
  | **Total 9 kategori** | **R$ 4.465.407,00 (36,18% revenue)** | | | |
  | **Rata-rata seluruh produk** | | **16,57%** | **R$ 120,14** | **R$ 19,91** |

  Sumber: revenue dan freight burden dari `results/04_q7_high_burden_categories.csv`; harga rata-rata per unit dari `results/04_q6_volume_vs_value.csv`. Ongkir per unit ≈ freight burden × harga rata-rata per unit. Baris rata-rata: harga = total revenue ÷ unit terjual (`results/02_kpi01.csv`), ongkir per unit = 16,57% × harga tersebut.

- Dari tabel ini, 8 dari 9 kategori berharga di bawah rata-rata seluruh produk, dan ongkir per unit kedelapan kategori itu berkisar R$ 15,51–22,44, tidak jauh dari rata-rata R$ 19,91. Pengecualiannya `office_furniture`: harganya justru di atas rata-rata (R$ 159,37), tetapi ongkirnya ≈ R$ 39,92 per unit, sekitar 2× rata-rata.

**Possible explanation (hipotesis):**

- Pada barang murah, tarif ongkir kemungkinan punya komponen yang relatif tetap per pengiriman, sehingga porsinya terhadap harga menjadi besar walaupun ongkirnya sendiri biasa saja. [Medium confidence — konsisten dengan ongkir per unit yang mendekati rata-rata pada harga yang rendah.] *Data yang dibutuhkan:* struktur tarif kurir, serta perbandingan ongkir per item pada order berisi satu item vs banyak item (bisa dihitung dari data yang sudah ada).
- Ongkir `office_furniture` mahal kemungkinan karena ukuran dan berat barangnya. [Medium confidence — konsisten dengan ongkir per unit sekitar 2× rata-rata meskipun harganya lebih tinggi.] *Data yang dibutuhkan:* berat dan dimensi produk. Kolom ini ada di file products mentah, tetapi belum dimodelkan ke star schema.
- Beban ongkir yang tinggi bisa menahan pembelian di kategori-kategori ini. [Low confidence — dataset hanya berisi order yang sudah terjadi, tanpa data kunjungan atau keranjang yang ditinggalkan.]

**Recommendation:** **Category Manager** bersama **Operations / Logistics** memakai tuas platform untuk dua pola ini. (1) Untuk kategori berharga murah — mulai dari yang freight burden-nya tertinggi, yaitu `telephony` (23,58%), `furniture_decor` (23,55%), dan `housewares` (23,17%) — tampilkan rekomendasi "produk lain dari seller yang sama" supaya lebih banyak item masuk ke satu pengiriman (di marketplace, barang dari seller berbeda umumnya dikirim terpisah), uji gratis ongkir yang disubsidi platform untuk keranjang berisi beberapa item, dan beri insentif seperti potongan komisi bagi seller yang menawarkan ongkir gabungan. (2) Untuk `office_furniture`, uji subsidi ongkir platform yang terarah, ditambah insentif bagi seller yang ikut menanggung sebagian ongkir. *Metrik keberhasilan:* freight burden per kategori (baseline rata-rata 16,57%), unit per order, dan jumlah order di kategori tersebut, dibanding periode atau kelompok kontrol.

**Expected impact:** Arah: beban ongkir yang ditanggung customer di kategori-kategori ini turun mendekati rata-rata, dan — jika hipotesis tentang tertahannya pembelian benar — volume di kategori tersebut naik. Risiko: subsidi ongkir dan potongan komisi menjadi biaya platform yang tidak bisa diukur dengan dataset ini, dan ambang gratis ongkir bisa membuat sebagian customer menunda pembelian.

---

## Insight 5 — SP menyumbang 38% revenue dengan beban ongkir terendah; di luar SP customer menanggung ongkir jauh lebih berat

**Finding:** São Paulo (SP) adalah pasar inti: 37,82% revenue dan 41,44% order, dengan freight burden terendah dari 27 state (13,80%). Di state utara dan timur laut Brasil, freight burden mencapai sekitar 24–28%, dan ongkir per order diperkirakan sekitar 2,2–2,8× lebih mahal daripada di SP.

**Evidence:**

- SP: revenue R$ 4.667.853,42 (**37,82%**), 37.242 order (**41,44%** dari 89.860 order), freight burden **13,80%** — terendah dari 27 state — dan AOV R$ 125,34, juga yang terendah. SP, RJ, dan MG bersama-sama menyumbang 63,02% revenue — `results/02_q3_region.csv` (Q3).
- Enam freight burden tertinggi: RR 27,83%, MA 26,25%, RO 25,26%, SE 24,38%, AM 24,33%, PI 23,88% — Q3.
- Ongkir per order (≈ freight burden × revenue ÷ order, dari Q3): SP ≈ R$ 17,30; AM ≈ R$ 37,57; MA ≈ R$ 43,04; RO ≈ R$ 46,11; RR ≈ R$ 48,83. Artinya sekitar 2,2–2,8× SP.
- AOV di beberapa state jauh berada di atas SP, misalnya PB R$ 214,89, AP R$ 202,78, AL R$ 201,45, dan AC R$ 201,09 — Q3.
- Catatan: state kecil hanya punya sedikit order (RR 40, AP 65, AC 77), sehingga angkanya mudah berfluktuasi.

**Possible explanation (hipotesis):**

- Seller kemungkinan terkonsentrasi di SP atau sekitarnya, sehingga jarak kirim ke customer SP pendek dan ongkirnya murah. [Medium confidence — SP adalah pusat ekonomi Brasil, tetapi lokasi seller ada di tabel sellers yang berada di luar scope project.] *Data yang dibutuhkan:* lokasi seller.
- AOV di state jauh mungkin lebih tinggi karena customer di sana hanya belanja jika barangnya cukup mahal untuk "sepadan" dengan ongkir, sehingga belanja kecil tidak jadi dilakukan. [Low confidence — dataset tidak berisi data keranjang yang ditinggalkan atau kunjungan tanpa pembelian.]

**Recommendation:** **Operations / Logistics** bersama **Head of Commercial** menjalankan pilot subsidi ongkir platform — atau ambang gratis ongkir yang dibiayai platform — di satu atau dua state yang ongkirnya tinggi tetapi volumenya cukup untuk diukur, misalnya BA (3,83% revenue, 3.094 order, freight burden 19,59%) atau PE (1.504 order, freight burden 22,30%), dengan state lain sebagai pembanding. SP tetap dijaga sebagai pasar inti yang paling murah dilayani, dan program pembelian kedua (Insight 2) paling masuk akal dimulai di sana karena basis customer-nya terbesar. *Metrik keberhasilan:* jumlah order dan revenue state pilot vs pembanding, freight burden state pilot, dan porsi revenue di luar SP (baseline 62,18% = 100% − 37,82%).

**Expected impact:** Arah: porsi revenue dari luar SP naik, sehingga ketergantungan pada satu state berkurang. Risiko: subsidi ongkir adalah biaya platform yang tidak terukur dengan dataset ini, dan pilot di state kecil rawan menghasilkan angka yang bising karena sampelnya sedikit.

---

## Insight 6 — Mix kategori bergeser ke health_beauty dan watches_gifts, sementara cool_stuff kehilangan lebih dari separuh porsinya

**Finding:** Dengan periode sebanding (Jan–Jul 2017 vs Jan–Jul 2018), `health_beauty` naik ke peringkat #1 dan `watches_gifts` melonjak dari #6 ke #2. Sebaliknya `cool_stuff` turun dari #5 ke #10: revenue-nya hanya naik 26,1% ketika total revenue naik 161,6%, sehingga porsinya turun lebih dari separuh (6,89% → 3,32%).

**Evidence:**

- Semua kategori yang share-nya berubah minimal 1 pp — `results/02_q2c_category_fair_period.csv` (Q2c, share dihitung dalam masing-masing periode Jan–Jul; total revenue kedua periode sama persis dengan Q1c):

  | Kategori | Share Jan–Jul 2017 | Share Jan–Jul 2018 | Perubahan | Peringkat |
  |---|---|---|---|---|
  | watches_gifts | 6,76% | 9,69% | +2,92 pp | #6 → #2 |
  | health_beauty | 7,98% | 9,97% | +2,00 pp | #2 → #1 |
  | baby | 2,00% | 3,60% | +1,59 pp | #15 → #9 |
  | construction_tools_construction | 0,06% | 1,57% | +1,51 pp | #49 → #18 |
  | small_appliances | 2,53% | 1,25% | −1,28 pp | #14 → #21 |
  | garden_tools | 4,72% | 3,07% | −1,65 pp | #8 → #11 |
  | toys | 4,13% | 2,37% | −1,76 pp | #12 → #12 |
  | perfumery | 4,46% | 2,34% | −2,12 pp | #9 → #13 |
  | cool_stuff | 6,89% | 3,32% | −3,57 pp | #5 → #10 |

- `cool_stuff`: revenue R$ 168.041,86 → R$ 211.948,81 (+26,1%), sementara total revenue Jan–Jul naik 161,6% (Q1c).
- **Kenapa tidak memakai Q2b langsung:** Q2b membandingkan 2017 setahun penuh dengan 2018 yang hanya sampai Juli, padahal 28,74% revenue 2017 jatuh di November–Desember (`results/02_q1_monthly.csv`). Akibatnya kategori musiman terdistorsi:
  - `toys` — 39,35% revenue 2017-nya jatuh di Nov–Des. Di Q2b share-nya tampak turun 2,65 pp (5,02% → 2,37%, peringkat #8 → #12, `results/02_q2b_category_year.csv`), padahal dengan periode sebanding penurunannya 1,76 pp dan peringkatnya tetap #12.
  - `watches_gifts` — di Q2b tampak stabil di peringkat #2 → #2, padahal dengan periode sebanding naik dari #6 ke #2.
  - Penurunan `cool_stuff` tidak bisa dijelaskan oleh efek Nov–Des: perbandingan Q2c sudah mengeluarkan kedua bulan itu, dan porsi Nov–Des `cool_stuff` sendiri (24,44% revenue 2017-nya) pun di bawah rata-rata 28,74%.

**Possible explanation (hipotesis):**

- Kemungkinan ada perubahan di sisi pasokan: seller dan produk baru masuk ke kategori yang tumbuh, atau seller `cool_stuff` berkurang. Sebagai petunjuk, `construction_tools_construction` muncul hampir dari nol dalam beberapa bulan (#49 → #18, dengan 66,72% revenue 2017-nya baru terjadi di Nov–Des). [Low confidence — data seller berada di luar scope.] *Data yang dibutuhkan:* jumlah seller dan produk aktif per kategori per bulan.
- Perubahan harga atau promosi di kategori tertentu. [Low confidence — tidak ada data promo.]
- Pergeseran selera customer. [Low confidence — tidak ada data survei maupun perilaku pencarian.]
- Awal 2017 masih fase awal dengan basis kecil, sehingga mix kategori Jan–Jul 2017 bisa sangat dipengaruhi oleh segelintir seller. [Medium confidence]

**Recommendation:** **Category Manager**: (1) investigasi `cool_stuff` sebelum mengambil tindakan — bandingkan jumlah seller aktif, jumlah produk yang aktif terjual, unit terjual, dan harga rata-rata 2017 vs 2018 (data seller tersedia di sistem platform walaupun di luar scope project ini), untuk mengetahui apakah penurunannya berasal dari sisi pasokan atau permintaan; (2) tambah pasokan di kategori yang tumbuh (`health_beauty`, `watches_gifts`, `baby`) lewat rekrutmen seller baru dan insentif seller seperti potongan komisi di bulan-bulan awal, lalu tonjolkan kategori tersebut lewat fitur rekomendasi dan halaman kategori; (3) wajibkan semua laporan perbandingan tahunan memakai periode sebanding. *Metrik keberhasilan:* share kategori per periode sebanding, pertumbuhan revenue tiap kategori dibanding pertumbuhan total platform, dan jumlah seller aktif di kategori sasaran.

**Expected impact:** Arah: keputusan assortment didasarkan pada pergeseran yang nyata, bukan artefak musiman, dan pasokan di kategori yang tumbuh bertambah. Risiko: jika penurunan `cool_stuff` berasal dari sisi permintaan, upaya menambah pasokan di sana bisa sia-sia — karena itu investigasi harus dilakukan lebih dulu — dan potongan komisi mengurangi pendapatan platform.

---

## Catatan metodologi

### Data terpotong di Agustus 2018 dan perubahan jendela analisis

- **Keputusan awal.** Di Fase 2, jendela analisis ditetapkan 2017-01 s/d 2018-08. Kelengkapan bulan waktu itu hanya dicek dari total order per bulan dan porsi order delivered, dan Agustus 2018 lolos kedua cek (6.351 order delivered, porsi delivered 97,5%, `results/02_q1d_orders_all_status_monthly.csv`).
- **Penemuan.** Saat menguji right-censoring untuk Insight 1 di Fase 5, data harian menunjukkan order Agustus 2018 menyusut tajam setelah tanggal 21: rata-rata 276,7 order per hari (semua status) pada 1–21 Agustus, tetapi hanya 702 order selama 22–31 Agustus (70,2 per hari), sampai tinggal 1 order pada 31 Agustus. Senin 20 Agustus masih 256 order, Senin 27 Agustus tinggal 67 (`results/02_q1e_orders_daily_aug_sep_2018.csv`). Penyebabnya kemungkinan besar berakhirnya pengumpulan data, bukan turunnya permintaan. [High confidence — penurunan 74% antara dua hari Senin berturut-turut lalu hampir nol order sesudahnya tidak lazim untuk permintaan riil, dan September–Oktober hanya berisi 20 order. Kriteria pengambilan data Olist sendiri tidak didokumentasikan.]
- **Keputusan baru.** Jendela analisis dipendekkan menjadi **2017-01 s/d 2018-07** (19 bulan), dan aturan kelengkapan bulan ditambah satu cek: **bulan terakhir jendela wajib dicek per hari** — rata-rata order harian 7 hari terakhirnya minimal 80% dari rata-rata hari-hari sebelumnya di bulan itu (`notebooks/01_data_cleaning.ipynb`, bagian 6). Juli 2018 lolos cek ini dengan rasio 1,25, sedangkan Agustus 2018 gagal dengan rasio 0,15.
- **Dampak.** Seluruh pipeline dijalankan ulang (notebook, database, query `02`–`05`). Jumlah order delivered yang dikecualikan naik menjadi 6.618 dari 96.478 (6,86%; notebook bagian 11). KPI notebook, SQL KPI-01, dan `sql/05_kpi_reference.sql` kembali cocok persis. **Arah kesimpulan keenam insight tidak berubah.** Angka pertumbuhan Q1c justru naik, karena Agustus 2018 yang terpotong sebelumnya ikut menekan total 2018. Rincian yang berubah: urutan tiga kategori murah dengan beban ongkir tertinggi di Insight 4, serta `housewares` dan `bed_bath_table` yang tidak lagi termasuk kategori yang share-nya berubah minimal 1 pp di Insight 6.
- **Pencegahan.** Q1c dan Q2c kini membaca bulan terakhir jendela langsung dari `dim_date`, tidak diketik manual, sehingga perbandingan periode sebanding otomatis ikut menyesuaikan jika jendela berubah lagi.

### Kandidat insight yang disesuaikan

- **Insight 1** — klaim awal "growth hanya dari volume" dilunakkan menjadi "hampir seluruhnya", karena AOV tetap naik sedikit (+0,3%). Klaim "volume 2018 mulai mendatar" **dihapus**: right-censoring status pengiriman ternyata tidak berpengaruh, tetapi laju harian awal Agustus justru tertinggi sepanjang 2018, sehingga tidak ada pola mendatar yang jelas.
- **Insight 2** — perkiraan awal "returning revenue 2–3%" dikoreksi dengan angka tepat (1,76% untuk seluruh jendela, 2,17% untuk Jan–Jul 2018). Ditambah **analisis kohort 12 bulan (Q4d)**, yang membuktikan rendahnya repeat rate bukan sekadar karena customer belum sempat kembali.
- **Insight 3** — Q5a hanya menunjukkan konsentrasi revenue, bukan apakah customer teratas adalah pembeli berulang. Sepuluh customer di Q5b terlalu sedikit untuk digeneralisasi ke 8.696 customer desil 1, sehingga ditambahkan query **Q5c**.
- **Insight 4** — "ongkir berat" ternyata untuk sebagian besar kategori bukan berarti ongkirnya mahal. Delapan dari sembilan kategori punya ongkir per unit yang mendekati rata-rata, tetapi harga barangnya murah.
- **Insight 6** — Q2b bias musiman (2017 setahun penuh vs 2018 yang hanya sampai Juli), sehingga ditambahkan query **Q2c** dengan periode sebanding.
- **Semua rekomendasi** hanya memakai tuas yang dikendalikan platform. Di marketplace, harga dan ongkir ditentukan seller dan kurir, sehingga tindakan seperti "bundling" atau "meninjau tarif kurir" diganti dengan fitur rekomendasi, voucher platform, subsidi ongkir platform, dan insentif seller.

---

## Ringkasan rekomendasi untuk manajemen

| Prioritas | Rekomendasi (tuas platform) | Stakeholder | Metrik keberhasilan | Insight |
|---|---|---|---|---|
| 1 | Program pembelian kedua: voucher platform, notifikasi/email platform, dan rekomendasi produk berdasarkan pembelian pertama (termasuk pemicu khusus setelah pembelian bernilai tinggi), diuji dengan kelompok kontrol | CRM / Marketing Manager, Category Manager | Repeat per kohort (baseline 12 bulan: 3,32%); porsi revenue returning (baseline Jan–Jul 2018: 2,17%); repeat rate desil 1 (baseline 8,61%) | 2, 3 |
| 2 | Fitur rekomendasi produk pelengkap, voucher platform untuk keranjang multi-item, ambang gratis ongkir bersubsidi platform, dan insentif bagi seller yang menawarkan paket | Head of Commercial | AOV (baseline R$ 137,35); unit per order (baseline 1,14) | 1 |
| 3 | Rekomendasi "produk lain dari seller yang sama", gratis ongkir bersubsidi platform untuk keranjang multi-item, subsidi ongkir terarah untuk `office_furniture`, dan insentif bagi seller yang ikut menanggung ongkir | Category Manager, Operations / Logistics | Freight burden per kategori (baseline rata-rata 16,57%) | 4 |
| 4 | Pilot subsidi ongkir platform di state berongkir tinggi dengan volume cukup (mis. BA atau PE) | Operations / Logistics, Head of Commercial | Order dan revenue state pilot vs pembanding; porsi revenue di luar SP (baseline 62,18%) | 5 |
| 5 | Investigasi penurunan `cool_stuff`; rekrut seller dan beri insentif seller di kategori yang tumbuh; wajibkan periode sebanding di laporan tahunan | Category Manager | Share kategori per periode sebanding; pertumbuhan kategori vs platform; seller aktif di kategori sasaran | 6 |

**Dasar urutan prioritas.** Retensi di urutan pertama karena menyangkut hampir seluruh basis customer (97,0% hanya belanja sekali, dan dengan pengamatan penuh 12 bulan pun hanya 3,32% yang kembali), sekaligus menjawab temuan konsentrasi revenue. Nilai per order di urutan kedua karena AOV nyaris tidak naik (+0,3%), sehingga menjadi pengungkit pertumbuhan berikutnya yang paling jelas. Isu ongkir di urutan ketiga dan keempat karena menyangkut 36,18% revenue (kategori) dan pertumbuhan di luar SP, tetapi biaya subsidinya belum bisa diukur tanpa data cost. Pergeseran kategori di urutan terakhir karena langkah pertamanya adalah investigasi, bukan eksekusi. Urutan ini adalah penilaian, bukan hasil perhitungan.

---

## Keterbatasan analisis

- **Tidak ada data cost, profit, maupun komisi.** Freight burden hanyalah proxy beban ongkir yang dibayar customer relatif terhadap harga barang — bukan profit dan bukan biaya perusahaan. Karena itu dampak finansial rekomendasi bagi platform (biaya voucher, subsidi ongkir, potongan komisi) tidak bisa dihitung.
- **Tidak ada data promo, channel marketing, kompetitor, kunjungan/konversi, maupun review.** Semua penyebab di dokumen ini adalah hipotesis, dan dampak rekomendasi hanya ditulis sebagai arah. Rekomendasi sebaiknya diuji lewat eksperimen terkontrol sebelum diterapkan secara luas.
- **Jendela analisis hanya 19 bulan (2017-01 s/d 2018-07).** Bulan di ujung dataset dikecualikan karena datanya tidak lengkap, yaitu 6.618 order delivered atau 6,86% dari seluruh order delivered (`notebooks/01_data_cleaning.ipynb`, bagian 11). Agustus 2018 ikut dikecualikan walaupun 1–21 Agustus sebenarnya lengkap, karena analisis dilakukan per bulan. Perbandingan antartahun memakai periode sebanding Jan–Jul (Q1c, Q2c).
- **Musim dan tren tidak bisa dipisahkan.** 2017 adalah tahun awal dengan basis yang masih tumbuh cepat, dan 2018 di jendela analisis hanya tujuh bulan, sehingga tidak ada tahun "normal" sebagai pembanding musiman.
- **Anomali pertengahan Juli 2018.** Pada 8–14 Juli order harian turun ke rata-rata 138,7 per hari sebelum pulih penuh, dan 7 hari terakhir Juli justru termasuk yang tertinggi di bulan itu (notebook bagian 6). Penyebabnya tidak diketahui. Juli tetap dipakai karena tidak menunjukkan tanda data terpotong.
- **Retensi hanya bisa diamati maksimal 12 bulan.** Kohort Q4d mengatasi masalah customer yang belum sempat kembali, tetapi siklus beli ulang barang tahan lama bisa lebih panjang dari 12 bulan, dan repeat rate Q4a hanya menghitung order di dalam jendela analisis.
- **Cakupan dataset tidak dijelaskan.** Dataset memuat 99.441 order untuk periode 2016–2018 (`notebooks/01_data_cleaning.ipynb`, bagian 1), tanpa penjelasan apakah ini seluruh transaksi atau sampel, maupun kriteria pengambilannya. [Medium confidence — dokumentasi dataset tidak menjelaskan metodenya.] Penyusutan order di akhir Agustus 2018 menunjukkan kriteria itu memengaruhi isi data. Karena itu angka volume absolut sebaiknya tidak dibaca sebagai ukuran pasar.
- **Lokasi seller di luar scope.** Tabel sellers tidak dipakai, sehingga penjelasan berbasis jarak kirim tidak bisa diverifikasi. Berat dan dimensi produk ada di file mentah, tetapi belum dimodelkan.
- **State kecil punya sampel kecil** (misalnya RR hanya 40 order), sehingga angkanya mudah berfluktuasi.
- **Korelasi bukan sebab-akibat.** Pola yang muncul bersamaan — misalnya AOV tinggi dan ongkir tinggi di state jauh — belum tentu saling menyebabkan.
