#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

input=args[1]
# input should be 1 column with numeric values, no header

library(tidyverse)
library(data.table)
dat<-fread(input, header=F)

#dat
dat %>%
  summarise(med=median(V1), max=max(V1), min=min(V1)) -> datSumm

#datSumm
write(datSumm$min, '')
write(datSumm$med, '')
write(datSumm$max, '')
