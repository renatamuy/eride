# Compressing rasters
# Rê 2023 
# R 4.3.1

# Packages 

require(terra)
require(rgrass)

setwd('F://') 

# Open

grassDir='C:/Program Files/GRASS GIS 8.2'

im="serang_mercator.tif"

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

rgrass::execGRASS("g.region",
                  raster="rast")

# Export not compressed float 64

rgrass::execGRASS("r.out.gdal",
                  input="rast",
                  output="serang_compressed_f64nc.tif",
                  format="GTiff",
                  type="Float64",
                  flags="overwrite")

# Export compressed float 64

rgrass::execGRASS("r.out.gdal",
                  input="rast",
                  output="serang_compressed_f64.tif",
                  format="GTiff",
                  type="Float64",
                  flags="overwrite",
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

# Export compressed byte

rgrass::execGRASS("r.out.gdal",
                  input="rast",
                  output="serang_compressed_byte.tif",
                  format="GTiff",
                  type="Float32",
                  flags="overwrite",
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

# Export further compressed float 32

rgrass::execGRASS("r.out.gdal",
                  input="rast",
                  output="serang_compressed_f32.tif",
                  format="GTiff",
                  type="Float32",
                  flags="overwrite",
                  createopt="TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

# Export not compressed float 32

rgrass::execGRASS("r.out.gdal",
                  input="rast",
                  output="serang_compressed_f32nc.tif",
                  format="GTiff",
                  type="Float32",
                  flags="overwrite")

#-----------------------------


