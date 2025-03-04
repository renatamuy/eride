# NOT RUN
# Toy pop generation 

# ------------------------------------------------------------------------------------------------------------
# R 4.4.1 Race for Your Life        
# eRIDE - March 2025
# Toy data: East of Nagreg (around -6.38 latitude and 106.56 longitude)
# Packages ---------------------------------------------------------------------------------------------------

require(terra)
require(rgrass)
require(here)
setwd(here())
setwd('script')
source('src/eride_run.R')

setwd(here())
setwd('toy_data_z0p28')

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

# Creating rast 
rgrass::execGRASS("r.in.gdal",
                  input = im,
                  output = "rast",
                  flags = c("overwrite"))

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
                  res = wres) # degrading working resolution to 100 m

# Download pop raster here and load locally: https://hub.worldpop.org/geodata/summary?id=6376
pop <- 'G:/indonesia/idn_ppp_2020.tif' 

rgrass::execGRASS("r.import",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

# List rasters
rgrass::execGRASS("g.list", type = "raster")

# Export pop to make the repo light

execGRASS("r.out.gdal", input = "pop", output = 'pop.tif', type = "Float32",
          flags = c("overwrite", "f"), createopt = "TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")

# The larger the radius, the slower the processing time
# default function radius is 10, we keep it as 10 as it approximates to 20 x 20 window size from Wilkinson et al (2018)
# default nproc=7, default memory = 1000
# Run eride and PAR with specified parameters (all default but z, in this case)
eride_run("rast", "pop", z = 0.28)

# Get results for toy region

results <- rast(imr)
results$fragments=rast("fragments.tif")
results$fragment_area <- rast("areas.tif")  
results$biodiversity <- rast("biodiversity.tif")
results$edges <- rast("edges.tif")
results$weighted_boundaries <- rast("wb.tif")
results$eRIDE<- rast("eRIDE.tif")
results$PAR <- rast('PAR.tif')

par(mfrow=c(2,2))
plot(results$biodiversity, main='biodiversity')
plot(results$edges, main='edges')
plot(results$eRIDE, main=paste('eRIDE with radius =', radius, 'px'))
plot(results$PAR, main= paste('Population at Risk per', wres,'m2') )

png(filename='results_toy.png', res=300, units = 'cm', width= 18, height = 10)
plot(results)
dev.off()

#--------------------------------------------------------------------------------------------