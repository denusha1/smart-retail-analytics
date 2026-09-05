"""Automated checks for dashboard analytics and report generation."""

import unittest

import pandas as pd

import app


class DashboardAnalyticsTests(unittest.TestCase):
    def test_dataset_loads_expected_records(self):
        self.assertEqual(len(app.DATA), 28)

    def test_dashboard_summary(self):
        payload = app.dashboard_payload({})
        self.assertEqual(payload["summary"]["transactions"], 28)
        self.assertEqual(payload["summary"]["revenue"], 1249755.0)
        self.assertEqual(payload["pagination"]["page_count"], 3)

    def test_branch_filter_changes_results(self):
        payload = app.dashboard_payload({"branch": ["S001"]})
        selfGreater = self.assertGreater
        selfGreater(payload["summary"]["transactions"], 0)
        self.assertLess(payload["summary"]["transactions"], 28)
        self.assertTrue(all(row["branch"] == "S001" for row in payload["transactions"]))

    def test_pagination_returns_ten_records(self):
        payload = app.dashboard_payload({"page": ["2"]})
        self.assertEqual(payload["pagination"]["page"], 2)
        self.assertEqual(len(payload["transactions"]), 10)

    def test_pdf_report_has_valid_signature_and_branding(self):
        report = app.pdf_bytes({})
        self.assertTrue(report.startswith(b"%PDF-1.4"))
        self.assertIn(b"RETAILPULSE", report)
        self.assertIn(b"CATEGORY PERFORMANCE", report)

    def test_forecast_and_alerts_are_generated(self):
        intelligence = app.dashboard_payload({})["intelligence"]
        self.assertEqual(len(intelligence["forecast"]), 7)
        self.assertGreaterEqual(len(intelligence["alerts"]), 2)

    def test_raw_csv_schema_is_normalised_for_dashboard(self):
        raw = pd.DataFrame([{"date": "2024-02-01", "store_id": "S009", "product_name": "Demo Item", "product_category": "Food", "quantity_sold": 2, "unit_price": 100, "total_sales": 200, "customer_type": "Online", "region": "North"}])
        normalised = app.normalize_uploaded_data(raw)
        self.assertEqual(normalised.iloc[0]["branch"], "S009")
        self.assertEqual(normalised.iloc[0]["revenue"], 200)
        self.assertEqual(normalised.iloc[0]["estimated_profit"], 40)


if __name__ == "__main__":
    unittest.main()
