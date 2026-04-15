"""
Reads from Bronze because Silver drops reviews_list.
"""
import pandas as pd
import ast
import re
import urllib
from sqlalchemy import create_engine
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

SERVER   = r"SAIDEEPAK-PC\SQLEXPRESS"
DATABASE = "ZomatoDB"

params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}", fast_executemany=True)

print("Loading reviews from Bronze...")
q = """
SELECT DISTINCT name, address, reviews_list
FROM bronze.zomato_raw
WHERE reviews_list IS NOT NULL AND reviews_list <> '[]'
"""
df = pd.read_sql(q, engine)
print(f"Restaurants with reviews: {len(df):,}")

analyzer = SentimentIntensityAnalyzer()

def parse_and_score(reviews_str):
    try:
        reviews = ast.literal_eval(reviews_str)
    except Exception:
        return (None, 0, None)
    if not reviews:
        return (None, 0, None)
    scores = []
    for item in reviews:
        if not isinstance(item, tuple) or len(item) < 2:
            continue
        text = item[1] or ""
        text = re.sub(r'^RATED\s*\n?\s*', '', text).strip()
        if len(text) < 5:
            continue
        scores.append(analyzer.polarity_scores(text)["compound"])
    if not scores:
        return (None, 0, None)
    avg = sum(scores) / len(scores)
    pct_pos = sum(1 for s in scores if s > 0.05) / len(scores)
    return (round(avg, 3), len(scores), round(pct_pos, 3))

print("Scoring (2-4 minutes)...")
df[["sentiment_compound", "n_reviews_scored", "pct_positive"]] = (
    df["reviews_list"].apply(parse_and_score).apply(pd.Series)
)

out = df[["name","address","sentiment_compound","n_reviews_scored","pct_positive"]]
out = out.dropna(subset=["sentiment_compound"]).copy()
out["name"]    = out["name"].astype(str).str[:300]
out["address"] = out["address"].astype(str).str[:500]
print(f"Valid scores: {len(out):,}")

print("Writing to gold.restaurant_sentiment...")
out.to_sql("restaurant_sentiment", engine, schema="gold",
           if_exists="replace", index=False, chunksize=1000)
print("Done.")

with engine.begin() as conn:
    n = conn.exec_driver_sql("SELECT COUNT(*) FROM gold.restaurant_sentiment").scalar()
    print(f"Rows in gold.restaurant_sentiment: {n:,}")