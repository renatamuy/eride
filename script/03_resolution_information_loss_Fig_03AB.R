# Automated extraction of values
# Renata Muylaert

require(here)

setwd(here())
setwd('results')
data <- read.table('resolution_effect_eride.txt', head=TRUE)

data


#-----
# Simulate NATURAL log normal
# Real example

mean_log <- 1  # mean of the underlying normal distribution, NOT raw data log(15)
sd_log <- 0.5  # standard deviation of the underlying normal distribution
n <- 100      # Number of samples

# Simulate log-normal-distributed values
lognormal_samples <- rlnorm(n, meanlog = mean_log, sdlog = sd_log)

# Note it will be continuous (as the raw data should be) and positively skewed
hist(lognormal_samples)

x_values <- seq(0, 15, by = 0.01)

plot(x_values, dlnorm(x_values, meanlog = mean_log, sdlog = sd_log), 
     type = 'l', col = 'blue', lwd = 2,
     main = "Log-Normal Distribution PDF",
     xlab = "Values", ylab = "Density")
grid()


# Model selection

library(MASS)
library(bbmle)
library(dplyr)
if(!requireNamespace("mgcv", quietly = TRUE)) install.packages("mgcv")
library(mgcv)
library(segmented)

head(data)

# set up df

data <- data.frame(scale=data$Resolution, cost=data$cost, information=data$SD_loss)

# abs diff (info loss)
data$information <- abs(data$information)

# Log normal using a constant slope (0.3  case) 
#lognorm_model_0p3 <- mle2(minuslogl = function(mu, sigma) {
#  -sum(dlnorm(data$information, meanlog = mu + 0.3 * data$cost, sdlog = sigma, log = TRUE))
#},
#start = list(mu = 0.5, sigma = 0.5))


# 0.5 slope
#lognorm_model_0p5 <- mle2(minuslogl = function(mu, sigma) {
#  -sum(dlnorm(data$information, meanlog = mu + 0.5 * data$cost, sdlog = sigma, log = TRUE))
#},
#start = list(mu = 0.5, sigma = 0.5))


#  estimated slope through log normal
#lognorm_model_slope <- mle2(   minuslogl = function(mu, sigma, beta) {
#    # Calculate the log-likelihood for the log-normal distribution
#    -sum(dlnorm(data$information, meanlog = mu + beta * data$cost, sdlog = sigma, log = TRUE))
#  },
#  start = list(mu = 0.5, sigma = 0.5, beta = 0.3)  # Initial value for beta
#)


# GLM model
glm_model <- glm(information ~ cost, data = data, family = gaussian)

#piecewise_model

piecewise_model <- segmented(glm_model, seg.Z = ~ cost, psi = list(cost = mean(data$cost)))

summary(piecewise_model)$coefficients

summary(piecewise_model)

target_value <- summary(piecewise_model)$psi[2]

target_value

closest_row <- which.min(abs(data$cost - target_value))

data[closest_row, 'scale' ]

# Exponential model
#exp_model <- glm(information ~ cost, data = data, family = Gamma(link = "log"))

# gam

gam_model3 <- gam(information ~ s(cost, k = 3), data = data, family = gaussian(link = "identity"))

# gam 
gam_model4 <- gam(information ~ s(cost, k = 4), data = data, family = gaussian(link = "identity"))

# No-effect (null) model
null_model <- glm(information ~ 1, data = data, family = gaussian)

#-------------
# Model selection # exp_model,lognorm_model_slope, lognorm_model_0p5, lognorm_model_0p3,

ICtab(gam_model3, gam_model4, piecewise_model,  glm_model, null_model, weights = TRUE, type="AICc", base=TRUE, nobs = nrow(data))

summary(piecewise_model)

# Model plots 

cost_seq <- seq(min(data$cost), max(data$cost), length.out = 100)

# Generate predictions for each model
predicted_data <- data.frame( cost = cost_seq,
  glm_pred = predict(glm_model, newdata = data.frame(cost = cost_seq), type = "response") #,
  #exp_pred = predict(exp_model, newdata = data.frame(cost = cost_seq), type = "response"),
  #lognorm_pred = exp(coef(lognorm_model_slope)["mu"] + 
  #                     coef(lognorm_model_slope)["beta"] * cost_seq),
  #lognorm_0p5_pred = exp(coef(lognorm_model_0p5)["mu"] + 
  #                               coef(lognorm_model_0p5)["beta"] * cost_seq)
)

