"""Seed an empty Supabase transactions table from the processed project dataset."""
import json
from urllib.error import HTTPError
import os
import urllib.request
import pandas as pd
from dotenv import load_dotenv

load_dotenv()
url = (os.getenv("SUPABASE_URL") or os.getenv("NEXT_PUBLIC_SUPABASE_URL") or "").rstrip("/")
key = os.getenv("SUPABASE_ANON_KEY") or os.getenv("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY")
if not url or not key:
    raise SystemExit("Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY in .env first.")

headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json", "Prefer": "return=minimal"}
def request(path, method="GET", payload=None):
    body = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(f"{url}/rest/v1/{path}", data=body, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=20) as response:
        return response.read()

existing = int(request("transactions?select=transaction_id", method="GET").count(b"transaction_id"))
if existing:
    print(f"Supabase already has transaction data; skipped seed ({existing}+ records found).")
    raise SystemExit(0)

df = pd.read_csv("data/processed/retail_enriched.csv")
columns = {"date":"transaction_date", "branch":"branch_id", "product_name":"product_name", "product_category":"category", "customer_type":"customer_type", "customer_segment":"customer_segment", "quantity_sold":"quantity_sold", "unit_price":"unit_price", "total_sales":"total_sales", "discount_percent":"discount_percent", "revenue":"revenue", "estimated_profit_margin_percent":"profit_margin_percent", "estimated_profit":"estimated_profit", "profit_margin":"profit_margin", "sales_performance":"sales_performance"}
records = df[list(columns)].rename(columns=columns).to_dict(orient="records")
try:
    request("transactions", method="POST", payload=records)
except HTTPError as error:
    detail = error.read().decode("utf-8", errors="replace")
    if error.code in (401, 403):
        raise SystemExit(
            "Supabase rejected inserts. Run sql/02_supabase_api_access.sql in the Supabase SQL Editor, then rerun this script."
        ) from error
    raise SystemExit(f"Supabase insert failed ({error.code}): {detail}") from error
print(f"Seeded {len(records)} transactions into Supabase.")
