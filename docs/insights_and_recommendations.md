# Key Insights & Recommendations — NusaMart

> **Aturan penulisan**
> - *Finding* dan *Evidence* hanya berisi fakta dari hasil query, lengkap dengan angka dan file sumbernya.
> - *Possible explanation* selalu ditandai sebagai **hipotesis**, dengan label keyakinan dan data yang dibutuhkan untuk membuktikannya.
> - *Expected impact* ditulis sebagai arah dampak, tanpa angka.
> - Target: 5–7 insight. Kualitas lebih penting dari jumlah.

## Cara membaca dokumen ini

- Semua angka berasal dari file di folder `results/`, yaitu hasil query di `sql/`. Setiap angka menyebut file sumbernya. Angka yang dihitung dari kolom sebuah file (bukan dibaca langsung) diberi keterangan cara hitungnya.
- Periode: **jendela analisis 2017-01 s/d 2018-08** (bulan yang datanya lengkap), kecuali disebut lain. Perbandingan antartahun memakai **periode sebanding Jan–Agu**, karena 2018 hanya tersedia sampai Agustus.
- Mata uang: Real Brasil (R$). *pp* = poin persentase.
- *Freight burden* = Σ ongkir ÷ Σ harga barang. Ongkir di dataset ini **dibayar oleh customer**, sehingga angka ini mengukur beban ongkir yang ditanggung customer relatif terhadap harga barang. Ini **proxy** — bukan profit, dan bukan biaya perusahaan.

---

## Insight 1 — Pertumbuhan 2018 hampir seluruhnya dari volume, dan volume itu mulai mendatar

**Finding:** Revenue Jan–Agu 2018 naik 141,1% dibanding Jan–Agu 2017, tetapi nilai rata-rata per order (AOV) nyaris tidak berubah (+0,5%). Pertumbuhan datang dari bertambahnya order dan customer, bukan dari customer yang belanja lebih besar. Di dalam 2018 sendiri, jumlah order bulanan sudah tidak naik lagi.

**Evidence:**

- Perbandingan periode sebanding — `results/02_q1c_fair_period_comparison.csv` (Q1c):

  | | Jan–Agu 2017 | Jan–Agu 2018 | Perubahan |
  |---|---|---|---|
  | Revenue | R$ 2.993.456,13 | R$ 7.218.125,12 | +141,1% |
  | Order | 21.998 | 52.783 | +139,9% |
  | Customer | 21.404 | 51.612 | +141,1% |
  | AOV | R$ 136,08 | R$ 136,75 | +0,5% |

- Revenue dan customer sama-sama tumbuh +141,1% bukan karena salah salin. Revenue per customer praktis tidak berubah: **R$ 139,85 di kedua periode**, dengan selisih kurang dari satu sen (revenue ÷ customer dari file yang sama). Karena revenue = customer × revenue per customer, keduanya otomatis tumbuh hampir persis sama.
- Order bulanan 2018 tidak lagi tumbuh: **7.069 (Januari) → 6.351 (Agustus)**, atau sekitar 6.856 order per bulan di Jan–Apr vs 6.340 di Mei–Agu. Revenue bulanan tertinggi 2018 (Mei, R$ 977.544,69) masih di bawah November 2017 (R$ 987.765,37) — `results/02_q1_monthly.csv`.
- Pertumbuhan YoY per bulan melambat tajam: **+727,1% (Januari 2018) → +51,2% (Agustus 2018)** — `results/02_q1b_yoy.csv` (Q1b).
- AOV bulanan hanya bergerak di rentang R$ 124,38–149,06 (2017) dan R$ 126,08–144,84 (2018), tanpa tren naik — `results/02_q1_monthly.csv`.

**Possible explanation (hipotesis):**

- Angka +141,1% sebagian besar mencerminkan fase awal bisnis, bukan percepatan di 2018. Januari 2017 baru berisi 750 order (`results/02_q1_monthly.csv`), sehingga pembanding 2017 masih sangat kecil. [High confidence — basis yang kecil dan YoY yang terus melambat terlihat langsung di data.]
- AOV mungkin datar karena belum ada mekanisme yang mendorong belanja lebih besar per order, seperti bundling, cross-sell, atau ambang gratis ongkir. [Low confidence — dataset tidak memuat data promo atau program apa pun.] *Data yang dibutuhkan:* histori promo dan fitur rekomendasi produk.
- Order 2018 yang mendatar bisa disebabkan pasar yang mulai jenuh, persaingan, atau pola musiman pertengahan tahun. Dengan data 20 bulan, tren dan musim tidak bisa dipisahkan. [Low confidence] *Data yang dibutuhkan:* minimal dua tahun penuh, data marketing, dan data kompetitor.

