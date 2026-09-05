# Smart Retail Web Dashboard

A responsive, data-backed dashboard is available without requiring Power BI or a database.

Run it from the repository root:

```bash
.venv/bin/python app.py
```

Then open [http://127.0.0.1:8000](http://127.0.0.1:8000). The dashboard exposes a small REST API and reads `data/processed/retail_enriched.csv`, so filters and KPIs stay aligned with the current dataset.
