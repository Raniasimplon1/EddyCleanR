IRRI EddyCo Gap Fill and Outlier Removal
========================================

This repository is a collection of R scripts used to clean eddy covariance tower data from IRRI Ecological Intensification (EI) platform. There are two versions of the script. The first version will clean all eddy covariance files found in a directory, filling gaps using the Zoo package and removing outliers using a Hampel filter from the pracma package to filter the time series and remove outliers.

The second version of the script checks a specified directory for the most recent data file from the eddy covariance tower and the most recent previous file. It then takes the two files and runs the same operations (gap filling and a Hampel filter) and then generates an estimate of evapotranspiration for the previous 24 hour time-period. IRRI uses this to then schedule pivot irrigation in the ecological intensification platform.

The IRRI Ecological Intensification platform is a field laboratory where probable futuristic rice production systems are developed and researched. The EI platform makes use of mechanization in rice production in conjunction with efficient irrigation, which this script is used for, and for the study of intensification and diversification of cropping systems and scheduling. The EI aims to produce three crops per year, two rice crops in rotation with a third non-rice crop (maize or mung bean) while being environmentally and ecologically sustainable.
