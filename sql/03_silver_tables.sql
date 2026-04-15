/*
 Silver: cleaned, typed, deduplicated.
 Two tables:
   silver.restaurants -> dimension (12,494 unique by name+address)
   silver.restaurant_listings -> fact (51,717 with listing_type preserved)
*/

USE ZomatoDB


-- ----- silver.restaurants-----
DROP TABLE IF EXISTS silver.restaurants;
GO
;WITH cleaned AS (
    SELECT
        CAST(TRIM(name) AS NVARCHAR(300)) AS restaurant_name,
        CAST(TRIM(address) AS NVARCHAR(500)) AS address,
        CAST(TRIM(location) AS NVARCHAR(200)) AS location,
        CAST(TRIM(listed_in_city) AS NVARCHAR(100)) AS city,
        CAST(TRIM(listed_in_type) AS NVARCHAR(100)) AS listing_type,
        CAST(TRIM(rest_type) AS NVARCHAR(200)) AS restaurant_type,
        CASE WHEN LOWER(TRIM(online_order)) = 'yes' THEN 1 ELSE 0 END AS has_online_order,
        CASE WHEN LOWER(TRIM(book_table)) = 'yes' THEN 1 ELSE 0 END AS has_table_booking,
        TRY_CAST(NULLIF(NULLIF(REPLACE(TRIM(rate), '/5', ''), 'NEW'), '-')
                 AS DECIMAL(3,1)) AS rating,
        votes,
        TRY_CAST(REPLACE(TRIM(approx_cost_for_two), ',', '') AS INT) AS cost_for_two,
        CAST(TRIM(cuisines) AS NVARCHAR(500)) AS cuisines_all,
        CAST(TRIM(CASE WHEN CHARINDEX(',', cuisines) > 0
                       THEN LEFT(cuisines, CHARINDEX(',', cuisines) - 1)
                       ELSE cuisines END) AS NVARCHAR(100)) AS primary_cuisine,
        CAST(TRIM(dish_liked) AS NVARCHAR(1000)) AS dish_liked,
        url,
        ingested_at
    FROM bronze.zomato_raw
    WHERE name IS NOT NULL AND LTRIM(RTRIM(name)) <> ''
),
deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY restaurant_name, address
               ORDER BY votes DESC, rating DESC
           ) AS rn
    FROM cleaned
)
SELECT
    restaurant_name, address, location, city, listing_type, restaurant_type,
    has_online_order, has_table_booking, rating, votes, cost_for_two,
    cuisines_all, primary_cuisine, dish_liked, url, ingested_at,
    CAST(CASE
        WHEN cost_for_two IS NULL THEN 'Unknown'
        WHEN cost_for_two <  300  THEN 'Budget'
        WHEN cost_for_two <  700  THEN 'Mid'
        WHEN cost_for_two < 1500  THEN 'Premium'
        ELSE 'Luxury'
    END AS NVARCHAR(20)) AS price_tier,
    CAST(CASE
        WHEN rating IS NULL   THEN 'Unrated'
        WHEN rating >= 4.5    THEN 'Excellent'
        WHEN rating >= 4.0    THEN 'Very Good'
        WHEN rating >= 3.5    THEN 'Good'
        WHEN rating >= 3.0    THEN 'Average'
        ELSE 'Poor'
    END AS NVARCHAR(20)) AS rating_segment
INTO silver.restaurants
FROM deduped
WHERE rn = 1


-- ----- silver.restaurant_listings -----
DROP TABLE IF EXISTS silver.restaurant_listings

SELECT
    CAST(TRIM(name)             AS NVARCHAR(300)) AS restaurant_name,
    CAST(TRIM(address)          AS NVARCHAR(500)) AS address,
    CAST(TRIM(listed_in_type)   AS NVARCHAR(100)) AS listing_type,
    CAST(TRIM(listed_in_city)   AS NVARCHAR(100)) AS city,
    TRY_CAST(NULLIF(NULLIF(REPLACE(TRIM(rate), '/5', ''), 'NEW'), '-')
             AS DECIMAL(3,1)) AS rating,
    votes,
    TRY_CAST(REPLACE(TRIM(approx_cost_for_two), ',', '') AS INT) AS cost_for_two,
    CASE WHEN LOWER(TRIM(online_order)) = 'yes' THEN 1 ELSE 0 END AS has_online_order,
    CASE WHEN LOWER(TRIM(book_table))   = 'yes' THEN 1 ELSE 0 END AS has_table_booking,
    ingested_at
INTO silver.restaurant_listings
FROM bronze.zomato_raw
WHERE name IS NOT NULL AND LTRIM(RTRIM(name)) <> ''


-- Verification
SELECT 'silver.restaurants' AS tbl, COUNT(*) AS rows FROM silver.restaurants
UNION ALL
SELECT 'silver.restaurant_listings', COUNT(*) FROM silver.restaurant_listings