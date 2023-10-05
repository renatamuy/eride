

library(terra)

setwd('G://strata')

workdir <- 'G://strata'

files_list <- paste(dir(workdir))[1:3]

raster_list <- lapply(files_list, rast)

mosaic(raster_list[[1]], raster_list[[2]], raster_list[[3]], fun="mean", filename="test.tif")
