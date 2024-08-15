#' ----
#' Nesi
#' script: mosaic rasters of interest for large portions of Asia
#' author: Renata Muylaert
#' date: 2022-05-18
#' ----

# Clean objects and memory size, vanish with scinot, load packages ---------------------

#rm(list = ls())
#gc() 
options(digits = 7, scipen = 999)
#memory.limit(size = 1.75e13)

require(terra)

workdir = "/scale_wlg_nobackup/filesets/nobackup/massey03262/strata"

setwd(workdir)

# Set timer

start <- print(Sys.time())

files_list <- paste(dir(workdir))[1:3]

raster_list <- lapply(files_list, rast)

class(raster_list)

#raster_list[[1]], raster_list[[2]], raster_list[[3]] ....... até raster n

myindex <- lapply(raster_list, identity)

mosaic_result <- do.call(mosaic, c(myindex, fun = "mean"))

plot(mosaic_result)

writeRaster(mosaic_result, 'teste1.tif', gdal=c("COMPRESS=DEFLATE", "TFW=YES"), overwrite=TRUE)

  print("Mosaicou")

  end <- print(Sys.time())
  
  print(end-start)

#----------------------------------------------------------------------------------
