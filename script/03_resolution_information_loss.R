


information <- rev(c(15, 12, 11,8,
                  7.4,7.2, 
                 7.22, 6.6,
                 6.6, 6.4, 3.3) )


information_loss <-  15 - information

mean(information_loss)

info_tag <- c('far_from_reality', '1 km' , rep('intermediate', 8), 'reality' )


scale <- rev(paste0(c(seq(100,1000, by=100), 5000), ' km'))

cost <- rev(c(24000000, 
              6600000,
              3000000,
              1700000,
              1100000,
              830000,
              619000,
              480000,
              391000,
              320000,
              19527     ))

plot(cost)

length(information)
length(cost)
length(info_tag)

plot( information_loss ~ cost, pch=19, cex=3, xlab='Pixel Cost', ylab='Information loss (eRIDE)')
text(cost, information_loss, labels = scale, pos = 4, col='firebrick', offset = 0.7)


plot( information ~ cost, pch=19, cex=3, xlab='Pixel Cost', ylab='Information (eRIDE)')
text(cost, information, labels = scale, pos = 4, col='firebrick', offset = 0.7)


# Simulate NATURAL log normal
# Real example

mean_log <- 1  # mean of the underlying normal distribution, NOT raw data log(15)
sd_log <- 0.5  # standard deviation of the underlying normal distribution
n <- 100      # Number of samples

# Simulate log-normal-distributed values
lognormal_samples <- rlnorm(n, meanlog = mean_log, sdlog = sd_log)

# Plot the results
hist(lognormal_samples)


     
#--

#-------------------------------------------------------------------------------------------------------------

