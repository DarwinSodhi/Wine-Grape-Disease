#Plotting Model output for RstanARM on updated pathogen host range
#September 14th 2020
rm(list=ls()) # remove everything currently held in the R memory
options(stringsAsFactors=FALSE)
setwd("~/Documents/GitHub/Wine-Grape-Disease/analysis/output/") 

library(tidyverse)
library(dplyr)
library(boot)
library(rstanarm)
library(rethinking)
library(egg)
library(broom)

#loading in datasets
focaldistance_onespecies <- read.csv("Focaldistanceonespecies.csv")
focaldistance_enitregenus <- read.csv("Focaldistanceentiregenus.csv")
mpd_all_sp_in_genus_ALL <- read.csv("mpd.all.sp.in.genus_ALL.csv")
mpd_all_sp_in_genus_majorpathogens_allhosts <- read.csv("mpd_all_sp_in_genus_majorpathogens_allhosts.csv")
mpd_single_sp_in_genus_ALL <- read.csv("mpd.single.sp.in.genus_ALL.csv")
mpd_single_sp_in_genus_majorpathogens_allhosts <- read.csv("mpd.single.sp.in.genus_majorpathogens_allhosts.csv")
yieldLoss <- read.csv("~/Documents/GitHub/Wine-Grape-Disease/data/yieldLoss.csv")

#Renaming columns 
colnames(focaldistance_enitregenus)[2] <- "pest"
colnames(focaldistance_onespecies)[2] <- "pest"
colnames(mpd_all_sp_in_genus_ALL)[1] <- "pest"
colnames(mpd_all_sp_in_genus_majorpathogens_allhosts)[1] <- "pest"
colnames(mpd_single_sp_in_genus_ALL)[1] <- "pest"
colnames(mpd_single_sp_in_genus_majorpathogens_allhosts)[1]<-"pest"

#adds an underscore between species names
yieldLoss$pest <- sub(" ", "_", yieldLoss$pest)

#new column based on shared pathogen names
Yieldloss2.0 <- merge(focaldistance_enitregenus, yieldLoss, by= "pest")

mpd_all_sp_in_genus_ALL <- bind_rows(mpd_all_sp_in_genus_ALL,mpd_all_sp_in_genus_majorpathogens_allhosts)

Yieldloss2.0 <- merge(mpd_all_sp_in_genus_ALL, Yieldloss2.0, by= "pest")

Yieldloss3.0<- merge(focaldistance_onespecies,yieldLoss, by= "pest")

mpd_single_sp_in_genus_ALL<- bind_rows(mpd_single_sp_in_genus_ALL,mpd_single_sp_in_genus_majorpathogens_allhosts)

Yieldloss3.0<- merge(mpd_single_sp_in_genus_ALL, Yieldloss3.0, by="pest")

#coverts no info value to NA
Yieldloss2.0$yieldLoss <- na_if(Yieldloss2.0$yieldLoss, "No info.")

Yieldloss3.0$yieldLoss<- na_if(Yieldloss3.0$yieldLoss, "No info.")

#renames column to impact
colnames(Yieldloss2.0)[14] <- "impact"

colnames(Yieldloss3.0)[13]<- "impact"

#converts column into numeric
Yieldloss2.0$impact <- as.numeric(Yieldloss2.0$impact)

Yieldloss3.0$impact <- as.numeric(Yieldloss3.0$impact)

#Multiplies impact value by 0.01
Yieldloss2.0$impact <- Yieldloss2.0$impact * 0.01

Yieldloss3.0$impact <- Yieldloss3.0$impact * 0.01


#### Linear_Model
impact_linear_model <- stan_glm(impact~ SES.FPD, data = Yieldloss2.0,
                                family = gaussian(link="identity"),)

summary(impact_linear_model,digits= 4)
launch_shinystan(impact_linear_model)

#creates data set from linear model
posteriorSamples <- as.data.frame(as.matrix(impact_linear_model)) 

# I think you can use this get predictions that might help with plotting ... for example:
range(focaldistance_enitregenus$SES.FPD, na.rm=TRUE)
newdat <- as.data.frame(seq(range(focaldistance_enitregenus$SES.FPD, na.rm=TRUE)[1], range(focaldistance_enitregenus$SES.FPD, na.rm=TRUE)[2], length.out=500))
names(newdat) <- "SES.FPD"


###rethinking code 2.0 (page101-103)

