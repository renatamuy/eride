# Landscape characterization
# GRASS 8.4.1 (2025)
# Packages ---------------------------------------------------------------------------------------------------

require(terra)
require(rgrass)
require(sf)

#-------------------------------------------------------------

# Find a spacious dir
setwd('E:/')

# Find grass on Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

# Find grass on Windows
grassDir='C:/Program Files/GRASS GIS 8.4'

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

rgrass::execGRASS("g.version")

# Check info for the region initialised
execGRASS("g.region", flags = "p", intern = TRUE)

# Define the desired extent in geographic coordinates (degrees)

java_extent <- c(104.8, 116, -9.0, -5.0)

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


rgrass::execGRASS("g.region",
                  flags = c("p"),  
                  n = as.character(north_3857),
                  s = as.character(south_3857),
                  e = as.character(east_3857),
                  w = as.character(west_3857),
                  res = '30')  

# Creating rast 
rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

# Check info for the region initialised
execGRASS("g.region", flags = "p", intern = TRUE)

# Now to forest patch characterization

# Create binary forest map
execGRASS("r.mapcalc",
          expression = "r = rast == 5 || rast == 6 || rast == 12 || rast == 13",
          flags = c("overwrite"))

# Create null background
execGRASS("r.mapcalc", flags = "overwrite",
          expression = "r_fragment_null = if(r == 1, 1, null())")

# Create zero background
execGRASS("r.mapcalc", flags = "overwrite",
          expression = "r_fragment_zero = if(r == 1, 1, 0)")

# Identify individual patches
execGRASS("r.clump", flags = c("d", "quiet", "overwrite"),
          input = "r_fragment_null", output = "r_fragment_id")

rgrass::execGRASS("g.list", type = "raster")

# Exporting area data table
# area flags 
# c: patch ID (category)
#a: area (in the same units as the raster's resolution, typically square meters if the raster has a resolution of 1m x 1m). When you use this flag, r.stats will calculate and output the real area for each zone based on the raster's resolution.
#n: count of pixels (cells) in each zone. When you use this flag, r.stats will give you the number of pixels (or cells) for each zone (fragment ID), rather than the actual area.

rgrass::execGRASS(cmd = "r.stats",
                  flags = c("a", "c", "n", "overwrite"),
                  separator = ",",
                  input = "r_fragment_id",
                  output = "java_fid_area_30m_grass8p4.csv")

rgrass::execGRASS("g.list", type = "raster")

# Read table of forest fragment and area

area_stats <- read.csv("java_fid_area_30m_grass8p4.csv", header= FALSE)

head(area_stats)
nrow(area_stats)
max(area_stats$V1)
summary(area_stats$V1)
summary(area_stats$V2)
summary(area_stats$V3)

colnames(area_stats) <- c('PID','Area', 'Ncell' )

plot(area_stats$Area, area_stats$Ncell)

summary(area_stats$Area)

area_stats$Area_ha <- area_stats$Area / 10000

summary(area_stats$Area_ha)

# convert ha to square km
0.1 / 100
5.3 / 100
347815.3 / 100

#--------------------------------------------------------------------------------------