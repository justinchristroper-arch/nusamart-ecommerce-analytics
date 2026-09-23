# Key Insights & Recommendations — NusaMart

> **Aturan penulisan**
> - *Finding* dan *Evidence* hanya berisi fakta dari hasil query, lengkap dengan angka dan file sumbernya.
> - *Possible explanation* selalu ditandai sebagai **hipotesis**, dengan label keyakinan dan data yang dibutuhkan untuk membuktikannya.
> - *Recommendation* hanya memakai tuas yang dikendalikan platform (subsidi ongkir platform, voucher platform, insentif seller, fitur platform), karena di marketplace harga dan ongkir ditentukan seller dan kurir.
> - *Expected impact* ditulis sebagai arah dampak, tanpa angka.
> - Target: 5–7 insight. Kualitas lebih penting dari jumlah.

## Cara membaca dokumen ini

- Semua angka berasal dari file di folder `results/`, yaitu hasil query di `sql/` (dan satu script pemeriksa di `src/`). Setiap angka menyebut file sumbernya. Angka yang dihitung dari kolom sebuah file (bukan dibaca langsung) diberi keterangan cara hitungnya.
- Periode: **jendela analisis 2017-01 s/d 2018-08** (bulan yang datanya lengkap), kecuali disebut lain. Perbandingan antartahun memakai **periode sebanding Jan–Agu**, karena 2018 hanya tersedia sampai Agustus. Catatan: pemeriksaan harian menunjukkan jumlah order yang menyusut tajam pada 22–31 Agustus 2018 — lihat Insight 1 dan bagian Keterbatasan.
- Mata uang: Real Brasil (R$). *pp* = poin persentase.
- *Freight burden* = Σ ongkir ÷ Σ harga barang. Ongkir di dataset ini **dibayar oleh customer**, sehingga angka ini mengukur beban ongkir yang ditanggung customer relatif terhadap harga barang. Ini **proxy** — bukan profit, dan bukan biaya perusahaan.

---

## Insight 1 — Pertumbuhan hampir seluruhnya dari volume, sementara nilai per order tidak ikut naik

**Finding:** Revenue Jan–Agu 2018 naik 141,1% dibanding Jan–Agu 2017, tetapi nilai rata-rata per order (AOV) nyaris tidak berubah (+0,5%). Pertumbuhan datang dari bertambahnya order dan customer, bukan dari belanja yang lebih besar per order. Laju pertumbuhan YoY melambat tajam sepanjang 2018, tetapi data yang ada belum cukup untuk menyimpulkan apakah volume order sudah mendatar.

**Evidence:**

- Perbandingan periode sebanding — `results/02_q1c_fair_period_comparison.csv` (Q1c):

  | | Jan–Agu 2017 | Jan–Agu 2018 | Perubahan |
  |---|---|---|---|
  | Revenue | R$ 2.993.456,13 | R$ 7.218.125,12 | +141,1% |
  | Order | 21.998 | 52.783 | +139,9% |
  | Customer | 21.404 | 51.612 | +141,1% |
  | AOV | R$ 136,08 | R$ 136,75 | +0,5% |

- Revenue dan customer sama-sama tumbuh +141,1% bukan karena salah salin. Revenue per customer praktis tidak berubah: **R$ 139,85 di kedua periode**, dengan selisih kurang dari satu sen (revenue ÷ customer dari file yang sama). Karena revenue = customer × revenue per customer, keduanya otomatis tumbuh hampir persis sama.
- Pertumbuhan YoY per bulan melambat tajam: **+727,1% (Januari 2018) → +80,2% (Juli 2018)**, bulan lengkap terakhir — `results/02_q1b_yoy.csv` (Q1b).
- **Cek right-censoring** — `results/02_q1d_orders_all_status_monthly.csv`. Order non-delivered tidak dimuat ke star schema, jadi hitungan ini dibuat dari file order mentah lewat `src/right_censoring_check.py`:
  - Order **semua status** juga tidak naik dari Januari ke Juli 2018 (7.269 → 6.292), sejalan dengan order delivered (7.069 → 6.159).
  - Order yang belum final (masih diproses atau dikirim) hanya 0,75%–2,29% per bulan di 2018 (46–165 order), dan di Agustus justru rendah (1,07%). Jadi bulan-bulan akhir tidak tampak lebih kecil karena ordernya belum sempat delivered.
- **Namun order harian menyusut tajam di akhir Agustus 2018** — `results/02_q1e_orders_daily_aug_sep_2018.csv`. Rata-rata 276,7 order per hari (semua status) pada 1–21 Agustus, tetapi hanya 702 order selama 22–31 Agustus (70,2 per hari), menyusut sampai 1 order pada 31 Agustus. Senin 20 Agustus masih 256 order, Senin 27 Agustus tinggal 67 (turun 74%). September–Oktober hanya berisi 20 order (`02_q1d`). Karena itu total Agustus (6.351 order delivered) tidak bisa dipakai sebagai bukti tren, dan pertumbuhan Q1c di atas cenderung terlalu rendah.
- Laju order harian 2018 (semua status; order per bulan ÷ jumlah hari, dari `02_q1d`): 231–240 order per hari di Jan–Apr, 222 di Mei, 203–206 di Jun–Jul, lalu 277 di 1–21 Agustus. Volume turun di pertengahan tahun lalu naik lagi — bukan pola mendatar yang jelas.
- AOV bulanan hanya bergerak di rentang R$ 124,38–149,06 (2017) dan R$ 126,08–144,84 (2018), tanpa tren naik — `results/02_q1_monthly.csv`.

