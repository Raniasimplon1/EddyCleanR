#' @title Clean all eddy covariance data files
#'
#' @description This function automates filtering and gap filling of eddy-
#' covariance data by filling gaps using functions from zoo and uses
#' a Hampel filter from the R package \code{\link{pracma}} to filter the time
#' series and remove outliers. Use this function to clean a series of eddy
#' covariance data.
#'
#' @param directory The directory where the eddy covariance data files are
#' stored that you wish to use to calculate ET values
#'
#' @param time_zone The time zone for which the data is native. Defaults to Asia/
#'Manila for IRRI HQ. Should not be changed unless you know what you are doing
#'and are outside of IRRI HQ
#'
#' @examples
#'
#' clean_all_files(directory = "~/Eddy Covariance Data/")
#'

clean_all_files <- function(directory = "~/Eddy Covariance Data/",
                            time_zone = "Asia/Manila"){
  setwd <- directory

  if(file.exists("Cleaned") == FALSE) dir.create("Cleaned")

  filenames <- list.files(directory, pattern = ".dat$", full.names = TRUE)
  datalist <- lapply(filenames, function(x) {read.table(file = x,
                                                        skip = 4,
                                                        sep = ",",
                                                        na.strings = "NAN")
    }
    )
  dataFile <- Reduce(function(x, y) {rbind(x, y)}, datalist)

  # format column 1 to be date/time in R
  dataFile[, 1] <- as.POSIXct(strptime(dataFile[, 1],
                                       format = "%Y-%m-%d %H:%M:%S"))
  # create dataframe of only the columns necessary for filling and filtering
  data.i <- dataFile[, c(1, 5, 62)]

  # check for any missing values in the data
  w <- sapply(data.i, function(x) any(is.na(x)))

  if (any(w)) {
    # if there are missing values, we fill them using na.approx,
    # a linear interpolation from the zoo package
    # convert the data frame to a zoo object for gap filling
    data.zoo <- zoo(data.i)
    # are there gaps in the LE data? If yes we fill them
    if (any(is.na(data.zoo[, 2]))) {
      data.zoo[, 2] <- na.approx(data.zoo[, 2]) # fill any gaps in LE
    }
    # are there gaps in the T data? If yes we fill them
    if (any(is.na(data.zoo[, 3]))) {
      data.zoo[, 3] <- na.approx(data.zoo[, 3]) # fill any gaps in T
    }

    # apply hampel filter, 4 value window, default threshold
    # to the gap-filled data to remove outliers
    FilteredLE <- hampel(as.numeric(coredata(data.zoo[, 2])), 4, t0 = 3)
    # apply hampel filter, 4 value window, default threshold to the gap-filled
    #data to remove outliers
    FilteredT  <- hampel(as.numeric(coredata(data.zoo[, 3])), 4, t0 = 3)
  } else {
    # there are no missing values, no imputation necessary so we move on
    #and only run the filter
    # apply hampel filter, 4 value window, default threshold to remove outliers
    FilteredLE <- hampel(data.i[, 2], 4, t0 = 3)
    # apply hampel filter, 4 value window, default threshold to remove outliers
    FilteredT  <- hampel(data.i[, 3], 4, t0 = 3)
  }

  Cleaned <- data.frame(data.i[, 1],
                       FilteredLE$y,
                       data.i[, 2],
                       FilteredT$y,
                       # create dataframe and format date,
                       # w/ cleaned/uncleaned data
                       data.i[, 3])
  # name columns properly
  names(Cleaned) <- c("Date", "FilteredLE", "UnfilteredLE",
                     "FilteredT", "UnfilteredT")

  # Calculate et values for each .5hr unit
  Cleaned <- mutate(Cleaned, et = FilteredLE/(2500-2.4*FilteredT)*3.6)

  # write the data into a .csv file for saving
  write.csv(Cleaned, paste(substr(directory, 1, 48),
                          "Cleaned/Cleaned_Data.csv", sep = ""),
            row.names = FALSE)
}

#eos
