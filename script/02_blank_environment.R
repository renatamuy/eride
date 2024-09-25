# Blank environment and region set

require(terra)
require(rgrass)

start_time <- Sys.time()

setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')


# Grass directory
grassDir = 'C:/Program Files/GRASS GIS 8.2'

rgrass::initGRASS(gisBase = grassDir,
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

# Step 2: Set the region for Java Island using degrees for ease

java_extent <- c(west = 105.0, east = 115.5, south = -8.0, north = -6.0)

wres <- 30  # Set your desired resolution

# Use rgrass::execGRASS to set the region
rgrass::execGRASS("g.region",
                  flags = c("p", "quiet"),  # "p" to print the region, "quiet" to suppress output
                  n = as.character(java_extent["north"]),
                  s = as.character(java_extent["south"]),
                  e = as.character(java_extent["east"]),
                  w = as.character(java_extent["west"]),
                  res = as.character(wres))
                  
# Set projection EPSG:3857 in grass
                  
rgrass::execGRASS("g.proj", flags = "c", proj4 = "+proj=merc +datum=WGS84")
             
# Now import any raster

rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

rgrass::execGRASS("g.list", type = "raster")

rgrass::execGRASS("g.region", flags = c("p"))

# Check project processing EPSG

rgrass::execGRASS("g.proj", flags = c("p"))

#----------------


                  