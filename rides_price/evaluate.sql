ALTER TABLE rides_price_test ADD COLUMN id SERIAL PRIMARY KEY;

ALTER TABLE rides_price_test ADD COLUMN forecast DOUBLE PRECISION;

UPDATE rides_price_test
SET forecast = rides_price_forecast_output.forecast_value
FROM rides_price_forecast_output
WHERE rides_price_test.id = rides_price_forecast_output.steps_ahead;

SELECT madlib.mean_abs_perc_error('rides_price_test', 'rides_price_mean_abs_perc_error', 'trip_price', 'forecast');

SELECT * FROM rides_price_mean_abs_perc_error;