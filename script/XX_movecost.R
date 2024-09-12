
# load a sample Digital Terrain Model
data(volc)
plot(volc)

# load a sample start location on the above DTM
data(volc.loc)

# load the sample destination locations on the above DTM
data(destin.loc)

# calculate walking-time isochrones based on the on-path Tobler's hiking function (default),
# setting the time unit to hours and the isochrones interval to 0.05 hour;
# also, since destination locations are provided,
# least-cost paths from the origin to the destination locations will be calculated
# and plotted; 8-directions move is used

result <- movecost(dtm=volc, origin=volc.loc, destin=destin.loc, move=8, breaks=0.05)

# same as above, but using the Irmischer-Clarke's hiking function (male, on-path)

result <- movecost(dtm=volc, origin=volc.loc, destin=destin.loc, funct="icmonp",
                   move=8, breaks=0.05)


# same as above, but using the 'cognitive slope'

result <- movecost(dtm=volc, origin=volc.loc, destin=destin.loc, funct="icmonp",
                   move=8, breaks=0.05, cogn.slp=TRUE)


# calculate accumulated cost surface and the least-cost path between the
# origin and one destination, and also calculate the LCP back to the origin

results <- movecost(dtm=volc, origin=volc.loc, destin=destin.loc[2,], move=8, return.base = TRUE)
