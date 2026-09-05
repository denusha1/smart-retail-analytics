#!/usr/bin/env python3
"""Smart Retail Analytics web dashboard.

Run: .venv/bin/python app.py
Open: http://127.0.0.1:8000
"""

from __future__ import annotations

import argparse
import cgi
import io
import json
import mimetypes
import os
import secrets
import threading
from http.cookies import SimpleCookie
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import pandas as pd
import numpy as np


ROOT = Path(__file__).resolve().parent
DATA_FILE = ROOT / "data" / "processed" / "retail_enriched.csv"
STATIC_DIR = ROOT / "dashboard" / "web"


def load_data() -> pd.DataFrame:
    df = pd.read_csv(DATA_FILE, parse_dates=["date"])
    return df.sort_values("date").reset_index(drop=True)


DATA = load_data()
DATA_LOCK = threading.RLock()
SESSIONS: set[str] = set()
SESSION_LOCK = threading.RLock()
ADMIN_EMAIL = os.getenv("RETAIL_ADMIN_EMAIL", "admin@retailpulse.lk")
ADMIN_PASSWORD = os.getenv("RETAIL_ADMIN_PASSWORD", "RetailPulse@2026")


def money(value: float) -> float:
    return round(float(value), 2)


def filtered_data(params: dict[str, list[str]]) -> pd.DataFrame:
    with DATA_LOCK:
        df = DATA.copy()
    for column in ("branch", "product_category", "customer_type"):
        value = params.get(column, [""])[0]
        if value:
            df = df[df[column] == value]
    start_date = params.get("start_date", [""])[0]
    end_date = params.get("end_date", [""])[0]
    if start_date:
        df = df[df["date"] >= pd.to_datetime(start_date)]
    if end_date:
        df = df[df["date"] <= pd.to_datetime(end_date)]
    return df


def normalize_uploaded_data(uploaded: pd.DataFrame) -> pd.DataFrame:
    """Accept either the project raw schema or the enriched schema and standardise it."""
    required = {"date", "product_name", "product_category", "quantity_sold", "unit_price", "customer_type"}
    missing = required - set(uploaded.columns)
    if missing:
        raise ValueError(f"Missing required columns: {', '.join(sorted(missing))}")
    df = uploaded.copy()
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    if df["date"].isna().any():
        raise ValueError("Every date must use a valid date format.")
    for column in ("quantity_sold", "unit_price"):
        df[column] = pd.to_numeric(df[column], errors="coerce")
    if df[["quantity_sold", "unit_price"]].isna().any().any():
        raise ValueError("Quantity sold and unit price must be numeric.")
    df["branch"] = df["branch"] if "branch" in df else (df["store_id"] if "store_id" in df else "S001")
    df["branch"] = df["branch"].fillna("S001")
    df["store_id"] = df["store_id"] if "store_id" in df else df["branch"]
    df["store_id"] = df["store_id"].fillna(df["branch"])
    df["region"] = df["region"] if "region" in df else "Unassigned"
    df["region"] = df["region"].fillna("Unassigned")
    df["total_sales"] = pd.to_numeric(df.get("total_sales", df["quantity_sold"] * df["unit_price"]), errors="coerce")
    df["revenue"] = pd.to_numeric(df.get("revenue", df["total_sales"]), errors="coerce")
    zeroes = pd.Series(0, index=df.index)
    df["discount_amount"] = pd.to_numeric(df.get("discount_amount", zeroes), errors="coerce").fillna(0)
    df["discount_percent"] = pd.to_numeric(df.get("discount_percent", zeroes), errors="coerce").fillna(0)
    default_margin = df["product_category"].map({"Electronics": 30, "Clothing": 40, "Home": 40, "Food": 20}).fillna(30)
    df["estimated_profit_margin_percent"] = pd.to_numeric(df.get("estimated_profit_margin_percent", default_margin), errors="coerce").fillna(default_margin)
    df["estimated_profit"] = pd.to_numeric(df.get("estimated_profit", df["revenue"] * df["estimated_profit_margin_percent"] / 100), errors="coerce")
    df["profit_margin"] = pd.to_numeric(df.get("profit_margin", df["estimated_profit_margin_percent"]), errors="coerce")
    df["customer_segment"] = df.get("customer_segment", df["customer_type"]).fillna(df["customer_type"])
    df["expected_total"] = pd.to_numeric(df.get("expected_total", df["revenue"]), errors="coerce")
    df["order_value"] = pd.to_numeric(df.get("order_value", df["revenue"]), errors="coerce")
    df["month"], df["year"] = df["date"].dt.month, df["date"].dt.year
    df["day_of_week"] = df["date"].dt.day_name()
    df["sales_performance"] = df.get("sales_performance", pd.Series("Standard", index=df.index)).fillna("Standard")
    columns = ["date", "month", "year", "day_of_week", "branch", "region", "store_id", "product_name", "product_category", "customer_type", "customer_segment", "quantity_sold", "unit_price", "total_sales", "discount_amount", "discount_percent", "revenue", "expected_total", "estimated_profit_margin_percent", "estimated_profit", "profit_margin", "sales_performance", "order_value"]
    return df[columns].sort_values("date").reset_index(drop=True)