**Possible explanation (hipotesis):**

- Angka +141,1% sebagian besar mencerminkan fase awal bisnis, bukan percepatan di 2018. Januari 2017 baru berisi 750 order (`results/02_q1_monthly.csv`), sehingga pembanding 2017 masih sangat kecil. [High confidence — basis yang kecil dan YoY yang terus melambat terlihat langsung di data.]
- Penyusutan order di 22–31 Agustus 2018 kemungkinan berasal dari berakhirnya pengumpulan data, bukan dari turunnya permintaan. [High confidence — penurunan 74% antara dua hari Senin berturut-turut, lalu hampir nol order sesudahnya, tidak lazim untuk permintaan riil. Kriteria pengambilan data Olist sendiri tidak didokumentasikan.]
- Turunnya laju harian di Jun–Jul dan lonjakan di awal Agustus bisa jadi pola musiman, misalnya menjelang Hari Ayah di Brasil (Minggu kedua Agustus, yaitu 12 Agustus 2018), bukan perubahan tren. [Low confidence — hanya ada satu periode 2018 dan tidak ada data kalender promo.] *Data yang dibutuhkan:* minimal dua tahun penuh dan kalender kampanye.
- AOV mungkin datar karena belum ada mekanisme di tingkat platform yang mendorong belanja lebih besar per order, seperti rekomendasi produk pelengkap atau voucher untuk keranjang multi-item. [Low confidence — dataset tidak memuat data promo atau fitur apa pun.] *Data yang dibutuhkan:* histori promo platform dan log fitur rekomendasi.

**Recommendation:** **Head of Commercial**, bersama tim produk platform, membuka pengungkit pertumbuhan kedua selain volume dengan tuas yang dikendalikan platform, diuji sebagai eksperimen terkontrol: (1) fitur rekomendasi produk pelengkap ("sering dibeli bersama") di halaman produk dan keranjang; (2) voucher platform untuk keranjang berisi beberapa item; (3) ambang gratis ongkir yang disubsidi platform; (4) insentif bagi seller yang menawarkan paket produk, misalnya potongan komisi. *Metrik keberhasilan:* AOV (baseline jendela analisis R$ 137,00) dan unit per order (baseline 1,14 = 109.880 unit ÷ 96.211 order, `results/02_kpi01.csv`) di grup eksperimen dibanding grup kontrol, sambil memastikan jumlah order tidak ikut turun.

**Expected impact:** Arah: nilai per order naik, sehingga pertumbuhan tidak lagi bergantung sepenuhnya pada penambahan order dan customer baru. Risiko: voucher, subsidi ongkir, dan potongan komisi adalah biaya atau pengurangan pendapatan bagi platform yang tidak bisa diukur dengan dataset ini (tidak ada data cost maupun komisi), dan ambang gratis ongkir bisa membuat customer menunda pembelian kecil.

---

## Insight 2 — 97% customer hanya belanja sekali, dan bahkan dengan pengamatan penuh 12 bulan hanya sekitar 3% yang kembali

**Finding:** Dari 93.104 customer di jendela analisis, 97,0% hanya pernah order satu kali, dan customer yang kembali (*returning*) hanya menyumbang 1,79% revenue. Rendahnya angka ini bukan sekadar karena customer belum sempat kembali: dari 13.592 customer yang order pertamanya Jan–Jun 2017 — semuanya bisa diamati penuh 12 bulan — hanya 3,32% yang order lagi di hari lain dalam 12 bulan.

**Evidence:**

- Repeat rate **3,0%**: hanya 2.789 dari 93.104 customer yang order dua kali atau lebih — `results/03_q4a_repeat_rate.csv` (Q4a).
- Distribusi order per customer: 90.315 customer (**97,0%**) order satu kali, 2.562 order dua kali, dan hanya 227 customer (0,24%) yang order tiga kali atau lebih. Maksimum 15 order oleh satu customer — `results/03_q4b_order_distribution.csv` (Q4b).
- **Kohort 12 bulan** — `results/03_q4d_cohort_12m_repeat.csv` (Q4d):
  - 13.592 customer dengan order pertama Jan–Jun 2017; jumlah ini sama dengan total customer baru Jan–Jun 2017 di Q4c. Order pertama paling lambat 30 Juni 2017, sehingga masa 12 bulan setiap customer berakhir paling lambat 30 Juni 2018 — sebelum Agustus 2018 yang tidak lengkap.
  - Hanya 451 customer (**3,32%**) yang order lagi di hari berbeda dalam 12 bulan. Per bulan kohort, angkanya stabil di 2,70%–3,62%.
  - Jika order tambahan di hari yang sama dengan order pertama ikut dihitung — definisi yang sama dengan Q4a — angkanya 4,53%. Artinya lebih dari 95% customer tidak order lagi dalam setahun.