**Recommendation:** **Head of Commercial** membuka pengungkit pertumbuhan kedua selain volume: uji bundling produk komplementer, rekomendasi cross-sell, dan ambang gratis ongkir sebagai eksperimen terkontrol di beberapa kategori terlebih dahulu. *Metrik keberhasilan:* AOV bulanan (baseline jendela analisis R$ 137,00) dan unit per order (baseline 1,14 = 109.880 unit ÷ 96.211 order, `results/02_kpi01.csv`) di grup eksperimen dibanding grup kontrol, sambil memastikan jumlah order tidak ikut turun.

**Expected impact:** Arah: nilai per order naik, sehingga pertumbuhan tidak lagi bergantung sepenuhnya pada penambahan order dan customer baru. Risiko: bundling dan diskon bisa menggerus margin — yang tidak terukur karena dataset tidak punya data cost — dan ambang gratis ongkir bisa membuat customer menunda pembelian kecil.

---

## Insight 2 — 97% customer hanya belanja sekali, dan customer yang kembali menyumbang kurang dari 3% revenue setiap bulan

**Finding:** Dari 93.104 customer di jendela analisis, 97,0% hanya pernah order satu kali. Customer yang kembali (*returning*) hanya menyumbang 1,79% dari total revenue selama jendela analisis, dan tidak pernah lebih dari 2,96% dalam satu bulan pun.

**Evidence:**

- Repeat rate **3,0%**: hanya 2.789 dari 93.104 customer yang order dua kali atau lebih — `results/03_q4a_repeat_rate.csv` (Q4a).
- Distribusi order per customer: 90.315 customer (**97,0%**) order satu kali, 2.562 order dua kali, dan hanya 227 customer (0,24%) yang order tiga kali atau lebih. Maksimum 15 order oleh satu customer — `results/03_q4b_order_distribution.csv` (Q4b).
- Porsi revenue dari customer returning — `results/03_q4c_new_vs_returning.csv` (Q4c):
  - Seluruh jendela analisis: **1,79%** (R$ 236.314,65 dari R$ 13.181.027,13; jumlah kolom `returning_revenue` ÷ jumlah revenue new + returning).
  - Jan–Agu 2018: **2,17%**. Per bulan berkisar 1,62% (Februari 2018) s/d 2,96% (Juni 2018), dan 2,96% adalah angka tertinggi di seluruh jendela.
  - Setiap bulan di 2018 ada 5.878–6.842 customer baru, tetapi hanya 112–187 customer returning.

**Possible explanation (hipotesis):**

- Sebagian angka rendah bersifat mekanis: customer yang pertama kali belanja di akhir periode hampir tidak punya waktu untuk kembali sebelum data berakhir. [High confidence — konsekuensi langsung dari jendela data 20 bulan.] Efek ini hanya menjelaskan sebagian, karena porsi returning tetap di bawah 3% sepanjang 2018, saat platform sudah berjalan lebih dari setahun.
- Banyak kategori besar adalah barang yang jarang dibeli ulang (misalnya `bed_bath_table`, `furniture_decor`, `watches_gifts`), sehingga siklus beli ulangnya bisa lebih panjang dari jendela data. Namun kategori dengan revenue terbesar, `health_beauty` (`results/02_q2_category.csv`), adalah barang habis pakai yang seharusnya sering dibeli ulang — jadi hipotesis ini tidak menjelaskan semuanya. [Low confidence — repeat rate per kategori belum dianalisis.] *Data yang dibutuhkan:* repeat rate per kategori pembelian pertama (bisa dihitung dari data yang sudah ada).
- Customer mungkin tidak punya alasan untuk kembali: mereka menemukan produk lewat pencarian harga, bukan karena hubungan dengan NusaMart, dan tidak ada program yang mengajak mereka kembali. [Low confidence — tidak ada data channel akuisisi maupun CRM.] *Data yang dibutuhkan:* channel akuisisi dan riwayat email/notifikasi.
- Pengalaman pengiriman yang buruk, misalnya keterlambatan, bisa menurunkan niat belanja lagi. [Low confidence] *Data yang dibutuhkan:* tanggal terima aktual vs estimasi (tersedia di tabel orders mentah, tetapi belum dimodelkan) dan data review (di luar scope).

