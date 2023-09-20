#  exponential decay 

latitudinal_model <- function(latitude, peak, k) {
  return(peak * exp(-k * abs(latitude)))
}

latitude <- 30  # Remember we have projected data!

# Max limit for mammals in 1 sqkm = 191
# Max limit for birds in 1sqkm = 532


peak <- 532 + 191 


k <- 0.02      

biodiversity <- latitudinal_model(latitude, peak, k)

biodiversity

latitudes <- seq(-90, 90, by = 1)  

biodiversity <- sapply(latitudes, function(lat) latitudinal_model(lat, peak, k))

plot(latitudes, biodiversity, type = "l", 
     xlab = "Latitude", ylab = "Biodiversity",
     main = "Latitudinal Biodiversity Pattern (exp)")

#---

# gaussian decay

latitudinal_model_gaussian <- function(latitude, plateau, width, center) {
  return(plateau * exp(-(latitude - center)^2 / (2 * width^2)))
}

# Specify a range of latitudes
latitudes <- seq(-90, 90, by = 1)  


plateau <- 100
width <- 20  
center <- 0  

biodiversity <- sapply(latitudes, function(lat) latitudinal_model_gaussian(lat, plateau, width, center))

plot(latitudes, biodiversity, type = "l", 
     xlab = "Latitude", ylab = "Biodiversity",
     main = "Latitudinal Biodiversity Pattern (Gaussian Decay)")

#----------------------------------------------------

# Informations about our projected data:

# EPSG:3857

origin=c(0,0)

Bounding_box = c(
  minlong = -180,
  minlat= -85.06,
  maxlong=180,   
  maxlat=85.06 )

Projected bounds=  c( 
    minlong= -20037508.34,
    minlat= -20048966.1,
    maxlong=20037508.34, 
    maxlat=20048966.1)