def forecast_and_alerts(df: pd.DataFrame) -> dict:
    """Generate an explainable linear trend forecast and operational alerts."""
    daily = df.groupby("date", sort=True)["revenue"].sum() if not df.empty else pd.Series(dtype=float)
    if len(daily) < 2:
        return {"forecast": [], "trend": "Insufficient data", "trend_percent": 0, "alerts": []}
    x = np.arange(len(daily))
    slope, intercept = np.polyfit(x, daily.to_numpy(), 1)
    last_date = daily.index[-1]
    forecast = []
    for day in range(1, 8):
        value = max(0, slope * (len(daily) + day - 1) + intercept)
        forecast.append({"date": (last_date + pd.Timedelta(days=day)).strftime("%d %b"), "value": money(value)})
    average_daily = float(daily.mean())
    trend_percent = round((slope * 7 / average_daily * 100) if average_daily else 0, 1)
    branch = df.groupby("branch")["revenue"].sum().sort_values()
    alerts = []
    if not branch.empty:
        alerts.append({"level": "attention", "title": f"Review {branch.index[0]} performance", "detail": f"It has the lowest revenue at LKR {branch.iloc[0]:,.0f}."})
    low_days = daily[daily < average_daily * 0.75]
    if not low_days.empty:
        alerts.append({"level": "insight", "title": "Low-sales days identified", "detail": f"{len(low_days)} day(s) were more than 25% below average daily revenue."})
    if df["discount_percent"].nunique() <= 1:
        alerts.append({"level": "opportunity", "title": "Test a controlled promotion", "detail": "No discount variation is present, so price sensitivity cannot yet be measured."})
    return {"forecast": forecast, "trend": "Upward" if slope >= 0 else "Downward", "trend_percent": abs(trend_percent), "alerts": alerts}


