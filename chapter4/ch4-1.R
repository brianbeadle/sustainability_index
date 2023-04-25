#################################
# running long model for paper 3
################################

setwd("C:/Users/Beadle/Documents/GitHub/paper3-organic_farming") 

knitr::opts_chunk$set(comment=NA, message=FALSE, warning=FALSE)
rm(list=ls())
library(tidyverse)
library(haven)
library(brms)
library(bayesplot)
library(ggplot2)
theme_set(theme_bw())
library(tictoc)
library(sampling)
library(shinystan)
library(rstanarm)

### loading in the data 

d <- read_dta("stata/dat/300-ord4_w-org_reduced4.dta")
d <- d %>% mutate( time = as.factor(YEAR - min(YEAR) + 1) )
d <- rename(d, id = idn)
d$id <- as.integer(d$id)
d$item <- as.factor(d$item)
d$TF8 <- as.factor(d$TF8)
d$A26 <- as.factor(d$A26)
d$org <- as.factor(d$org)
# d <- d %>% filter( item == c("1", "2", "3") )
table(d$item)

d$y <- factor( d$y, levels = c("0", "1", "2", "3"), ordered = TRUE ) 
glimpse(d, width = 60)

table(d$y)

### getting sample: find package for cluster

#set.seed(647382)
#n <- round(length(unique(d$id))*0.05, 0)
#samplecluster <- cluster(d, clustername=c("id"), size=n, method="srswor")
#dsample <- getdata(d, samplecluster)
#d <- dsample

#summary(d)

cbind(n, nrow(d))

ggplot( d, aes(x=y) ) +
  stat_count(width = 0.5) +
  xlab("") +
  facet_wrap(~item)

### fitting the model

#fn <- "x" # "results/oirm-2013-2pl.rds"
#fn <- "results/asi-wcovariates-2013.rds"
#if (file.exists(fn)) {
#  file.remove(fn)
#}
tic("fit1")
prior <-
  # discrimination
  prior("normal(0, 1)", class = "Intercept", dpar = "disc") +             # alpha
  prior("normal(0, 1)", class = "sd", group = "item", dpar = "disc") +    # sigma_alpha
  # unit-specific effects 
  prior("constant(1)", class = "sd", group = "id") +
  # item-specific effects 
  prior("normal(0, 1)", class = "sd", coef = "Intercept", group = "item") +
  # time effects 
  prior("normal(0, 1)", class = "b")   
formula <- brmsformula(
  y ~ 1 + (1|i|item) + time + (1 + time|id),
  disc ~ 1 + (1|i|item)
)
fit1 <- brm( 
  formula = formula,
  data = d,
  family = cumulative(link = "logit"),
  prior = prior,
  cores = 8,
  iter = 1000,
  warmup = 500,
  # refresh = 0,
  file = "results/asi-wcovariates-2013.rds"
)

toc()

summary(fit1)

### conditional effects and markov chain monte carlo plots 

conditional_effects(fit1,  effects = c("org"), categorical = TRUE, robust = FALSE, probs = c(0.25, 0.75) )

posterior <- as.matrix(fit1)

plot_title <- ggtitle("Posterior distributions",
                      "with medians and 80% intervals")
mcmc_areas(posterior,
           pars = c("org"), categorical = TRUE,
           prob = 0.8) + plot_title


# extract the number of divergence transitions
np <- nuts_params(fit1)
sum(subset(np, Parameter == "divergent__")$Value)

prior_summary(fit1)

### discrimination parameter
library(tidybayes)
fit1 %>% 
  spread_draws(r_item__disc[Intercept,]) %>% 
  median_qi(item_mean = exp(r_item__disc), .width = c(.95)) %>%
  ggplot(aes(y = Intercept, x = item_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  scale_y_discrete( limits = seq(1, 9, 1) ) +
  ggtitle("Discrimination")


# extract item and easiness parameters
ranef1 <- ranef(fit1)
# discriminations
alpha <- ranef1$item[, , "disc_Intercept"] %>%
  exp() %>% 
  as_tibble() %>%
  rownames_to_column()
# item easinesses (deviations from thresholds)
beta <- ranef1$item[, , "Intercept"] %>%
  as_tibble() %>%
  rownames_to_column()
# put easinesses and discriminations together
bind_rows(beta, alpha, .id = "nlpar") %>%
  rename(item = "rowname") %>%
  mutate(item = as.numeric(item)) %>%
  mutate(nlpar = factor(nlpar, labels = c("Easiness", "Discrimination"))) %>%
  ggplot(aes(item, Estimate, ymin = Q2.5, ymax = Q97.5)) +
  facet_wrap("nlpar", scales = "free_x") +
  geom_pointrange() +
  coord_flip() +
  labs(x = "Item Number") + 
  scale_x_discrete( limits=1:9 )

df.re <- ranef(fit1) 
dim(df.re$id) # dimension: no of units X no sum. stats (4) X no. od parameters

df.re <- data.frame( asi = df.re$id[,1,] ) # extract mean
dim(df.re)

df.re <- tibble::rownames_to_column(df.re, "id")
head(df.re)

nrow(df.re) # number of AS values: one value for each farm in each year 

write.csv(df.re, file = "stata/results/asi-wcovariates-2013.csv")
