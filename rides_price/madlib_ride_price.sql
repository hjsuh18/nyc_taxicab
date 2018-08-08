-- train arima model and forecast the price of a ride from JFK to Times Square
DROP TABLE IF EXISTS rides_price_output;
DROP TABLE IF EXISTS rides_price_output_residual;
DROP TABLE IF EXISTS rides_price_output_summary;
DROP TABLE IF EXISTS rides_price_forecast_output;

SELECT madlib.arima_train('rides_price_train', -- input table
			'rides_price_output', -- output table
			'one_hour', -- timestamp column
			'trip_price', -- timeseries column
			NULL, -- grouping columns
			TRUE, -- include_mean
			ARRAY[1,1,1] -- non-seasonal orders
			);

SELECT madlib.arima_forecast('rides_price_output', -- model table
                        'rides_price_forecast_output', -- output table
                        240 -- steps_ahead
                        );