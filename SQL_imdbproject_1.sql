USE imdb;

-- Q1. Find the total number of rows in each table of the schema?
SELECT table_name,
table_rows 
FROM information_schema.tables
WHERE table_schema = 'imdb';

-- Q2. Which columns in the movie table have null values?
SELECT 
SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS title_nulls,
SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS year_nulls,
SUM(CASE WHEN date_published IS NULL THEN 1 ELSE 0 END) AS date_published_nulls,
SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS duration_nulls,
SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
SUM(CASE WHEN worlwide_gross_income IS NULL THEN 1 ELSE 0 END) AS worlwide_gross_income_nulls,
SUM(CASE WHEN languages IS NULL THEN 1 ELSE 0 END) AS languages_nulls,
SUM(CASE WHEN production_company IS NULL THEN 1 ELSE 0 END) AS production_company_nulls
FROM movie;

-- Q3. Find the total number of movies released each year? How does the trend look month wise? (Output expected)

SELECT year, COUNT(*) AS number_of_movies
FROM movie
GROUP BY year;

SELECT MONTH(date_published) AS Month, COUNT(*) AS number_of_movies
FROM movie
GROUP BY MONTH(date_published)
ORDER BY number_of_movies DESC;

-- Q4. How many movies were produced in the USA or India in the year 2019??
SELECT COUNT(*) AS number_of_movies 
FROM movie
WHERE year=2019
AND (Country LIKE '%USA%' OR country LIKE '%India%');

-- Q5. Find the unique list of the genres present in the data set?
SELECT DISTINCT genre FROM genre;

-- Q6.Which genre had the highest number of movies produced overall?
SELECT genre, COUNT(*) AS no_of_movies 
FROM genre
GROUP BY genre
ORDER BY no_of_movies DESC
LIMIT 1;

-- Q7. How many movies belong to only one genre?
WITH movie_summary AS (
SELECT movie_id, COUNT(*) AS no_of_genres
FROM genre
GROUP BY movie_id
HAVING COUNT(*)=1)
SELECT COUNT(movie_id) FROM movie_summary;

-- Q8.What is the average duration of movies in each genre? 
SELECT genre, AVG(duration) AS avg_duration 
FROM genre g
JOIN movie m ON g.movie_id=m.id
GROUP BY genre
ORDER BY avg_duration DESC;

-- Q9.What is the rank of the ‘thriller’ genre of movies among all the genres in terms of number of movies produced? 
WITH summary AS (
SELECT genre, COUNT(*) AS no_of_movies,
RANK() OVER(ORDER BY COUNT(*) DESC) AS genre_rank
FROM genre
GROUP BY genre)
SELECT * FROM summary
WHERE genre='Thriller';

-- Q10.  Find the minimum and maximum values in  each column of the ratings table except the movie_id column?
SELECT MIN(avg_rating) AS min_avg_rating,
MAX(avg_rating) AS max_avg_rating,
MIN(total_votes) AS min_total_votes,
MAX(total_votes) AS max_total_votes,
MIN(median_rating) AS min_median_rating,
MAX(median_rating) AS max_median_rating
FROM ratings;

-- Q11. Which are the top 10 movies based on average rating?
WITH movie_summary AS (
SELECT title, avg_rating, 
RANK() OVER(ORDER BY avg_rating DESC) AS movie_rank
FROM movie m 
JOIN ratings r ON m.id=r.movie_id)
SELECT * FROM movie_summary
WHERE movie_rank<=10;

-- Q12. Summarise the ratings table based on the movie counts by median ratings.
SELECT median_rating, COUNT(*) AS movie_count FROM ratings
GROUP BY median_rating
ORDER BY movie_count DESC;

-- Q13. Which production house has produced the most number of hit movies (average rating > 8)??
WITH prod_summary AS (
SELECT production_company, COUNT(m.id) AS movie_count,  
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS prod_comp_rank
FROM movie m 
JOIN ratings r ON m.id=r.movie_id
WHERE avg_rating>8
AND production_company IS NOT NULL
GROUP BY production_company)
SELECT * FROM prod_summary
WHERE prod_comp_rank=1;