- Porsi revenue dari customer returning — `results/03_q4c_new_vs_returning.csv` (Q4c):
  - Seluruh jendela analisis: **1,79%** (R$ 236.314,65 dari R$ 13.181.027,13; jumlah kolom `returning_revenue` ÷ jumlah revenue new + returning).
  - Jan–Agu 2018: **2,17%**. Per bulan berkisar 1,62% (Februari 2018) s/d 2,96% (Juni 2018), dan 2,96% adalah angka tertinggi di seluruh jendela.
  - Setiap bulan di 2018 ada 5.878–6.842 customer baru, tetapi hanya 112–187 customer returning.

**Possible explanation (hipotesis):**

- Hipotesis "customer belum sempat kembali" sudah diuji dengan kohort di atas, dan hanya menjelaskan sebagian kecil. Waktu pengamatan memang menurunkan angka Q4a (3,0% untuk seluruh customer, dibanding 4,53% untuk kohort yang diamati penuh dengan definisi yang sama), tetapi levelnya tetap sangat rendah. [High confidence — diuji langsung dengan Q4d.]
- Banyak kategori besar adalah barang yang jarang dibeli ulang (misalnya `bed_bath_table`, `furniture_decor`, `watches_gifts`), sehingga siklus beli ulangnya bisa lebih panjang dari 12 bulan. Namun kategori dengan revenue terbesar, `health_beauty` (`results/02_q2_category.csv`), adalah barang habis pakai yang seharusnya sering dibeli ulang — jadi hipotesis ini tidak menjelaskan semuanya. [Low confidence — repeat rate per kategori belum dianalisis.] *Data yang dibutuhkan:* repeat rate per kategori pembelian pertama (bisa dihitung dari data yang sudah ada).
- Customer mungkin tidak punya alasan untuk kembali ke platform: mereka menemukan produk lewat pencarian harga, bukan karena hubungan dengan NusaMart, dan tidak ada program platform yang mengajak mereka kembali. [Low confidence — tidak ada data channel akuisisi maupun CRM.] *Data yang dibutuhkan:* channel akuisisi dan riwayat email/notifikasi.
- Pengalaman pengiriman yang buruk, misalnya keterlambatan, bisa menurunkan niat belanja lagi. [Low confidence] *Data yang dibutuhkan:* tanggal terima aktual vs estimasi (tersedia di tabel orders mentah, tetapi belum dimodelkan) dan data review (di luar scope).

**Recommendation:** **CRM / Marketing Manager** menjalankan program pembelian kedua dengan tuas platform — voucher platform yang berlaku untuk seller mana pun, notifikasi dan email dari platform, serta rekomendasi produk berdasarkan pembelian pertama — sebagai eksperimen: sebagian customer baru menerima program, sebagian lagi menjadi kelompok kontrol. **Head of Commercial** memakai hasilnya untuk menimbang ulang pembagian budget akuisisi vs retensi. *Metrik keberhasilan:* persentase customer baru yang order lagi di hari berbeda dalam periode tertentu setelah order pertamanya, dihitung per kohort dan dibanding kontrol (baseline 12 bulan: 3,32%, kohort Jan–Jun 2017), serta porsi revenue returning per bulan (baseline Jan–Agu 2018: 2,17%).

**Expected impact:** Arah: lebih banyak customer baru yang kembali dan porsi revenue returning naik, sehingga pertumbuhan tidak lagi hampir sepenuhnya bergantung pada akuisisi customer baru. Risiko: biaya voucher ditanggung platform dan tidak terukur tanpa data cost, dan insentif bisa saja hanya dinikmati customer yang sebenarnya akan kembali tanpa insentif.

---

## Insight 3 — 10% customer teratas menyumbang 41% revenue, tetapi hampir seluruhnya dari pembelian besar sekali jalan

**Finding:** Revenue sangat terkonsentrasi: 10% customer dengan belanja terbesar menyumbang 41,10% revenue. Namun kelompok ini bukan pelanggan setia — 91,97% revenue mereka berasal dari customer yang hanya belanja satu kali.

**Evidence:**

- Desil 1 (9.311 customer) = R$ 5.417.492,73 = **41,10%** revenue. 20% customer teratas menyumbang 56,62%, sedangkan separuh customer terbawah (desil 6–10) hanya 16,69% — `results/03_q5a_decile.csv` (Q5a).
- Rata-rata belanja per customer di desil 1 adalah R$ 581,84, sekitar 4,1× rata-rata seluruh customer (R$ 141,57 = total revenue ÷ total customer, `results/02_kpi01.csv`) — `results/03_q5c_decile_repeat.csv` (Q5c).
- Repeat rate desil 1 hanya **8,59%** (800 customer), dan **91,97%** revenue desil 1 berasal dari pembeli sekali. Di desil 10, repeat rate-nya 0,17% — Q5c.
- Pola yang sama terlihat di 10 customer terbesar: 9 dari 10 hanya punya satu order, dan yang terbesar belanja R$ 13.440,00 dalam satu order — `results/03_q5b_top_customers.csv` (Q5b).

**Possible explanation (hipotesis):**

