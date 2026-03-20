"""
02_upload_to_bigquery.py
Upload generated CSV files to Google BigQuery with validation and error reporting.
Prerequisite: gcloud auth application-default login
"""

import os
from typing import Tuple, List, Dict

import pandas as pd
from google.cloud import bigquery
from google.cloud.exceptions import NotFound


# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_ID = "ross-bi-project-03"
DATASET_ID = "traffic_ad_roi"
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
ERROR_DIR = os.path.join(os.path.dirname(__file__), "..", "error_reports")
LOCATION = "US"

os.makedirs(ERROR_DIR, exist_ok=True)


# ── BigQuery schemas ──────────────────────────────────────────────────────────
SCHEMAS = {
    "campaigns": [
        bigquery.SchemaField("campaign_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("campaign_name", "STRING"),
        bigquery.SchemaField("channel", "STRING"),
        bigquery.SchemaField("campaign_type", "STRING"),
        bigquery.SchemaField("daily_budget", "FLOAT64"),
        bigquery.SchemaField("start_date", "DATE"),
        bigquery.SchemaField("end_date", "DATE"),
    ],
    "ad_impressions": [
        bigquery.SchemaField("impression_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("campaign_id", "STRING"),
        bigquery.SchemaField("date", "DATE"),
        bigquery.SchemaField("impressions", "INTEGER"),
        bigquery.SchemaField("clicks", "INTEGER"),
        bigquery.SchemaField("ctr", "FLOAT64"),
        bigquery.SchemaField("spend_usd", "FLOAT64"),
    ],
    "sessions": [
        bigquery.SchemaField("session_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("campaign_id", "STRING"),
        bigquery.SchemaField("channel", "STRING"),
        bigquery.SchemaField("session_date", "DATE"),
        bigquery.SchemaField("session_ts", "DATETIME"),
        bigquery.SchemaField("device", "STRING"),
        bigquery.SchemaField("country", "STRING"),
        bigquery.SchemaField("pages_viewed", "INTEGER"),
        bigquery.SchemaField("session_duration_sec", "INTEGER"),
        bigquery.SchemaField("is_bounce", "INTEGER"),
    ],
    "conversions": [
        bigquery.SchemaField("order_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("session_id", "STRING"),
        bigquery.SchemaField("campaign_id", "STRING"),
        bigquery.SchemaField("channel", "STRING"),
        bigquery.SchemaField("order_date", "DATE"),
        bigquery.SchemaField("order_ts", "DATETIME"),
        bigquery.SchemaField("order_value_usd", "FLOAT64"),
        bigquery.SchemaField("device", "STRING"),
        bigquery.SchemaField("country", "STRING"),
    ],
}


TYPE_MAP = {
    "STRING": "string",
    "INTEGER": "Int64",
    "FLOAT64": "float64",
    "DATE": "date",
    "DATETIME": "datetime",
    "TIMESTAMP": "datetime",
    "BOOLEAN": "boolean",
    "BOOL": "boolean",
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


def normalize_string_empty_to_na(series: pd.Series) -> pd.Series:
    return series.replace(r"^\s*$", pd.NA, regex=True)


def coerce_column(series: pd.Series, field: bigquery.SchemaField) -> Tuple[pd.Series, pd.Series]:
    field_type = field.field_type.upper()

    if field_type == "STRING":
        s = series.astype("string")
        s = normalize_string_empty_to_na(s)
        return s, pd.Series([False] * len(series), index=series.index)

    if field_type == "INTEGER":
        numeric = pd.to_numeric(series, errors="coerce")
        invalid = series.notna() & normalize_string_empty_to_na(series.astype("string")).notna() & numeric.isna()
        return numeric.astype("Int64"), invalid

    if field_type == "FLOAT64":
        numeric = pd.to_numeric(series, errors="coerce")
        invalid = series.notna() & normalize_string_empty_to_na(series.astype("string")).notna() & numeric.isna()
        return numeric.astype("float64"), invalid

    if field_type == "DATE":
        dt = pd.to_datetime(series, errors="coerce")
        invalid = series.notna() & normalize_string_empty_to_na(series.astype("string")).notna() & dt.isna()
        return dt.dt.date, invalid

    if field_type in ("DATETIME", "TIMESTAMP"):
        dt = pd.to_datetime(series, errors="coerce")
        invalid = series.notna() & normalize_string_empty_to_na(series.astype("string")).notna() & dt.isna()
        return dt.dt.to_pydatetime(), invalid

    if field_type in ("BOOLEAN", "BOOL"):
        mapping = {
            "true": True, "false": False,
            "1": True, "0": False,
            "yes": True, "no": False,
            "y": True, "n": False
        }
        s = series.astype("string").str.strip().str.lower()
        converted = s.map(mapping)
        invalid = s.notna() & converted.isna()
        return converted.astype("boolean"), invalid

    return series, pd.Series([False] * len(series), index=series.index)


def validate_dataframe(df: pd.DataFrame, table_name: str) -> Tuple[pd.DataFrame, pd.DataFrame, Dict]:
    schema = SCHEMAS[table_name]
    expected_cols = [f.name for f in schema]
    required_cols = [f.name for f in schema if f.mode == "REQUIRED"]

    actual_cols = list(df.columns)
    missing_cols = [c for c in expected_cols if c not in actual_cols]
    extra_cols = [c for c in actual_cols if c not in expected_cols]

    error_rows: List[Dict] = []

    if missing_cols:
        for col in missing_cols:
            error_rows.append({
                "source_row_number": None,
                "table_name": table_name,
                "column_name": col,
                "error_type": "missing_column",
                "raw_value": None,
                "message": f"Missing required schema column: {col}"
            })

    work_df = df.copy()

    for col in expected_cols:
        if col not in work_df.columns:
            work_df[col] = pd.NA

    work_df = work_df[expected_cols]

    row_error_map: Dict[int, List[str]] = {}

    for field in schema:
        col = field.name
        raw_series = work_df[col]

        converted, invalid_mask = coerce_column(raw_series, field)
        work_df[col] = converted

        for idx in work_df.index[invalid_mask]:
            row_error_map.setdefault(idx, []).append(f"{col}: invalid {field.field_type}")
            error_rows.append({
                "source_row_number": int(idx) + 2,
                "table_name": table_name,
                "column_name": col,
                "error_type": "invalid_type",
                "raw_value": df.loc[idx, col] if col in df.columns else None,
                "message": f"Invalid {field.field_type} value"
            })

    for col in required_cols:
        null_mask = work_df[col].isna()
        for idx in work_df.index[null_mask]:
            row_error_map.setdefault(idx, []).append(f"{col}: REQUIRED but null/blank")
            error_rows.append({
                "source_row_number": int(idx) + 2,
                "table_name": table_name,
                "column_name": col,
                "error_type": "required_null",
                "raw_value": df.loc[idx, col] if col in df.columns else None,
                "message": "Required field is null or blank"
            })

    for col in extra_cols:
        error_rows.append({
            "source_row_number": None,
            "table_name": table_name,
            "column_name": col,
            "error_type": "extra_column",
            "raw_value": None,
            "message": f"Extra column not in schema: {col}"
        })

    invalid_row_indexes = sorted(row_error_map.keys())
    valid_df = work_df.drop(index=invalid_row_indexes).copy()

    error_report_df = pd.DataFrame(error_rows)

    summary = {
        "table_name": table_name,
        "source_rows": len(df),
        "valid_rows": len(valid_df),
        "invalid_rows": len(invalid_row_indexes),
        "missing_columns": missing_cols,
        "extra_columns": extra_cols,
    }

    return valid_df, error_report_df, summary


def save_error_report(table_name: str, error_report_df: pd.DataFrame):
    error_path = os.path.join(ERROR_DIR, f"{table_name}_error_report.csv")
    if error_report_df.empty:
        pd.DataFrame(columns=[
            "source_row_number", "table_name", "column_name",
            "error_type", "raw_value", "message"
        ]).to_csv(error_path, index=False)
    else:
        error_report_df.to_csv(error_path, index=False)
    return error_path


def compare_with_bigquery(client, table_ref: str, expected_rows: int):
    table = client.get_table(table_ref)
    loaded_rows = table.num_rows
    matched = loaded_rows == expected_rows
    return loaded_rows, matched


def upload_table(client, table_name):
    csv_path = os.path.join(DATA_DIR, f"{table_name}.csv")
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

    df = pd.read_csv(csv_path)
    print(f"\n--- {table_name} ---")
    print(f"  Source rows: {len(df):,}")

    valid_df, error_report_df, summary = validate_dataframe(df, table_name)
    error_path = save_error_report(table_name, error_report_df)

    print(f"  Valid rows: {summary['valid_rows']:,}")
    print(f"  Invalid rows: {summary['invalid_rows']:,}")
    print(f"  Error report: {error_path}")

    if summary["missing_columns"]:
        raise ValueError(
            f"{table_name}: missing schema columns: {summary['missing_columns']}"
        )

    if valid_df.empty and len(df) > 0:
        raise ValueError(f"{table_name}: all rows failed validation. Upload stopped.")

    job_config = bigquery.LoadJobConfig(
        schema=SCHEMAS[table_name],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    print(f"  Uploading valid rows to {table_ref} ...")
    job = client.load_table_from_dataframe(valid_df, table_ref, job_config=job_config)
    job.result()

    loaded_rows, matched = compare_with_bigquery(client, table_ref, len(valid_df))
    print(f"  BigQuery rows: {loaded_rows:,}")

    if not matched:
        raise ValueError(
            f"{table_name}: row count mismatch. source valid rows={len(valid_df)}, "
            f"bigquery rows={loaded_rows}"
        )

    print(f"  ✓ {table_name} uploaded and validated successfully.")


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
