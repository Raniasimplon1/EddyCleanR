#' @title Clean One Day (24 hour) Eddy Covariance Data File
#'
#'@description This function automates filtering and gap filling of eddy-
#'covariance data from the IRRI Ecological Intensification Platform for
#'calculating evapotranspiration for irrigation scheduling. This function
#'checks a specified directory for the most recent data file from the eddy
#'covariance tower and the most recent previous file. It then takes the two
#'files and runs the same operations (gap filling and a Hampel filter) and
#'then generates an estimate of evapotranspiration for the previous 24 hour
#'time-period. IRRI uses this to then schedule pivot irrigation in the
#'ecological intensification platform.
#'
#' @param directory The directory where the eddy covariance data files are
#' stored that you wish to use to calculate ET values
#'
#'@param time_zone The time zone for which the data is native. Defaults to Asia/
#'Manila for IRRI HQ. Should not be changed unless you know what you are doing
#'and are outside of IRRI HQ
#'
#' @examples

#' clean_one_day(directory = "~/Eddy Covariance Data/")
#'

clean_one_day <- function(directory = "~/Eddy Covariance Data/",
                          time_zone = "Asia/Manila"){

  setwd(directory)

  # check to see if cleaned directory exists, if not create
  if(file.exists("cleaned") == FALSE) dir.create("cleaned")

  # Determine where we are in time and space
  options(tz = time_zone)
  Sys.setenv(TZ = time_zone)

  # The filenaming convention means that we have to go back to previous for
  # the date, to determine the file from current
  # What day was the day before yesterday, according to the system clock?
  previous <- as.Date(today(time_zone) - 2)
  # What day was yesterday, according to the computer's system clock?
  current <- as.Date(today(time_zone) - 1)

  # When do we want to start the ET calculations, need to back up for the
  # filter window to work properly
  begin <- ymd_hms(paste(previous, "12:30:00", sep = ""),
                   tz = "Asia/Manila", quiet = TRUE)
  # When do we want to end the ET calculations
  end <- ymd_hms(paste(current, "16:00:00", sep = ""), tz = "Asia/Manila",
                 quiet = TRUE)

  # find file in directory that matches the current date
  current_file <- ldply(list.files(directory,
                                   pattern = paste("?[[:graph:]]+.flux_",
                                                   substr(current, 1, 4), "_",
                                                   substr(current, 6, 7), "_",
                                                   substr(current, 9, 10),
                                                   "[[:graph:]]+.dat$",
                                                   sep = "")),
                        read.table,
                        skip = 4,
                        na.strings = "NAN",
                        sep = ",")

  # import table of data for previous day, maybe necessary to fill
  # gap at begining of 24hr period
  previous_file <- ldply(list.files(directory,
                                   pattern = paste("?[[:graph:]]+.flux_",
                                                   substr(previous, 1, 4), "_",
                                                   substr(previous, 6, 7), "_",
                                                   substr(previous, 9, 10),
                                                   "[[:graph:]]+.dat$",
                                                   sep = "")),
                         read.table,
                         skip = 4,
                         na.strings = "NAN",
                         sep = ",")

  # combine the two files into one data frame
  data_day <- rbind(previous_file, current_file)

  if (length(data_day[, 1]) == 0)
    stop("You do not have eddy covariance data for the current time-period, or your computer's system time is not correct. Please check the directory where the files are located for files with time-stamp names that include yesterday's and the day before yesterday's date. Also make sure your system clock is set to the proper time, date and time zone 'Asia/Manila PHT'.")

  # format column 1 to be date/time in R
  data_day[, 1] <- ymd_hms(data_day[, 1], tz = "Asia/Manila", quiet = TRUE)
  # create dataframe of only the columns necessary for filling and filtering
  data_day <- data_day[, c(1, 5, 62)]

  # assign names to keep things straight
  names(data_day) <- c("Date", "LE", "Temperature")

  # check for any missing values in the data
  w <- sapply(data_day, function(x) any(is.na(x)))

  # if there are missing values, we fill them using na.approx,
  # a linear interpolation from the zoo package
  if (any(w)) {
    # convert the data frame to a zoo object for gap filling
    data_zoo <- zoo(data_day)
    # are there gaps in the LE data? If yes we fill them
    if (any(is.na(data_zoo[, 2]))) {
      # fill any gaps in LE
      data_zoo[, 2] <- na.approx(data_zoo[, 2])
    }
    # are there gaps in the T data? If yes we fill them
    if (any(is.na(data_zoo[, 3]))) {
      data_zoo[, 3] <- na.approx(data_zoo[, 3])
      # fill any gaps in T
    }

    # apply hampel filter, 4 value window, default threshold
    # to the gap-filled data to remove outliers
    filtered_LE <- hampel(as.numeric(coredata(data_zoo[, 2])), 4, t0 = 3)
    # apply hampel filter, 4 value window, default threshold to the gap-filled
    # data to remove outliers
    filtered_T  <- hampel(as.numeric(coredata(data_zoo[, 3])), 4, t0 = 3)
  } else {
    # there are no missing values, no imputation necessary so we
    # move on and only run the filter
    # apply hampel filter, 4 value window, default threshold to remove outliers
    filtered_LE <- hampel(data_day[, 2], 4, t0 = 3)
    # apply hampel filter, 4 value window, default threshold to remove outliers
    filtered_T  <- hampel(data_day[, 3], 4, t0 = 3)
  }

  cleaned <- data.frame(data_day[c(8:55), 1],
                        filtered_LE$y[c(8:55)],
                        data_day[c(8:55), 2],
                        filtered_T$y[c(8:55)],
                        data_day[c(8:55), 3])

  names(cleaned) <- c("Date", "Filtered_LE", "Unfiltered_LE",
                      "Filtered_T", "Unfiltered_T")

  # calculate et values for each 0.5hr unit
  cleaned <- mutate(cleaned, et = Filtered_LE / (2500 - 2.4 * Filtered_T) * 3.6)

  daily_et <- mean(cleaned$et)/2

  # write the data into a .csv file for saving
  write.csv(cleaned, paste(directory, "/cleaned/",
                           substr(end, 1, 10), ".csv", sep = ""))

  # return the ET calculation value
  cat(paste("The daily ET value is ", round(daily_et, 2), ".", sep = ""))
}

#eos