#this gives you ten data points
focaldistance_enitregenus2.0<-focaldistance_enitregenus[1:12,]

#new model with just ten data points
impact_linear_model2.0 <- stan_glm(impact2~ SES.FPD, data = focaldistance_enitregenus2.0,
                                   family = gaussian(link="identity"),)


#extracts entire posterior
posteriorSamples <- as.data.frame(as.matrix(impact_linear_model2.0))
posteriorSamples <- as.data.frame(as.matrix(impact_linear_model))

mu_at_5 <- posteriorSamples$`(Intercept)` + posteriorSamples$SES.FPD * 5
#extracts first 10 samples
posteriorSamples10 <-posteriorSamples[1:10,]


#plots 10 data points with uncertainity 
plot(impact2~SES.FPD, data=focaldistance_enitregenus)

for(i in 1:10)
  abline(a=posteriorSamples10$`(Intercept)`[i], b=posteriorSamples10$SES.FPD[i], col=col.alpha("black",0.3))


######Putting it all together

#gets posterior
posteriorSamples <- as.data.frame(as.matrix(impact_linear_model))

#gets original data
orginal_data<- as.data.frame(focaldistance_enitregenus$SES.FPD)

dose <- (matrix(NA, nrow= nrow(posteriorSamples), ncol = ncol(t(orginal_data))))

#does the link function in rethinking with orginal model! (Each column is full posterior for each original data point)
for (n in 1:49){
  dose[,n]<- as.matrix(posteriorSamples$`(Intercept)` + posteriorSamples$SES.FPD * orginal_data[n,])
  
} 

#codes for new data
newdatlength <- 50
newdat <- as.data.frame(seq(range(focaldistance_enitregenus$SES.FPD, na.rm=TRUE)[1], range(focaldistance_enitregenus$SES.FPD, na.rm=TRUE)[2], length.out=newdatlength))

dose2.0 <- (matrix(NA, nrow= nrow(posteriorSamples), ncol = ncol(t(newdat))))

#codes for link function with new data (Each column is full posterior for each new data point)
for (n in 1:newdatlength){
  dose2.0[,n]<- as.matrix(posteriorSamples$`(Intercept)` + posteriorSamples$SES.FPD * newdat[n,])
  
} 


#figure 4.6
plot(impact~SES.FPD, data=Yieldloss2.0, type= "n")
for ( i in 1:100 )
  points(t(newdat) , dose2.0[i,] , pch=16 , col=col.alpha(rangi2,0.1))

# summarize the distribution of dose2.0
dose2.0.mean <- apply( dose2.0 , 2 , mean )
dose2.0.HPDI <- apply( dose2.0 , 2 , HPDI , prob=0.89 )

#plots linearmodel.pdf
# plot raw data
# fading out points to make line and interval more visible
plot( impact~SES.FPD , data=Yieldloss2.0 , col=col.alpha(rangi2,0.5), ylab= "Yield Loss", ylim= c(0,1) )

# plot the MAP line, aka the mean impacts for each SES.FPD
lines(t(newdat), dose2.0.mean)
# plot a shaded region for 89% HPDI
shade(dose2.0.HPDI,t(newdat) )

#### Invlogit 
#converts impact to inverse logit
Yieldloss2.0$impact2 <- inv.logit(Yieldloss2.0$impact) 



impact_invlogit_model <- stan_glm(impact2~ SES.FPD, data = Yieldloss2.0,
                                  family = gaussian(link="identity"),)

#gets posterior
posteriorSamples2.0 <- as.data.frame(as.matrix(impact_invlogit_model))
posteriorSamples2.0 <- posteriorSamples2.0[1:4000,]

#obtains original data
orginal_data<- as.data.frame(Yieldloss2.0$SES.FPD)

#creates empty matrix
afterhours <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(orginal_data))))

for (n in 1:nrow(orginal_data)){
  afterhours[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$SES.FPD * orginal_data[n,])
  #back transforms each row after inverlogit each impact
  #afterhours[,n]  <- as.matrix(logit(afterhours[,n] ))
} 


#codes for new data

#codes for new data
newdatlength <- 50
newdat <- as.data.frame(seq(-15, 15, length.out=newdatlength))
#as.data.frame(seq(range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[1], range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[2], length.out=newdatlength))

afterhours3.0 <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(newdat))))

for (n in 1:nrow(newdat)){
  afterhours3.0[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$SES.FPD * newdat[n,])
  #back transforms each row after inverlogit each impact
  #afterhours3.0[,n]  <- as.matrix(logit(afterhours3.0[,n] ))
} 


