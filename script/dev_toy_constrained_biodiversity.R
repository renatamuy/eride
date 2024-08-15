# Load required libraries
require(terra)
require(lsmetrics)
require(rgrass)

set.seed(123)

grassDir='C:/Program Files/GRASS GIS 8.2'

# a base raster

im="F://results_eride1_serang//eride1_serang.tif"

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im), # optional SpatialGrid object
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

# Define the raster dimensions (number of rows and columns)

nrows <- 100
ncols <- 100

rgrass::execGRASS('r.mapcalc',
                  expression='estimated_richness = rand(0, 500)',
                  seed=123,
                  flags = c("overwrite"))


rgrass::execGRASS('r.mapcalc',
                  expression='IUCN_richness = rand(0, 191)',
                  seed=123,
                  flags = c("overwrite"))

rgrass::execGRASS("g.list", 
                  type='raster')

estimated_richness <- rgrass::read_RAST("estimated_richness", flags = "quiet", return_format = "terra")

IUCN_richness <- rgrass::read_RAST("IUCN_richness", flags = "quiet", return_format = "terra")

# Constrain the estimated richness by the maximum observed value
 
rgrass::execGRASS(cmd = "r.mapcalc",
                  flags = "overwrite",
                  expression = "constrained_richness = if(estimated_richness > observed_richness, observed_richness, estimated_richness)")

rgrass::execGRASS("g.list", 
                  type='raster')

constrained_richness <- rgrass::read_RAST("constrained_richness", flags = "quiet", return_format = "terra")

par(mfrow=c(1,3))

plot(estimated_richness)

plot(IUCN_richness)

plot(constrained_richness)

dev.off()

rgrass::execGRASS("r.out.gdal",
                  input="constrained_richness",
                  output="constrained_richness.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"))#,
                  #createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")


#unlink("grassdb", recursive = TRUE)

#-----------