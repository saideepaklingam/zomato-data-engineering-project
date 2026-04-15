import pandas as pd
from sqlalchemy import create_engine
import urllib
import os

SERVER   = r"SAIDEEPAK-PC\SQLEXPRESS"
DATABASE = "ZomatoDB"
OUT_DIR  = r"D:\zomato-data-engineering-project\data\exports"

params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# Check folder first
print("Saving files to:", os.path.abspath(OUT_DIR))
print("Folder exists:", os.path.exists(OUT_DIR))

exports = [
    ("kpi_summary.csv", "SELECT * FROM gold.kpi_summary"),
    ("city_cuisine_performance.csv", "SELECT * FROM gold.city_cuisine_performance"),
    ("market_gaps.csv", "SELECT * FROM gold.market_gaps ORDER BY votes_per_restaurant DESC"),
    ("online_order_effect.csv", "SELECT * FROM gold.online_order_effect ORDER BY price_tier, has_online_order"),
    ("value_leaders.csv", "SELECT * FROM gold.value_leaders ORDER BY rating_per_1000rs DESC"),
    ("listing_type_effect.csv", "SELECT * FROM gold.listing_type_effect ORDER BY avg_rating DESC"),
    ("restaurant_sentiment.csv", "SELECT * FROM gold.restaurant_sentiment"),
    ("restaurant_segments.csv", "SELECT * FROM gold.restaurant_segments"),
    ("rating_sentiment_gap.csv", "SELECT * FROM gold.v_rating_sentiment_gap WHERE n_reviews_scored >= 20"),
]

for filename, query in exports:
    df = pd.read_sql(query, engine)
    path = os.path.join(OUT_DIR, filename)
    df.to_csv(path, index=False, encoding="utf-8")
    print(f"Saved: {path} | Rows: {len(df)}")

print("\nDone.")