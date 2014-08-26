##############################################################################
# title         : Clean_All_Files.R;
# purpose       : function to clean eddy covariance data for automation of
#               : pivot irrigation for the IRRI ecological intensification plots;
# producer      : prepared by A. H. Sparks;
# last update   : in Los Baños, Phliippines, August 2014;
# inputs        : .dat files from eddy covariance towers;
# outputs       : cleaned eddy covariance data as a .csv file;
# comments      : provided as-is, no guarantees;
# licence       : GPL2;
##############################################################################

# Step 1: Load all the libraries necessary for this function to work
library(pracma)
library(compiler)
library(plyr)
library(zoo)

# Step 2: Start the real work
if(file.exists("Output") == FALSE) dir.create("Output") # check to see if output directory exists, if not create

cleaner <- function(directory){
  
  filenames <- list.files(directory, pattern = ".dat$", full.names = TRUE)
  datalist <- lapply(filenames, function(x) {read.table(file = x, 
                                                        skip = 4, # skip importing the first four lines of headers and whatnot
                                                        sep = ",", # the original data is parsed with commas
                                                        na.strings = "NAN")}) # replace NAN with NA in R for missing values)
  dataFile <- Reduce(function(x, y) {rbind(x, y)}, datalist) 
    
  dataFile[, 1] <- as.POSIXct(strptime(dataFile[, 1], format = "%Y-%m-%d %H:%M:%S")) # format column 1 to be date/time in R
  data.i <- dataFile[, c(1, 5, 62)] # create dataframe of only the columns necessary for filling and filtering
  
  w <- sapply(data.i, function(x) any(is.na(x))) # check for any missing values in the data

  if (any(w)) { # if there are missing values, we fill them using na.approx, a linear interpolation from the zoo package
    data.zoo <- zoo(data.i) # convert the data frame to a zoo object for gap filling
    if (any(is.na(data.zoo[, 2]))) { # are there gaps in the LE data? If yes we fill them
      data.zoo[, 2] <- na.approx(data.zoo[, 2]) # fill any gaps in LE
    } 
    if (any(is.na(data.zoo[, 3]))) { # are there gaps in the T data? If yes we fill them
      data.zoo[, 3] <- na.approx(data.zoo[, 3]) # fill any gaps in T
    }
    
    FilteredLE <- hampel(as.numeric(coredata(data.zoo[, 2])), 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to the gap-filled data to remove outliers
    FilteredT  <- hampel(as.numeric(coredata(data.zoo[, 3])), 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to the gap-filled data to remove outliers
  } else { # there are no missing values, no imputation necessary so we move on and only run the filter
    
    FilteredLE <- hampel(data.i[, 2], 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to remove outliers
    FilteredT  <- hampel(data.i[, 3], 4, t0 = 3) # apply hampel filter, 4 value window, default threshold to remove outliers
  }
       
  output <- data.frame(data.i[, 1], 
                       FilteredLE$y, 
                       data.i[, 2], 
                       FilteredT$y, 
                       data.i[, 3]) # create dataframe and format date, w/ cleaned/uncleaned data
  names(output) <- c("Date", "FilteredLE", "UnfilteredLE", "FilteredT", "UnfilteredT") # name columns properly
  
  output <- mutate(output, et = FilteredLE/(2500-2.4*FilteredT)*3.6) #Calculate et values for each .5hr unit
  
  write.csv(output, paste(substr(directory, 1, 48), "Output/Cleaned_Data.csv", sep = ""), row.names = FALSE) # write the data into a .csv file for saving on server and e-mailing (to be added later) 
}

theCleaner <- cmpfun(cleaner) # byte compile the function for just a touch more speed

#eos
