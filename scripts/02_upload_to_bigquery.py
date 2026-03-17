"""
02_upload_to_bigquery.py
Upload generated CSV files to Google BigQuery.
Prerequisite: gcloud auth application-default login
"""

import os
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
import pandas as pd

# ── Config — edit these ───────────────────────────────────────────────────────
PROJECT_ID  = "your-gcp-project-id"       # ← replace
DATASET_ID  = "traffic_ad_roi"             # will be created if not exist
DATA_DIR    = os.path.join(os.path.dirname(__file__), "..", "data")
LOCATION    = "US"

# ── BigQuery schemas ─────────────────────────────────────────────────────────
SCHEMAS = {
    "campaigns": [
        bigquery.SchemaField("campaign_id",   "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("campaign_name", "STRING"),
        bigquery.SchemaField("channel",       "STRING"),
        bigquery.SchemaField("campaign_type", "STRING"),
        bigquery.SchemaField("daily_budget",  "FLOAT64"),
        bigquery.SchemaField("start_date",    "DATE"),
        bigquery.SchemaField("end_date",      "DATE"),
    ],
    "ad_impressions": [
        bigquery.SchemaField("impression_id",  "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("campaign_id",    "STRING"),
        bigquery.SchemaField("date",           "DATE"),
        bigquery.SchemaField("impressions",    "INTEGER"),
        bigquery.SchemaField("clicks",         "INTEGER"),
        bigquery.SchemaField("ctr",            "FLOAT64"),
        bigquery.SchemaField("spend_usd",      "FLOAT64"),
    ],
    "sessions": [
        bigquery.SchemaField("session_id",           "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("campaign_id",          "STRING"),
        bigquery.SchemaField("channel",              "STRING"),
        bigquery.SchemaField("session_date",         "DATE"),
        bigquery.SchemaField("session_ts",           "DATETIME"),
        bigquery.SchemaField("device",               "STRING"),
        bigquery.SchemaField("country",              "STRING"),
        bigquery.SchemaField("pages_viewed",         "INTEGER"),
        bigquery.SchemaField("session_duration_sec", "INTEGER"),
        bigquery.SchemaField("is_bounce",            "INTEGER"),
    ],
    "conversions": [
        bigquery.SchemaField("order_id",         "STRING",  mode="REQUIRED"),
        bigquery.SchemaField("session_id",       "STRING"),
        bigquery.SchemaField("campaign_id",      "STRING"),
        bigquery.SchemaField("channel",          "STRING"),
        bigquery.SchemaField("order_date",       "DATE"),
        bigquery.SchemaField("order_ts",         "DATETIME"),
        bigquery.SchemaField("order_value_usd",  "FLOAT64"),
        bigquery.SchemaField("device",           "STRING"),
        bigquery.SchemaField("country",          "STRING"),
    ],
}

def ensure_dataset(client):
    dataset_ref = f"{PROJECT_ID}.{DATASET_ID}"
    try:
        client.get_dataset(dataset_ref)
        print(f"  Dataset {DATASET_ID} already exists.")
    except NotFound:
        ds = bigquery.Dataset(dataset_ref)
        ds.location = LOCATION
        client.create_dataset(ds)
        print(f"  Dataset {DATASET_ID} created.")

def upload_table(client, table_name):
    csv_path  = os.path.join(DATA_DIR, f"{table_name}.csv")
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

    df = pd.read_csv(csv_path)
    print(f"  Uploading {table_name}: {len(df):,} rows...")

    job_config = bigquery.LoadJobConfig(
        schema=SCHEMAS[table_name],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        skip_leading_rows=1,
        source_format=bigquery.SourceFormat.CSV,
    )

    job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
    job.result()
    print(f"  ✓ {table_name} uploaded successfully.")

def main():
    client = bigquery.Client(project=PROJECT_ID)
    print(f"Connected to BigQuery project: {PROJECT_ID}")

    ensure_dataset(client)

    for table in ["campaigns", "ad_impressions", "sessions", "conversions"]:
        upload_table(client, table)

    print("\n=== All tables uploaded to BigQuery ===")
    print(f"Dataset: {PROJECT_ID}.{DATASET_ID}")

if __name__ == "__main__":
    main()
