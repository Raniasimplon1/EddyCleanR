IRRI EddyCo Gap Fill and Outlier Removal
========================================

This repository is a collection of R scripts used to clean eddy covariance tower data from IRRI Ecological Intensification (EI) platform. There are two versions of the script. The first version will clean all eddy covariance files found in a directory, filling gaps using the R (R Core Team, 2014) package, zoo (Seileis and Grothendieck, 2005) and removing outliers using a Hampel filter from the R package pracma (Borchers, 2014) to filter the time series and remove outliers.

The second version of the script checks a specified directory for the most recent data file from the eddy covariance tower and the most recent previous file. It then takes the two files and runs the same operations (gap filling and a Hampel filter) and then generates an estimate of evapotranspiration for the previous 24 hour time-period. IRRI uses this to then schedule pivot irrigation in the ecological intensification platform.

The IRRI Ecological Intensification platform is a field laboratory where probable futuristic rice production systems are developed and researched. The EI platform makes use of mechanization in rice production in conjunction with efficient irrigation, which this script is used for, and for the study of intensification and diversification of cropping systems and scheduling. The EI aims to produce three crops per year, two rice crops in rotation with a third non-rice crop (maize or mung bean) while being environmentally and ecologically sustainable.

# References
Hans Werner Borchers (2014). pracma: Practical Numerical Math Functions. R package version 1.7.0. http://CRAN.R-project.org/package=pracma
Achim Zeileis and Gabor Grothendieck (2005). zoo: S3 Infrastructure for Regular and Irregular Time Series. Journal of Statistical Software, 14(6), 1-27. URL http://www.jstatsoft.org/v14/i06/
R Core Team (2014). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL http://www.R-project.org/.