# mosaic rasters

library(terra)

setwd('G://strata')

workdir <- 'G://strata'

files_list <- paste(dir(workdir))[1:3]

raster_list <- lapply(files_list, rast)

class(raster_list)

#raster_list[[1]], raster_list[[2]], raster_list[[3]] ....... até raster n

myindex <- lapply(raster_list, identity)

mosaic_result <- do.call(mosaic, c(myindex, fun = "mean"))

plot(mosaic_result)

writeRaster(mosaic_result, 'test.tif', gdal=c("COMPRESS=DEFLATE", "TFW=YES"), overwrite=TRUE)

#--------------------------------------------------------------





