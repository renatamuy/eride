# Preparing population density raster
# Plotting Population at risk
# Setting up zone of influence reach of 100 km
# devtools::install_github("NINAnor/oneimpact", ref = "HEAD")

require(raster)
require(oneimpact)
require(terra)
library (rasterVis)
require(RColorBrewer)
require(here())

#  PAR -----------------------------------------------------------------------------------------------

javapar <- terra::rast('E:/eride_scales_z0p20/PAR_100.tif')

myPal <- rev(RColorBrewer::brewer.pal('Spectral', n=10))

myTheme <- rasterTheme(region = myPal)

rasterVis::levelplot(javapar, par.settings = myTheme, main='Population at risk')

# Nearest - Gaussian decay influence, ZoI = 100 km
# Cumulative impacts from pop_at_risk_pandemics
# Node weights are == pop density

# Link (flow) value is ~ 1 / (popdensity pixel x* pop density pixel y)

zoi <- c(1000*100)

zoi_values <- c(1000*100)

risk_100km <- calc_zoi_cumulative(javapar, type = "Gauss", radius = zoi_values)

levelplot(risk_100km, par.settings = myTheme, main='Received risk (100 km)')


# export outputs SLOW!
#"azure2"

#ggsave(filename= 'Fig_04B.png', dpi=400, width=18, height = 10, units = 'cm')

#-------------------------------------------------------------------------------------