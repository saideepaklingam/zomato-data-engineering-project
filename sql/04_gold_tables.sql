/*
 Zomato Bangalore — Gold layer
 Pre-computed aggregates and business-ready tables for dashboard.
 Idempotent: safe to re-run.
*/

USE ZomatoDB

-- G0. KPI summary (one-row table for scorecard visuals)

DROP TABLE IF EXISTS gold.kpi_summary
SELECT
    COUNT(*) AS total_restaurants,
    SUM(CASE WHEN rating IS NOT NULL THEN 1 ELSE 0 END) AS rated_restaurants,
    CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
    CAST(AVG(CAST(cost_for_two AS FLOAT)) AS INT) AS avg_cost_for_two,
    CAST(AVG(CAST(has_online_order AS FLOAT)) * 100 AS DECIMAL(4,1)) AS online_order_pct,
    CAST(AVG(CAST(has_table_booking AS FLOAT)) * 100 AS DECIMAL(4,1)) AS table_booking_pct,
    COUNT(DISTINCT location) AS total_localities,
    COUNT(DISTINCT primary_cuisine) AS total_cuisines
INTO gold.kpi_summary
FROM silver.restaurants;


-- G1. City x Cuisine performance
DROP TABLE IF EXISTS gold.city_cuisine_performance;
SELECT
    city,
    primary_cuisine,
    COUNT(*) AS restaurant_count,
    CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
    CAST(AVG(CAST(cost_for_two AS FLOAT)) AS INT) AS avg_cost_for_two,
    SUM(votes) AS total_votes,
    CAST(AVG(CAST(has_online_order AS FLOAT)) AS DECIMAL(3,2)) AS online_order_ratio
INTO gold.city_cuisine_performance
FROM silver.restaurants
WHERE primary_cuisine IS NOT NULL AND primary_cuisine <> ''
GROUP BY city, primary_cuisine

-- G2. Market gaps (tightened filter)
--     Localities where a cuisine is highly rated but scarce.

DROP TABLE IF EXISTS gold.market_gaps;
;WITH loc_cuisine AS (
    SELECT
        location,
        primary_cuisine,
        COUNT(*)  AS supply,
        AVG(rating) AS avg_rating,
        SUM(votes)  AS demand_signal
    FROM silver.restaurants
    WHERE primary_cuisine IS NOT NULL AND rating IS NOT NULL
    GROUP BY location, primary_cuisine
)
SELECT
    location,
    primary_cuisine,
    supply,
    CAST(avg_rating AS DECIMAL(3,2)) AS avg_rating,
    demand_signal,
    CAST(demand_signal * 1.0 / supply AS INT) AS votes_per_restaurant
INTO gold.market_gaps
FROM loc_cuisine
WHERE supply BETWEEN 2 AND 5
  AND avg_rating >= 4.0
  AND demand_signal >= 1000;
GO

-- G3. Online-order effect, controlled by price tier

DROP TABLE IF EXISTS gold.online_order_effect;
SELECT
    price_tier,
    has_online_order,
    COUNT(*) AS n,
    CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
    CAST(AVG(CAST(votes AS FLOAT)) AS INT) AS avg_votes
INTO gold.online_order_effect
FROM silver.restaurants
WHERE rating IS NOT NULL
GROUP BY price_tier, has_online_order;
GO

-- ---------------------------------------------------------------
-- G4. Value leaders (rating per rupee, min 20 restaurants per loc)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS gold.value_leaders;
SELECT TOP 100
    location,
    COUNT(*) AS n_restaurants,
    CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
    CAST(AVG(CAST(cost_for_two AS FLOAT)) AS INT) AS avg_cost,
    CAST(AVG(rating) / NULLIF(AVG(CAST(cost_for_two AS FLOAT)),0) * 1000
         AS DECIMAL(6,3)) AS rating_per_1000rs
INTO gold.value_leaders
FROM silver.restaurants
WHERE rating IS NOT NULL AND cost_for_two IS NOT NULL
GROUP BY location
HAVING COUNT(*) >= 20
ORDER BY rating_per_1000rs DESC;
GO

-- ---------------------------------------------------------------
-- G5. Listing-type effect (uses the listings fact table)
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS gold.listing_type_effect;
SELECT
    listing_type,
    COUNT(*) AS n,
    CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
    CAST(AVG(CAST(cost_for_two AS FLOAT)) AS INT) AS avg_cost,
    SUM(votes) AS total_votes
INTO gold.listing_type_effect
FROM silver.restaurant_listings
WHERE rating IS NOT NULL
GROUP BY listing_type;
GO

-- ---------------------------------------------------------------
-- G6. Rating-vs-sentiment gap view
--     Run this block AFTER the sentiment script.
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS gold.v_rating_sentiment_gap;
GO
CREATE VIEW gold.v_rating_sentiment_gap AS
SELECT
    r.restaurant_name,
    r.address,
    r.location,
    r.primary_cuisine,
    r.rating,
    r.votes,
    s.sentiment_compound,
    s.pct_positive,
    s.n_reviews_scored,
    CAST((r.rating - 3.0) / 2.0 AS DECIMAL(4,3)) AS rating_norm,
    CAST(((r.rating - 3.0) / 2.0) - s.sentiment_compound AS DECIMAL(4,3)) AS gap
FROM silver.restaurants r
INNER JOIN gold.restaurant_sentiment s
    ON r.restaurant_name = s.name
   AND r.address         = s.address
WHERE r.rating IS NOT NULL
  AND s.n_reviews_scored >= 5;
GO

-- ---------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------
SELECT 'kpi_summary' AS tbl, COUNT(*) AS rows FROM gold.kpi_summary
UNION ALL SELECT 'city_cuisine_performance', COUNT(*) FROM gold.city_cuisine_performance
UNION ALL SELECT 'market_gaps', COUNT(*) FROM gold.market_gaps
UNION ALL SELECT 'online_order_effect', COUNT(*) FROM gold.online_order_effect
UNION ALL SELECT 'value_leaders', COUNT(*) FROM gold.value_leaders
UNION ALL SELECT 'listing_type_effect', COUNT(*) FROM gold.listing_type_effect;
GO