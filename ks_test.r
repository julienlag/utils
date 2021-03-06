#!/usr/bin/Rscript

#performs Kolmogorov-Smirnov test on two distributions, and returns p-value in STDOUT

options(warn=-1)
args<-commandArgs(TRUE)
target=read.table(args[1])$V1
subject=read.table(args[2])$V2
cat(ks.test(target,subject)$p.value,"\n")