- Konsentrasi kemungkinan didorong oleh produk berharga tinggi yang dibeli sekali, bukan oleh customer yang sering kembali. Sebagai gambaran di level kategori, harga rata-rata `computers` adalah R$ 1.098,92 per unit (`results/04_q6_volume_vs_value.csv`). [Medium confidence — konsisten dengan 91,97% revenue desil 1 yang berasal dari pembeli sekali, tetapi komposisi kategori per desil belum dianalisis.] *Data yang dibutuhkan:* revenue per kategori untuk setiap desil (bisa dihitung dari data yang sudah ada).
- Repeat rate desil 1 (8,59%) lebih tinggi daripada rata-rata (3,0%) sebagian karena efek mekanis: belanja dua kali otomatis menambah total revenue seseorang, sehingga pembeli berulang lebih mungkin masuk desil atas. [High confidence — konsekuensi dari cara desil dihitung, yaitu berdasarkan total revenue per customer.]

**Recommendation:** **CRM / Marketing Manager** bersama **Category Manager** memakai pembelian pertama yang bernilai tinggi sebagai pemicu kampanye pembelian kedua dengan tuas platform: fitur rekomendasi produk pelengkap (misalnya aksesori untuk barang yang baru dibeli, dari seller mana pun) dan voucher platform untuk pembelian berikutnya — alih-alih program poin loyalitas umum, karena kelompok bernilai tinggi justru belum loyal. Category Manager menyusun pemetaan kategori pelengkap yang dipakai fitur rekomendasi tersebut. *Metrik keberhasilan:* repeat rate desil 1 (baseline 8,59%) dan porsi revenue desil 1 yang berasal dari pembeli sekali (baseline 91,97%, arah yang diharapkan: turun), sambil memantau porsi revenue desil 1 (baseline 41,10%).

**Expected impact:** Arah: sebagian pembelian besar sekali jalan berubah menjadi hubungan berulang, sehingga ketergantungan revenue pada transaksi besar yang tidak berulang berkurang. Risiko: untuk barang tahan lama, customer mungkin memang tidak membutuhkan pembelian lanjutan, dan voucher untuk customer bernilai tinggi menjadi biaya platform yang bisa mahal.

---

## Insight 4 — Sembilan kategori besar (36% revenue) membebani customer dengan ongkir di atas rata-rata, kebanyakan karena harga barangnya murah, bukan karena ongkirnya mahal

**Finding:** Sembilan kategori yang revenue-nya di atas rata-rata kategori juga membebani customer dengan ongkir di atas rata-rata (freight burden di atas 16,63%), dan bersama-sama menyumbang 36,24% revenue. Pada delapan di antaranya, ongkir per unit sebenarnya tidak jauh dari rata-rata; bebannya menjadi tinggi karena harga barangnya di bawah rata-rata. Hanya `office_furniture` yang ongkir per unitnya memang mahal, sekitar 2× rata-rata.

**Evidence:**

- Q7 memilih kategori yang memenuhi **dua syarat sekaligus**: revenue di atas rata-rata kategori (≈ R$ 178.121,99 = total revenue ÷ 74 kategori, dari `results/02_kpi01.csv` dan `results/04_q6_volume_vs_value.csv`) **dan** freight burden di atas rata-rata keseluruhan 16,63%:

  | Kategori | Revenue | Freight burden | Harga rata-rata per unit | Ongkir per unit (≈) |
  |---|---|---|---|---|
  | bed_bath_table | R$ 1.022.955,77 | 19,71% | R$ 93,46 | R$ 18,42 |
  | sports_leisure | R$ 952.840,40 | 17,10% | R$ 113,24 | R$ 19,36 |
  | furniture_decor | R$ 706.237,17 | 23,67% | R$ 87,24 | R$ 20,65 |
  | housewares | R$ 614.341,62 | 23,20% | R$ 90,57 | R$ 21,01 |
  | garden_tools | R$ 469.135,40 | 20,58% | R$ 110,05 | R$ 22,65 |
  | telephony | R$ 309.631,94 | 22,36% | R$ 70,02 | R$ 15,66 |
  | office_furniture | R$ 266.853,43 | 25,02% | R$ 160,56 | R$ 40,17 |
  | stationery | R$ 223.788,69 | 20,46% | R$ 90,75 | R$ 18,57 |
  | pet_shop | R$ 211.005,96 | 18,40% | R$ 109,90 | R$ 20,22 |
  | **Total 9 kategori** | **R$ 4.776.790,38 (36,24% revenue)** | | | |
  | **Rata-rata seluruh produk** | | **16,63%** | **R$ 119,96** | **R$ 19,95** |

  Sumber: revenue dan freight burden dari `results/04_q7_high_burden_categories.csv`; harga rata-rata per unit dari `results/04_q6_volume_vs_value.csv`. Ongkir per unit ≈ freight burden × harga rata-rata per unit. Baris rata-rata: harga = total revenue ÷ unit terjual (`results/02_kpi01.csv`), ongkir per unit = 16,63% × harga tersebut.

- Dari tabel ini, 8 dari 9 kategori berharga di bawah rata-rata seluruh produk, dan ongkir per unit kedelapan kategori itu berkisar R$ 15,66–22,65, tidak jauh dari rata-rata R$ 19,95. Pengecualiannya `office_furniture`: harganya justru di atas rata-rata (R$ 160,56), tetapi ongkirnya ≈ R$ 40,17 per unit, sekitar 2× rata-rata.