def dashboard_payload(params: dict[str, list[str]]) -> dict:
    df = filtered_data(params)
    page_size = 10
    page = max(int(params.get("page", ["1"])[0]), 1)
    revenue = money(df["revenue"].sum())
    profit = money(df["estimated_profit"].sum())
    by_category = df.groupby("product_category", sort=False)["revenue"].sum().sort_values(ascending=False)
    by_branch = df.groupby("branch", sort=False)["revenue"].sum().sort_values(ascending=False)
    comparison_period = params.get("comparison_period", ["daily"])[0]
    period_aliases = {"monthly": "M", "quarterly": "Q", "yearly": "Y"}
    if comparison_period in period_aliases:
        series = df.groupby(df["date"].dt.to_period(period_aliases[comparison_period]))["revenue"].sum()
        labels = [str(index) for index in series.index]
    else:
        series = df.groupby("date", sort=True)["revenue"].sum()
        labels = [index.strftime("%d %b") for index in series.index]
    recent = df.sort_values("date", ascending=False)
    total_transactions = len(recent)
    page_count = max((total_transactions + page_size - 1) // page_size, 1)
    page = min(page, page_count)
    recent = recent.iloc[(page - 1) * page_size: page * page_size]

    return {
        "summary": {
            "revenue": revenue,
            "profit": profit,
            "margin": round((profit / revenue * 100) if revenue else 0, 1),
            "transactions": int(len(df)),
            "quantity": int(df["quantity_sold"].sum()),
            "average_order": money(df["order_value"].mean()) if not df.empty else 0,
        },
        "charts": {
            "revenue_by_category": [{"label": str(k), "value": money(v)} for k, v in by_category.items()],
            "revenue_by_branch": [{"label": str(k), "value": money(v)} for k, v in by_branch.items()],
            "daily_revenue": [{"label": label, "value": money(value)} for label, value in zip(labels, series.values)],
        },
        "transactions": [
            {
                "date": row.date.strftime("%d %b %Y"), "branch": row.branch,
                "product": row.product_name, "category": row.product_category,
                "channel": row.customer_type, "quantity": int(row.quantity_sold),
                "revenue": money(row.revenue), "profit": money(row.estimated_profit),
            }
            for row in recent.itertuples()
        ],
        "pagination": {"page": page, "page_size": page_size, "page_count": page_count, "total": total_transactions},
        "intelligence": forecast_and_alerts(df),
    }


def pdf_bytes(params: dict[str, list[str]]) -> bytes:
    """Create a branded one-page PDF report without an external PDF dependency."""
    df = filtered_data(params)
    revenue, profit = money(df["revenue"].sum()), money(df["estimated_profit"].sum())
    margin = profit / revenue * 100 if revenue else 0
    category = df.groupby("product_category")["revenue"].sum().sort_values(ascending=False)
    escape = lambda value: str(value).replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
    commands: list[str] = []
    def rect(x: int, y: int, width: int, height: int, color: str) -> None: commands.append(f"{color} rg {x} {y} {width} {height} re f")
    def text(value: str, x: int, y: int, size: int, color: str, bold: bool = False) -> None:
        commands.extend(("BT", f"/{'F2' if bold else 'F1'} {size} Tf", f"{color} rg", f"{x} {y} Td", f"({escape(value)}) Tj", "ET"))
    # Branded header and report metadata
    rect(0, 730, 595, 112, "0.055 0.125 0.29")
    rect(50, 788, 26, 26, "0.27 0.58 0.95")
    text("RP", 55, 796, 10, "1 1 1", True)
    text("RETAILPULSE", 86, 800, 11, "0.75 0.88 1", True)
    text("SMART RETAIL ANALYTICS", 86, 785, 8, "0.57 0.72 0.93")
    text("Performance report", 50, 754, 25, "1 1 1", True)
    text("Prepared from the current selected retail dataset", 51, 737, 9, "0.78 0.86 0.97")
    text("CONFIDENTIAL BUSINESS REPORT", 388, 794, 8, "0.58 0.75 0.98", True)
    # KPI cards
    cards = [(50, "TOTAL REVENUE", f"LKR {revenue:,.0f}", "0.15 0.37 0.72"), (230, "ESTIMATED PROFIT", f"LKR {profit:,.0f}", "0.08 0.57 0.43"), (410, "PROFIT MARGIN", f"{margin:.1f}%", "0.88 0.48 0.12")]
    for x, label, value, accent in cards:
        rect(x, 620, 145, 82, "0.97 0.985 1")
        rect(x, 620, 4, 82, accent)
        text(label, x + 14, 681, 8, "0.38 0.47 0.61", True)
        text(value, x + 14, 651, 17, "0.10 0.20 0.36", True)
        text("Current filtered view", x + 14, 633, 8, "0.50 0.58 0.69")
    text("PERFORMANCE SNAPSHOT", 50, 583, 10, "0.18 0.31 0.53", True)
    text(f"{len(df)} transactions analysed", 50, 563, 10, "0.31 0.40 0.53")
    text(f"{int(df['quantity_sold'].sum()):,} total units sold", 220, 563, 10, "0.31 0.40 0.53")
    text(f"Average order: LKR {df['order_value'].mean() if not df.empty else 0:,.0f}", 385, 563, 10, "0.31 0.40 0.53")
    # Category revenue table and bars
    rect(50, 278, 495, 245, "0.985 0.99 1")
    text("CATEGORY PERFORMANCE", 68, 494, 11, "0.12 0.25 0.45", True)
    text("Category", 68, 469, 8, "0.39 0.48 0.61", True)
    text("Revenue", 434, 469, 8, "0.39 0.48 0.61", True)
    max_value = float(category.max()) if not category.empty else 1
    for index, (name, value) in enumerate(category.items()):
        y = 438 - index * 42
        rect(68, y - 8, 460, 1, "0.90 0.94 0.98")
        text(name, 68, y + 5, 10, "0.17 0.29 0.49", True)
        rect(185, y, int(190 * value / max_value), 8, "0.28 0.58 0.93")
        text(f"LKR {value:,.0f}", 434, y + 5, 10, "0.12 0.29 0.55", True)
    # Footer
    rect(0, 0, 595, 44, "0.055 0.125 0.29")
    text("RetailPulse | Decision-ready retail intelligence", 50, 18, 8, "0.72 0.84 0.97")
    text("Generated report", 465, 18, 8, "0.72 0.84 0.97")
    stream = "\n".join(commands).encode("latin-1", "replace")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>", b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> /Contents 4 0 R >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>", b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>",
    ]
    result = bytearray(b"%PDF-1.4\n")
    offsets = []
    for index, obj in enumerate(objects, 1):
        offsets.append(len(result))
        result.extend(f"{index} 0 obj\n".encode() + obj + b"\nendobj\n")
    xref = len(result)
    result.extend(f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode())
    result.extend(b"".join(f"{offset:010d} 00000 n \n".encode() for offset in offsets))
    result.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode())
    return bytes(result)