-- Q14. How many movies released in each genre during March 2017 in the USA had more than 1,000 votes?
SELECT genre, COUNT(m.id) AS movie_count FROM movie m
JOIN genre g ON m.id=g.movie_id
JOIN ratings r ON r.movie_id=m.id
WHERE (date_published BETWEEN '2017-03-01' AND '2017-03-31')
AND country LIKE '%USA%'
AND total_votes>1000
GROUP BY genre
ORDER BY movie_count DESC;

-- Q15. Find movies of each genre that start with the word ‘The’ and which have an average rating > 8?
SELECT title, avg_rating, genre  FROM movie m
JOIN genre g ON m.id=g.movie_id
JOIN ratings r ON r.movie_id=m.id
WHERE title LIKE 'The%'
AND avg_rating>8;

-- Q16. Of the movies released between 1 April 2018 and 1 April 2019, how many were given a median rating of 8?
SELECT COUNT(m.id) AS movie_count FROM movie m
JOIN ratings r ON r.movie_id=m.id
WHERE (date_published BETWEEN '2018-04-01' AND '2019-04-01')
AND median_rating=8;

SHOW VARIABLES LIKE 'sql_mode';
SET GLOBAL sql_mode='';


-- Q17. Do German movies get more votes than Italian movies? 
WITH languages_summary AS (
SELECT languages, SUM(total_votes) AS total_votes FROM movie m
JOIN ratings r ON r.movie_id=m.id
WHERE languages LIKE '%German%'
UNION
SELECT languages, SUM(total_votes) AS total_votes FROM movie m
JOIN ratings r ON r.movie_id=m.id
WHERE languages LIKE '%Italian%'), final_summary AS (
SELECT * FROM languages_summary
ORDER BY total_votes DESC
LIMIT 1)
SELECT IF(languages LIKE 'German','Yes','No') AS final_result
FROM final_summary;


-- Q19. Who are the top three directors in the top three genres whose movies have an average rating > 8?
-- (Hint: The top three genres would have the most number of movies with an average rating > 8.)
WITH top_three_genres AS (
SELECT genre, COUNT(m.id) AS movie_count FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN genre g ON m.id=g.movie_id
WHERE avg_rating>8
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 3), director_summary AS (
SELECT n.name, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS director_rank
FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN genre g ON m.id=g.movie_id
JOIN director_mapping dm ON m.id=dm.movie_id
JOIN names n ON n.id=dm.name_id
JOIN top_three_genres ttg ON g.genre=ttg.genre
WHERE avg_rating>8
-- AND genre IN (SELECT genre FROM top_three_genres)
GROUP BY n.name)
SELECT name AS director_name, movie_count FROM director_summary
WHERE director_rank<=3;

-- Q20. Who are the top two actors whose movies have a median rating >= 8?
WITH actor_summary AS (
SELECT n.name AS actor_name, COUNT(m.id) AS movie_count,
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS actor_rank
FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN role_mapping rm ON rm.movie_id=m.id
JOIN names n ON n.id=rm.name_id
WHERE median_rating>=8
AND category='actor'
GROUP BY n.name)
SELECT actor_name, movie_count FROM actor_summary
WHERE actor_rank<=2;

-- Q21. Which are the top three production houses based on the number of votes received by their movies?
WITH prod_summary AS (
SELECT production_company, SUM(total_votes) AS vote_count, 
RANK() OVER(ORDER BY SUM(total_votes) DESC) AS prod_comp_rank
FROM movie m
JOIN ratings r ON r.movie_id=m.id
WHERE production_company IS NOT NULL
GROUP BY production_company)
SELECT * FROM prod_summary
WHERE prod_comp_rank<=2;

-- Q22. Rank actors with movies released in India based on their average ratings. Which actor is at the top of the list?
-- Note: The actor should have acted in at least five Indian movies. 
SELECT n.name AS actor_name, 
SUM(total_votes) AS total_votes,
COUNT(m.id) AS movie_count,
ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) AS actor_avg_rating,
RANK() OVER(ORDER BY ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) DESC) AS actor_rank
FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN role_mapping rm ON rm.movie_id=m.id
JOIN names n ON n.id=rm.name_id
WHERE country LIKE '%India%'
AND category='actor'
GROUP BY n.name
HAVING COUNT(m.id) >=5;