**Possible explanation (hipotesis):**

- Pada barang murah, tarif ongkir kemungkinan punya komponen yang relatif tetap per pengiriman, sehingga porsinya terhadap harga menjadi besar walaupun ongkirnya sendiri biasa saja. [Medium confidence — konsisten dengan ongkir per unit yang mendekati rata-rata pada harga yang rendah.] *Data yang dibutuhkan:* struktur tarif kurir, serta perbandingan ongkir per item pada order berisi satu item vs banyak item (bisa dihitung dari data yang sudah ada).
- Ongkir `office_furniture` mahal kemungkinan karena ukuran dan berat barangnya. [Medium confidence — konsisten dengan ongkir per unit sekitar 2× rata-rata meskipun harganya lebih tinggi.] *Data yang dibutuhkan:* berat dan dimensi produk. Kolom ini ada di file products mentah, tetapi belum dimodelkan ke star schema.
- Beban ongkir yang tinggi bisa menahan pembelian di kategori-kategori ini. [Low confidence — dataset hanya berisi order yang sudah terjadi, tanpa data kunjungan atau keranjang yang ditinggalkan.]

**Recommendation:** **Category Manager** bersama **Operations / Logistics** memakai tuas platform untuk dua pola ini. (1) Untuk kategori berharga murah — mulai dari yang freight burden-nya tertinggi, yaitu `furniture_decor` (23,67%), `housewares` (23,20%), dan `telephony` (22,36%) — tampilkan rekomendasi "produk lain dari seller yang sama" supaya lebih banyak item masuk ke satu pengiriman (di marketplace, barang dari seller berbeda umumnya dikirim terpisah), uji gratis ongkir yang disubsidi platform untuk keranjang berisi beberapa item, dan beri insentif seperti potongan komisi bagi seller yang menawarkan ongkir gabungan. (2) Untuk `office_furniture`, uji subsidi ongkir platform yang terarah, ditambah insentif bagi seller yang ikut menanggung sebagian ongkir. *Metrik keberhasilan:* freight burden per kategori (baseline rata-rata 16,63%), unit per order, dan jumlah order di kategori tersebut, dibanding periode atau kelompok kontrol.

**Expected impact:** Arah: beban ongkir yang ditanggung customer di kategori-kategori ini turun mendekati rata-rata, dan — jika hipotesis tentang tertahannya pembelian benar — volume di kategori tersebut naik. Risiko: subsidi ongkir dan potongan komisi menjadi biaya platform yang tidak bisa diukur dengan dataset ini, dan ambang gratis ongkir bisa membuat sebagian customer menunda pembelian.

---

## Insight 5 — SP menyumbang 38% revenue dengan beban ongkir terendah; di luar SP customer menanggung ongkir jauh lebih berat

**Finding:** São Paulo (SP) adalah pasar inti: 38,36% revenue dan 42,00% order, dengan freight burden terendah dari 27 state (13,85%). Di state utara dan timur laut Brasil, freight burden mencapai 24–28%, dan ongkir per order diperkirakan sekitar 2,2–2,8× lebih mahal daripada di SP.

**Evidence:**

- SP: revenue R$ 5.055.587,13 (**38,36%**), 40.406 order (**42,00%** dari 96.211 order), freight burden **13,85%** — terendah dari 27 state — dan AOV R$ 125,12, juga yang terendah. SP, RJ, dan MG bersama-sama menyumbang 63,40% revenue — `results/02_q3_region.csv` (Q3).
- Enam freight burden tertinggi: RR 27,83%, MA 26,22%, RO 24,70%, AM 24,51%, SE 24,26%, PI 24,16% — Q3.
- Ongkir per order (≈ freight burden × revenue ÷ order, dari Q3): SP ≈ R$ 17,33; AM ≈ R$ 37,45; MA ≈ R$ 42,77; RO ≈ R$ 46,43; RR ≈ R$ 48,83. Artinya sekitar 2,2–2,8× SP.
- AOV di beberapa state jauh berada di atas SP, misalnya PB R$ 218,09, AP R$ 199,62, AC R$ 199,14, dan AL R$ 199,00 — Q3.
- Catatan: state kecil hanya punya sedikit order (RR 40, AP 67, AC 80), sehingga angkanya mudah berfluktuasi.

**Possible explanation (hipotesis):**

- Seller kemungkinan terkonsentrasi di SP atau sekitarnya, sehingga jarak kirim ke customer SP pendek dan ongkirnya murah. [Medium confidence — SP adalah pusat ekonomi Brasil, tetapi lokasi seller ada di tabel sellers yang berada di luar scope project.] *Data yang dibutuhkan:* lokasi seller.
- AOV di state jauh mungkin lebih tinggi karena customer di sana hanya belanja jika barangnya cukup mahal untuk "sepadan" dengan ongkir, sehingga belanja kecil tidak jadi dilakukan. [Low confidence — dataset tidak berisi data keranjang yang ditinggalkan atau kunjungan tanpa pembelian.]