**Recommendation:** **CRM / Marketing Manager** menjalankan program pembelian kedua untuk customer baru — misalnya pengingat dan voucher terjadwal setelah order pertama — sebagai eksperimen: sebagian customer baru menerima program, sebagian lagi menjadi kelompok kontrol. **Head of Commercial** memakai hasilnya untuk menimbang ulang pembagian budget akuisisi vs retensi. *Metrik keberhasilan:* repeat rate kohort eksperimen vs kontrol (baseline 3,0%) dan porsi revenue returning per bulan (baseline Jan–Agu 2018: 2,17%).

**Expected impact:** Arah: porsi revenue dari customer returning naik, sehingga pertumbuhan tidak lagi hampir sepenuhnya bergantung pada akuisisi customer baru. Risiko: biaya voucher tidak terukur tanpa data cost, dan insentif bisa saja hanya dinikmati customer yang sebenarnya akan kembali tanpa insentif.

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

**Recommendation:** **CRM / Marketing Manager** bersama **Category Manager** menjadikan pembelian pertama yang bernilai tinggi sebagai pemicu kampanye pembelian kedua yang relevan — misalnya aksesori atau produk pelengkap dari barang yang baru dibeli — alih-alih program poin loyalitas umum, karena kelompok bernilai tinggi justru belum loyal. *Metrik keberhasilan:* repeat rate desil 1 (baseline 8,59%) dan porsi revenue desil 1 yang berasal dari pembeli sekali (baseline 91,97%, arah yang diharapkan: turun), sambil memantau porsi revenue desil 1 (baseline 41,10%).

**Expected impact:** Arah: sebagian pembelian besar sekali jalan berubah menjadi hubungan berulang, sehingga ketergantungan revenue pada transaksi besar yang tidak berulang berkurang. Risiko: untuk barang tahan lama, customer mungkin memang tidak membutuhkan pembelian lanjutan, dan insentif untuk customer bernilai tinggi bisa mahal.

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

**Recommendation:** **Category Manager** bersama **Operations / Logistics** memisahkan dua penanganan: (1) untuk kategori berharga murah, mulai dari yang freight burden-nya tertinggi — `furniture_decor` (23,67%), `housewares` (23,20%), dan `telephony` (22,36%) — uji bundling atau ambang minimum belanja supaya satu pengiriman berisi lebih banyak item; (2) untuk `office_furniture`, tinjau tarif kurir khusus barang besar/berat dan uji opsi pengiriman alternatif. *Metrik keberhasilan:* freight burden per kategori (baseline rata-rata 16,63%), unit per order, dan jumlah order di kategori tersebut, dibanding periode atau kelompok kontrol.

**Expected impact:** Arah: freight burden di kategori-kategori ini turun mendekati rata-rata, dan — jika hipotesis tentang tertahannya pembelian benar — volume di kategori tersebut naik. Risiko: subsidi ongkir menjadi biaya perusahaan yang tidak bisa diukur dengan dataset ini, bundling bisa menurunkan harga efektif per item, dan ambang minimum belanja bisa membuat sebagian customer batal membeli.

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

**Recommendation:** **Operations / Logistics** bersama **Head of Commercial** menjalankan pilot subsidi atau ambang gratis ongkir di satu atau dua state yang ongkirnya tinggi tetapi volumenya cukup untuk diukur — misalnya BA (3,74% revenue, 3.253 order, freight burden 19,76%) atau PE (1.587 order, freight burden 22,66%) — dengan state lain sebagai pembanding. SP tetap dijaga sebagai pasar inti yang paling murah dilayani, dan program pembelian kedua (Insight 2) paling masuk akal dimulai di sana karena basis customer-nya terbesar. *Metrik keberhasilan:* jumlah order dan revenue state pilot vs pembanding, freight burden state pilot, dan porsi revenue di luar SP (baseline 61,64% = 100% − 38,36%).