# Calculate confidence intervals for GLM
glm_se <- predict(glm_model, newdata = data.frame(cost = cost_seq), type = "response", se.fit = TRUE)
predicted_data$glm_lwr <- glm_se$fit - 1.96 * glm_se$se.fit
predicted_data$glm_upr <- glm_se$fit + 1.96 * glm_se$se.fit

#piecewise

piecewise_predictions <- predict(piecewise_model, newdata = predicted_data, interval = "confidence")

# Add predictions and confidence intervals to predicted_data
predicted_data$piecewise_pred <- piecewise_predictions[, "fit"]
predicted_data$piecewise_lwr <- piecewise_predictions[, "lwr"]
predicted_data$piecewise_upr <- piecewise_predictions[, "upr"]

# Calculate confidence intervals for Exponential Model
#exp_se <- predict(exp_model, newdata = data.frame(cost = cost_seq), type = "response", se.fit = TRUE)
#predicted_data$exp_lwr <- exp_se$fit - 1.96 * exp_se$se.fit
#predicted_data$exp_upr <- exp_se$fit + 1.96 * exp_se$se.fit

# Log-normal model confidence intervals
#lognorm_mu <- coef(lognorm_model_slope)["mu"]
#lognorm_beta <- coef(lognorm_model_slope)["beta"]
#lognorm_sigma <- coef(lognorm_model_slope)["sigma"]

# Calculate log-normal prediction intervals
#predicted_data$lognorm_lwr <- exp(lognorm_mu + lognorm_beta * cost_seq - 1.96 * lognorm_sigma)
#predicted_data$lognorm_upr <- exp(lognorm_mu + lognorm_beta * cost_seq + 1.96 * lognorm_sigma)

# Log-normal model confidence intervals
#lognorm0p5_mu <- coef(lognorm_model_0p5)["mu"]
#lognorm0p5_beta <- coef(lognorm_model_0p5)["beta"]
#lognorm0p5_sigma <- coef(lognorm_model_0p5)["sigma"]

# Calculate log-normal prediction intervals
#predicted_data$lognorm0p5_lwr <- exp(lognorm0p5_mu + lognorm0p5_beta * cost_seq - 1.96 * lognorm0p5_sigma)
#predicted_data$lognorm0p5_upr <- exp(lognorm0p5_mu + lognorm0p5_beta * cost_seq + 1.96 * lognorm0p5_sigma)

# gam
gam_predictions <- predict(gam_model3, newdata = predicted_data, se.fit = TRUE)

# Calculate upper and lower bounds for confidence intervals
predicted_data$gam_pred3 <- gam_predictions$fit
predicted_data$gam_lwr3 <- gam_predictions$fit - 1.96 * gam_predictions$se.fit
predicted_data$gam_upr3 <- gam_predictions$fit + 1.96 * gam_predictions$se.fit

# gam 4
gam_predictions <- predict(gam_model4, newdata = predicted_data, se.fit = TRUE)

# Calculate upper and lower bounds for confidence intervals
predicted_data$gam_pred4 <- gam_predictions$fit
predicted_data$gam_lwr4 <- gam_predictions$fit - 1.96 * gam_predictions$se.fit
predicted_data$gam_upr4 <- gam_predictions$fit + 1.96 * gam_predictions$se.fit


# Plot 

library(ggplot2)

