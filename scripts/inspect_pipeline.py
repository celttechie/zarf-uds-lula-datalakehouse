#!/usr/bin/env python3
"""
Interactive Medallion Data Lakehouse Inspector.
Runs the complete Medallion ETL pipeline with real S3 (via Moto), PyArrow Parquet,
DuckDB vectorized SQL queries, and relational Gold table materialization,
printing full visual inspection tables at every layer.
"""
import os
import sys
import json
import sqlite3
import pyarrow.parquet as pq
import duckdb
from moto import mock_aws
import boto3

sample_transactions = [
    {"transaction_id": "tx-1001", "user_id": "usr-01", "category": "Electronics", "amount": 120.50, "timestamp": "2026-08-27T10:00:00Z"},
    {"transaction_id": "tx-1002", "user_id": "usr-02", "category": "Clothing",    "amount": 45.00,  "timestamp": "2026-08-27T10:05:00Z"},
    {"transaction_id": "tx-1003", "user_id": "usr-01", "category": "Groceries",   "amount": 210.25, "timestamp": "2026-08-27T10:10:00Z"},
    {"transaction_id": "tx-1004", "user_id": "usr-03", "category": "Clothing",    "amount": 255.00, "timestamp": "2026-08-27T10:15:00Z"},
    {"transaction_id": "tx-1005", "user_id": "usr-02", "category": "Electronics", "amount": 80.00,  "timestamp": "2026-08-27T10:20:00Z"},
    {"transaction_id": "tx-1006", "user_id": "usr-04", "category": "Groceries",   "amount": 165.00, "timestamp": "2026-08-27T10:25:00Z"}
]

def run_inspection():
    print("=" * 75)
    print("🔍 MEDALLION DATA LAKEHOUSE: FULL INTERACTIVE INSPECTION")
    print("=" * 75)

    with mock_aws():
        s3 = boto3.client("s3", region_name="us-east-1")
        s3.create_bucket(Bucket="bronze")
        s3.create_bucket(Bucket="silver")

        # ---------------------------------------------------------
        # 1. BRONZE LAYER INSPECTION (Raw Ingestion)
        # ---------------------------------------------------------
        print("\n📦 [LAYER 1: BRONZE S3 INGESTION]")
        raw_json_str = "\n".join([json.dumps(t) for t in sample_transactions])
        s3.put_object(
            Bucket="bronze",
            Key="transactions.json",
            Body=raw_json_str.encode('utf-8')
        )
        
        # Read back directly from S3 to verify
        obj = s3.get_object(Bucket="bronze", Key="transactions.json")
        raw_content = obj['Body'].read().decode('utf-8')
        bronze_raw = [json.loads(line) for line in raw_content.splitlines() if line]
        
        print(f" -> Target Bucket: s3://bronze/transactions.json")
        print(f" -> Verified Payload: {len(bronze_raw)} raw JSON records stored immutably in S3")
        print("\n   [Raw Bronze Records Sample]:")
        for item in bronze_raw[:4]:
            print(f"    • ID: {item['transaction_id']} | User: {item['user_id']} | Cat: {item['category']:<12} | Amt: ${item['amount']:<6.2f} | Time: {item['timestamp']}")

        # ---------------------------------------------------------
        # 2. SILVER LAYER INSPECTION (Columnar Parquet Transformation)
        # ---------------------------------------------------------
        print("\n" + "-" * 75)
        print("⚡ [LAYER 2: SILVER PARQUET TRANSFORMATION]")
        print(" -> Ingesting Bronze JSON with DuckDB & exporting to Apache Parquet...")
        
        # Save raw JSON locally as intermediate staging
        json_tmp_path = "/tmp/transactions_bronze.json"
        with open(json_tmp_path, "w") as f:
            f.write(raw_content)

        con = duckdb.connect()
        # Load Bronze JSON into DuckDB & export to columnar Parquet
        parquet_path = "/tmp/transactions_silver.parquet"
        con.execute(f"COPY (SELECT * FROM read_json_auto('{json_tmp_path}')) TO '{parquet_path}' (FORMAT PARQUET, COMPRESSION SNAPPY)")
        
        with open(parquet_path, "rb") as f:
            parquet_bytes = f.read()
        s3.put_object(Bucket="silver", Key="transactions.parquet", Body=parquet_bytes)

        parquet_file = pq.ParquetFile(parquet_path)
        schema = parquet_file.schema_arrow
        
        print(f" -> Target S3 Object: s3://silver/transactions.parquet")
        print(f" -> Parquet File Size: {len(parquet_bytes)} bytes (Compressed with Snappy)")
        print(f" -> Row Groups: {parquet_file.num_row_groups} | Total Rows: {parquet_file.metadata.num_rows}")
        print("\n   [Arrow Columnar Schema & Types]:")
        for field in schema:
            print(f"    • Column '{field.name}': {field.type}")

        print("\n   [DuckDB In-Memory Query on Silver Parquet Table]:")
        df = con.execute(f"SELECT transaction_id, user_id, category, amount, timestamp FROM read_parquet('{parquet_path}')").df()
        print(df.to_string(index=False))

        # ---------------------------------------------------------
        # 3. GOLD LAYER INSPECTION (Aggregated Serving Mart)
        # ---------------------------------------------------------
        print("\n" + "-" * 75)
        print("📊 [LAYER 3: GOLD RELATIONAL WAREHOUSE MATERIALIZATION]")
        print(" -> Executing DuckDB Vectorized SQL Aggregations on Silver Parquet...")
        
        metrics = con.execute(f"""
            SELECT 
                category,
                COUNT(*) as total_transactions,
                ROUND(SUM(amount), 2) as total_sales_usd,
                ROUND(AVG(amount), 2) as avg_transaction_value
            FROM read_parquet('{parquet_path}')
            GROUP BY category
            ORDER BY total_sales_usd DESC
        """).fetchall()

        # Connect to relational SQL database matching PostgreSQL schema
        db = sqlite3.connect(":memory:")
        cur = db.cursor()
        cur.execute("""
            CREATE TABLE category_sales_metrics (
                category TEXT PRIMARY KEY,
                total_transactions INTEGER,
                total_sales_usd REAL,
                avg_transaction_value REAL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        cur.executemany("""
            INSERT INTO category_sales_metrics 
            (category, total_transactions, total_sales_usd, avg_transaction_value)
            VALUES (?, ?, ?, ?)
        """, metrics)
        db.commit()

        print(" -> Data successfully inserted/upserted into SQL table 'category_sales_metrics'")
        print("\n   [Gold Warehouse Query Results (SELECT * FROM category_sales_metrics)]:")
        cur.execute("SELECT category, total_transactions, total_sales_usd, avg_transaction_value FROM category_sales_metrics")
        rows = cur.fetchall()
        
        print(f"   {'Category':<15} | {'Total Txns':<10} | {'Total Sales ($)':<15} | {'Avg Value ($)':<12}")
        print("   " + "-" * 62)
        for r in rows:
            print(f"   {r[0]:<15} | {r[1]:<10} | ${r[2]:<14.2f} | ${r[3]:<11.2f}")

    print("\n" + "=" * 75)
    print("✅ COMPLETE PIPELINE VERIFIED FROM RAW INGESTION TO SQL SERVING MART!")
    print("=" * 75)

if __name__ == "__main__":
    run_inspection()
