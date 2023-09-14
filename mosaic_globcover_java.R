# Mosaic Java

rm(list = ls())
gc() 
options(digits = 7, scipen = 999)
memory.limit(size = 1.75e13)

library(raster)
library(rgdal)
library(sp) 
library(gdalUtils)

workdir = "F://map//"

setwd(workdir)

# Set timer

start <- print(Sys.time())

suppressPackageStartupMessages(library(rgdal)) 

files_list <- c('00N_110E.tif', '00N_120E.tif', '00N_100E.tif')

nome.arq.wgs84 <- paste("java.tif", sep="") #check if projection is assigned

# Mosaic - preserves EPSG:4326 - WGS 84

mosaic_rasters(gdalfile = files_list, dst_dataset = file.path("F:/", nome.arq.wgs84), of = "GTiff")


print("Mosaicou")

end <- print(Sys.time()) # 10 min

print(end-start)

#----------------------------------------------------------------------------------
