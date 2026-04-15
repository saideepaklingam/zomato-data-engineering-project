

### **Zomato Bangalore — Data Engineering Project**



End-to-end pipeline. 12,494 Bangalore restaurants, raw CSV to interactive dashboard. Medallion architecture (Bronze → Silver → Gold) on SQL Server + Python + Power BI. Sentiment analysis and KMeans clustering bolted on as analytical extensions.



#### **Dashboard Preview**



![Dashboard - Page 1: Landscape](dashboard/screenshots/page1_landscape.png)

![Dashboard - Page 2: Market Opportunities](dashboard/screenshots/page2_market_opportunities.png)

![Dashboard - Page 3: Rating Truth Check](dashboard/screenshots/page3_truth_check.png)


#### **Data Source**

[Zomato Bangalore Restaurants — Kaggle](https://www.kaggle.com/datasets/himanshupoddar/zomato-bangalore-restaurants)

Download zomato.csv and place it at data/raw/zomato.csv.



#### **Stack**

|Layer|Tool|Reason|
|-|-|-|
|Ingestion|Python + pandas|50MB file, fits in RAM. to\_sql works fine.|
|Storage|SQL Server|Need ACID, window functions, CTEs, TRY\_CAST for Silver. Schema-on-write catches bad data at load time, not three days later.|
|Processing|T-SQL|Cleaning is tabular — string fixes, casting, dedup with ROW\_NUMBER, aggregation. SQL engine optimises the plan. Beats pandas once you cross a few lakh rows.|
|Sentiment|VADER|Rule-based, built for short social-text. Zomato reviews are exactly that. Seconds per 1000 reviews on CPU. BERT takes hours for almost no accuracy gain on text this short|
|Clustering|scikit-learn, KMeans|Centroids are interpretable, linear time, works well after StandardScaler. DBSCAN throws half the points as outliers. Hierarchical is O(n²).|
|Dashboard|Power BI|Native SQL connector. VertiPaq is fast. DAX measures keep KPI logic close to the data.|



**Left out:** Airflow (one-shot load), Spark (dataset too small), indexes (12K rows, planner scans anyway).



#### **Data Flow**



zomato.csv (51,717 rows)

&#x20;      │

&#x20;      ▼  Python: 01\_load\_raw\_to\_sql.py

bronze.zomato\_raw  (raw + audit cols)

&#x20;      │

&#x20;      ▼  T-SQL: 03\_silver\_tables.sql

silver.restaurants         (12,494 unique — dim)

**silver.restaurant\_listings (51,717 listings — fact)

&#x20;      │

&#x20;      ▼  T-SQL: 04\_gold\_tables.sql + Python extensions

gold.kpi\_summary

gold.city\_cuisine\_performance

gold.market\_gaps

gold.online\_order\_effect

gold.value\_leaders

gold.listing\_type\_effect

gold.restaurant\_sentiment      (VADER scores)

gold.restaurant\_segments       (KMeans clusters)

gold.v\_rating\_sentiment\_gap    (view)

&#x20;      │

&#x20;      ▼

Power BI dashboard (3 pages)



#### **Repository Layout**



zomato-data-engineering-project/

├── data/raw/zomato.csv

├── sql/

│   ├── 01\_database\_setup.sql

│   ├── 03\_silver\_tables.sql

│   ├── 04\_gold\_tables.sql

│   └── 05\_analysis\_queries.sql

├── python/

│   ├── 01\_load\_raw\_to\_sql.py

│   ├── 02\_sentiment\_analysis.py

│   └── 03\_clustering.py

├── dashboard/zomato\_dashboard.pbix

├── docs/project\_notes.md

└── README.md



#### **Headline Findings**

1\. Marathahalli neighbour hood is under-supplied in European cuisine. Three restaurants only. 4.5 stars average. 5,650 votes each. Strongest market-gap signal in the dataset. Next two candidates: Indiranagar (European), Koramangala 4th Block (American).

2\. Online ordering = +0.14 stars in Mid-tier and Luxury. But only 27% of Luxury places offer it. Could be adoption lag, could be positioning. Don't know.

3\. WYT RestroPub on MG Road. Zomato shows 2.6 stars. But 89% of the 225 written reviews are positive, sentiment score +0.72. Biggest rating-vs-sentiment gap with a real sample behind it.

4\. 5,796 restaurants (26%) cluster as "undiscovered favourites". Cheap, low votes, +0.79 sentiment, 97% positive reviews. Good food, no audience. The interesting marketing segment.



#### **How to Reproduce**



\# 1. Env

conda create -n zomato python=3.11 -y

conda activate zomato

pip install pandas sqlalchemy pyodbc vaderSentiment scikit-learn



\# 2. SQL setup (SSMS)

\# Run sql/01\_database\_setup.sql



\# 3. Ingestion

python python/01\_load\_raw\_to\_sql.py



\# 4. Silver + Gold (SSMS)

\# Run sql/03\_silver\_tables.sql

\# Run sql/04\_gold\_tables.sql



\# 5. Sentiment + clustering

python python/02\_sentiment\_analysis.py

python python/03\_clustering.py



\# 6. Open dashboard/zomato\_dashboard.pbix, hit Refresh.



Connection (change if yours is different):



Server: 'Your Server Name'

Database: ZomatoDB

Auth: Windows



##### **Design decisions worth calling out**



1. No synthetic data. Considered it, rejected. Real 12,494 restaurants have enough signal for the questions being asked.
2. Two Silver tables, not one. restaurants (12,494) is the dimension. restaurant\_listings (51,717) is the fact. Raw file repeats each restaurant once per Zomato listing category (Delivery, Dine-out, Buffet etc). Dedup without keeping the fact grain throws away listing\_type. Couldn't have answered the listing-type questions otherwise.
3. Bronze column widths set explicitly in Silver. pandas → SQL gives you NVARCHAR(MAX). Cannot be indexed. Silver casts to bounded widths.
4. Sample-size floor on sentiment gap. n\_reviews\_scored >= 20. First version had Panchavati Gaurav Thali on top with 6 reviews. That's noise, not a signal.
5. KPI denominator transparency. Both shown. total\_restaurants = 12,494 (all). rated\_restaurants = 9,491 (numeric rating only). No silent filter hiding 3,000 places.



Author

Sai Deepak Lingam · GitHub:  · Project 1 of 4 in a data engineering portfolio series.



