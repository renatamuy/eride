# eRIDE optimized
# Packages ---------------------------------------------------------------------------------------------------
# library(pak)
# pak::pkg_install("mauriciovancine/lsmetrics")
require(terra)
require(lsmetrics)
require(rgrass)

setwd('E://')

# Initialise the grass environment.
#import your image -creates a grass environment layer called "rast"
# Base data - real landscape
#"C:/Program Files/GRASS GIS 8.2"
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

grassDir='C:/Program Files/GRASS GIS 8.2'

im="globcover_reg_mercator.tif"

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)


rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

# Crop the extent of the environment to that of you image.
rgrass::execGRASS("g.region",
                  raster="rast")

start_time <- Sys.time()

# Create a binary image of forest areas - here, this is raster values between 51 and 115. Hope that's correct.
# Saves the output as a grass environment layer called "r"

# For map layer
# rgrass::execGRASS("r.mapcalc",
#                  expression="r = rast > 50 && rast < 116",
#                  flags=c("overwrite"))

## Use this one for strata data. (layers 5,6,12 and 13 are considered forest).
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

nprocs=7
memory=1000
z=0.2
radius=25

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
                  size = radius,
                  weighting_function="gaussian",
                  weighting_factor=2,
                  method = "average",
                  nprocs = nprocs,
                  memory = memory)
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
                  output="fragments.tif",
                  format="GTiff",
                  type="Byte",
                  flags="overwrite")
rgrass::execGRASS(cmd = "g.message",
                  message = "Fragment areas map...")
rgrass::execGRASS("r.out.gdal",
                  input="r_fragment_area_ncell",
                  output="areas.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
rgrass::execGRASS(cmd = "g.message",
                  message = "Latitude maps...")
rgrass::execGRASS("r.out.gdal",
                  input="latitude",
                  output="latitude.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
rgrass::execGRASS("r.out.gdal",
                  input="latitude_scale_values",
                  output="latitude_scales.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
rgrass::execGRASS(cmd = "g.message",
                  message = "Biodiversity map...")
rgrass::execGRASS("r.out.gdal",
                  input="bio",
                  output="biodiversity.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
rgrass::execGRASS(cmd = "g.message",
                  message = "Edges map...")
rgrass::execGRASS("r.out.gdal",
                  input="r_edges",
                  output="edges.tif",
                  format="GTiff",
                  type="Byte",
                  flags="overwrite")
rgrass::execGRASS(cmd = "g.message",
                  message = "Weighted edges map...")
rgrass::execGRASS("r.out.gdal",
                  input="wb",
                  output="wb.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
rgrass::execGRASS(cmd = "g.message",
                  message = "eRIDE...")
rgrass::execGRASS("r.out.gdal",
                  input="eRIDE",
                  output="eRIDE.tif",
                  format="GTiff",
                  type="Float32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

#r.compress 
results <- rast(im)
results$fragments=rast("fragments.tif")
results$fragment_area <- rast("areas.tif")  
results$biodiversity <- rast("biodiversity.tif")
results$edges <- rast("edges.tif")
results$weighted_boundaries <- rast("wb.tif")
results$eRIDE<- rast("eRIDE.tif")

res2=terra::crop(results,ext(13110000,13115000,-920000,-915000))
plot(res2)

plot(results$eRIDE)

end_time <- Sys.time()
end_time - start_time

#--------------------------------------------