def openapi_spec() -> dict:
    paths = {
        "/api/auth": "Current authentication session",
        "/api/filters": "Available dashboard filters",
        "/api/dashboard": "Analytics, comparison, forecast and alerts",
        "/api/upload": "Upload and normalise retail CSV data",
        "/api/export.csv": "Download filtered transactions as CSV",
        "/api/export.pdf": "Download a branded performance report",
    }
    return {"openapi": "3.0.3", "info": {"title": "RetailPulse Analytics API", "version": "1.0.0"}, "paths": {path: {"get" if path != "/api/upload" else "post": {"summary": summary, "responses": {"200": {"description": "Success"}}}} for path, summary in paths.items()}}


class DashboardHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: object) -> None:
        print(f"[{self.log_date_time_string()}] {fmt % args}")

    def send_json(self, payload: dict, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_download(self, content: bytes, filename: str, content_type: str) -> None:
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def session_id(self) -> str | None:
        cookie = SimpleCookie(self.headers.get("Cookie"))
        return cookie.get("retailpulse_session").value if cookie.get("retailpulse_session") else None

    def authenticated(self) -> bool:
        session_id = self.session_id()
        with SESSION_LOCK:
            return bool(session_id and session_id in SESSIONS)

    def redirect(self, location: str) -> None:
        self.send_response(HTTPStatus.SEE_OTHER)
        self.send_header("Location", location)
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        if parsed.path == "/login.html":
            if self.authenticated():
                self.redirect("/")
                return
        elif parsed.path == "/api/auth":
            self.send_json({"authenticated": self.authenticated(), "user": ADMIN_EMAIL if self.authenticated() else None})
            return
        elif parsed.path.startswith("/api/") and not self.authenticated():
            self.send_json({"error": "Authentication required"}, HTTPStatus.UNAUTHORIZED)
            return
        elif parsed.path not in ("/styles.css", "/styles-v2.css", "/login-styles.css", "/login.js", "/favicon.ico") and not self.authenticated():
            self.redirect("/login.html")
            return
        if parsed.path == "/api/health":
            self.send_json({"status": "ok", "records": len(DATA)})
            return
        if parsed.path == "/api/openapi.json":
            self.send_json(openapi_spec())
            return
        if parsed.path == "/api/filters":
            self.send_json({
                "branches": sorted(DATA["branch"].unique().tolist()),
                "categories": sorted(DATA["product_category"].unique().tolist()),
                "channels": sorted(DATA["customer_type"].unique().tolist()),
            })
            return
        if parsed.path == "/api/dashboard":
            self.send_json(dashboard_payload(params))
            return
        if parsed.path == "/api/export.csv":
            columns = ["date", "branch", "product_name", "product_category", "customer_type", "quantity_sold", "revenue", "estimated_profit"]
            content = filtered_data(params)[columns].to_csv(index=False).encode("utf-8")
            self.send_download(content, "retailpulse-transactions.csv", "text/csv; charset=utf-8")
            return
        if parsed.path == "/api/export.pdf":
            self.send_download(pdf_bytes(params), "retailpulse-performance-report.pdf", "application/pdf")
            return

        requested = "index.html" if parsed.path in ("/", "") else parsed.path.lstrip("/")
        target = (STATIC_DIR / requested).resolve()
        if STATIC_DIR.resolve() not in target.parents and target != STATIC_DIR.resolve():
            self.send_error(HTTPStatus.FORBIDDEN)
            return
        if not target.is_file():
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        content = target.read_bytes()
        if requested == "login-styles.css":
            content += b"\n" + (STATIC_DIR / "login-premium.css").read_bytes()
        if requested == "styles-v2.css":
            content += b"\n" + (STATIC_DIR / "upload-and-filters.css").read_bytes()
            content += b"\n" + (STATIC_DIR / "date-filters.css").read_bytes()
        if requested.endswith(".html") and requested != "login.html":
            content = content.replace(b"</body>", b'<script src="/theme.js"></script></body>')
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", mimetypes.guess_type(str(target))[0] or "application/octet-stream")
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/api/login":
            length = int(self.headers.get("Content-Length", "0"))
            try:
                payload = json.loads(self.rfile.read(length).decode("utf-8"))
            except (json.JSONDecodeError, UnicodeDecodeError):
                self.send_json({"error": "Invalid request body"}, HTTPStatus.BAD_REQUEST)
                return
            email = str(payload.get("email", ""))
            password = str(payload.get("password", ""))
            if not (secrets.compare_digest(email, ADMIN_EMAIL) and secrets.compare_digest(password, ADMIN_PASSWORD)):
                self.send_json({"error": "Incorrect email or password"}, HTTPStatus.UNAUTHORIZED)
                return
            session_id = secrets.token_urlsafe(32)
            with SESSION_LOCK:
                SESSIONS.add(session_id)
            body = json.dumps({"ok": True}).encode("utf-8")
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Set-Cookie", f"retailpulse_session={session_id}; HttpOnly; SameSite=Lax; Path=/")
            self.end_headers()
            self.wfile.write(body)
            return
        if not self.authenticated():
            self.send_json({"error": "Authentication required"}, HTTPStatus.UNAUTHORIZED)
            return
        if parsed.path == "/api/upload":
            if int(self.headers.get("Content-Length", "0")) > 10 * 1024 * 1024:
                self.send_json({"error": "CSV upload must be 10 MB or smaller."}, HTTPStatus.REQUEST_ENTITY_TOO_LARGE)
                return
            try:
                form = cgi.FieldStorage(fp=self.rfile, headers=self.headers, environ={"REQUEST_METHOD": "POST", "CONTENT_TYPE": self.headers.get("Content-Type", "")})
                if "file" not in form or not getattr(form["file"], "file", None):
                    raise ValueError("Choose a CSV file to upload.")
                uploaded = pd.read_csv(io.BytesIO(form["file"].file.read()))
                normalized = normalize_uploaded_data(uploaded)
                global DATA
                with DATA_LOCK:
                    backup = DATA_FILE.with_name("retail_enriched.backup.csv")
                    if DATA_FILE.exists():
                        DATA_FILE.replace(backup)
                    normalized.to_csv(DATA_FILE, index=False)
                    DATA = normalized
                self.send_json({"ok": True, "records": len(DATA), "backup": backup.name})
            except (ValueError, pd.errors.ParserError, UnicodeDecodeError) as error:
                self.send_json({"error": str(error)}, HTTPStatus.BAD_REQUEST)
            return
        if parsed.path == "/api/logout":
            session_id = self.session_id()
            with SESSION_LOCK:
                SESSIONS.discard(session_id) if session_id else None
            self.send_json({"ok": True})
            return
        self.send_error(HTTPStatus.NOT_FOUND)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the Smart Retail Analytics dashboard")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=int(os.getenv("PORT", "8000")))
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), DashboardHandler)
    print(f"Smart Retail dashboard running at http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
