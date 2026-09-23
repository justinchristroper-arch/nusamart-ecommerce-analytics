"""
right_censoring_check.py
Cek right-censoring untuk Insight 1 ("volume 2018 mulai mendatar").

Masalahnya: fact_sales hanya berisi order DELIVERED. Order yang dibeli menjelang
akhir data mungkin belum sempat delivered saat data ditarik (17 Okt 2018),
sehingga order delivered di bulan-bulan akhir bisa tampak turun padahal hanya
belum selesai dikirim. Order non-delivered memang tidak dimuat ke star schema,
jadi script ini menghitung order SEMUA status langsung dari file mentah.

Output:
- results/02_q1d_orders_all_status_monthly.csv
    order per bulan pembelian, dipecah menjadi delivered / masih diproses /
    dibatalkan, plus batas atas: delivered + masih diproses (kalau semua order
    yang masih diproses kelak delivered).
- results/02_q1e_orders_daily_aug_sep_2018.csv
    order per hari, 1 Agu s/d 30 Sep 2018, untuk melihat apakah akhir Agustus
    terpotong oleh berakhirnya pengumpulan data.

Cara pakai (dari folder root repo):
    .venv\\Scripts\\python.exe src/right_censoring_check.py
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw" / "olist_orders_dataset.csv"
OUT = ROOT / "results"

# Status yang belum final (masih mungkin menjadi delivered) vs yang sudah final
IN_PROCESS = ["shipped", "invoiced", "processing", "approved", "created"]
CANCELLED = ["canceled", "unavailable"]
ANALYSIS_MONTHS = ("2017-01", "2018-08")  # sama dengan dim_date.is_analysis_month

orders = pd.read_csv(
    RAW,
    usecols=["order_id", "order_status", "order_purchase_timestamp"],
    parse_dates=["order_purchase_timestamp"],
)
orders["group"] = np.select(
    [
        orders["order_status"].eq("delivered"),
        orders["order_status"].isin(IN_PROCESS),
        orders["order_status"].isin(CANCELLED),
    ],
    ["delivered", "in_process", "canceled_unavailable"],
    default="other",
)
assert (orders["group"] != "other").all(), "Ada status order yang belum dipetakan"


def per_group(key):
    t = pd.crosstab(orders[key], orders["group"])
    t = t.reindex(columns=["delivered", "in_process", "canceled_unavailable"], fill_value=0)
    t.insert(0, "orders_all_status", t.sum(axis=1))
    return t


# ---------- per bulan ----------
orders["month"] = orders["order_purchase_timestamp"].dt.to_period("M")
monthly = per_group("month")
monthly = monthly.reindex(pd.period_range(monthly.index.min(), monthly.index.max(), freq="M"), fill_value=0)
monthly["delivered_upper_bound"] = monthly["delivered"] + monthly["in_process"]
monthly["pct_delivered"] = (
    monthly["delivered"] / monthly["orders_all_status"].where(monthly["orders_all_status"] > 0) * 100
).round(2)
monthly["pct_in_process"] = (
    monthly["in_process"] / monthly["orders_all_status"].where(monthly["orders_all_status"] > 0) * 100
).round(2)
monthly.index = monthly.index.astype(str)
monthly.index.name = "month"
monthly["is_analysis_month"] = monthly.index.to_series().between(*ANALYSIS_MONTHS)
monthly.to_csv(OUT / "02_q1d_orders_all_status_monthly.csv")

# ---------- per hari, Agustus-September 2018 ----------
orders["date"] = orders["order_purchase_timestamp"].dt.normalize()
daily = per_group("date")
days = pd.date_range("2018-08-01", "2018-09-30", freq="D")
daily = daily.reindex(days, fill_value=0)
daily.index.name = "date"
daily.insert(0, "day_of_week", daily.index.dayofweek + 1)  # 1 = Senin
daily.index = daily.index.strftime("%Y-%m-%d")
daily.to_csv(OUT / "02_q1e_orders_daily_aug_sep_2018.csv")

pd.set_option("display.width", 200)
print("=== Order per bulan (2018 + batas data) ===")
print(monthly.loc["2017-12":].to_string())
print("\n=== Order per hari, 20 Agu - 10 Sep 2018 ===")
print(daily.loc["2018-08-20":"2018-09-10"].to_string())
print(f"\nTersimpan: results/02_q1d_orders_all_status_monthly.csv ({len(monthly)} baris)")
print(f"Tersimpan: results/02_q1e_orders_daily_aug_sep_2018.csv ({len(daily)} baris)")
