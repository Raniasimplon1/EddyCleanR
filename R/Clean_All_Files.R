#' @title Clean all eddy covariance data files in a directory
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
#' \dontrun{
#' clean_all_files(directory = "~/Eddy Covariance Data/")
#' }
#'
#'@export
clean_all_files <- function(directory = "~/Eddy Covariance Data/",
                            time_zone = "Asia/Manila") {
  Filtered_LE <- Filtered_T <- NULL
  if (!isTRUE(file.exists(paste0(directory, "/cleaned"))))
    dir.create(paste0(directory, "/cleaned"))
  filenames <-
    list.files(directory, pattern = ".dat$", full.names = TRUE)
  datalist <- lapply(filenames, function(x) {
    utils::read.table(
      file = x,
      skip = 4,
      sep = ",",
      na.strings = "NAN"
    )
  })
  data_file <- Reduce(function(x, y) {
    rbind(x, y)
  },
  datalist)
  # format column 1 to be date/time in R
  data_file[, 1] <- as.POSIXct(strptime(data_file[, 1],
                                        format = "%Y-%m-%d %H:%M:%S"))
  # create dataframe of only the columns necessary for filling and filtering
  data_i <- data_file[, c(1, 5, 62)]
  # check for any missing values in the data
  w <- sapply(data_i, function(x)
    any(is.na(x)))
  if (any(w)) {
    # if there are missing values, we fill them using zoo::na.approx,
    # a linear interpolation from the zoo package
    # convert the data frame to a zoo object for gap filling
    data_zoo <- zoo::zoo(data_i)
    # are there gaps in the LE data? If yes we fill them
    if (any(is.na(data_zoo[, 2]))) {
      data_zoo[, 2] <- zoo::na.approx(data_zoo[, 2]) # fill any gaps in LE
    }
    # are there gaps in the T data? If yes we fill them
    if (any(is.na(data_zoo[, 3]))) {
      data_zoo[, 3] <- zoo::na.approx(data_zoo[, 3]) # fill any gaps in T
    }
    # apply hampel filter, 4 value window, default threshold
    # to the gap-filled data to remove outliers
    Filtered_LE <-
      pracma::hampel(as.numeric(zoo::coredata(data_zoo[, 2])), 4,
                     t0 = 3)
    # apply hampel filter, 4 value window, default threshold to the gap-filled
    # data to remove outliers
    Filtered_T  <-
      pracma::hampel(as.numeric(zoo::coredata(data_zoo[, 3])), 4,
                     t0 = 3)
  } else {
    # there are no missing values, no imputation necessary so we move on
    # and only run the filter
    # apply hampel filter, 4 value window, default threshold to remove outliers
    Filtered_LE <- pracma::hampel(data_i[, 2], 4, t0 = 3)
    # apply hampel filter, 4 value window, default threshold to remove outliers
    Filtered_T  <- pracma::hampel(data_i[, 3], 4, t0 = 3)
  }
  cleaned <- data.frame(data_i[, 1],
                        Filtered_LE$y,
                        data_i[, 2],
                        Filtered_T$y,
                        # create dataframe and format date,
                        # w/ cleaned/uncleaned data
                        data_i[, 3])
  # name columns properly
  names(cleaned) <- c("Date",
                      "Filtered_LE",
                      "UnFiltered_LE",
                      "Filtered_T",
                      "UnFiltered_T")
  # Calculate et values for each .5hr unit
  cleaned <- dplyr::mutate(cleaned, et = Filtered_LE /
                             (2500 - 2.4 * Filtered_T) * 3.6)
  # write the data into a .csv file for saving
  utils::write.csv(cleaned,
                   paste0(directory,
                          "/cleaned/cleaned_Data.csv", sep = ""),
                   row.names = FALSE)
}
#eos
