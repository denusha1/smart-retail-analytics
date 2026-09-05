FROM python:3.11-slim
WORKDIR /app
COPY app.py ./
COPY data/processed/retail_enriched.csv data/processed/retail_enriched.csv
COPY dashboard/web dashboard/web
RUN pip install --no-cache-dir pandas numpy
EXPOSE 8000
ENV PORT=8000
CMD ["python", "app.py", "--host", "0.0.0.0"]
