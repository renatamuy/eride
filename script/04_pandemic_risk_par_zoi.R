# Preparing population density raster
# Plotting Population at risk
# Read population data
#devtools::install_github("NINAnor/oneimpact", ref = "HEAD")

require(raster)
require(oneimpact)
require(terra)

pop <- terra::rast('D://OneDrive - Massey University//_env//human_population//worldpop//idn_pd_2020_1km_unconstrained_mercator_cubicspline.tif')

plot(pop)

#  ------------------------------------

# Crop using Serang ax example (or user defined area)

e <- extent(11772921, 11868677, -743856.3, -655423.3)

toy <- crop(pop, e)

plot(toy)

summary(values(toy))

poprast <- terra::rast(toy)

# calculate cumulative zone of influence for multiple influence radii,
# using a Gaussian filter
#finding a way to detect an radius threshold in Wilkinson et al..

#11772921, 11868677, -743856.3, -655423.3 

#10571502, 10664321, 585603.9, 678422.9

# Serang eride -----------------------------------------------------------------------------------------------

serang_eride <- terra::rast('F://results_eride1_serang//eride1_serang.tif')

serang_eride

poprast <- terra::rast(pop)

# Matching eRIDE with pop

#The estimated population at risk (PAR) for each pixel was defined as the product
#of the pixel eRIDE index and the population density at that location. 

res(pop) / res(serang_eride)

# Degrading eRIDE ?

# Forcing pop to 30 M

popd30m <- resample(pop, serang_eride)

plot(popd30m)

plot(1/popd30m)

# Pandemic risk 30 m

pop_at_risk_pandemics <- popd30m * serang_eride$eride

plot(pop_at_risk_pandemics, main= 'Population at risk')

library (rasterVis)
require(RColorBrewer)

myPal <- rev(RColorBrewer::brewer.pal('Spectral', n=10))

myTheme <- rasterTheme(region = myPal)

rasterVis::levelplot(pop_at_risk_pandemics, par.settings = myTheme, main='Population at risk')

# Nearest - Gaussian decay influence, ZoI = 1000m
# Cumulative impacts from pop_at_risk_pandemics
# 1 km fast

# What is the scale of the effect?

# Toy data pandemic potential

# Node weights are == pop density

# Link (flow) value is ~ 1 / (popdensity pixel x* pop density pixel y)

zoi <- c(1000, 2000, 3000, 4000)

res(pop_at_risk_pandemics)

zoi_values <- c(1000)

risk_1km <- calc_zoi_cumulative(pop_at_risk_pandemics, type = "Gauss", radius = zoi_values)

levelplot(risk_1km, par.settings = myTheme, main='Received risk (1 km)')

risk_5km <- calc_zoi_cumulative(pop_at_risk_pandemics, type = "Gauss", radius = 5000)

levelplot(risk_5km, par.settings = myTheme, main='Received risk (5 km)')

# calculate cumulative zone of influence for multiple influence radii,
# using a circle neighborhood

cumzoi_circle <- calc_zoi_cumulative(pop_at_risk_pandemics, type = "circle", radius = zoi_values)
plot(cumzoi_circle)

# calculate cumulative zone of influence for multiple influence radii,
# using an exponential decay neighborhood
cumzoi_exp <- calc_zoi_cumulative(pop_at_risk_pandemics, type = "exp_decay", radius = zoi_values)
plot(cumzoi_exp)

# comparing
plot(c(pop_at_risk_pandemics, cumzoi_gauss[[1]], cumzoi_circle[[1]], cumzoi_exp[[1]]),
     main = c('Population at risk of pandemics (30 m)', "Gaussian 4 km",
              "Circle 4km",
              "Exponential decay 4 km"))

# plot maps
# export outputs