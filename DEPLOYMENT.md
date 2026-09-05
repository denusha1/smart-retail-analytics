# Deployment

## Render

1. Push this repository to GitHub.
2. In Render, choose **New > Blueprint** and select the repository.
3. Render reads `render.yaml`, installs dependencies, and starts the dashboard on its assigned `PORT`.
4. Configure these environment variables in Render before sharing the link:

   - `RETAIL_ADMIN_EMAIL`
   - `RETAIL_ADMIN_PASSWORD`

The service will receive a public URL such as `https://retailpulse-analytics.onrender.com` after deployment.

## Automated tests

Run the verification suite locally:

```bash
.venv/bin/python -m unittest discover -s tests -v
```

## Docker

```bash
docker build -t retailpulse .
docker run --rm -p 8000:8000 -e RETAIL_ADMIN_EMAIL=admin@company.lk -e RETAIL_ADMIN_PASSWORD=change-me retailpulse
```

## API documentation

After signing in, open `/docs.html` for Swagger UI. The OpenAPI JSON schema is served from `/api/openapi.json`.

## Real-time MySQL mode

1. Create the schema with `sql/01_database_setup.sql`.
2. Import transactions with `import_data.py` after configuring its database credentials.
3. Copy `.env.example` values into your hosting environment and set `DATABASE_URL`.

When `DATABASE_URL` is set, the API refreshes data from MySQL for every analytics request. The browser dashboard polls for updates every 30 seconds, so new sales, target changes, and inventory alerts appear without a manual page refresh.
