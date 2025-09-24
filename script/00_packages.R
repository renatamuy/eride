# package list
pkg_list_cran <- c("memuse",
                  "segmented",
                   "bbmle",
                   "devtools", 
                   "here",
                   "tidyverse",
                   "xlsx", 
                   "data.table",
                   "janitor",
                   "stringi",
                   "reshape2",
                   "DataExplorer",
                   "skimr",
                   "rnaturalearth",
                   "rnaturalearthdata",
                   "spData",
                   "sf",
                   "raster",
                   "rasterVis",
                   "terra",
                   "ggmap",
                   "ggspatial",
                   "ggbump",
                   "gghighlight",
                   "ggraph",
                   "ggridges",
                   "igraph",
                   "maps",
                   "mapdata",
                   "legendMap",
                   "htmlwidgets",
                   "htmltools",
                   "lattice",
                   "ggpubr",
                   "graphlayouts",
                   "RColorBrewer",
                   "viridis",
                   "wesanderson",
                   "hrbrthemes",
                   "tidyterra",
                   "sfnetworks", 
                  "exactextractr")

# require else install all packages
lapply(X = pkg_list_cran, 
       FUN = function(x) if(!require(x, character.only = TRUE)) install.packages(x, dep = TRUE, quiet = TRUE))

# packages from github
if(!require(scico)) devtools::install_github("thomasp85/scico")
if(!require(platexpress)) devtools::install_github("raim/platexpress")
if(!require(Manu)) devtools::install_github("G-Thomson/Manu")
if(!require(ggsflabel)) devtools::install_github("yutannihilation/ggsflabel")

# end ---------------------------------------------------------------------