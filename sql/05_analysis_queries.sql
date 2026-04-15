
-- Zomato Bangalore — Business Analysis Queries

USE ZomatoDB

-- Q1. Landscape overview — the headline numbers.
SELECT * FROM gold.kpi_summary


-- Q2. Top 10 most popular cuisines by restaurant count across Bangalore.
SELECT TOP 10 primary_cuisine, SUM(restaurant_count) AS total_restaurants
FROM gold.city_cuisine_performance
WHERE primary_cuisine IS NOT NULL AND primary_cuisine <> ''
GROUP BY primary_cuisine
ORDER BY total_restaurants DESC


-- Q3. Which cities have the highest average rating? (sorted, min 50 restaurants)
SELECT city,
       SUM(restaurant_count) AS restaurants,
       CAST(SUM(avg_rating * restaurant_count) / SUM(restaurant_count)
            AS DECIMAL(3,2)) AS weighted_rating
FROM gold.city_cuisine_performance
GROUP BY city
HAVING SUM(restaurant_count) >= 50
ORDER BY weighted_rating DESC


-- Q4. Top 10 market-gap opportunities — where should a new restaurant open?
SELECT TOP 10 location, primary_cuisine, supply, avg_rating, demand_signal, votes_per_restaurant
FROM gold.market_gaps
ORDER BY votes_per_restaurant DESC


-- Q5. Does online ordering correlate with higher ratings? Controlled by price tier.
SELECT price_tier,
       has_online_order,
       n,
       avg_rating,
       avg_votes
FROM gold.online_order_effect
WHERE price_tier <> 'Unknown'
ORDER BY price_tier, has_online_order


-- Q6. Best "rating per rupee" localities — where do you get the most value?
SELECT TOP 10 location, n_restaurants, avg_rating, avg_cost, rating_per_1000rs
FROM gold.value_leaders
ORDER BY rating_per_1000rs DESC


-- Q7. Which listing type (Delivery, Dine-out, Buffet, etc.) gets the best ratings?
SELECT listing_type, n, avg_rating, avg_cost, total_votes
FROM gold.listing_type_effect
ORDER BY avg_rating DESC


-- Q8. Rating-inflation suspects — high stars but lukewarm review text.
SELECT TOP 10 restaurant_name, location, primary_cuisine,
              rating, sentiment_compound, n_reviews_scored, gap
FROM gold.v_rating_sentiment_gap
WHERE rating >= 4.0 AND sentiment_compound < 0.3 AND n_reviews_scored >= 20
ORDER BY gap DESC


-- Q9. Hidden gems — low star rating but glowing review text.
SELECT TOP 10 restaurant_name, location, primary_cuisine,
              rating, sentiment_compound, n_reviews_scored, gap
FROM gold.v_rating_sentiment_gap
WHERE rating <= 3.2 AND sentiment_compound > 0.5 AND n_reviews_scored >= 20
ORDER BY gap


-- Q10. Restaurant segment breakdown — how does each KMeans cluster perform?
SELECT segment,
       COUNT(*) AS n,
       CAST(AVG(rating) AS DECIMAL(3,2)) AS avg_rating,
       CAST(AVG(CAST(votes AS FLOAT)) AS INT) AS avg_votes,
       CAST(AVG(CAST(cost_for_two AS FLOAT)) AS INT) AS avg_cost,
       CAST(AVG(sentiment_compound) AS DECIMAL(4,3)) AS avg_sentiment
FROM gold.restaurant_segments
GROUP BY segment
ORDER BY n DESC