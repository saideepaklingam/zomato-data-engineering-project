/*
 Bronze table bronze.zomato_raw is created by
 python/01_load_raw_to_sql.py via pandas to_sql(if_exists='replace').

 Schema:
   - 17 source columns (all NVARCHAR(MAX) except votes BIGINT)
   - Renamed:
       approx_cost(for two people) -> approx_cost_for_two
       listed_in(type) -> listed_in_type
       listed_in(city) -> listed_in_city
   - Audit columns added:
       ingested_at  DATETIME
       source_file  NVARCHAR
*/

USE ZomatoDB

-- Sanity check only. No DDL here — Bronze is owned by the Python loader.

SELECT TOP 5 * FROM bronze.zomato_raw

SELECT COUNT(*) AS bronze_rows FROM bronze.zomato_raw