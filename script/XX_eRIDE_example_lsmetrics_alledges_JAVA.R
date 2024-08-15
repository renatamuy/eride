##############################################################################################################
# eRIDE - Overall species-area estimated risk for novel infectious disease emergence
# Algorithm updated from Wilkinson et al. (2018) to R 4.1.3 
# Run in lsmetrics :)
##############################################################################################################

memory.size()
Sys.getenv("R_ARCH")
rm(list = ls())
gc() 
options(digits=7, scipen=999)
memory.limit(size= 1.75e13)

# Packages ---------------------------------------------------------------------------------------------------
library(pak)
#pak::pkg_install("mauriciovancine/lsmetrics")
require(terra)
require(lsmetrics)

# Set timer
start <- print(Sys.time())

# Load prepared input data -----------------------------------------------------------------------------------
# 2019 hansen data 

# Base data - real landscape
rr <- rast('F://java_mercator.tif') 

# Defining habitat patches from land cover for the region of interest ------------------------------------------------
habitat_codes <- seq(51,115)

r <- rr %in% habitat_codes

plot(r) 

# Creating grass db in a chosen location
path_grass <- "C:/Program Files/GRASS GIS 8.2" #as.character(link2GI::findGRASS()[1]) 

rgrass::initGRASS(gisBase = path_grass,
                  SG = r,
                  gisDbase = "grassdb",
                  location = "newLocation", # 
                  mapset = "PERMANENT",
                  override = TRUE)

# Exporting from r to grass
rgrass::write_RAST(x = r, flags = c("o", "overwrite", "quiet"), vname = "r", verbose = FALSE)

# check grass environment
rgrass::execGRASS("g.list", parameters=list(type="rast", mapset="PERMANENT"), intern=TRUE)

# area
lsmetrics::lsm_fragment_area(input = "r", id = TRUE, table = TRUE)

# importing pids from grass to r
r_fragment_id <- rgrass::read_RAST("r_fragment_id", flags = "quiet", return_format = "terra")

# plot
plot(r_fragment_id, legend = FALSE, axes = FALSE, main = "Fragment id")
#plot(as.polygons(r, dissolve = FALSE), lwd = .1, add = TRUE)
#plot(as.polygons(r), add = TRUE)
#text(r_fragment_id)

# import areas from grass to r
r_fragment_area <- rgrass::read_RAST("r_fragment_area_ha", flags = "quiet", return_format = "terra")

plot(r_fragment_area, legend = FALSE, axes = FALSE, main = "Fragment area (ha)")

# tables
da_fragment <- readr::read_csv("r_fragment.csv", show_col_types = FALSE)
da_fragment

da_fragment_summary <- readr::read_csv("r_fragment_summary.csv", show_col_types = FALSE)
da_fragment_summary 

# delete grassdb
#unlink("grassdb", recursive = TRUE)
#unlink("r_fragment.csv")
#unlink("r_fragment_summary.csv")

# Perimeter --------------------------------------------------------------------------------------------------
print(Sys.time())
lsmetrics::lsm_perimeter(input = "r", perimeter_area_ratio = FALSE)
print(Sys.time())
r_perimeter <- terra::rast(rgrass::read_RAST("r_perimeter", flags = "quiet", return_format = "SGDF"))
print(Sys.time())

plot(r_perimeter, legend = FALSE, axes = FALSE, main = "Fragment perimeter")

#-------------------------------------------------------------------------------------------------------------
# Data output

results <- r

# From hectares back to square meters

results$area_sqm <- 10000*r_fragment_area

results$perimeter <- r_perimeter

# Biodiversity model -----------------------------------------------------------------------------------------
# patch biodiversity (convert area to diversity using the power law B = cA^z)
# Here c is 1, and z is ANYTHING BELOW 0.5, we use 0.2

c = 1
z = 0.2

results$biodiversity <- c*results$area_sqm^z

plot(results$biodiversity )

# boundaries
print(Sys.time())
lsmetrics::lsm_morphology(input = "r")
print(Sys.time())

# import all edges from grass to r

rgrass::execGRASS("g.list", parameters=list(type="rast", mapset="PERMANENT"), intern=TRUE)
print(Sys.time())
r_mophology <- rgrass::read_RAST("r_morphology", flags = "quiet", return_format = "terra")

