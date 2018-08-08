#!/usr/bin/python
import psycopg2
import psycopg2.extras
import pandas as pd
import numpy as np
from statsmodels.tsa.api import ExponentialSmoothing
import matplotlib.pyplot as plt

def main():
	# get a connection
	conn = psycopg2.connect(dbname='nyc_data', user='postgres', host='localhost')
	
	# cursor object allows querying of database
	# server-side cursor is created to prevent all records to be downloaded
	# at once from the server
	cursor_train = conn.cursor('train', cursor_factory=psycopg2.extras.DictCursor)
	cursor_test = conn.cursor('test', cursor_factory=psycopg2.extras.DictCursor)
	
	# execute SQL query to get training dataset
	cursor_train.execute('SELECT * FROM rides_length_train')
	cursor_test.execute('SELECT * FROM rides_length_test')

	# fetch records from database
	ride_length_train = cursor_train.fetchall()
	ride_length_test = cursor_test.fetchall()

	# make records into a pandas dataframe
	ride_length_train = pd.DataFrame(np.array(ride_length_train), columns = ['time', 'trip_length'])
	ride_length_test = pd.DataFrame(np.array(ride_length_test), columns = ['time', 'trip_length'])

	# convert the type of columns of dataframe to datetime and timedelta
	ride_length_train['time'] = pd.to_datetime(ride_length_train['time'], format = '%Y-%m-%d %H:%M:%S')	
	ride_length_test['time'] = pd.to_datetime(ride_length_test['time'], format = '%Y-%m-%d %H:%M:%S')
	ride_length_train['trip_length'] = pd.to_timedelta(ride_length_train['trip_length'])
	ride_length_test['trip_length'] = pd.to_timedelta(ride_length_test['trip_length'])
	
	# set the index of dataframes to the timestamp
	ride_length_train.set_index('time', inplace = True)
	ride_length_test.set_index('time', inplace = True)

	# convert into seconds
	ride_length_train['trip_length'] = ride_length_train['trip_length']/np.timedelta64(1, 's')
	ride_length_test['trip_length'] = ride_length_test['trip_length']/np.timedelta64(1, 's')

	print 'Exponential smoothing'
	fit = ExponentialSmoothing(np.asarray(ride_length_train['trip_length']), seasonal_periods = 56, trend = 'add', seasonal = 'add').fit()

	print 'forecast'
	ride_length_test['forecast'] = fit.forecast(len(ride_length_test))
	print ride_length_test

	plt.plot(ride_length_test)
	plt.title('Taxicab Ride Length from Financial District to Times Square by Time')
	plt.xlabel('Date')
	plt.ylabel('Ride Length')
	plt.legend(['Observed', 'Predicted'])
	plt.show()

	# ride_length_test.to_pickle("./ride_length.pkl")

if __name__ == "__main__":
	main()