# Connect to database and fetch records
library("DBI")
con <- dbConnect(RPostgres::Postgres(), dbname = "nyc_data",
			host = "localhost",
			user = "postgres")
rides_price_train_query <- dbSendQuery(con, "SELECT * FROM rides_price_train;")
rides_price_train <- dbFetch(rides_price_train_query)
dbClearResult(rides_price_train_query)

# convert the dataframe into a time series
library("xts")
xts_rides_price <- xts(rides_price_train$trip_price, order.by = as.POSIXct(rides_price_train$one_hour, format = "%Y-%m-%d %H:%M:%S"))
attr(xts_rides_price, 'frequency') <- 168

# use auto.arima() to calculate the orders
library("forecast")
fit <- auto.arima(xts_rides_price[,1])

# see the summary of the fit
summary(fit)