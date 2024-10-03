# eRIDE ad PAR run
# October 2024
#---------------------------------------------------------------------------------------

require(terra)
require(rgrass)

#setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')

setwd('E:/')

# Find grass on Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

# Find grass on Windows
grassDir='C:/Program Files/GRASS GIS 8.2'


# Set the desired environment --------------------------------------------------------------------------------
# Land use raster

im="E://globcover_reg_mercator.tif"

imr <- rast(im)

plot(imr)

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "asia",  
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

# Set region resolution

wres <- '100' # 3 arc (~100 m)

rgrass::execGRASS("g.region",
                  raster="rast", 
                  res = wres) 

execGRASS("g.region", flags = "p", intern = TRUE)

# Check rast back from GRASS to R

raster_back <- read_RAST("rast", return_format = "terra") 
 
raster_back # note that rast now has resolution = wres

plot(raster_back)
hist(raster_back)

# Import and reproject Pop for pop at risk (PAR) calculation

pop <- 'G:/indonesia/idn_ppp_2020.tif' # 100 m

rgrass::execGRASS("r.import",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

# Set region extent

rgrass::execGRASS("g.region",
                  raster="pop") 

# List rasters

rgrass::execGRASS("g.list", type = "raster")

# Call function

source("C:/Users/rdelaram/Documents/GitHub/eride/script/src/eride_run.R")

eride_run("rast", "pop")

#-------------------------------------------------------------------------------------------------------------