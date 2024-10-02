# eRIDE ad PAR run
# September 2024
#---------------------------------------------------------------------------------------

require(terra)
require(rgrass)

#setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')

setwd('E:/')

# Find grass
#Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

#Windows
grassDir='C:/Program Files/GRASS GIS 8.2'


# Set the desired environment --------------------------------------------------------------------------------

# Import Pop for pop at risk (PAR) calculation

wd = 'G:/'

pop <- 'G:/indonesia/idn_ppp_2020.tif' # 100 m

# Creating pop as base for the environment


im="E://globcover_reg_mercator.tif"

#imr <- rast(im)

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

rgrass::execGRASS("g.list", type = "raster")

# Import with reprojection

rgrass::execGRASS("r.import",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

rgrass::execGRASS("g.list", type = "raster")

# Set environment extent and resolution

wres <- '100' # 3 arc (~100 m)

rgrass::execGRASS("g.region",
                  raster="pop", 
                  res = wres) 

#-------------------------------------------------------------------------------------------------------------


# Creating a blank raster from rast to run eride for a smaller region

# Land use raster

im="E://globcover_reg_mercator.tif"

#imr <- rast(im)

#---------------------------------------------------

# Creating rast 

rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))


# Create blank raster for custom region ----------------------------------------------------------------------

#refext <- ext(imr)
#resolution_reference <- res(imr)
#crs_reference <- crs(imr)

#blank_raster <- rast(extent=refext, 
 #                    res=resolution_reference, 
  #                   crs=crs_reference)

#values(blank_raster) <- NA

#writeRaster(blank_raster, filename = 'blank_raster.tif', overwrite=TRUE)

# Import 

#rgrass::execGRASS("r.in.gdal",
 #                 input = 'blank_raster.tif',
 #                 output = "blank_raster",
  #                flags = c("overwrite"))




# List rasters

rgrass::execGRASS("g.list", type = "raster")

# Call function

source("C:/Users/rdelaram/Documents/GitHub/eride/script/src/eride_run.R")

# Example call

eride_run("rast", "pop")

#-------------------------------------------------------------------------------------------------------------