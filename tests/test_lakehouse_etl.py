import unittest
from unittest.mock import MagicMock
import os
import sys

# Mock third-party libraries in sys.modules so unit tests run anywhere without external pip packages
mock_boto3 = MagicMock()
mock_duckdb = MagicMock()
mock_psycopg2 = MagicMock()
mock_botocore = MagicMock()

sys.modules["boto3"] = mock_boto3
sys.modules["duckdb"] = mock_duckdb
sys.modules["psycopg2"] = mock_psycopg2
sys.modules["botocore"] = mock_botocore
sys.modules["botocore.client"] = mock_botocore

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from src import lakehouse_etl

class TestLakehouseETL(unittest.TestCase):

    def test_medallion_pipeline_flow(self):
        """Verify Bronze, Silver, and Gold execution flow in lakehouse_etl.py"""
        # Configure Mock S3 Client
        mock_s3 = MagicMock()
        mock_boto3.client.return_value = mock_s3

        # Configure Mock DuckDB Connection
        mock_con = MagicMock()
        mock_duckdb.connect.return_value = mock_con
        mock_con.execute.return_value.fetchall.return_value = [
            ("Electronics", 2, 200.50),
            ("Clothing", 2, 300.00),
            ("Groceries", 2, 375.25),
        ]

        # Configure Mock PostgreSQL Connection
        mock_pg_conn = MagicMock()
        mock_pg_cursor = MagicMock()
        mock_psycopg2.connect.return_value = mock_pg_conn
        mock_pg_conn.cursor.return_value = mock_pg_cursor

        # Run ETL main function
        lakehouse_etl.main()

        # 1. Verify Bronze Layer (S3 Put Object)
        mock_s3.put_object.assert_called_once()
        call_kwargs = mock_s3.put_object.call_args.kwargs
        self.assertEqual(call_kwargs["Bucket"], "bronze")
        self.assertEqual(call_kwargs["Key"], "transactions.json")
        self.assertIn("Alice", call_kwargs["Body"])

        # 2. Verify Silver Layer (DuckDB Parquet Copy)
        duckdb_calls = [str(call) for call in mock_con.execute.mock_calls]
        self.assertTrue(any("transactions.parquet" in c for c in duckdb_calls), "Parquet transformation missing")
        self.assertTrue(any("read_json_auto" in c for c in duckdb_calls), "Bronze JSON read missing")

        # 3. Verify Gold Layer (PostgreSQL Table Creation & Upsert)
        pg_calls = [str(call) for call in mock_pg_cursor.execute.mock_calls]
        self.assertTrue(any("category_sales_metrics" in c for c in pg_calls), "Table creation missing")
        self.assertTrue(any("ON CONFLICT" in c for c in pg_calls), "Upsert statement missing")
        self.assertEqual(mock_pg_cursor.execute.call_count, 4)  # 1 CREATE TABLE + 3 upsert rows
        mock_pg_conn.commit.assert_called_once()

if __name__ == "__main__":
    unittest.main()
