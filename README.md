
IRRI Eddy Covariance Gap Fill and Outlier Removal and et Calculation
========================================

[![Travis-CI Build Status](https://travis-ci.org/adamhsparks/EddyCleanR.svg?branch=master)](https://travis-ci.org/adamhsparks/EddyCleanR)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/adamhsparks/EddyCleanR?branch=master&svg=true)](https://ci.appveyor.com/project/adamhsparks/EddyCleanR)

EddyCleanR is used to clean eddy covariance tower data from IRRI Ecological Intensification (EI) platform. 

The IRRI Ecological Intensification platform is a field laboratory where probable futuristic rice production systems are developed and researched. The EI platform makes use of mechanization in rice production in conjunction with efficient irrigation, which this script is used for, and for the study of intensification and diversification of cropping systems and scheduling. The EI aims to produce three crops per year, two rice crops in rotation with a third non-rice crop (maize or mung bean) while being environmentally and ecologically sustainable.

## Quick start

```r
install.packages("devtools")  
library(devtools)  
install_github("adamhsparks/EddyCleanR")  
```

# Meta

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

# References
1. Hans Werner Borchers (2014). pracma: Practical Numerical Math Functions. R package version 1.7.0. http://CRAN.R-project.org/package=pracma
2. Achim Zeileis and Gabor Grothendieck (2005). zoo: S3 Infrastructure for Regular and Irregular Time Series. Journal of Statistical Software, 14(6), 1-27. URL http://www.jstatsoft.org/v14/i06/
3. R Core Team (2014). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL http://www.R-project.org/.
