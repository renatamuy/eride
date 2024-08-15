# Load required libraries
require(terra)
require(lsmetrics)
require(rgrass)

#https://grass.osgeo.org/grass83/manuals/rasterintro.html

set.seed(123)

# Set up high storage dir

setwd('G://')

grassDir='C:/Program Files/GRASS GIS 8.2'

im="G://eride_region_not_latcor//biodiversity.tif" 

im2='G://birds_mammals_mercator_100m.tif'

# Set location at 100 m

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im), 
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

# Set region as small

#rgrass::execGRASS("g.region",
 #                 n="13115000", 
  #                e="-915000", 
   #               s="13110000", 
    #              w="-920000")

# Import 


# Import with on the fly warping

rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

rgrass::execGRASS("r.import",
                  input = im2,
                  output = "birds_mammals",
                  flags = c("overwrite"))


# Check rasters

rgrass::execGRASS("g.list", 
                  type='raster', mapset='PERMANENT')

# Run calculation for the region

rgrass::execGRASS("r.mapcalc",
                  expression=paste0("constrained_bio = rast * birds_mammals"),
                  flags=c("overwrite"))

# Check

rgrass::execGRASS("g.list", 
                  type='raster')

# Export

rgrass::execGRASS("r.out.gdal",
                  input="constrained_bio",
                  output="constrained_bio.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")


#-----------------------------------------------------------