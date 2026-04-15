### **ZOMATO- SELF NOTES**



#### **Setup**



1. env: zomato. pandas, sqlalchemy+pyodbc, vader
2. csv: 51717×17. only votes is num. rate="4.1/5", cost="1,100" wtf
3. 3 cols had brackets '()' , renamed at ingest



#### **Database**



1. Created ZomatoDB
2. Created schemas: bronze / silver / gold. 
3. IF NOT EXISTS everywhere.



#### **Bronze**



1. to\_sql(if\_exists="replace"). 
2. fine for dev only.
3. audit cols: ingested\_at, source\_file.



#### **Silver**



1. TRY\_CAST not CAST
2. rate: NULLIF "NEW","-". NOT 0
3. cost: strip comma → INT
4. y/n → 1/0
5. primary\_cuisine = first before comma
6. price\_tier, rating\_segment row level
7. dedup: 51717 → 12494 unique (name,addr). row\_number, max votes



err 1919 on CREATE INDEX → to\_sql made NVARCHAR(MAX), can't index, 1700b limit. fix: CAST AS NVARCHAR(N)

mentor said 12494 too low, expected 40k. ran diag, 12494 correct. → check counts urself



split: restaurants(12494, dim) + restaurant\_listings(51717, fact). dedup killed listing\_type

indexes — added 3, dropped. 12k rows planner scans anyway. plan = Clust Idx Scan. NYC Taxi later



#### **Gold**



1. Created 6 tables. 
2. No basic data analysis like 'top 10 cuisines'
3. Table created

   * &#x09;kpi\_summary,
   * &#x09;city\_cuisine\_performance,
   * &#x09;market\_gaps,
   * &#x09;online\_order\_effect,
   * &#x09;value\_leaders,
   * &#x09;listing\_type\_effect.	

**every script: DROP TABLE IF EXISTS on top.**



* market\_gaps v1 broken, supply=1 → single lucky shops. v2: supply 2-5 AND demand>=1000. top = Marathahalli, 3 euro, 4.5 star rating, 5650 votes each
* kpi\_summary late add — page1 was agg-of-agg. SQL one-row table > DAX, keeps dash gold-only
* denom — 12494 total, 9491 rated. don't report rated as total. both. AVG ignores NULL anyway



#### **Sentiment**



1. VADER, 3min, 22544 places
2. BERT not worth at this scale
3. reviews\_list = stringified py tuples ugh
4. strip "RATED\\n", compound, avg per restaurant

   * pct\_positive, n\_reviews\_scored



**sample size:** Panchavati Gaurav Thali looked like inflation (4.0 stars, -0.38 sentiment) — but n\_reviews\_scored = 6. added >= 20 filter. → every derived metric needs sample-size floor.


#### **Clustering**



1. KMeans k=5 on rating, log(votes), cost, sentiment, pct\_positive.
2. log(votes) because raw is 100 to 16K+. StandardScaler after.
3. missing sentiment → 0, don't drop.
4. elbow k=2..8, picked 5. names after, not before.



**clusters:** c0 undiscovered (5,796) / c1 mainstream (6,023) / c2 struggling (2,256) / c3 premium (3,266) / c4 meh (4,253).



#### **Power BI**



1. gold only, 3 pages
2. DAX SELECTEDVALUE, not col drag (avoids "Sum of total\_restaurants")
3. refresh: SQL + powerbi cache separate. Home→Refresh
4. avg\_rating: 3.63 correct, 3.70 was mentor vibe. trust SQL



### **Skipped for this project**



Airflow / Spark. one CSV, 50MB. wrong tools here.



