
rgrass::execGRASS("g.list", 
                  type='raster')

rgrass::execGRASS("g.region",
                  n="13115000", 
                  e="-915000", 
                  s="13110000", 
                  w="-920000") 

unlink("grassdb", recursive = TRUE)