# DAX Measures — NusaMart Dashboard

Buat measure di Power BI Desktop: pilih tabel `fact_sales` → **New measure** → tempel satu per satu.
Semua angka harus cocok dengan `sql/05_kpi_reference.sql`.

## Persiapan model (Model view)

1. Relasi (one-to-many, single direction):
   - `dim_date[date_key]` → `fact_sales[order_date]`
   - `dim_customer[customer_unique_id]` → `fact_sales[customer_unique_id]`
   - `dim_product[product_id]` → `fact_sales[product_id]`
2. Klik kanan `dim_date` → **Mark as date table** → kolom `date_key`.
3. Di `dim_date`, sort kolom `month_name` berdasarkan `month` (Column tools → Sort by column), supaya urutan bulan benar.

## KPI utama

```DAX
Total Revenue = SUM ( fact_sales[price] )

Total Orders = DISTINCTCOUNT ( fact_sales[order_id] )

Total Customers = DISTINCTCOUNT ( fact_sales[customer_unique_id] )

AOV = DIVIDE ( [Total Revenue], [Total Orders] )

Units Sold = COUNTROWS ( fact_sales )

Total Freight = SUM ( fact_sales[freight_value] )

Freight Burden % = DIVIDE ( [Total Freight], [Total Revenue] )
```

`DIVIDE` dipakai (bukan `/`) karena otomatis menangani pembagian dengan nol.
Freight Burden dihitung sebagai rasio dari total, **bukan** rata-rata rasio per baris.

## Pertumbuhan (butuh dim_date yang sudah di-mark sebagai date table)

```DAX
Revenue PM = CALCULATE ( [Total Revenue], DATEADD ( dim_date[date_key], -1, MONTH ) )

Revenue MoM % = DIVIDE ( [Total Revenue] - [Revenue PM], [Revenue PM] )

Revenue PY = CALCULATE ( [Total Revenue], SAMEPERIODLASTYEAR ( dim_date[date_key] ) )

Revenue YoY % = DIVIDE ( [Total Revenue] - [Revenue PY], [Revenue PY] )
```

## Customer

```DAX
-- Customer baru = order pertamanya jatuh di periode yang sedang difilter
New Customers =
VAR MinDate = MIN ( dim_date[date_key] )
VAR MaxDate = MAX ( dim_date[date_key] )
RETURN
    CALCULATE (
        [Total Customers],
        FILTER (
            dim_customer,
            dim_customer[first_order_date] >= MinDate
                && dim_customer[first_order_date] <= MaxDate
        )
    )

Returning Customers = [Total Customers] - [New Customers]

Returning Customer % = DIVIDE ( [Returning Customers], [Total Customers] )

-- Customer yang punya >= 2 order dalam konteks filter saat ini
Repeat Customers =
COUNTROWS (
    FILTER (
        VALUES ( fact_sales[customer_unique_id] ),
        CALCULATE ( DISTINCTCOUNT ( fact_sales[order_id] ) ) >= 2
    )
)

Repeat Rate % = DIVIDE ( [Repeat Customers], [Total Customers] )
```

Catatan: angka new vs returning **per bulan** di Power BI harus sama dengan query Q4c di `sql/03_customer_analysis.sql`. Cek minimal 2–3 bulan secara manual.

Konsentrasi revenue per desil (Q5a) lebih mudah dan lebih akurat dihitung di SQL. Tampilkan hasilnya di dashboard sebagai tabel/visual dari query tersebut, atau tulis angkanya di halaman insight.