**Expected impact:** Arah: porsi revenue dari luar SP naik, sehingga ketergantungan pada satu state berkurang. Risiko: subsidi ongkir adalah biaya perusahaan yang tidak terukur dengan dataset ini, dan pilot di state kecil rawan menghasilkan angka yang bising karena sampelnya sedikit.

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

**Recommendation:** **Category Manager**: (1) investigasi `cool_stuff` sebelum mengambil tindakan — bandingkan unit terjual, jumlah produk yang aktif terjual, dan harga rata-rata 2017 vs 2018 untuk mengetahui apakah penurunannya berasal dari sisi pasokan atau permintaan; (2) prioritaskan perluasan assortment di kategori yang tumbuh (`health_beauty`, `watches_gifts`, `baby`, `housewares`); (3) wajibkan semua laporan perbandingan tahunan memakai periode sebanding. *Metrik keberhasilan:* share kategori per periode sebanding, dan pertumbuhan revenue tiap kategori dibanding pertumbuhan total platform.

**Expected impact:** Arah: keputusan assortment didasarkan pada pergeseran yang nyata, bukan artefak musiman, dan ada peluang memulihkan `cool_stuff` jika penyebabnya di sisi pasokan. Risiko: jika penurunan `cool_stuff` berasal dari sisi permintaan, investasi untuk memulihkannya bisa sia-sia — karena itu investigasi harus dilakukan sebelum investasi.

---

## Catatan metodologi: kandidat insight yang disesuaikan

Keenam insight di atas berasal dari kandidat awal hasil Fase 4. Setelah setiap angka dicek ulang langsung dari `results/`, lima kandidat disesuaikan supaya tidak melebihi apa yang didukung data:

- **Insight 1** — "growth hanya dari volume" dilunakkan menjadi "hampir seluruhnya", karena AOV tetap naik sedikit (+0,5%). Ditambah temuan order bulanan 2018 yang mendatar; tanpa konteks ini, angka +141,1% memberi kesan pertumbuhan yang masih melaju.
- **Insight 2** — perkiraan awal "returning revenue 2–3%" dikoreksi dengan angka tepat: 1,79% untuk seluruh jendela dan 2,17% untuk Jan–Agu 2018. Beberapa bulan di 2018 berada di bawah 2%.
- **Insight 3** — Q5a hanya menunjukkan konsentrasi revenue, bukan apakah customer teratas adalah pembeli berulang. Sepuluh customer di Q5b terlalu sedikit untuk digeneralisasi ke 9.311 customer desil 1, sehingga ditambahkan query **Q5c** (`sql/03_customer_analysis.sql`).
- **Insight 4** — "ongkir berat" ternyata untuk sebagian besar kategori bukan berarti ongkirnya mahal. Delapan dari sembilan kategori punya ongkir per unit yang mendekati rata-rata, tetapi harga barangnya murah. Pembedaan ini mengubah rekomendasinya: bundling untuk barang murah, dan peninjauan tarif kurir hanya untuk `office_furniture`.
- **Insight 6** — Q2b ternyata bias musiman (2017 setahun penuh vs 2018 Jan–Agu), sehingga ditambahkan query **Q2c** (`sql/02_sales_analysis.sql`) dengan periode sebanding. Arah temuannya tetap, tetapi rinciannya berubah: kenaikan `watches_gifts` ternyata lebih besar dan penurunan `toys` lebih kecil dari yang terlihat di Q2b.

---

## Ringkasan rekomendasi untuk manajemen