-- Q23.Find out the top five actresses in Hindi movies released in India based on their average ratings? 
-- Note: The actresses should have acted in at least three Indian movies. 
SELECT n.name AS actress_name, 
SUM(total_votes) AS total_votes,
COUNT(m.id) AS movie_count,
ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) AS actress_avg_rating,
RANK() OVER(ORDER BY ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) DESC) AS actress_rank
FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN role_mapping rm ON rm.movie_id=m.id
JOIN names n ON n.id=rm.name_id
WHERE country LIKE '%India%'
AND languages LIKE '%Hindi%'
AND category='actress'
GROUP BY n.name
HAVING COUNT(m.id) >=3;


-- Q25. What is the genre-wise running total and moving average of the average movie duration? 
SELECT genre, AVG(duration) AS avg_duration,
SUM(AVG(duration)) OVER(ORDER BY genre ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_duration,
AVG(AVG(duration)) OVER(ORDER BY genre ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS moving_avg_duration 
FROM movie m 
JOIN genre g ON m.id=g.movie_id
GROUP BY genre;

-- Q26. Which are the five highest-grossing movies of each year that belong to the top three genres? 
-- (Note: The top 3 genres would have the most number of movies.)
WITH top_three_genres AS (
SELECT genre, COUNT(m.id) AS movie_count FROM movie m
JOIN ratings r ON r.movie_id=m.id
JOIN genre g ON m.id=g.movie_id
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 3), income_summary AS (
SELECT g.genre, year, title AS movie_name, 
CAST(REPLACE(REPLACE(IFNULL(worlwide_gross_income,0),'$',''),'INR','') AS DECIMAL(10)) AS worldwide_gross_income,
RANK() OVER(PARTITION BY year ORDER BY CAST(REPLACE(REPLACE(IFNULL(worlwide_gross_income,0),'$',''),'INR','') AS DECIMAL(10)) DESC) AS movie_rank
FROM movie m 
JOIN genre g ON m.id=g.movie_id
JOIN top_three_genres ttg ON ttg.genre=g.genre)
SELECT * FROM income_summary
WHERE movie_rank<=5;

-- Q27.  Which are the top two production houses that have produced the highest 
-- number of hits (median rating >= 8) among multilingual movies?
WITH prod_summary AS (
SELECT production_company, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) As prod_comp_rank
FROM movie m
JOIN ratings r ON m.id=r.movie_id
WHERE median_rating>=8
AND POSITION(',' IN languages)>0
AND production_company IS NOT NULL
GROUP BY production_company)
SELECT * FROM prod_summary
WHERE prod_comp_rank<=2;


-- Q28. Who are the top 3 actresses based on number of Super Hit movies (average rating >8) in drama genre?
WITH actress_summary AS (
SELECT n.name AS actress_name, 
SUm(total_votes) AS total_votes,
COUNT(m.id) AS movie_count,
ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) AS actress_avg_rating,
RANK() OVER(ORDER BY COUNT(m.id)  DESC) AS  actress_rank
FROM movie m
JOIN ratings r ON m.id=r.movie_id
JOIN genre g ON m.id=g.movie_id
JOIN role_mapping rm ON rm.movie_id=m.id
JOIN names n ON n.id=rm.name_id
WHERE avg_rating>8
AND genre='Drama'
AND category='actress'
GROUP BY n.name)
SELECT * FROM actress_summary
WHERE actress_rank<=3;

/* Q29. Get the following details for top 9 directors (based on number of movies)
Director id
Name
Number of movies
Average inter movie duration in days
Average movie ratings
Total votes
Min rating
Max rating
total movie durations */
WITH director_summary AS (
SELECT dm.name_id AS director_id, 
n.name AS director_name,
m.id AS movie_id,
duration, avg_rating, total_votes,
date_published,
LEAD(date_published) OVER(PARTITION BY n.name ORDER BY date_published) AS next_publish_date
FROM movie m
JOIN ratings r ON m.id=r.movie_id
JOIN director_mapping dm ON dm.movie_id=m.id
JOIN names n ON n.id=dm.name_id)
SELECT director_id, director_name, 
COUNT(movie_id) AS number_of_movies,
ROUND(SUM(DATEDIFF(next_publish_date,date_published))/(COUNT(movie_id) -1)) AS avg_inter_movie_days,
ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) AS avg_rating,
SUM(total_votes) AS total_votes,
MIN(avg_rating) AS min_avg_rating,
MAX(avg_rating) AS max_avg_rating,
SUM(duration) AS total_duration
FROM director_summary
GROUP BY director_id, director_name
ORDER BY COUNT(movie_id) DESC
LIMIT 9;
