# calculations related to Big Skate catch inputs for 2019 assessment

catch.dir <- 'C:/SS/skates/catch'

landings <- read.csv(file.path(catch.dir, "Big skate catches for Ian landings.csv"))
discards <- read.csv(file.path(catch.dir, "Big skate catches for Ian LN discards.csv"))
totals <- read.csv(file.path(catch.dir, "Big skate catches for Ian totals.csv"))

# recalculate discard fraction for longnose
discards$discard.rate <- discards$Dicscard / discards$LSKT.total.catch.estimated.based.on.Dover
lines(discards$Year, 2000*discards$discard.rate, col=2, lwd=4)
abline(h=2000)


# plot longnose info
plot(discards$Year, discards$LSKT, type='h', lwd=10, lend=3, ylim=c(0,3000), yaxs='i')
points(discards$Year, discards$TOTAL.Land, type='h', lwd=10, lend=3, col=4)
lines(discards$Year, 2000*discards$discard.rate, col=2, lwd=4)
abline(h=2000, lty=3, col=2)

# aggregate big skate catches
landings.BS <- aggregate(landings$Landings..mt.,
                         by = list(landings$Year),
                         FUN = sum)
names(landings.BS) <- c("Year", "Landings_mt")

landings.BS$discard.rate.LN <- NA
for(y in discards$Year){
  landings.BS$discard.rate.LN[landings.BS$Year == y] <-
    discards$discard.rate[discards$Year == y]
}

landings.BS$discard.rate.LN[landings.BS$discard.rate.LN < 0] <- 0.001
abline(v=1995)

# linear model fit to pre-1995 landings has non-significant
# slope of -0.1 ton per year over 45 years
# (prediction 62.9 in 1950 to 58.1 in 1995 vs. mean across years of 62.4
yrs.sub <- landings.BS$Year %in% 1950:1995

lm.landings <- lm(Landings_mt ~ Year,
                  data=landings.BS[yrs.sub,])
summary(lm.landings)
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)
## (Intercept) 269.9685   343.9152   0.785    0.435
## Year         -0.1062     0.1759  -0.604    0.548
lm.landings$coeff[1] + 1950*lm.landings$coeff[2]
## 62.90116 
lm.landings$coeff[1] + 1995*lm.landings$coeff[2]
## 58.12268 

mean.landings <- mean(landings.BS$Landings_mt[yrs.sub],
                      na.rm = TRUE)
mean.landings
## [1] 63.21791

# mean discard rate
mean.discard.rate.LN <-
  mean(landings.BS$discard.rate.LN[yrs.sub],
       na.rm=TRUE)
## [1] 0.924647

# linear regression (non-significant increase of 0.0003 per year)
lm.discard.rate <- lm(discard.rate.LN ~ Year,
                      data = landings.BS[yrs.sub,])


# create new total catch estimates
# (note, mixing mean and annual values produced terrible results)
landings.BS$total_mean_catch_mean_rate_mt <- NA
landings.BS$total_annual_catch_annual_rate_mt <- NA

# create new average discard estimates
landings.BS$discard_mean_catch_mean_rate_mt <- NA

landings.BS$total_mean_catch_mean_rate_mt[yrs.sub] <-
  mean.landings / (1 - mean.discard.rate.LN)
landings.BS$total_annual_catch_annual_rate_mt[yrs.sub] <-
  landings.BS$Landings_mt[yrs.sub] /
    (1 - landings.BS$discard.rate.LN[yrs.sub])

# mean discard amount
landings.BS$discard_mean_catch_mean_rate_mt[yrs.sub] <-
  mean.landings / (1 - mean.discard.rate.LN) - mean.landings
summary(landings.BS$discard_mean_catch_mean_rate_mt)
  ##  Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
  ## 775.7   775.7   775.7   775.7   775.7   775.7      57

# linear ramp to 1950
landings.BS$discard_mean_catch_mean_rate_mt[landings.BS$Year < 1950] <- 
  (landings.BS$Year[landings.BS$Year < 1950] - 1916) / (1950 - 1916) *
    landings.BS$discard_mean_catch_mean_rate_mt[landings.BS$Year == 1950]

# 3-year moving averages
landings.BS$Landings_3yr_avg <- NA
landings.BS$discard.rate.LN_3yr_avg <- NA
landings.BS$total_3yr_catch_3yr_rate_mt <- NA
for(y in 1950:1995){
  row <- which(landings.BS$Year == y)
  yrs <- y + -1:1
  landings.BS$Landings_3yr_avg[row] <-
    mean(landings.BS$Landings_mt[landings.BS$Year %in% yrs], na.rm=TRUE)
  landings.BS$discard.rate.LN_3yr_avg[row] <-
    mean(landings.BS$discard.rate.LN[landings.BS$Year %in% yrs], na.rm=TRUE)
}
landings.BS$total_3yr_catch_3yr_rate_mt <- 
  landings.BS$Landings_3yr_avg /
    (1 - landings.BS$discard.rate.LN_3yr_avg)


# plot landings and rates
plot(landings.BS[,c("Year","Landings_mt")],
                 type='h', lwd=6, lend=3, ylim=c(0,3000), yaxs='i', col=4)
abline(lm.landings, col=3)
abline(h = mean(landings.BS$Landings_mt[yrs.sub]), col=2)

lines(discards$Year, 1000*discards$discard.rate, col=2, lwd=2)
abline(h = 1000, lty=3, col=2)
abline(a = 1000*lm.discard.rate$coeff[1],
       b = 1000*lm.discard.rate$coeff[2], col=3)
abline(h = 1000*mean.discard.rate.LN,
       col=2)

lines(landings.BS$Year, landings.BS$total_mean_catch_mean_rate_mt,
      lwd=2, col=1)
lines(landings.BS$Year, landings.BS$total_annual_catch_annual_rate_mt,
      lwd=2, col=4)
lines(landings.BS$Year, landings.BS$total_3yr_catch_3yr_rate_mt,
      lwd=2, col=5)
lines(landings.BS$Year, landings.BS$discard_mean_catch_mean_rate_mt,
      lwd=2, col=6)
lines(landings.BS$Year, landings.BS$Landings_mt + landings.BS$discard_mean_catch_mean_rate_mt,
      lwd=2, col=6)

#yr, seas, fleet, catch, catch_se
landings.table <- data.frame(yr = landings.BS$Year,
                             seas = 1,
                             fleet = ifelse(landings.BS$Year < 1995, 2, 1),
                             catch = round(landings.BS$Landings_mt, 1),
                             catch_se = 0.01,
                             note = ifelse(landings.BS$Year < 1995,
                                 "#_historical_landings",
                                 "#_current_landings"))
disc_mort <- 0.5
discards.table <- data.frame(yr = landings.BS$Year,
                             seas = 1,
                             fleet = 3,
                             catch = round(disc_mort *
                                             landings.BS$discard_mean_catch_mean_rate_mt, 1),
                             catch_se = 0.01,
                             note = "#_estimated_discards")
discards.table <- discards.table[discards.table$yr < 1995,]
write.csv(rbind(landings.table, discards.table),
          file = file.path(catch.dir, 'catch_for_SS_4-23-2019.csv'), row.names=FALSE)