| Prioritas | Rekomendasi | Stakeholder | Metrik keberhasilan | Insight |
|---|---|---|---|---|
| 1 | Program pembelian kedua untuk customer baru, termasuk pemicu khusus setelah pembelian bernilai tinggi, diuji sebagai eksperimen dengan kelompok kontrol | CRM / Marketing Manager, Category Manager | Repeat rate kohort (baseline 3,0%); porsi revenue returning (baseline 2018: 2,17%); repeat rate desil 1 (baseline 8,59%) | 2, 3 |
| 2 | Uji bundling, cross-sell, dan ambang gratis ongkir untuk menaikkan nilai per order | Head of Commercial | AOV (baseline R$ 137,00); unit per order (baseline 1,14) | 1 |
| 3 | Turunkan beban ongkir di 9 kategori besar: bundling atau ambang minimum belanja untuk kategori berharga murah, dan tinjau tarif kurir untuk `office_furniture` | Category Manager, Operations / Logistics | Freight burden per kategori (baseline rata-rata 16,63%) | 4 |
| 4 | Pilot subsidi atau ambang gratis ongkir di state berongkir tinggi dengan volume cukup (mis. BA atau PE) | Operations / Logistics, Head of Commercial | Order dan revenue state pilot vs pembanding; porsi revenue di luar SP (baseline 61,64%) | 5 |
| 5 | Investigasi penurunan `cool_stuff`, perluas assortment kategori yang tumbuh, dan wajibkan periode sebanding di laporan tahunan | Category Manager | Share kategori per periode sebanding; pertumbuhan kategori vs platform | 6 |

**Dasar urutan prioritas.** Retensi di urutan pertama karena menyangkut hampir seluruh basis customer (97,0% hanya belanja sekali) dan sekaligus menjawab temuan konsentrasi revenue. Nilai per order di urutan kedua karena AOV nyaris tidak naik (+0,5%) justru ketika volume mulai mendatar, sehingga menjadi pengungkit pertumbuhan berikutnya yang paling jelas. Isu ongkir di urutan ketiga dan keempat karena menyangkut 36,24% revenue (kategori) dan pertumbuhan di luar SP, tetapi biayanya belum bisa diukur tanpa data cost. Pergeseran kategori di urutan terakhir karena langkah pertamanya adalah investigasi, bukan eksekusi. Urutan ini adalah penilaian, bukan hasil perhitungan.

---

## Keterbatasan analisis

- **Tidak ada data cost atau profit.** Freight burden hanyalah proxy beban ongkir yang dibayar customer relatif terhadap harga barang — bukan profit dan bukan biaya perusahaan. Karena itu dampak finansial rekomendasi, misalnya biaya voucher atau subsidi ongkir, tidak bisa dihitung.
- **Tidak ada data promo, channel marketing, kompetitor, kunjungan/konversi, maupun review.** Semua penyebab di dokumen ini adalah hipotesis, dan dampak rekomendasi hanya ditulis sebagai arah. Rekomendasi sebaiknya diuji lewat eksperimen terkontrol sebelum diterapkan secara luas.
- **Jendela analisis hanya 20 bulan (2017-01 s/d 2018-08).** Bulan di ujung dataset dikecualikan karena datanya tidak lengkap, yaitu 267 order delivered atau 0,28% dari seluruh order delivered (`notebooks/01_data_cleaning.ipynb`, bagian 11). Karena 2018 hanya tersedia sampai Agustus, perbandingan antartahun memakai periode sebanding Jan–Agu (Q1c, Q2c).
- **Musim dan tren tidak bisa dipisahkan.** 2017 adalah tahun awal dengan basis yang masih tumbuh cepat, dan 2018 hanya delapan bulan, sehingga tidak ada tahun "normal" sebagai pembanding musiman.
- **Retensi sulit diukur dalam 20 bulan.** Customer yang bergabung di akhir periode hampir tidak punya waktu untuk kembali, siklus beli ulang barang tahan lama bisa lebih panjang dari jendela data, dan repeat rate hanya menghitung order di dalam jendela analisis.
- **Cakupan dataset tidak dijelaskan.** Dataset memuat 99.441 order untuk periode 2016–2018 (`notebooks/01_data_cleaning.ipynb`, bagian 1), tanpa penjelasan apakah ini seluruh transaksi atau sampel. [Medium confidence — dokumentasi dataset tidak menjelaskan metode pengambilannya.] Karena itu angka volume absolut sebaiknya tidak dibaca sebagai ukuran pasar.
- **Lokasi seller di luar scope.** Tabel sellers tidak dipakai, sehingga penjelasan berbasis jarak kirim tidak bisa diverifikasi. Berat dan dimensi produk ada di file mentah, tetapi belum dimodelkan.
- **State kecil punya sampel kecil** (misalnya RR hanya 40 order), sehingga angkanya mudah berfluktuasi.
- **Korelasi bukan sebab-akibat.** Pola yang muncul bersamaan — misalnya AOV tinggi dan ongkir tinggi di state jauh — belum tentu saling menyebabkan.
