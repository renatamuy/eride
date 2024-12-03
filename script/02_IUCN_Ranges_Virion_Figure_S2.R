# Simple plot viruses ~ mammal hosts
# Virus layer - detailed resolution
# Viruses from mammals 
# Mammal hosts layer IUCN 2021

require(raster)
require(here)
require(vroom)
require(sf)
require(tidyverse)
require(fasterize)

setwd("D://OneDrive - Massey University//hostland//virion-main/Virion")

virion <- vroom("Virion.csv.gz")

rbase <- raster('D://OneDrive - Massey University//_env//_env_27km_ss6//bio_1.tif')

r <- raster::raster(ext=extent(c(-180, 180, -90, 90)), crs = crs(rbase), res=res(rbase))

iucn <- st_read(dsn = 'D:/OneDrive - Massey University/_env/mammals/IUCN_2021',
                layer = 'MAMMALS_TERRESTRIAL_ONLY')

virion %>% filter(HostClass == "mammalia") %>%
  dplyr::select(Host, Virus) %>%
  distinct() %>%
  group_by(Host) %>%
  summarize(NVirus = n_distinct(Virus)) -> nvir


iucn %>% mutate(binomial = tolower(binomial)) %>%
  left_join(nvir, by = c('binomial' = 'Host')) %>%
  filter(NVirus > 0) -> iucn

# Number of hosts

map.num.m <- fasterize(iucn, r, field = NULL, fun = 'count')
map.num.m

# Number of viruses

map.sum.m <- fasterize(iucn, r, field = "NVirus", fun = 'sum')

map.sum.m

modelhv <- glm(values(map.sum.m)~ values(map.num.m))

setwd('C:/Users/rdelaram/Documents/GitHub/eride/results/')

jpeg("Figure_S2.jpg", width = 18, height = 18, units='cm', res = 300)
plot(values(map.sum.m)~ values(map.num.m), xlab='Mammal hosts', ylab='Viruses')
abline(modelhv, col='blue', lty=1, lwd=4)
dev.off()

# proportion of hosts with verbatim iucn range matches = 84%
n_distinct(iucn$binomial) / n_distinct(nvir$Host)

hosts <- raster::stack(map.num.m, map.sum.m )


#------------
setwd(here())

dir.create('results')
setwd('results')
dir.create('pull_virus_IUCN_2021')
setwd('pull_virus_IUCN_2021')

names(hosts) <- c("mammal_hosts", 'mammal_viruses')


#setwd('F://')
setwd(here())
setwd('results')
terra::writeRaster(hosts$mammal_hosts, file = paste(names(hosts)[1], "_27km.tif", sep=""), 
                    format="GTiff", 
                    bylayer=TRUE,
                    overwrite=TRUE)


raster::writeRaster(hosts$mammal_viruses, file = paste(names(hosts)[2], "_27km.tif", sep=""), 
                   format="GTiff", 
                  bylayer=TRUE,
              overwrite=TRUE)

#------