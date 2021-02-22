#!/usr/bin/R


#### plot matrix of pass / warn / fail, to get a summary per project

.libPaths("/nfs/software/R/packages")

# retrieve command line arguments
args <- commandArgs(trailingOnly =TRUE)

library(ggplot2)
library(reshape2)

# read matrix allsamples_summary created by script fastqc_summarize_across_samples.sh, calling this one
mat.fastqc <- read.table(args[[1]], sep="\t", header=T, as.is=T)
rownames(mat.fastqc) <- mat.fastqc$Sample
mat.fastqc <- mat.fastqc[,-grep("Sample", colnames(mat.fastqc))]

# melt to ggplot format
df <- melt(t(mat.fastqc))

# geom_tile: heatmap-like; filling colors are peaks (ugly default colors that will be changed)
p <- ggplot(df, aes(x=Var2, y=Var1)) + geom_tile(aes(fill=factor(value)))

col.sel=c("darkred", "forestgreen", "darkorange3")
# adjust color scale, add legend
p <- p + scale_fill_manual(name = "value", 
                        values = col.sel, 
                        labels=c("Fail","Pass","Warn"))

# rotate x-axis labels
p1 <- p + theme(axis.text.x = element_text(angle = 300, hjust = 0)) + scale_x_discrete(name="") + scale_y_discrete(name="")

# save in file
pdf("FastQC_project_summary.pdf", height=8, width=12)
plot(p1)
dev.off()


#### plot per base sequence quality: finally not plotted

#mat.seqq <- read.table(args[[2]], sep="\t", header=T, as.is=T)

#colnames(mat.seqq)[grep("^X", colnames(mat.seqq))] <- gsub("X", "Q",colnames(mat.seqq)[grep("^X", colnames(mat.seqq))])
#rownames(mat.seqq) <- mat.seqq$Sample
#mat.seqq <- mat.seqq[,-grep("Sample", colnames(mat.seqq))]

# melt to ggplot format
#df <- melt(t(mat.seqq))

# plot one line per sample
#p2 <- ggplot(data=df, aes(x=Var1, y=value, group=Var2, colour=Var2)) + geom_line() + theme(axis.text.x = element_text(angle = 300, hjust = 0))

#p2 <- p2 + theme(legend.title=element_blank(), legend.text=element_text(size=5))

# save in file
#pdf("FastQC_per_base_median_quality.pdf", height=8, width=15)
#plot(p2)
#dev.off()


#### Save table_summary.txt as Excel

library(WriteXLS, lib="/nfs/users/bi/sbonnin/Rlibs")

mat.summ <- read.table(args[[2]], sep="\t", header=T, as.is=T)

WriteXLS("mat.summ", ExcelFileName="FastQC_table_summary.xls", col.names=T, row.names=F, AdjWidth=T, BoldHeaderRow=T)




























