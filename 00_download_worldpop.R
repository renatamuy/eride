# Download worldpop 2020 100 m


install.packages("devtools")
devtools::install_github("wpgp/wpgpDownloadR")

# load package
library(wpgpDownloadR)


path <- paste0('G:/',"/worldpop_100m")

dir.create(path)

listc <- wpgpListCountries()

cvec <- listc$ISO3[1:length(listc$ISO3)]

#wpgpListCountryDatasets(ISO3="CHN")

#cvec <- 'MWI'

for(c in cvec){
  
  print(c)
  
  r <- wpgpGetCountryDataset(ISO3 = c,
                             covariate = "ppp_2020",
                             destDir = path)
  
  rm(r)
}

#Stopped at "MWI" 133  Malawi

listc$ISO3

tocheck <- list.files( paste0('G:/',"/worldpop_100m"))

vectocheck <- toupper(substr(tocheck, start=1,stop=3))


length(unique(vectocheck))

length(listc$ISO3 )

# Does the second term contain everything in the first term?

setdiff(vectocheck,listc$ISO3 )

# Does the second term contain everything in the first term?

setdiff(listc$ISO3, vectocheck )

length(unique(listc$ISO3))

# MLW was not there, so try to get it, but also no success:
#URL caused a warning: ftp://ftp.worldpop.org.uk/GIS/Population/Global_2000_2020/2020/MWI/mwi_ppp_2020.tif
#Here's the original warning message:
#downloaded length 0 != reported length 0Warning message:
#In readLines(con, n = 1) :
#incomplete final line found on 'C:\Users\rdelaram\AppData\Local\Temp\RtmpCqH6r1/wpgpDatasets.md5'



