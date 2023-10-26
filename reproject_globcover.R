# Reprojecting in GRASS GIS

require(terra)
require(rgrass)

startp <- print(Sys.time())

setwd('E://')

grassDir='C:/Program Files/GRASS GIS 8.2'

im="globcover_reg_mercator.tif"

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

setwd('F://')

im_to_reproject="strata/00N_130E.tif"

rgrass::execGRASS("r.import",
                  input = im_to_reproject,
                  output = "r_reprojected",
                  flags = c("overwrite"))

# Crop the extent of the environment to that of you image.
#rgrass::execGRASS("g.region",
 #                 raster="rast")

startp <- Sys.time()

## import from grass to r

rgrass::execGRASS("r.out.gdal",
                  input = 'r_reprojected',
                  output = "r_mercator_Int32.tif",
                  format="GTiff",
                  type="Int32",
                  flags=c("overwrite","f"),
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES") 

print("Exported")

end <- print(Sys.time())

print(end-startp)

r_reprojected <- rgrass::read_RAST("r_reprojected", flags = "quiet", return_format = "terra")

end <- print(Sys.time())

print(end-startp)

#print("Reprojected")

#writeRaster(r_reprojected, 'r_reprojected.tif', gdal=c("COMPRESS=DEFLATE", "TFW=YES"), overwrite=TRUE)

print("Exported")

end <- print(Sys.time())

print(end-startp)

# delete grassdb
unlink("grassdb", recursive = TRUE)
