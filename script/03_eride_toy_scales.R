#--------------------------------------------------
# R 4.4.1 Race for Your Life        
# eRIDE scales - Sep 2024

# Packages ---------------------------------------------------------------------------------------------------

# Base raster 

raster_info <- rast('E://globcover_reg_mercator.tif')
print(crs(raster_info))
plot(raster_info)

require(terra)
require(rgrass)

start_time <- Sys.time()

# Grass directory
grassDir = 'C:/Program Files/GRASS GIS 8.2'

# Initialise the GRASS environment

setwd('E://')

# WGS 84 / Pseudo-Mercator or Web Mercator (EPSG:3857)

im ='globcover_reg_mercator.tif'

rgrass::initGRASS(gisBase = grassDir,
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

start_time <- Sys.time()


# if im is in db, then remove this step
rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

end_time <- Sys.time()
end_time - start_time

rgrass::execGRASS("g.region", flags = "p")

# Check projection EPSG:3857 in grass
#+no_defs when you want full control over the parameters being used in the projection and want to avoid relying on any implicit defaults.

rgrass::execGRASS("g.proj", flags = "c", proj4 = "+proj=merc +datum=WGS84 +no_defs")

# Check datum

rgrass::execGRASS("g.region", flags = "p")

rgrass::execGRASS("g.list", type = "raster")

# Parameters
nprocs=7
memory=1000
z=0.2
# The larger the radius, the slower the processing time
# Approximating it to 20 x 20 window size from Wilkinson et al (2018)
radius = 10
window_size = 2 * radius + 1

# Set region of interest

start_time <- Sys.time()

library(sf)

# Define the extent in geographic coordinates (degrees)

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

resolution_values <- c(30, 60, 100, 500, 1000, 5000)

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
  
  rgrass::execGRASS("r.mapcalc",
                    expression="r = rast == 5 || rast == 6 || rast == 12 || rast == 13",
                    flags=c("overwrite"))
  

  rgrass::execGRASS(cmd = "g.message",
                    message = "Creating NULL background")
  rgrass::execGRASS(cmd = "r.mapcalc",
                    flags = "overwrite",
                    expression = "r_frament_null = if(r == 1, 1, null())")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Creating ZERO background")
  rgrass::execGRASS(cmd = "r.mapcalc", flags = "overwrite",
                    expression = "r_frament_zero = if(r == 1, 1, 0)")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Identifying individual patches")
  rgrass::execGRASS(cmd = "r.clump",
                    flags = c("d", "quiet", "overwrite"),
                    input = "r_frament_null",
                    output = "r_fragment_id")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Counting cells of patches")
  rgrass::execGRASS(cmd = "r.stats.zonal",
                    flags = c("overwrite"),
                    base = "r_fragment_id",
                    cover = "r_frament_null",
                    method = "count",
                    output = "r_fragment_area_ncell")
  rgrass::execGRASS(cmd = "g.message",
                    message = paste0("Converting to biodiversity based on species area parameter of ",z))
  rgrass::execGRASS("r.mapcalc",
                    expression=paste0("bio = r_fragment_area_ncell^",z),
                    flags=c("overwrite"))
  rgrass::execGRASS(cmd = "g.message",
                    message = "Calculating Latitude map...")
  
  rgrass::execGRASS(cmd = "r.mapcalc",
                    flags = "overwrite",
                    expression = "latitude = y()* r_frament_zero")
  rgrass::execGRASS(cmd = "r.stats.zonal",
                    flags = c("overwrite"),
                    base = "r_fragment_id",
                    cover = "latitude",
                    method = "average",
                    output = "latitude_scale_values")
  
  ### NEED TO SCALE BIODIVERSITY LAYER BY LATITUDE DATA HERE ###
  
  rgrass::execGRASS(cmd = "g.message",
                    message = paste0("Finding patch edges using ",nprocs," processors"))
  rgrass::execGRASS(cmd = "r.neighbors",
                    flags = c("c", "overwrite"),
                    input = "r_frament_zero",
                    output = "r_range",
                    size = 3,
                    method = "range",
                    nprocs = nprocs,
                    memory = memory)
  rgrass::execGRASS(cmd = "g.message",
                    message = "Creating edges layer")
  rgrass::execGRASS("r.mapcalc",
                    expression=paste0("r_edges = r_range * r_frament_zero"),
                    flags=c("overwrite"))
  rgrass::execGRASS(cmd = "g.message",
                    message = "Creating weighted boundaries")
  rgrass::execGRASS("r.mapcalc",
                    expression=paste0("wb = bio * r_edges"),
                    flags=c("overwrite"))
  rgrass::execGRASS(cmd = "g.message",
                    message = paste0("Calculating eRIDE with a gaussian weighted radius of ",radius," pixels using ",nprocs," processors"))
  rgrass::execGRASS(cmd = "r.neighbors",
                    flags = c("overwrite"),
                    input = "wb",
                    output = "eRIDE",
                    size = window_size,
                    weighting_function="gaussian",
                    weighting_factor=2,
                    method = "average",
                    nprocs = nprocs,
                    memory = memory)
  # Population at risk (PAR)
  rgrass::execGRASS(cmd = "g.message",
                    message = "Creating PAR raster")
  rgrass::execGRASS("r.mapcalc",
                    expression=paste0("PAR = eRIDE * pop"),
                    flags=c("overwrite"))
  
  rgrass::execGRASS(cmd = "g.message",
                    message = "Writing images to disk")
  ## All binary (mask) images are written in "Byte" format
  ## All numerical data is forced into "float32" format with TFW (separate world file) and DEFLATE (compression).
  ## This causes a slight loss of precision, as GRASS stores the data in DCELL format, which is only lossless when using "float64"
  ## The loss of precision is minute, but allows a 10x decrease in file size.
  ## As a guide to disk usage - each output numerical data file will be approximately 3/4 the size of the original "tif" file (for Renata's mercator data).
  
  rgrass::execGRASS(cmd = "g.message",
                    message = "Fragment map...")
  rgrass::execGRASS("r.out.gdal",
                    input="r_frament_zero",
                    output=paste0("fragments_", wres, ".tif"),
                    format="GTiff",
                    type="Byte",
                    flags="overwrite")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Fragment areas map...")
  rgrass::execGRASS("r.out.gdal",
                    input="r_fragment_area_ncell",
                    output=paste0("areas_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  # Latitude map creation
  rgrass::execGRASS(cmd = "g.message",
                    message = "Latitude maps...")
  rgrass::execGRASS("r.out.gdal",
                    input="latitude",
                    output=paste0("latitude_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  rgrass::execGRASS("r.out.gdal",
                    input="latitude_scale_values",
                    output=paste0("latitude_scale_values_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Biodiversity map...")
  # Optional: correct for latitude accordingly
  rgrass::execGRASS("r.out.gdal",
                    input="bio",
                    output=paste0("biodiversity_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Edges map...")
  rgrass::execGRASS("r.out.gdal",
                    input="r_edges",
                    output=paste0("edges_", wres, ".tif"),
                    format="GTiff",
                    type="Byte",
                    flags="overwrite")
  rgrass::execGRASS(cmd = "g.message",
                    message = "Weighted edges map...")
  rgrass::execGRASS("r.out.gdal",
                    input="wb",
                    output=paste0("wb_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  rgrass::execGRASS(cmd = "g.message",
                    message = "eRIDE...")
  rgrass::execGRASS("r.out.gdal",
                    input="eRIDE",
                    output=paste0("eride_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  #PAR
  rgrass::execGRASS("r.out.gdal",
                    input="PAR",
                    output=paste0("PAR_", wres, ".tif"),
                    format="GTiff",
                    type="Float32",
                    flags=c("overwrite","f"),
                    createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  
  message("Finished processing for resolution: ", wres)
}

print('finished')

end_time <- Sys.time()
end_time - start_time

# List rasters
rgrass::execGRASS("g.list", type = "raster")

#-------------------------------------------------------------------------------------------------------------