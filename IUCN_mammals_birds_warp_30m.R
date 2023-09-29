# Warping IUCN AOH (Lumbierres et al data) to 30 m Mercator

# Load required libraries
require(terra)
require(lsmetrics)
require(rgrass)

set.seed(123)

grassDir='C:/Program Files/GRASS GIS 8.2'

im="F://results_eride1_serang//eride1_serang.tif" # Change to base raster

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im), # optional SpatialGrid object
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

mammals <- 'F:/LUMBIERRES/Richness_mammals/Mammals_Richness_AOH_all.tiff'
birds <- 'F:/LUMBIERRES/Richness_birds/Birds_Richness_AOH_all/'

rgrass::execGRASS("r.import",
                  input = mammals,
                  output = "mammals",
                  flags = c("overwrite"))

rgrass::execGRASS("r.import",
                  input = birds,
                  output = "birds",
                  flags = c("overwrite"))


rgrass::execGRASS("g.list", 
                type='raster')

rgrass::execGRASS("r.mapcalc" 
                  expression = 'IUCN_bio = mammals + birds')

# Exporting

setwd('G://')

rgrass::execGRASS("r.out.gdal",
                  input="mammals",
                  output="mammals_mercator_30m.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")


rgrass::execGRASS("r.out.gdal",
                  input="birds",
                  output="birds_mercator_30m.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

rgrass::execGRASS("r.out.gdal",
                  input="birds",
                  output="birds_mercator_30m.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")




#rgrass::execGRASS(cmd = "r.mapcalc",
 #                 flags = "overwrite",
 #                 expression = "constrained_bio = if(estimated_richness > observed_richness, observed_richness, estimated_richness)")

#---------------------