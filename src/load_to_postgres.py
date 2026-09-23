"""
load_to_postgres.py
Memasukkan 4 CSV bersih (data/processed/) ke tabel PostgreSQL yang sudah
dibuat oleh sql/01_create_schema.sql.

PENTING - PORT: PostgreSQL 17 di mesin pengembangan ini berjalan di port 5433,
bukan 5432 (port 5432 sudah dipakai container Docker milik project lain).
Port harus ditulis eksplisit di connection string.

Menyetel kredensial (PowerShell). Cara di bawah membuat password diketik tanpa
tampil di layar dan tidak ikut tersimpan di riwayat perintah:

    $pw    = Read-Host "Password user postgres" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                 [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw))
    $enc   = [uri]::EscapeDataString($plain)   # aman untuk karakter @ : / # % ?
    [Environment]::SetEnvironmentVariable(
        'NUSAMART_DB_URL',
        "postgresql+psycopg2://postgres:$enc@localhost:5433/nusamart",
        'User')

Lalu buka PowerShell BARU (supaya variabel terbaca), dan jalankan:

    python src/load_to_postgres.py

Kenapa lewat environment variable? Supaya password tidak pernah tertulis di
dalam kode atau file repo, sehingga tidak mungkin ikut ter-commit ke GitHub.
`EscapeDataString` sekaligus menangani password berkarakter khusus, yang kalau
tidak di-encode akan merusak struktur connection string.
"""
import os
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

DB_URL = os.environ.get("NUSAMART_DB_URL")
if not DB_URL:
    sys.exit("NUSAMART_DB_URL belum di-set. Lihat petunjuk di bagian atas file ini.")

PROCESSED = Path(__file__).resolve().parent.parent / "data" / "processed"

# Urutan penting: tabel dimensi dulu, fact terakhir (karena ada foreign key)
TABLES = [
    ("dim_date", ["date_key"]),
    ("dim_customer", ["first_order_date"]),
    ("dim_product", []),
    ("fact_sales", ["order_date"]),
]

engine = create_engine(DB_URL)

# Kosongkan tabel dulu supaya script aman dijalankan ulang (tidak dobel)
with engine.begin() as conn:
    conn.execute(text("TRUNCATE fact_sales, dim_customer, dim_product, dim_date;"))

for table, date_cols in TABLES:
    df = pd.read_csv(PROCESSED / f"{table}.csv", parse_dates=date_cols)
    for col in date_cols:
        df[col] = df[col].dt.date
    df.to_sql(table, engine, if_exists="append", index=False, chunksize=5000, method="multi")
    print(f"{table:14s} {len(df):>8,} baris dimuat")

# Verifikasi: jumlah baris di database harus sama dengan CSV
with engine.connect() as conn:
    for table, _ in TABLES:
        n_db = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
        n_csv = len(pd.read_csv(PROCESSED / f"{table}.csv"))
        status = "OK" if n_db == n_csv else "TIDAK SAMA"
        print(f"cek {table:14s} db={n_db:,} csv={n_csv:,} -> {status}")
