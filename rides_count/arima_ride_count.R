# Install and load RPostgres package
# install.packages("RPostgres")
library("DBI")

# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
con <- dbConnect(RPostgres::Postgres(), dbname = "nyc_data",
			host = "localhost",
			user = "postgres")

# list tables in database to verify connection
dbListTables(con)

# query the database and input result into R data frame
# training dataset with data 2016/01/01 - 2016/01/21
count_rides_train_query <- dbSendQuery(con, "SELECT * FROM rides_count_train;")
count_rides_train <- dbFetch(count_rides_train_query)
dbClearResult(count_rides_train_query)
head(count_rides_train)

# testing dataset with data 2016/01/22 - 2016/01/31
count_rides_test_query <- dbSendQuery(con, "SELECT * FROM rides_count_test")
count_rides_test <- dbFetch(count_rides_test_query)
dbClearResult(count_rides_test_query)
head(count_rides_test)

# install and load the necessary packages
# install.packages("xts")
library("xts")

# convert the data frame into time series
xts_count_rides <- xts(count_rides_train$count, order.by = as.POSIXct(count_rides_train$one_hour, format = "%Y-%m-%d %H:%M:%S"))

# set the freqeuncy of series as weekly 24 * 7
attr(xts_count_rides, 'frequency') <- 168

# install and load the necessary packages
# install.packages("forecast")
library("forecast")

# use auto.arima to automatically get the arima model paremeters with best fit
fit <- auto.arima(xts_count_rides[,1], D = 1, seasonal = TRUE)

# see the summary of the fit
summary(fit)

# forecast future values using the arima model, h specifies the number of readings to forecast
fcast <- forecast(fit, h=168)

# plot the values forecasted
plot(fcast, include = 168, main="Taxicab Pickup Count in Times Square by Time", xlab="Date", ylab="Pickup Count", xaxt="n", col="red", fcol="blue")

# plot the observed values from the testing dataset
count_rides_test$x <- seq(4, 4 + 239 * 1/168, 1/168)
count_rides_test <- subset(count_rides_test, count_rides_test$one_hour < as.POSIXct("2016-01-29"))
lines(count_rides_test$x, count_rides_test$count, col="red")

ticks <- seq(3, 5, 1/7)
dates <- seq(as.Date("2016-01-15"), as.Date("2016-01-29"), by="days")
dates <- format(dates, "%m-%d %H:%M")
axis(1, at=ticks, labels=dates)
legend('topleft', legend=c("Observed", "Predicted"), col=c("red", "blue"), lwd=c(2.5,2.5))

# save.image('weekly_pickup_count_arima.RData')