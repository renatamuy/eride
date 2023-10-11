# Disaggregating mammals and birds

gc()

require(terra)

setwd('G://')

r <- rast('E://birds_mammals_mercator_100m.tif')

ref <- rast("E://globcover_reg_mercator.tif")

# GeoTiff files are, by default, written with LZW compression

mb <- terra::resample(r, ref, method="bilinear", filename='birds_mammals_mercator_30m.tif')

#-------------------------------------------------