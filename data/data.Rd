---
title: "Exploratory Data Analysis and Cleaning for RITA Flight Data"
author: "Heki Wong"
date: "01/30/2016"
output: html_document
---

### About
This data set contains information on United States airline flight delays and performance.  The dataset includes all domestic flights from all carriers to/from major airports from June, 2003 through November, 2014.

[Download the data set from RITA.](http://www.transtats.bts.gov/OT_Delay/ot_delaycause1.asp?display=download&pn=0&month=11&year=2014)


### Load and inspect data
```{r}
# setwd('~/Dropbox/moocs/udacity-data-science/p5/data/')
df <- read.csv('334221194_112014_3544_airline_delay_causes.csv')
str(df)
summary(df)
head(df)
```

### Clean data
```{r}
library(dplyr)
# clean up date
df$date <- as.Date(paste(df$year, df$X.month, 1, sep='-'), format="%Y-%m-%d")
summary(df$date)

nrow(table(df$carrier))

# make a new summary table
ef <- df %>%
  group_by(date, year, carrier_name) %>%
  summarize(arrivals = sum(arr_flights),
            delayed = sum(arr_del15),
            cancelled = sum(arr_cancelled),
            diverted = sum(arr_diverted)) %>%
  transform(on_time = 1 - delayed/arrivals)

# stash NA values
ef <- ef[complete.cases(ef),]
```

### Exploratory Plots
```{r}
library(ggplot2)

ggplot(data = ef,
       aes(x = date, y = on_time)) +
  geom_line(aes(color = carrier_name))
```

### Find Airlines to Subset Data
```{r}
# aggregate by carrier name
agg <- ef %>%
  group_by(carrier_name) %>%
  summarize(monthly_avg = mean(arrivals),
            arrivals = sum(arrivals))

# pull 75th percentile, by monthly average arrivals
selected_carriers <- subset(agg, monthly_avg >= quantile(monthly_avg, 0.81))$carrier_name
selected_carriers

```

### Reshape Data
```{r}
ff <- subset(ef, is.element(carrier_name, selected_carriers)) %>%
  group_by(year, carrier_name) %>%
  summarize(arrivals = sum(arrivals),
            delayed = sum(delayed),
            cancelled = sum(cancelled),
            diverted = sum(diverted)) %>%
  transform(on_time = 1 - delayed/arrivals)
ff <- ff[complete.cases(ff),]

```

### Replot
```{r}
summary(df$year)

library(gridExtra)
p1 <- ggplot(data = ff,
       aes(x = year, y = on_time)) +
  geom_line(aes(color = carrier_name)) +
  scale_x_continuous(limits=c(2003, 2014), breaks=c(2003:2014))

p2 <- ggplot(data = ff,
       aes(x = year, y = arrivals)) +
  geom_line(aes(color = carrier_name)) +
  scale_x_continuous(limits=c(2003, 2014), breaks=c(2003:2014))

grid.arrange(p1, p2, ncol=1)
```

### Export New CSV
```{r}
write.csv(ff, file="data.csv", row.names=FALSE)
```