#figure 4.6
plot(impact2~SES.FPD, data=Yieldloss2.0, type= "n")
for ( i in 1:10 )
  points(t(newdat) , afterhours3.0[i,] , pch=16 , col=col.alpha(rangi2,0.1))

# summarize the distribution of dose2.0
afterhours3.0.mean <- apply( afterhours3.0 , 2 , mean )
afterhours3.0.HPDI <- apply( afterhours3.0 , 2 , HPDI , prob=0.89 )

##### Inverselogit with MPD
#### Invlogit 
#converts impact to inverse logit
Yieldloss2.0$impact2 <- inv.logit(Yieldloss2.0$impact) 

Yieldloss2.0<- Yieldloss2.0[complete.cases(Yieldloss2.0), ]

impact_invlogit_model <- stan_glm(impact2~ mpd.obs.z, data = Yieldloss2.0,
                                  family = gaussian(link="identity"),)

#gets posterior
posteriorSamples2.0 <- as.data.frame(as.matrix(impact_invlogit_model))
posteriorSamples2.0 <- posteriorSamples2.0[1:4000,]

#obtains original data
orginal_data<- as.data.frame(Yieldloss2.0$mpd.obs.z)

#creates empty matrix
afterhours <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(orginal_data))))

for (n in 1:nrow(orginal_data)){
  afterhours[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * orginal_data[n,])
  #back transforms each row after inverlogit each impact
  afterhours[,n]  <- as.matrix(logit(afterhours[,n] ))
} 


#codes for new data

#codes for new data
newdatlength <- 50
newdat <- as.data.frame(seq(-13, 15, length.out=newdatlength))
#as.data.frame(seq(range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[1], range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[2], length.out=newdatlength))

afterhours3.0 <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(newdat))))

for (n in 1:nrow(newdat)){
  afterhours3.0[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * newdat[n,])
  #back transforms each row after inverlogit each impact
  #\afterhours3.0[,n]  <- as.matrix(logit(afterhours3.0[,n] ))
} 


#figure 4.6
plot(impact2~mpd.obs.z, data=Yieldloss2.0, type= "n")
for ( i in 1:10 )
  points(t(newdat) , afterhours3.0[i,] , pch=16 , col=col.alpha(rangi2,0.1))

# summarize the distribution of dose2.0
afterhours3.0.mean <- apply( afterhours3.0 , 2 , mean )
afterhours3.0.HPDI <- apply( afterhours3.0 , 2 , HPDI , prob=0.89 )




#below plots Inverselogit_linearmodel.pdf
# plots raw data
# fading out points to make line and interval more visible
plot( impact~mpd.obs.z , data=Yieldloss2.0 , col=col.alpha(rangi2,0.5), ylab= "Yield Loss", ylim= c(0,1))

# plot the MAP line, aka the mean impacts for each SES.FPD
lines(t(newdat), afterhours3.0.mean)
# plot a shaded region for 89% HPDI
shade(afterhours3.0.HPDI,t(newdat) )

### testing a prediction
##### Inverselogit with MPD
#### Invlogit 
#converts impact to inverse logit
Yieldloss2.0$impact2 <- inv.logit(Yieldloss2.0$impact) 

#Yieldloss2.0<- Yieldloss2.0[complete.cases(Yieldloss2.0), ]

impact_invlogit_model2.0 <- stan_glm(impact2~ mpd.obs.z + ntaxa, data = Yieldloss2.0,
                                  family = gaussian(link="identity"),)

#gets posterior
posteriorSamples2.0 <- as.data.frame(as.matrix(impact_invlogit_model2.0))
posteriorSamples2.0 <- posteriorSamples2.0[1:4000,]

#obtains original data
orginal_data<- as.data.frame(Yieldloss2.0$mpd.obs.z)

#creates empty matrix
afterhours <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(orginal_data))))

for (n in 1:nrow(orginal_data)){
  afterhours[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * orginal_data[n,])
  #back transforms each row after inverlogit each impact
  #afterhours[,n]  <- as.matrix(logit(afterhours[,n] ))
} 


#codes for new data

#codes for new data
newdatlength <- 50
newdat <- as.data.frame(seq(-13, 15, length.out=newdatlength))
#as.data.frame(seq(range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[1], range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[2], length.out=newdatlength))

afterhours3.0 <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(newdat))))

