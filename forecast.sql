-- Make tables for time series forecasting analysis
--------------------------------------------------------------------------------------------------------
-- Add a column for trip_length by taking the difference of pickup and dropoff times
ALTER TABLE rides ADD COLUMN trip_length INTERVAL;
UPDATE rides SET trip_length = dropoff_datetime - pickup_datetime;

-- Clean data - rides with trip_length above 3 hours are likely to be anomalies
DELETE FROM rides WHERE trip_length > interval '3:00:00';

--------------------------------------------------------------------------------------------------------

-- SEASONAL ARIMA WITH R SECTION

DROP TABLE IF EXISTS rides_count CASCADE;
CREATE TABLE rides_count(
	one_hour TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	count NUMERIC
);
SELECT create_hypertable('rides_count', 'one_hour');


WITH data AS (
	SELECT time_bucket('1 hour', pickup_datetime) AS one_hour,
	COUNT(*) AS count
	FROM rides
	WHERE ST_Distance(pickup_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-73.9851,40.7589),4326),2163)) < 400
	GROUP BY one_hour ORDER BY one_hour
),
period AS (
	SELECT time_bucket('1 hour', no_gaps) one_hour
	FROM  generate_series('2016-01-01 00:00:00'::timestamp, '2016-01-31 23:59:59', '1 hour') no_gaps
)
INSERT INTO rides_count
SELECT period.one_hour, coalesce(data.count, 0)
FROM period
LEFT JOIN data ON period.one_hour = data.one_hour
ORDER BY period.one_hour;

--------------------------------------------------------------------------------------------------------

-- NON-SEASONAL ARIMA WITH MADLIB SECTION

-- Make a table for the price of a ride from JFK to Times Square
-- rate_code = 2 is the rate code for taxicab rides from/to JFK
-- (40.7589, -73.9851)  are the cooridinates of Times Square
DROP TABLE IF EXISTS rides_price CASCADE;
CREATE TABLE rides_price(
	one_hour TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	trip_price DOUBLE PRECISION
);
SELECT create_hypertable('rides_price', 'one_hour');
WITH data AS (
	SELECT
	time_bucket('1 hour', pickup_datetime) AS one_hour,
	CAST (AVG(total_amount) AS DOUBLE PRECISION) as price
	FROM rides
	WHERE rate_code = 2 AND
	ST_Distance(dropoff_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-73.9851,40.7589),4326),2163)) < 400
	GROUP BY one_hour ORDER BY one_hour
),
period AS (
	SELECT time_bucket('1 hour', no_gaps) one_hour
	FROM  generate_series('2016-01-01 00:00:00'::timestamp, '2016-01-31 23:59:59', '1 hour') no_gaps
)
INSERT INTO rides_price
SELECT period.one_hour,
(SELECT data.price FROM data 
	WHERE data.one_hour <= period.one_hour
	ORDER BY data.one_hour DESC LIMIT 1) AS trip_price
FROM period
ORDER BY period.one_hour;

--------------------------------------------------------------------------------------------------------

-- HOLT WINTERS WITH PYTHON

-- Make a table for the length of a ride from Financial District to Times Square
-- (40.7075, -74.0113) are the coordinates of the Financial District
-- (40.7589, -73.9851) are the coordinates of Times Square
DROP TABLE IF EXISTS rides_length CASCADE;
CREATE TABLE rides_length(
	three_hour TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	trip_length INTERVAL
);
SELECT create_hypertable('rides_length', 'three_hour');
WITH data AS (
	SELECT
	time_bucket('3 hour', pickup_datetime) AS three_hour,
	AVG(trip_length) AS length
	FROM rides
	WHERE
	ST_Distance(pickup_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-74.0113,40.7075),4326),2163)) < 400 AND
	ST_Distance(dropoff_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-73.9851,40.7589),4326),2163)) < 400
	GROUP BY three_hour ORDER BY three_hour
	),
period AS (
	SELECT time_bucket('3 hour',  no_gaps) three_hour
	FROM  generate_series('2016-01-01 00:00:00'::timestamp, '2016-01-31 23:59:59', '3 hour') no_gaps
	)
INSERT INTO rides_length
SELECT period.three_hour,
(SELECT data.length FROM data
	WHERE data.three_hour <= period.three_hour
	ORDER BY data.three_hour DESC LIMIT 1) AS trip_length
FROM period
ORDER BY period.three_hour;