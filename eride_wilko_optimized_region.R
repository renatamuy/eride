# eRIDE optimized
# Packages ---------------------------------------------------------------------------------------------------
# library(pak)
# pak::pkg_install("mauriciovancine/lsmetrics")
require(terra)
require(lsmetrics)
require(rgrass)

setwd('E://')

#"C:/Program Files/GRASS GIS 8.2"
# Initialise the grass environment.
#import your image -creates a grass environment layer called "rast"
# Base data - real landscape

require(terra)
require(lsmetrics)
require(rgrass)

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
rgrass::execGRASS("r.mapcalc",
                  expression="r = rast > 50 && rast < 116",
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
                  type="Float64",
                  flags="overwrite")
rgrass::execGRASS(cmd = "g.message",
                  message = "Biodiversity map...")
rgrass::execGRASS("r.out.gdal",
                  input="bio",
                  output="biodiversity.tif",
                  format="GTiff",
                  type="Float64",
                  flags="overwrite")
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
                  type="Float64",
                  flags="overwrite")
rgrass::execGRASS(cmd = "g.message",
                  message = "eRIDE...")
rgrass::execGRASS("r.out.gdal",
                  input="eRIDE",
                  output="eRIDE.tif",
                  format="GTiff",
                  type="Float64",
                  flags="overwrite") #createopt="TFW=YES,COMPRESS=DEFLATE"

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


# createopt="TFW=YES,COMPRESS=DEFLATE"
#--------------------------------------------