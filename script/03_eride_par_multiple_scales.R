#--------------------------------------------------
# R 4.4.1 Race for Your Life        
# eRIDE scales - October 2024

# Packages ---------------------------------------------------------------------------------------------------

# Base raster 

source("C:/Users/rdelaram/Documents/GitHub/eride/script/src/eride_run.R")
require(terra)
require(rgrass)
library(sf)

#-------------------------------------------------------------

# Find a spacious dir
setwd('E:/')

# Find grass on Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

# Find grass on Windows
grassDir='C:/Program Files/GRASS GIS 8.2'

# Set the desired environment --------------------------------------------------------------------------------
# Land use raster
im="E://java_clip_globcover_mercator.tif"

# init
rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "scales",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

rgrass::execGRASS("g.list", type = "raster")

# Creating rast 
rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

# Check info for the region initialised
execGRASS("g.region", flags = "p", intern = TRUE)

# Import and reproject pop for pop at risk (PAR) calculation
pop <- 'G:/indonesia/idn_ppp_2020.tif' # 100 m

rgrass::execGRASS("r.import",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

# List rasters
rgrass::execGRASS("g.list", type = "raster")

# Define the desired extent in geographic coordinates (degrees)

java_extent <- c(105.0, 115.5, -8.0, -6.0)

# Create the bounding box

bbox <- st_bbox(c(xmin = java_extent[1], 
                  xmax = java_extent[2], 
                  ymin = java_extent[3], 
                  ymax = java_extent[4]))

# Transform wanted region to Pseudo-Mercator (EPSG:3857)

bbox_sf <- st_as_sfc(bbox)

st_crs(bbox_sf) <- 4326

bbox_3857 <- st_transform(bbox_sf, 3857)

# Extract values from bbox_3857
north_3857 <- st_bbox(bbox_3857)["ymax"]
south_3857 <- st_bbox(bbox_3857)["ymin"]
east_3857 <- st_bbox(bbox_3857)["xmax"]
west_3857 <- st_bbox(bbox_3857)["xmin"]

# Resolutions

resolution_values <- c(100, 200, 300, 400, 500, 1000, 2000, 5000)

for (wres in resolution_values) {
  message("Running for resolution: ", wres)

  # Define the geographic extent for Java Island transformed to meters

  # Use rgrass::execGRASS to set the region
  rgrass::execGRASS("g.region",
                    flags = c("p"),  
                    n = as.character(north_3857),
                    s = as.character(south_3857),
                    e = as.character(east_3857),
                    w = as.character(west_3857),
                    res = as.character(wres))  
  
    eride_run_scales("rast", "pop")
  
  message("Finished processing for resolution: ", wres)
 
}

print('Finished!')

# List rasters
rgrass::execGRASS("g.list", type = "raster")

# Start processing
#-------------- eRIDE and PAR calculation
# Create a binary image of forest areas - here, this is raster values between 51 and 115.
# Saves the output as a grass environment layer called "r"
# Choose land cover for map layer
# rgrass::execGRASS("r.mapcalc",
#                  expression="r = rast > 50 && rast < 116",
#                  flags=c("overwrite"))
## Use the present script ONLY for strata folder data. (layers 5,6,12 and 13 are considered forest).
## STRATA LAYER DATA:
# 1	True desert	⩾90% bare ground
# 2	Semi-arid land	⩾25% to <90% bare ground
# 3	Dense short vegetation	0% to <25% bare ground
# 4	Open tree cover	⩾3 and (<10 m or <70% tree cover)
# 5	Dense tree cover	⩾10 m and ⩾70% tree cover
# 6	Recent tree cover gain	Recent ⩾3 m and ⩾10% tree cover
# 7	Non-fire loss no trees, no cropland, no built-up
#  	Wetland strata
# 8	Salt pan	⩾90% bare ground
# 9	Semi-arid	⩾25% to <90% bare ground
# 10	Dense short vegetation	0% to <25% bare ground
# 11	Open tree cover	⩾3 and (<10 m or <70% tree cover)
# 12	Dense tree cover	⩾10 m and ⩾70% tree cover
# 13	Recent tree cover gain	Recent ⩾3 m and ⩾10% tree cover
# 14	Non-fire loss, no trees, no cropland, no built-up
# 	Superseding strata
# 15	Ice	Permanent ice
# 16	Water	Permanent surface water
# 17	Cropland	Cropland land use
# 18	Built-up	Human-built surfaces and structures
# 19	Ocean	Ocean
#-------------------------------------------------------------------------------------------------------------