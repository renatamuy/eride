# Allen raster -  1° WGS84 resolution (c. 100 km at the equator),

setwd('allen')

load('predictions.RData')

#  shows the predicted distribution of new events being observed (weighted model output with current reporting effort)
predictions

psub <- predictions %>% select( lon, lat, bsm_weight_pubs)

allen <- raster::rasterFromXYZ(psub) 

crs(allen) <-  "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0" 

plot(allen)

res(allen)



# shows the estimated risk of event locations after factoring out reporting bias (weighted model output reweighted by population)
psubpeople <-data.frame(cbind(predictions$lon, predictions$lat, predictions$bsm_weight_pop))

allenpeople <- raster::rasterFromXYZ(psubpeople) http://127.0.0.1:18881/graphics/plot_zoom_png?width=2048&height=1090

crs(allenpeople) <-  "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0" 

plot(allenpeople)

hist(values(allenpeople))

summary(allen)
summary(allenpeople)
summary(predictions$bsm_response)


# Raw response
allen_response_sub <-  predictions %>% dplyr::select( lon, lat, bsm_response)

allen_response <- raster::rasterFromXYZ(allen_response_sub) 

crs(allen_response) <-  "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0" 

plot(allen_response)

writeRaster(allen, filename = 'allen_pubs.tif', format="GTiff", overwrite=TRUE)
writeRaster(allenpeople, filename = 'allen_pop.tif', format="GTiff", overwrite=TRUE)
writeRaster(allen_response, filename = 'allen_response.tif', format="GTiff", overwrite=TRUE)


png(filename = 'allen_outputs.png', width = 10, height = 18, units = 'cm', res=400)
par(mfrow=c(3,1))
plot(allen, main='weighted model output with current reporting effort')
plot(allenpeople, main='weighted model output reweighted by population')
plot(allen_response, main='model response' )
dev.off()
############################