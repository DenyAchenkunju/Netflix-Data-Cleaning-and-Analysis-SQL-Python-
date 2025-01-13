
-----Handling the duplicates----
SELECT * FROM netflix_raw
WHERE UPPER(title) IN (
SELECT UPPER(title)
FROM netflix_raw
GROUP BY title,type
HAVING COUNT(*) >1)
ORDER BY title;


----Removing the duplicates
WITH cte as
(SELECT *, ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) as rn
FROM netflix_raw)
SELECT show_id,type,title,CAST(date_added as DATE) as date_added,release_year,rating,CASE WHEN duration IS NULL THEN rating ELSE duration END as duration,description
INTO netflix
FROM cte
WHERE rn =1;

---new table for listed in,director,country,cast

SELECT show_id,TRIM(value) as director
INTO netflix_directors --- created the table netflix_directors
FROM netflix_raw
CROSS APPLY string_split(director,',');



SELECT show_id,TRIM(value) as cast
into netflix_cast
FROM netflix_raw
CROSS APPLY string_split(cast,',')

---Datatype conversion for date_added as date

SELECT CAST(date_added as DATE) as date_added
FROM netflix_raw;


-----Populate missing values in country,duration columns


SELECT show_id,m.country
FROM netflix_raw nr
INNER JOIN 
(SELECT director,country
FROM netflix_country nc
INNER JOIN netflix_directors nd
ON nc.show_id = nd.show_id
GROUP BY director,country) m
ON nr.director = m.director
WHERE nr.country IS NULL;

--for duration missing values

SELECT *, CASE WHEN duration IS NULL THEN rating ELSE duration END as duration
FROM netflix_raw
WHERE duration IS NULL
-------------------------------------------------------------------------------------------------
-----------------------------------------DATA ANALYSIS-------------------------------------------
/*1.For each director count the no of movies and TV shows created by them in separate columns for directors
who have created TV shows and movies both */

SELECT nd.director,COUNT(CASE WHEN n.type = 'Movie' THEN n.show_id END) as no_of_movie,
COUNT(CASE WHEN n.type = 'TV Show' THEN n.show_id END) as no_of_tv_show
FROM netflix n
INNER JOIN netflix_directors nd
ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type) > 1;

---2. Which country has the highest no. of comedy movies------

SELECT TOP 1 nc.country, COUNT(distinct ng.show_id) as no_of_movies
FROM netflix_genre ng
INNER JOIN netflix_country nc on ng.show_id = nc.show_id
INNER JOIN netflix n on ng.show_id = nc.show_id
WHERE ng.genre ='Comedies' and n.type = 'Movie'
group by nc.country
ORDER BY no_of_movies DESC


---3.For each year (as per date added to netflix ) which director has maximum number of movies released---
WITH cte as
(
SELECT YEAR(date_added) as year_released,nd.director,COUNT(n.show_id) as no_of_movies,ROW_NUMBER() OVER(PARTITION BY YEAR(date_added) 
ORDER BY COUNT(n.show_id) DESC, nd.director) as rn
FROM netflix n
INNER JOIN netflix_directors nd
ON n.show_id = nd.show_id
WHERE type = 'Movie'
GROUP BY YEAR(date_added),nd.director)
--ORDER BY no_of_movies DESC) 
SELECT director,year_released
FROM cte
WHERE rn =1;

--------------------------------------------------------------------------------------------------

----4.What is the average duration of movies in each genre-------

SELECT ng.genre,AVG(CAST(REPLACE(duration,' min','') AS int)) as avg_duration_int
FROM netflix n
INNER JOIN netflix_genre ng
ON n.show_id = ng.show_id
WHERE type ='Movie'
GROUP BY ng.genre;


----------------------------------------------------------------------------------------------------

---5.Find the list of directors who have created horror and comedy movies both.
---display director names along with number of comedy and horror movies directed by them.


SELECT nd.director,COUNT(CASE WHEN ng.genre = 'Comedies' THEN n.show_id END) as no_of_comedy_movies,
COUNT(CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id END) as no_of_Horror_movies
FROM netflix n
INNER JOIN netflix_directors nd
ON n.show_id = nd.show_id
INNER JOIN netflix_genre ng
ON n.show_id =ng.show_id
WHERE n.type = 'Movie'
AND ng.genre IN('Comedies','Horror Movies')
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre) > 1;









