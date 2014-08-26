##############################################################################
# title         : Clean_24_hour_files.R;
# version       : 2.0;
# purpose       : function to clean eddy covariance data for automation of
#               : pivot irrigation for the IRRI ecological intensification plots;
# producer      : prepared by A. H. Sparks;
# last update   : in Los Baños, Phliippines, August 2014;
# inputs        : .dat files from eddy covariance towers;
# outputs       : cleaned eddy covariance data as a .csv file;
# comments      : provided as-is, no guarantees;
# licence       : GPL2;
##############################################################################

# Step 1: Load all the libraries necessary for this function to work ####
library(pracma)
library(compiler)
library(plyr)
library(sqldf)
library(lubridate)
library(zoo)
library(stringr)

# Step 2: Start the real work ####
if(file.exists("Output") == FALSE) dir.create("Output") # check to see if output directory exists, if not create

cleaner <- function(directory){
  
  # Determine where we are in time and space
  options(tz = "Asia/Manila") # Which time zone are we working in? Presumably for IRRI only, would be changed for other location.
  Sys.setenv(TZ = "Asia/Manila")
  
  # The filenaming convention means that we have to go back to yesterday"s date to pull in today"s file
  yesterday <- as.Date(Sys.Date()-2) # What day was the day before yesterday, according to the computer"s system clock?
  today <- as.Date(Sys.Date()-1) # What day was yesterday, according to the computer"s system clock?
  
  begin <- ymd_hms(paste(yesterday, "12:30:00", sep = ""), tz = "Asia/Manila", quiet = TRUE) # When do we want to start the ET calculations, need to back up for the filter window to work properly
  end <- ymd_hms(paste(today, "16:00:00", sep = ""), tz = "Asia/Manila", quiet = TRUE) # When do we want to end the ET calculations
  
  # Determine where the files are located now that we know where we are, where are they?
  dataFiles <- list.files(directory, pattern = ".dat$") # make a list of .dat files in directory
  currentFile <- str_match(dataFiles, pattern = noquote(paste("?[[:graph:]]+.flux_", substr(today, 1, 4), "_", substr(today, 6, 7), "_", substr(today, 9, 10), "[[:graph:]]+.dat$", sep = ""))) # find file in directory that matches the current date
  currentDay <- read.table(paste(directory, currentFile[which(!is.na(currentFile)), ],  sep = "/"), # import table of data for current day to calculate ET
                           skip = 4, # skip importing the first four lines of headers and whatnot
                           sep = ",", # the original data is parsed with commas
                           na.strings = "NAN") # replace NAN with NA in R for missing values
  previousDay <- read.table(paste(directory, dataFiles[which(!is.na(currentFile))-1], sep = "/"), # import table of data for previous day, maybe necessary to fill gap at begining of 24hr period
                            skip = 4, # skip importing the first four lines of headers and whatnot
                            sep = ",", # the original data is parsed with commas
                            na.strings = "NAN") # replace NAN with NA in R for missing values 
  day <- rbind(previousDay, currentDay) # combine the two files into one data frame
  
  day[, 1] <- as.character(day[, 1]) # format the object class to character from factor for transformation using lubridate
  day[, 1] <- ymd_hms(day[, 1], tz = "Asia/Manila", quiet = TRUE) # format column 1 to be date/time in R
  data <- day[, c(1, 5, 62)] # create dataframe of only the columns necessary for filling and filtering
  data[, 1] <- as.numeric(data[, 1]) # convert date to numeric for SQL query
  names(data) <- c("Date", "LE", "Temperature") # assign names to run a SQL query using the Date column
  
  data.day <- sqldf(paste("SELECT * FROM data WHERE Date > "", as.numeric(begin), "" AND Date <= "", as.numeric(end), """,  sep = "")) # query the 48 observations we need for one day
  class(data.day[, 1]) = c("POSIXt","POSIXct") # now that we have the new database, convert the dates back to a date format
  
  w <- sapply(data.day, function(x) any(is.na(x))) # check for any missing values in the data
  
  if (any(w)) { # if there are missing values, we fill them using na.approx, a linear interpolation from the zoo package
    data.zoo <- zoo(data.day) # convert the data frame to a zoo object for gap filling
    if (any(is.na(data.zoo[, 2]))) { # are there gaps in the LE data? If yes we fill them
      data.zoo[, 2] <- na.approx(data.zoo[, 2]) # fill any gaps in LE
    } 
    if (any(is.na(data.zoo[, 3]))) { # are there gaps in the T data? If yes we fill them
      data.zoo[, 3] <- na.approx(data.zoo[, 3]) # fill any gaps in T
    }
    
    FilteredLE <- hampel(as.numeric(coredata(data.zoo[, 2])), 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to the gap-filled data to remove outliers
    FilteredT  <- hampel(as.numeric(coredata(data.zoo[, 3])), 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to the gap-filled data to remove outliers
  } else { # there are no missing values, no imputation necessary so we move on and only run the filter
    
    FilteredLE <- hampel(data.day[, 2], 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to remove outliers
    FilteredT  <- hampel(data.day[, 3], 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to remove outliers
  }
  
  output <- data.frame(data.day[c(8:55), 1], 
                       FilteredLE$y[c(8:55)], 
                       data.day[c(8:55), 2], 
                       FilteredT$y[c(8:55)], 
                       data.day[c(8:55), 3]) # create dataframe and format date, w/ cleaned/uncleaned data
  names(output) <- c("Date", "FilteredLE", "UnfilteredLE", "FilteredT", "UnfilteredT") # name columns properly
  output <- mutate(output, et = FilteredLE/(2500-2.4*FilteredT)*3.6) # calculate et values for each 0.5hr unit
  
  daily.et <- output$et/2
  write.csv(output, paste(substr(directory, 1, 48), "Output/", substr(end, 1, 10), ".csv", sep = "")) # write the data into a .csv file for saving on server and e-mailing (to be added later) 
  cat(paste("The daily ET value is", daily.et, sep = " ")) # return the ET calculation in the console below
}

# Step 4: byte compile ####
theCleaner <- cmpfun(cleaner) # byte compile the function for just a touch more speed

#eos