**Recommendation:** **Operations / Logistics** bersama **Head of Commercial** menjalankan pilot subsidi ongkir platform — atau ambang gratis ongkir yang dibiayai platform — di satu atau dua state yang ongkirnya tinggi tetapi volumenya cukup untuk diukur, misalnya BA (3,74% revenue, 3.253 order, freight burden 19,76%) atau PE (1.587 order, freight burden 22,66%), dengan state lain sebagai pembanding. SP tetap dijaga sebagai pasar inti yang paling murah dilayani, dan program pembelian kedua (Insight 2) paling masuk akal dimulai di sana karena basis customer-nya terbesar. *Metrik keberhasilan:* jumlah order dan revenue state pilot vs pembanding, freight burden state pilot, dan porsi revenue di luar SP (baseline 61,64% = 100% − 38,36%).

**Expected impact:** Arah: porsi revenue dari luar SP naik, sehingga ketergantungan pada satu state berkurang. Risiko: subsidi ongkir adalah biaya platform yang tidak terukur dengan dataset ini, dan pilot di state kecil rawan menghasilkan angka yang bising karena sampelnya sedikit.

---

## Insight 6 — Mix kategori bergeser ke health_beauty dan watches_gifts, sementara cool_stuff kehilangan lebih dari separuh porsinya

**Finding:** Dengan periode sebanding (Jan–Agu 2017 vs Jan–Agu 2018), `health_beauty` naik ke peringkat #1 dan `watches_gifts` melonjak dari #6 ke #2. Sebaliknya `cool_stuff` turun dari #5 ke #10: revenue-nya hanya naik 10,4% ketika total revenue naik 141,1%, sehingga porsinya turun lebih dari separuh (6,89% → 3,16%).

**Evidence:**

- Semua kategori yang share-nya berubah minimal 1 pp — `results/02_q2c_category_fair_period.csv` (Q2c, share dihitung dalam masing-masing periode Jan–Agu; total revenue kedua periode sama persis dengan Q1c):

  | Kategori | Share Jan–Agu 2017 | Share Jan–Agu 2018 | Perubahan | Peringkat |
  |---|---|---|---|---|
  | watches_gifts | 6,72% | 9,53% | +2,81 pp | #6 → #2 |
  | health_beauty | 8,14% | 10,47% | +2,33 pp | #2 → #1 |
  | construction_tools_construction | 0,09% | 1,70% | +1,62 pp | #47 → #18 |
  | baby | 2,27% | 3,47% | +1,20 pp | #14 → #9 |
  | housewares | 4,26% | 5,43% | +1,17 pp | #9 → #6 |
  | small_appliances | 2,21% | 1,19% | −1,02 pp | #15 → #22 |
  | bed_bath_table | 8,50% | 7,38% | −1,12 pp | #1 → #3 |
  | toys | 3,96% | 2,33% | −1,63 pp | #12 → #14 |
  | perfumery | 4,07% | 2,42% | −1,66 pp | #11 → #12 |
  | garden_tools | 4,61% | 2,94% | −1,67 pp | #8 → #11 |
  | cool_stuff | 6,89% | 3,16% | −3,74 pp | #5 → #10 |

- `cool_stuff`: revenue R$ 206.306,37 → R$ 227.743,70 (+10,4%), sementara total revenue Jan–Agu naik 141,1% (Q1c).
- **Kenapa tidak memakai Q2b langsung:** Q2b membandingkan 2017 setahun penuh dengan 2018 yang hanya Jan–Agu, padahal 28,74% revenue 2017 jatuh di November–Desember (`results/02_q1_monthly.csv`). Akibatnya kategori musiman terdistorsi:
  - `toys` — 39,35% revenue 2017-nya jatuh di Nov–Des. Di Q2b share-nya tampak turun 2,69 pp (5,02% → 2,33%, `results/02_q2b_category_year.csv`), padahal dengan periode sebanding penurunannya 1,63 pp.
  - `watches_gifts` — di Q2b tampak stabil di peringkat #2 → #2, padahal dengan periode sebanding naik dari #6 ke #2.
  - Penurunan `cool_stuff` tidak bisa dijelaskan oleh efek Nov–Des: perbandingan Q2c sudah mengeluarkan kedua bulan itu, dan porsi Nov–Des `cool_stuff` sendiri (24,44% revenue 2017-nya) pun di bawah rata-rata 28,74%.

**Possible explanation (hipotesis):**

