##############################################################################
# title         : Clean_All_Files.R;
# purpose       : function to clean eddy covariance data for automation of
#               : pivot irrigation for the IRRI ecological intensification plots;
# producer      : prepared by A. H. Sparks;
# last update   : in Los Baños, Phiilppines, August 2014;
# inputs        : .dat files from eddy covariance towers;
# outputs       : cleaned eddy covariance data as a .csv file;
# comments      : Script provided as-is with no guarantees or support;
# license       : GPL2;
##############################################################################

# Step 1: Source the external file that contains the cleaning function in it.
source("src/TheECCleaner.R")

# Step 2: (optional so commented out) Read the help file that explains the methods being used to clean the data.
#?zoo # fills missing data values
#?hampel # filters outliers

# Step 3: Set the directory that holds the data files to be used.
# Put your files to be cleaned in the directory that you fill in below
# Please note, any .dat files that are found in this directory will automatically be cleaned
directory <- "../Data"

# Step 4: Run the function, output will be found in the "Output" sub-directory of the directory you set above
theCleaner(directory)

#eos
