"""
Bronze ingestion: data/raw/zomato.csv -> bronze.zomato_raw
Renaming SQL-unsafe columns. Add audit columns.
"""
import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime
import urllib

CSV_PATH = "data/raw/zomato.csv"
SERVER   = r"SAIDEEPAK-PC\SQLEXPRESS"
DATABASE = "ZomatoDB"
TABLE    = "zomato_raw"
SCHEMA   = "bronze"

params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}", fast_executemany=True)

print("Reading CSV...")
df = pd.read_csv(CSV_PATH)
print(f"Rows: {len(df):,} | Cols: {len(df.columns)}")

rename_map = {
    "approx_cost(for two people)": "approx_cost_for_two",
    "listed_in(type)": "listed_in_type",
    "listed_in(city)": "listed_in_city",
}
df = df.rename(columns=rename_map)

df["ingested_at"] = datetime.now()
df["source_file"] = "zomato.csv"

print(f"Writing to {SCHEMA}.{TABLE} ...")
df.to_sql(
    name=TABLE, con=engine, schema=SCHEMA,
    if_exists="replace", index=False, chunksize=1000,
)
print("Done.")

with engine.begin() as conn:
    n = conn.exec_driver_sql(f"SELECT COUNT(*) FROM {SCHEMA}.{TABLE}").scalar()
    print(f"Row count in SQL: {n:,}")