for (n in 1:nrow(newdat)){
  afterhours3.0[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * newdat[n,])
  #back transforms each row after inverlogit each impact
  #\afterhours3.0[,n]  <- as.matrix(logit(afterhours3.0[,n] ))
} 


#figure 4.6
plot(impact2~mpd.obs.z, data=Yieldloss2.0, type= "n")
for ( i in 1:10 )
  points(t(newdat) , afterhours3.0[i,] , pch=16 , col=col.alpha(rangi2,0.1))

# summarize the distribution of dose2.0
afterhours3.0.mean <- apply( afterhours3.0 , 2 , mean )
afterhours3.0.HPDI <- apply( afterhours3.0 , 2 , HPDI , prob=0.89 )


#below plots Inverselogit_linearmodel.pdf
# plots raw data
# fading out points to make line and interval more visible
plot( impact2~mpd.obs.z , data=Yieldloss2.0 , col=col.alpha(rangi2,0.5), ylab= "Yield Loss", ylim= c(0,1))

# plot the MAP line, aka the mean impacts for each SES.FPD
lines(t(newdat), afterhours3.0.mean)
# plot a shaded region for 89% HPDI
shade(afterhours3.0.HPDI,t(newdat) )

#### model comparisons 
loo1 <- loo(post1, k_threshold = 0.7)
loo2 <- loo(post2)
loo3 <- loo(post3)
loo4 <- loo(post4, k_threshold = 0.7)
comp <- compare_models(loo1, loo2, loo3, loo4)

loo1<- loo(impact_invlogit_model)
loo2 <- loo(impact_invlogit_model2.0)
comp <- loo_compare(loo1, loo2)

##########
#running model with single species mpd values instead
Yieldloss3.0$impact2 <- inv.logit(Yieldloss3.0$impact) 

#Yieldloss2.0<- Yieldloss2.0[complete.cases(Yieldloss2.0), ]

impact_invlogit_model3.0 <- stan_glm(impact2~ mpd.obs.z, data = Yieldloss3.0,
                                     family = gaussian(link="identity"),)

#gets posterior
posteriorSamples2.0 <- as.data.frame(as.matrix(impact_invlogit_model3.0))
posteriorSamples2.0 <- posteriorSamples2.0[1:4000,]

#obtains original data
orginal_data<- as.data.frame(Yieldloss3.0$mpd.obs.z)

#creates empty matrix
afterhours <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(orginal_data))))

for (n in 1:nrow(orginal_data)){
  afterhours[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * orginal_data[n,])
  #back transforms each row after inverlogit each impact
  #afterhours[,n]  <- as.matrix(logit(afterhours[,n] ))
} 


#codes for new data

#codes for new data
newdatlength <- 50
newdat <- as.data.frame(seq(-9, 15, length.out=newdatlength))
#as.data.frame(seq(range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[1], range(Yieldloss2.0$SES.FPD, na.rm=TRUE)[2], length.out=newdatlength))

afterhours3.0 <- (matrix(NA, nrow= nrow(posteriorSamples2.0), ncol = ncol(t(newdat))))

for (n in 1:nrow(newdat)){
  afterhours3.0[,n] <- as.matrix(posteriorSamples2.0$`(Intercept)` + posteriorSamples2.0$mpd.obs.z * newdat[n,])
  #back transforms each row after inverlogit each impact
  #\afterhours3.0[,n]  <- as.matrix(logit(afterhours3.0[,n] ))
} 


#figure 4.6
plot(impact2~mpd.obs.z, data=Yieldloss3.0, type= "n")
for ( i in 1:10 )
  points(t(newdat) , afterhours3.0[i,] , pch=16 , col=col.alpha(rangi2,0.1))

# summarize the distribution of dose2.0
afterhours3.0.mean <- apply( afterhours3.0 , 2 , mean )
afterhours3.0.HPDI <- apply( afterhours3.0 , 2 , HPDI , prob=0.89 )


#below plots Inverselogit_linearmodel.pdf
# plots raw data
# fading out points to make line and interval more visible
plot( impact2~mpd.obs.z , data=Yieldloss3.0 , col=col.alpha(rangi2,0.5), ylab= "Yield Loss", ylim= c(0,1))

# plot the MAP line, aka the mean impacts for each SES.FPD
lines(t(newdat), afterhours3.0.mean)
# plot a shaded region for 89% HPDI
shade(afterhours3.0.HPDI,t(newdat) )