# Create the plot with larger font sizes
plot <- ggplot(data, aes(x = cost, y = information)) +
  geom_point(color = "black", size = 4, alpha = 0.6) +  # Observed data
  # GLM model
  geom_line(data = predicted_data, aes(x = cost, y = glm_pred), color = "firebrick", linetype = "dotdash", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = glm_lwr, ymax = glm_upr), fill = "red", alpha = 0.2) +
  # Exponential model
  #geom_line(data = predicted_data, aes(x = cost, y = exp_pred), color = "darkgreen", linetype = "dashed", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = exp_lwr, ymax = exp_upr), fill = "green", alpha = 0.2) +
  # Log-normal model 0p5
  #geom_line(data = predicted_data, aes(x = cost, y = lognorm_0p5_pred), color = "purple", linetype = "dotted", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = lognorm_lwr, ymax = lognorm_upr), fill = "purple", alpha = 0.2) +
  # GAM model
  geom_line(data = predicted_data, aes(x = cost, y = gam_pred3), color = "khaki", linetype = "dotdash", size = 1) +
  # GAM model
  geom_line(data = predicted_data, aes(x = cost, y = gam_pred4), color = "orange", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = gam_lwr, ymax = gam_upr), fill = "orange", alpha = 0.2) +
  # Piecewise modelhttp://127.0.0.1:44635/graphics/plot_zoom_png?width=730&height=1054
  geom_line(data = predicted_data, aes(x = cost, y = piecewise_pred), color = "black",  size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = piecewise_lwr, ymax = piecewise_upr), fill = "cyan", alpha = 0.2) +
  # Axis labels and theme
  labs(
    title = "A",
    x = "Cost",
    y = "Information loss (eRIDE) - SD"
  ) +
  #scale_y_log10(limits = c(0.1, 30))+
  geom_label(aes(label = paste0(scale, ' m')  ), color = "black", hjust = -0.2, vjust = 0.5, size = 3.5) + # note rev
  coord_cartesian(ylim = c(-0.5, 3), xlim = c(0, 2.8e+7)) +  # Adjust y-axis limits
  theme_minimal(base_size = 14) +  # Increase base font size
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 14),
    legend.position = "top",
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  ) 

plot

setwd('C://Users//rdelaram//Documents//GitHub//eride//results//')
ggsave("model_selection_eride_SD.jpg", plot = plot, width = 8, height = 8, dpi = 300)  

#---------------------------------------------------------

# Mean loss -  models

data <- read.table('resolution_effect_eride.txt', head=TRUE)

data

# set up df

data <- data.frame(scale=data$Resolution, cost=data$cost, information=data$Mean_loss)

# abs diff (Mean info loss)
data$information <- abs(data$information)

# GLM model
glm_model <- glm(information ~ cost, data = data, family = gaussian)

#piecewise_model

piecewise_model <- segmented(glm_model, seg.Z = ~ cost, psi = list(cost = mean(data$cost)))

summary(piecewise_model)

target_value <- summary(piecewise_model)$psi[2]

target_value

closest_row <- which.min(abs(data$cost - target_value))

data[closest_row, 'scale' ]
data


# Exponential model
#exp_model <- glm(information ~ cost, data = data, family = Gamma(link = "log"))

# gam

gam_model3 <- gam(information ~ s(cost, k = 3), data = data, family = gaussian(link = "identity"))

# gam 
gam_model4 <- gam(information ~ s(cost, k = 4), data = data, family = gaussian(link = "identity"))

# No-effect (null) model
null_model <- glm(information ~ 1, data = data, family = gaussian)

#-------------
# Model selection # exp_model,lognorm_model_slope, lognorm_model_0p5, lognorm_model_0p3,

ICtab(gam_model3, gam_model4, piecewise_model,  glm_model, null_model, weights = TRUE, type="AICc", base=TRUE, nobs = nrow(data))

# Model plots 

cost_seq <- seq(min(data$cost), max(data$cost), length.out = 100)

# Generate predictions for each model
predicted_data <- data.frame( cost = cost_seq,
                              glm_pred = predict(glm_model, newdata = data.frame(cost = cost_seq), type = "response") #,
                              #exp_pred = predict(exp_model, newdata = data.frame(cost = cost_seq), type = "response"),
                              #lognorm_pred = exp(coef(lognorm_model_slope)["mu"] + 
                              #                     coef(lognorm_model_slope)["beta"] * cost_seq),
                              #lognorm_0p5_pred = exp(coef(lognorm_model_0p5)["mu"] + 
                              #                               coef(lognorm_model_0p5)["beta"] * cost_seq)
)

# Calculate confidence intervals for GLM
glm_se <- predict(glm_model, newdata = data.frame(cost = cost_seq), type = "response", se.fit = TRUE)
predicted_data$glm_lwr <- glm_se$fit - 1.96 * glm_se$se.fit
predicted_data$glm_upr <- glm_se$fit + 1.96 * glm_se$se.fit