- Kemungkinan ada perubahan di sisi pasokan: seller dan produk baru masuk ke kategori yang tumbuh, atau seller `cool_stuff` berkurang. Sebagai petunjuk, `construction_tools_construction` muncul hampir dari nol dalam beberapa bulan (#47 → #18, dengan 66,72% revenue 2017-nya baru terjadi di Nov–Des). [Low confidence — data seller berada di luar scope.] *Data yang dibutuhkan:* jumlah seller dan produk aktif per kategori per bulan.
- Perubahan harga atau promosi di kategori tertentu. [Low confidence — tidak ada data promo.]
- Pergeseran selera customer. [Low confidence — tidak ada data survei maupun perilaku pencarian.]
- Awal 2017 masih fase awal dengan basis kecil, sehingga mix kategori Jan–Agu 2017 bisa sangat dipengaruhi oleh segelintir seller. [Medium confidence]

**Recommendation:** **Category Manager**: (1) investigasi `cool_stuff` sebelum mengambil tindakan — bandingkan jumlah seller aktif, jumlah produk yang aktif terjual, unit terjual, dan harga rata-rata 2017 vs 2018 (data seller tersedia di sistem platform walaupun di luar scope project ini), untuk mengetahui apakah penurunannya berasal dari sisi pasokan atau permintaan; (2) tambah pasokan di kategori yang tumbuh (`health_beauty`, `watches_gifts`, `baby`, `housewares`) lewat rekrutmen seller baru dan insentif seller seperti potongan komisi di bulan-bulan awal, lalu tonjolkan kategori tersebut lewat fitur rekomendasi dan halaman kategori; (3) wajibkan semua laporan perbandingan tahunan memakai periode sebanding. *Metrik keberhasilan:* share kategori per periode sebanding, pertumbuhan revenue tiap kategori dibanding pertumbuhan total platform, dan jumlah seller aktif di kategori sasaran.

**Expected impact:** Arah: keputusan assortment didasarkan pada pergeseran yang nyata, bukan artefak musiman, dan pasokan di kategori yang tumbuh bertambah. Risiko: jika penurunan `cool_stuff` berasal dari sisi permintaan, upaya menambah pasokan di sana bisa sia-sia — karena itu investigasi harus dilakukan lebih dulu — dan potongan komisi mengurangi pendapatan platform.

---

## Catatan metodologi: kandidat insight yang disesuaikan

Keenam insight di atas berasal dari kandidat awal hasil Fase 4. Setiap angka dicek ulang langsung dari `results/`, lalu tiga celah yang mungkin ditanyakan diuji secara khusus. Hasilnya:

- **Insight 1** — klaim awal "growth hanya dari volume" dilunakkan menjadi "hampir seluruhnya", karena AOV tetap naik sedikit (+0,5%). Klaim tambahan "volume 2018 mulai mendatar" **dihapus** setelah dua pemeriksaan: (a) *right-censoring* status pengiriman ternyata tidak berpengaruh, karena order semua status juga tidak naik dan porsi order yang belum final tetap kecil; tetapi (b) data harian menunjukkan 22–31 Agustus 2018 tidak lengkap, dan laju harian awal Agustus justru yang tertinggi di 2018. Penurunan Januari → Agustus sebagian adalah artefak data.
- **Insight 2** — perkiraan awal "returning revenue 2–3%" dikoreksi dengan angka tepat: 1,79% untuk seluruh jendela dan 2,17% untuk Jan–Agu 2018. Ditambah **analisis kohort 12 bulan (Q4d)**, yang membuktikan rendahnya repeat rate bukan sekadar karena customer belum sempat kembali.
- **Insight 3** — Q5a hanya menunjukkan konsentrasi revenue, bukan apakah customer teratas adalah pembeli berulang. Sepuluh customer di Q5b terlalu sedikit untuk digeneralisasi ke 9.311 customer desil 1, sehingga ditambahkan query **Q5c**.
- **Insight 4** — "ongkir berat" ternyata untuk sebagian besar kategori bukan berarti ongkirnya mahal. Delapan dari sembilan kategori punya ongkir per unit yang mendekati rata-rata, tetapi harga barangnya murah.
- **Insight 6** — Q2b ternyata bias musiman (2017 setahun penuh vs 2018 Jan–Agu), sehingga ditambahkan query **Q2c** dengan periode sebanding. Arah temuannya tetap, tetapi kenaikan `watches_gifts` ternyata lebih besar dan penurunan `toys` lebih kecil dari yang terlihat di Q2b.
- **Semua rekomendasi** ditinjau ulang agar hanya memakai tuas yang dikendalikan platform. Di marketplace, harga dan ongkir ditentukan seller dan kurir, sehingga tindakan seperti "bundling" atau "meninjau tarif kurir" diganti dengan fitur rekomendasi, voucher platform, subsidi ongkir platform, dan insentif seller.

---

## Ringkasan rekomendasi untuk manajemen

| Prioritas | Rekomendasi (tuas platform) | Stakeholder | Metrik keberhasilan | Insight |
|---|---|---|---|---|
| 1 | Program pembelian kedua: voucher platform, notifikasi/email platform, dan rekomendasi produk berdasarkan pembelian pertama (termasuk pemicu khusus setelah pembelian bernilai tinggi), diuji dengan kelompok kontrol | CRM / Marketing Manager, Category Manager | Repeat per kohort (baseline 12 bulan: 3,32%); porsi revenue returning (baseline 2018: 2,17%); repeat rate desil 1 (baseline 8,59%) | 2, 3 |
| 2 | Fitur rekomendasi produk pelengkap, voucher platform untuk keranjang multi-item, ambang gratis ongkir bersubsidi platform, dan insentif bagi seller yang menawarkan paket | Head of Commercial | AOV (baseline R$ 137,00); unit per order (baseline 1,14) | 1 |
| 3 | Rekomendasi "produk lain dari seller yang sama", gratis ongkir bersubsidi platform untuk keranjang multi-item, subsidi ongkir terarah untuk `office_furniture`, dan insentif bagi seller yang ikut menanggung ongkir | Category Manager, Operations / Logistics | Freight burden per kategori (baseline rata-rata 16,63%) | 4 |
| 4 | Pilot subsidi ongkir platform di state berongkir tinggi dengan volume cukup (mis. BA atau PE) | Operations / Logistics, Head of Commercial | Order dan revenue state pilot vs pembanding; porsi revenue di luar SP (baseline 61,64%) | 5 |
| 5 | Investigasi penurunan `cool_stuff`; rekrut seller dan beri insentif seller di kategori yang tumbuh; wajibkan periode sebanding di laporan tahunan | Category Manager | Share kategori per periode sebanding; pertumbuhan kategori vs platform; seller aktif di kategori sasaran | 6 |

**Dasar urutan prioritas.** Retensi di urutan pertama karena menyangkut hampir seluruh basis customer (97,0% hanya belanja sekali, dan dengan pengamatan penuh 12 bulan pun hanya 3,32% yang kembali), sekaligus menjawab temuan konsentrasi revenue. Nilai per order di urutan kedua karena AOV nyaris tidak naik (+0,5%), sehingga menjadi pengungkit pertumbuhan berikutnya yang paling jelas. Isu ongkir di urutan ketiga dan keempat karena menyangkut 36,24% revenue (kategori) dan pertumbuhan di luar SP, tetapi biaya subsidinya belum bisa diukur tanpa data cost. Pergeseran kategori di urutan terakhir karena langkah pertamanya adalah investigasi, bukan eksekusi. Urutan ini adalah penilaian, bukan hasil perhitungan.

---

## Keterbatasan analisis

- **Tidak ada data cost, profit, maupun komisi.** Freight burden hanyalah proxy beban ongkir yang dibayar customer relatif terhadap harga barang — bukan profit dan bukan biaya perusahaan. Karena itu dampak finansial rekomendasi bagi platform (biaya voucher, subsidi ongkir, potongan komisi) tidak bisa dihitung.
- **Tidak ada data promo, channel marketing, kompetitor, kunjungan/konversi, maupun review.** Semua penyebab di dokumen ini adalah hipotesis, dan dampak rekomendasi hanya ditulis sebagai arah. Rekomendasi sebaiknya diuji lewat eksperimen terkontrol sebelum diterapkan secara luas.
- **Agustus 2018 ternyata tidak lengkap.** 22–31 Agustus hanya berisi 702 order (70,2 per hari), dibanding 276,7 per hari pada 1–21 Agustus (`results/02_q1e_orders_daily_aug_sep_2018.csv`). Pemeriksaan di Fase 2 hanya melihat total dan porsi delivered per bulan, sehingga hal ini tidak terdeteksi. Jendela analisis saat ini masih memuat Agustus 2018, sehingga angka yang mencakup bulan itu — misalnya Q1c dan KPI total — sedikit lebih rendah dari seharusnya. **Keputusan apakah jendela dipendekkan menjadi 2017-01 s/d 2018-07 masih menunggu persetujuan.**
- **Jendela analisis hanya 20 bulan (2017-01 s/d 2018-08).** Bulan di ujung dataset dikecualikan karena datanya tidak lengkap, yaitu 267 order delivered atau 0,28% dari seluruh order delivered (`notebooks/01_data_cleaning.ipynb`, bagian 11). Perbandingan antartahun memakai periode sebanding Jan–Agu (Q1c, Q2c).
- **Musim dan tren tidak bisa dipisahkan.** 2017 adalah tahun awal dengan basis yang masih tumbuh cepat, dan 2018 hanya delapan bulan (dengan Agustus tidak lengkap), sehingga tidak ada tahun "normal" sebagai pembanding musiman.
- **Retensi hanya bisa diamati maksimal 12 bulan.** Kohort Q4d mengatasi masalah customer yang belum sempat kembali, tetapi siklus beli ulang barang tahan lama bisa lebih panjang dari 12 bulan, dan repeat rate Q4a hanya menghitung order di dalam jendela analisis.
- **Cakupan dataset tidak dijelaskan.** Dataset memuat 99.441 order untuk periode 2016–2018 (`notebooks/01_data_cleaning.ipynb`, bagian 1), tanpa penjelasan apakah ini seluruh transaksi atau sampel, maupun kriteria pengambilannya. [Medium confidence — dokumentasi dataset tidak menjelaskan metodenya.] Penyusutan order di akhir Agustus 2018 menunjukkan kriteria itu memengaruhi isi data. Karena itu angka volume absolut sebaiknya tidak dibaca sebagai ukuran pasar.
- **Lokasi seller di luar scope.** Tabel sellers tidak dipakai, sehingga penjelasan berbasis jarak kirim tidak bisa diverifikasi. Berat dan dimensi produk ada di file mentah, tetapi belum dimodelkan.
- **State kecil punya sampel kecil** (misalnya RR hanya 40 order), sehingga angkanya mudah berfluktuasi.
- **Korelasi bukan sebab-akibat.** Pola yang muncul bersamaan — misalnya AOV tinggi dan ongkir tinggi di state jauh — belum tentu saling menyebabkan.
