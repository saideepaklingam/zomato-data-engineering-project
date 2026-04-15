"""
KMeans segmentation -> gold.restaurant_segments
Features: rating, log(votes), cost, sentiment, pct_positive.
k=5 chosen for business context.
"""
import pandas as pd
import numpy as np
import urllib
from sqlalchemy import create_engine
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans

SERVER   = r"SAIDEEPAK-PC\SQLEXPRESS"
DATABASE = "ZomatoDB"

params = urllib.parse.quote_plus(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}", fast_executemany=True)

q = """
SELECT r.restaurant_name, r.address, r.location, r.primary_cuisine,
       r.rating, r.votes, r.cost_for_two, r.has_online_order,
       s.sentiment_compound, s.pct_positive, s.n_reviews_scored
FROM silver.restaurants r
LEFT JOIN gold.restaurant_sentiment s
  ON r.restaurant_name = s.name AND r.address = s.address
WHERE r.rating IS NOT NULL AND r.cost_for_two IS NOT NULL AND r.votes > 0
"""
df = pd.read_sql(q, engine)
print(f"Clustering candidates: {len(df):,}")

df["sentiment_compound"] = df["sentiment_compound"].fillna(0)
df["pct_positive"]       = df["pct_positive"].fillna(0.5)

features = ["rating","votes","cost_for_two","sentiment_compound","pct_positive"]
X = df[features].copy()
X["votes"] = np.log1p(X["votes"])

X_scaled = StandardScaler().fit_transform(X)

inertias = []
for k in range(2, 9):
    inertias.append(KMeans(n_clusters=k, random_state=42, n_init=10).fit(X_scaled).inertia_)
print("Inertias by k:", dict(zip(range(2,9), [round(i) for i in inertias])))

k = 5
model = KMeans(n_clusters=k, random_state=42, n_init=10)
df["cluster"] = model.fit_predict(X_scaled)

profile = df.groupby("cluster")[features].mean().round(2)
profile["n"] = df.groupby("cluster").size()
print("\nCluster profiles:\n", profile)

# IMPORTANT: verify these labels match your actual profile before shipping.
# KMeans cluster IDs can shuffle across runs; re-read the profile above and
# reassign if needed (e.g., which cluster has lowest rating+lowest sentiment
# = 'Genuinely struggling', which has highest cost+votes = 'Premium', etc.)
labels = {
    0: "Undiscovered favourites",
    1: "Mainstream winners",
    2: "Genuinely struggling",
    3: "Premium destinations",
    4: "Average middle",
}
df["segment"] = df["cluster"].map(labels)

out = df[["restaurant_name","address","location","primary_cuisine",
          "rating","votes","cost_for_two",
          "sentiment_compound","cluster","segment"]].copy()
out["restaurant_name"] = out["restaurant_name"].astype(str).str[:300]
out["address"]         = out["address"].astype(str).str[:500]
out["location"]        = out["location"].astype(str).str[:200]
out["primary_cuisine"] = out["primary_cuisine"].astype(str).str[:100]
out["segment"]         = out["segment"].astype(str).str[:50]

out.to_sql("restaurant_segments", engine, schema="gold",
           if_exists="replace", index=False, chunksize=1000)
print(f"\nWrote {len(out):,} rows to gold.restaurant_segments")