#piecewise

piecewise_predictions <- predict(piecewise_model, newdata = predicted_data, interval = "confidence")

# Add predictions and confidence intervals to predicted_data
predicted_data$piecewise_pred <- piecewise_predictions[, "fit"]
predicted_data$piecewise_lwr <- piecewise_predictions[, "lwr"]
predicted_data$piecewise_upr <- piecewise_predictions[, "upr"]

# gam
gam_predictions <- predict(gam_model3, newdata = predicted_data, se.fit = TRUE)

# Calculate upper and lower bounds for confidence intervals
predicted_data$gam_pred3 <- gam_predictions$fit
predicted_data$gam_lwr3 <- gam_predictions$fit - 1.96 * gam_predictions$se.fit
predicted_data$gam_upr3 <- gam_predictions$fit + 1.96 * gam_predictions$se.fit

# gam 4
gam_predictions <- predict(gam_model4, newdata = predicted_data, se.fit = TRUE)

# Calculate upper and lower bounds for confidence intervals
predicted_data$gam_pred4 <- gam_predictions$fit
predicted_data$gam_lwr4 <- gam_predictions$fit - 1.96 * gam_predictions$se.fit
predicted_data$gam_upr4 <- gam_predictions$fit + 1.96 * gam_predictions$se.fit

# Plot Mean

plot_mean <- ggplot(data, aes(x = cost, y = information)) +
  geom_point(color = "black", size = 4, alpha = 0.6) +  # Observed data
  # GLM model
  geom_line(data = predicted_data, aes(x = cost, y = glm_pred), color = "firebrick", linetype = "dotdash", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = glm_lwr, ymax = glm_upr), fill = "red", alpha = 0.2) +
  # Exponential model
  #geom_line(data = predicted_data, aes(x = cost, y = exp_pred), color = "darkgreen", linetype = "dashed", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = exp_lwr, ymax = exp_upr), fill = "green", alpha = 0.2) +
  # Log-normal model 0p5
  #geom_line(data = predicted_data, aes(x = cost, y = lognorm_0p5_pred), color = "purple", linetype = "dotted", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = lognorm_lwr, ymax = lognorm_upr), fill = "purple", alpha = 0.2) +
  # GAM model
  geom_line(data = predicted_data, aes(x = cost, y = gam_pred3), color = "khaki", linetype = "dotdash", size = 1) +
  # GAM model
  geom_line(data = predicted_data, aes(x = cost, y = gam_pred4), color = "orange", linetype = "dotdash", size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = gam_lwr, ymax = gam_upr), fill = "orange", alpha = 0.2) +
  # Piecewise modelhttp://127.0.0.1:44635/graphics/plot_zoom_png?width=730&height=1054
  geom_line(data = predicted_data, aes(x = cost, y = piecewise_pred), color = "black",  size = 1) +
  #geom_ribbon(data = predicted_data, aes(x = cost, ymin = piecewise_lwr, ymax = piecewise_upr), fill = "cyan", alpha = 0.2) +
  # Axis labels and theme
  labs(
    title = "B",
    x = "Cost",
    y = "Information loss (eRIDE) - Mean"
  ) +
  #scale_y_log10(limits = c(0.1, 30))+
  geom_label(aes(label = paste0(scale, ' m')  ), color = "black", hjust = -0.2, vjust = 0.5, size = 3.5) + # note rev
  coord_cartesian(ylim = c(-0.5, 3), xlim = c(0, 2.8e+7)) +  # Adjust y-axis limits
  theme_minimal(base_size = 14) +  # Increase base font size
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 14),
    legend.position = "top",
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  ) 

plot_mean

setwd('C://Users//rdelaram//Documents//GitHub//eride//results//')
ggsave("model_selection_eride_mean.jpg", plot = plot_mean, width = 8, height = 8, dpi = 300) 


library(ggpubr)

combined_plot <- ggarrange(plot, plot_mean, ncol = 2, nrow = 1)

ggsave("Fig_03_AB.jpg", combined_plot, width = 11, height = 6, dpi = 300)
#--------------------------------