print(Sys.time())
r_edge <- rgrass::read_RAST("r_edge", flags = "quiet", return_format = "terra")
r_branch <- rgrass::read_RAST("r_branch", flags = "quiet", return_format = "terra")
r_corridor <- rgrass::read_RAST("r_corridor", flags = "quiet", return_format = "terra")
r_stepping_stone <- rgrass::read_RAST("r_stepping_stone", flags = "quiet", return_format = "terra")
r_perforation <- rgrass::read_RAST("r_perforation", flags = "quiet", return_format = "terra")

all_edges <- r_edge + r_branch + r_corridor + r_stepping_stone + r_perforation

plot(all_edges)
#check 
all_edges_bin <- subst(all_edges, 2, 1)

# lsm_core_edge
#lsmetrics::lsm_core_edge(input = "r",
#                         edge_depth = 40,
#                         core_number = TRUE,
#                         core_edge_original = TRUE,
#                         calculate_area = FALSE,
#                         calculate_percentage = FALSE,
#                         buffer_radius = 100,
#                         buffer_circular = FALSE)
#checking_edge <- rgrass::read_RAST("r_edge40", flags = "quiet", return_format = "terra")
#plot(checking_edge)

print(Sys.time())

#-------------------------------------------------------------------------------------------------------------
# patch boundaries
results$boundaries = all_edges_bin

results$boundaries[is.na(results$boundaries)] <- 0

# weight boundary values based on biodiversity
results$weighted_boundaries <- results$boundaries * results$biodiversity

results$weighted_boundaries[is.na(results$weighted_boundaries)] <- 0

middle <- print(Sys.time())

middle - start

# eRide is the sum of the weighted boundaries within a given radius.
# This radius is a bit arbitrary, but you have to think of it in terms of 
#"distances over which contacts are meaningful"
# we will use a 51 pixel box (has to be an odd number), but you can use circles and other shapes of different sizes
## note there is a package called "fasterRaster" which could speed this up. I haven't tried it yet.
# px times res ~27 m
# This function is SLOW The larger the box, the slower it is. The 51 pixel box will be slow. Set radius to 25 
# if you want something faster.
## We can make our own version of focalWeight by creating a gaussian weighted matrix, and using focal

radius = 25

mat=raster::raster(nrows=radius,ncols=radius,xmn=0,xmx=1,ymn=0,ymx=1,crs="")
mat$layer[1:(radius^2)]=0
for(x in 1:nrow(mat)){
  for(y in 1:ncol(mat)){
    mat[x,y]=(((x-((radius+1)/2))^2)+((y-((radius+1)/2))^2))^0.5
  }
}
mat[1:(radius^2)]=max(mat[1:(radius^2)])-mat[1:(radius^2)]
mat[1:(radius^2)]=mat[1:(radius^2)]/sum(mat[1:(radius^2)])

#plot(mat)

# Calculate eRIDE---------------------------------------------------------------------------------------------
results$eride = terra::focal(results$weighted_boundaries, w=as.matrix(mat), fun=sum)

plot(results$eride, main='eRIDE1')

# Exporting outputs ------------------------------------------------------------------------------------------
dir.create('results_java_eride_lsmetrics_alledges')

setwd('results_java_eride_lsmetrics_alledges')

terra::writeRaster(results, filename = 'eride1_lsmetrics.tif',  gdal=c("COMPRESS=DEFLATE", "TFW=YES"), overwrite=TRUE)

radiusres <- round(radius*res(r), digits=2)

sink("method.txt") 

cat('This result was obtained by calculating eRIDE with the 
                 following parameters. A forest pixel was considered any pixel 
                 with a forest cover types from globcover 2019 (Hansen et al. 2022) (codes ',habitat_codes,
    '). Then, we converted forest area for each patch into species number 
(biodiversity) by using species-area formula as a Biodiversity = cA^Z, 
where c = ', c,'and z = ')
cat(z)
cat(
  '. After that we extract data from patch boundaries and weight them 
by patch biodiversity values. 
Then, we calculate eRIDE, which is a sum of 
the weighted boundaries within a radius of ')
cat(radius)
cat('pixels, wich means ')
cat(radiusres)
cat(' meters, considering a circular custom gaussian weighted matrix,
used to create an eRIDE surface for our entire region of interest.')

sink()

# Export figure
png('results_eride1.png', res = 300, width = 24, height = 20, units = 'cm')
plot(results)
dev.off()

end <- print(Sys.time())

print(end-start)
#-------------------------------------------------------------------------------------------------------------