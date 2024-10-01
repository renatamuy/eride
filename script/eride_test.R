require(terra)
require(rgrass)

setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')

# Find grass
#Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

#Windows
grassDir='C:/Program Files/GRASS GIS 8.2'

# Initialise the grass environment
# import your image -creates a grass environment layer called "rast"

im="toy.tif"

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(im),
                  gisDbase = "grassdb",
                  location = "default",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)


# Creating a blank raster to run eride for a smaller region
# IMR is reference image for a fast run

imr <- rast('toy.tif')

# Toy extent ----------------------------------------------------------------------

refext <- ext(imr)
resolution_reference <- res(imr)
crs_reference <- crs(imr)

blank_raster <- rast(extent=refext, 
                     res=resolution_reference, 
                     crs=crs_reference)

values(blank_raster) <- NA

writeRaster(blank_raster, filename = 'blank_raster.tif', overwrite=TRUE)

# Set the extent of the environment to that of you image ----------------

rgrass::execGRASS("r.in.gdal",
                  input = 'blank_raster.tif',
                  output = "blank_raster",
                  flags = c("overwrite"))

# Set working resolution 

wres <- '30' # 3 arc (~100 m)

rgrass::execGRASS("g.region",
                  raster="blank_raster", 
                  res = wres) #degrading working resolution to 100 m


# Creating rast 

rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

# Imported Pop for pop at risk (PAR) calc

wd = 'G:/'

pop <- 'G://human_population/worldpop//idn_pd_2020_1km_unconstrained_mercator.tif' # 1km

#idn <- rast('G://worldpop_100m//idn_ppp_2020.tif')

#plot(idn)

# Creating pop

rgrass::execGRASS("r.in.gdal",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))


# List rasters

rgrass::execGRASS("g.list", type = "raster")



source("C:/Users/rdelaram/Documents/GitHub/eride/script/src/eride_run.R")

# Example call

eride_run("rast", "pop")


