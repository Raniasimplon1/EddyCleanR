##############################################################################
# title         : Run_This_to_Clean_24_Hour_Files_and_ET.R;
# purpose       : function to clean eddy covariance data for automation of
#               : pivot irrigation for the IRRI ecological intensification plots;
# producer      : prepared by A. Sparks;
# last update   : in Bangkok, Thailand, March 2013;
# inputs        : .dat files from eddy covariance towers;
# outputs       : cleaned eddy covariance data as a .csv file;
# comments      : provided as-is, no guarantees;
# licence       : GPL2;
##############################################################################

# Step 1: Source the external file that contains the cleaning function in it.
source("Clean_24_Hour_Files.R")

# Step 2: (optional so commented out) Read the help file that explains the methods being used to clean the data.
#?na.approx # fills missing data values
#?hampel # filters outliers

# Step 3: Set the directory that holds the data files to be used.
# Please note, any .dat files that are found in this directory will automatically be cleaned, defaults to ../Data
directory <- "../Data"

# Step 4: Run the function, output will be found in the "Output" sub-directory of the directory you set above
theCleaner(directory)

#eos
