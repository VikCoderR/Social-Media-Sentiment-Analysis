--Create Database 'Social_media_Review'

-- Connect to the DATABASE

---Table Creation

-- Table 1: Stores social media posts

DROP TABLE IF EXISTS social_media_posts;
CREATE TABLE social_media_posts (
    post_id SERIAL PRIMARY KEY,
    platform VARCHAR(50),
    username VARCHAR(100),
    post_text TEXT,
    post_date DATE
);

-- Table 2: Stores sentiment analysis results

DROP TABLE IF EXISTS sentiment_analysis;
CREATE TABLE sentiment_analysis (
			sentiment_id SERIAL PRIMARY KEY,
			post_id INT REFERENCES social_media_posts(post_id) ON DELETE CASCADE,
			sentiment_label VARCHAR(20),
			sentiment_score FLOAT
		);


-- Insert Data into Tables

--Insert Data into social_media_posts

COPY social_media_posts(post_id, platform, username, post_text, post_date)
FROM 'C:\Program Files\PostgreSQL\17\social_media_posts.csv'
CSV HEADER;

--Insert Data into sentiment_analysis

COPY sentiment_analysis(sentiment_id,post_id,sentiment_label,sentiment_score)
FROM '‪C:\Program Files\PostgreSQL\17\sentiment_analysis.csv'
CSV HEADER;



--Basic Level Questions 

-- 1)How many posts are there on each social media platform?
   SELECT platform, COUNT(post_id)AS Total_post
   FROM social_media_posts
   GROUP BY platform;

-- 2)How many posts are positive, negative, or neutral?
    SELECT sentiment_label, COUNT(sentiment_id)AS Post_review_count
    FROM sentiment_analysis
    GROUP BY sentiment_label;

--3)Identify the users who are the most active on social media.
  
  WITH ACTIVE_USER AS
  (SELECT username,platform,COUNT(post_id)AS No_of_post
   FROM social_media_posts
   GROUP BY 1,2
   ORDER BY  No_of_post DESC)
   SELECT * FROM ACTIVE_USER
   WHERE No_of_post= (SELECT MAX(No_of_post) FROM ACTIVE_USER )

-- 4)What is the average sentiment score for each platform?
--Check which platform has the happiest or saddest posts on average.


SELECT P.platform, ROUND(AVG(A.sentiment_score)::NUMERIC,2) As Sentiment_score
FROM social_media_posts P
JOIN sentiment_analysis A ON
P.post_id=A.post_id
GROUP BY  P.platform
ORDER BY Sentiment_score DESC;


-- 5)Which platform has the highest number of negative posts?

SELECT P.platform, COUNT(A.post_id) As Negative_posts
FROM social_media_posts P
JOIN sentiment_analysis A ON
P.post_id=A.post_id
WHERE A.sentiment_label='Negative'
GROUP BY  P.platform
ORDER BY  Negative_posts DESC
LIMIT 1;

-- 6)Which day of the week has the most social media activity?

SELECT
EXTRACT (DOW FROM post_date)AS Day_of_the_week,
TO_CHAR(post_date, 'Day') AS day_name,
COUNT(POST_ID)AS NO_OF_POST
FROM social_media_posts
GROUP BY Day_of_the_week, day_name
ORDER BY  NO_OF_POST DESC;


--Advanced Level Questions 

-- 1)Which platform has the most balanced sentiment distribution?
WITH sentiment_counts AS (
    SELECT 
        p.platform,
        s.sentiment_label,
        COUNT(*) AS sentiment_count
    FROM social_media_posts p
    JOIN sentiment_analysis s ON p.post_id = s.post_id
    GROUP BY p.platform, s.sentiment_label
),
total_posts AS (
    SELECT 
        platform, 
        SUM(sentiment_count) AS total_count
    FROM sentiment_counts
    GROUP BY platform
),
sentiment_distribution AS (
    SELECT 
        sc.platform,
        SUM(CASE WHEN sc.sentiment_label = 'Positive' THEN sc.sentiment_count ELSE 0 END) * 100.0 / tp.total_count AS positive_pct,
        SUM(CASE WHEN sc.sentiment_label = 'Neutral' THEN sc.sentiment_count ELSE 0 END) * 100.0 / tp.total_count AS neutral_pct,
        SUM(CASE WHEN sc.sentiment_label = 'Negative' THEN sc.sentiment_count ELSE 0 END) * 100.0 / tp.total_count AS negative_pct
    FROM sentiment_counts sc
    JOIN total_posts tp ON sc.platform = tp.platform
    GROUP BY sc.platform, tp.total_count
),
sentiment_variation AS (
    SELECT platform, unnest(ARRAY[positive_pct, neutral_pct, negative_pct]) AS sentiment_value
    FROM sentiment_distribution
)
SELECT platform, ROUND(STDDEV(sentiment_value), 4) AS sentiment_stddev
FROM sentiment_variation
GROUP BY platform
ORDER BY sentiment_stddev ASC
LIMIT 1;


-- 2)How has sentiment evolved over time on different platforms?
--Track whether posts are becoming more positive or negative over the months or years.

SELECT 
    platform, 
    DATE_TRUNC('month', post_date) AS month, 
   ROUND (AVG(sentiment_score)::NUMERIC,2) AS avg_sentiment
FROM social_media_posts p
JOIN sentiment_analysis s ON p.post_id = s.post_id
GROUP BY platform, month
ORDER BY platform, month;

-- 3)Which platform shows the most extreme emotions (highest positive and lowest negative sentiment)?


WITH emotion_count AS
(SELECT p.platform,COUNT(a.sentiment_label)AS sentiment_count,a.sentiment_label as emotion
FROM social_media_posts p
JOIN  sentiment_analysis a
ON p.post_id = a.post_id
GROUP BY p.platform,a.sentiment_label
)
SELECT * FROM emotion_count
WHERE ( sentiment_count=(SELECT MAX(sentiment_count)FROM emotion_count WHERE emotion = 'Positive'))
OR    ( sentiment_count=(SELECT MIN(sentiment_count)FROM emotion_count WHERE emotion = 'Negative'))



-- 4)Detect users who frequently share negative content?

SELECT COUNT(p.post_id),(p.username)as users,(a.sentiment_label) AS comments
FROM social_media_posts p
JOIN  sentiment_analysis a
ON p.post_id = a.post_id
WHERE a.sentiment_label='Negative' 
GROUP BY users, comments
ORDER BY  COUNT(p.post_id) desc

-- 5)Can a user's sentiment trend be predicted over time?
--Analyze whether a user's mood changes based on their posting history.

SELECT 
    p.username,
    DATE_TRUNC('month', p.post_date) AS month,
    AVG(s.sentiment_score) AS avg_sentiment
FROM social_media_posts p
JOIN sentiment_analysis s ON p.post_id = s.post_id
GROUP BY p.username, month
ORDER BY p.username, month;

---END OF PROJECT
