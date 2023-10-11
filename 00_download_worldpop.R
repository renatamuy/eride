# Download worldpop 2020 100 m


install.packages("devtools")
devtools::install_github("wpgp/wpgpDownloadR")

# load package
library(wpgpDownloadR)


path <- paste0('G:/',"/worldpop_100m")

dir.create(path)

listc <- wpgpListCountries()

cvec <- listc$ISO3

wpgpListCountryDatasets(ISO3="CHN")

for(c in cvec){
  
  print(c)
  
  r <- wpgpGetCountryDataset(ISO3 = c,
                             covariate = "ppp_2020",
                             destDir = path)
  
  rm(r)
}

