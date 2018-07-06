#!/usr/bin/env Rscript
#args = commandArgs(trailingOnly=TRUE)

folderName <- "/home/isabelalves/Dropbox/instDuThorax/f2"
#folderName <- "/mnt/beegfs/ialves/fTwo"
set.seed(97)
library("randomcoloR")

prefix <- "20180323.FRENCHWGS.REF0002"
sufix <- "onlysnps.MQ.30.mapRmved.hwe1e4.maxmiss.90.CENTRE.mac2G.noDouble"

allPops <- c("BRETAGNE", "PAYS-DE-LA-LOIRE", "CENTRE", "BASSE-NORMANDIE.HAUTE-NORMANDIE", "LIMOUSIN.POITOU-CHARENTES", "NORD-PAS-DE-CALAIS.PICARDIE", "ALSACE.LORRAINE")
acronyms <- c("BRE", "PL", "C", "N", "LPCH", "NCP", "AL")
sampleSizes <- c(323, 297, 29, 19, sum(24, 22), sum(76,11), sum(15,27))
totalSize <- 856

# allPops <- c("FINISTERE", "COTES-DARMOR", "MORBIHAN", "ILLE-ET-VILAINE", "LOIRE-ATLANTIQUE", "MAYENNE", "MAINE-ET-LOIRE", "SARTHE", "VENDEE")
# acronyms <- c("FIN", "CDA", "MOR", "IEV", "LA", "MAY", "MEL", "SAR", "VEN")
# sampleSizes <- c(109, 70, 80, 64, 88, 43, 72, 23, 71)
# totalSize <- 856

chrms <- paste0("chr", 1:22)

#colors_reg <- randomColor(length(allPops), luminosity = "dark")
#colors_reg <- c("#b2182b", "#d6604d", "#f4a582", "#fddbc7",  "#f7f7f7",  "#d1e5f0", "#92c5de", "#4393c3","#2166ac")
colors_reg <- c("#01665e", "#5ab4ac", "#c7eae5", "#f5f5f5", "#f6e8c3", "#d8b365", "#8c510a")
#chrID <- "chr22"
count_p <- 1
cat(paste0(paste0(allPops, collapse = "\t"), "\n"), file = paste0(folderName, "/f2_mac2Global_ALLreg.txt"), sep = "\t")

pPop_total_nb_double_global <- list()
doubleSharing_acrossPop <- list()

for (popToAnalise in allPops) {
  
  #popToAnalise <- "BRETAGNE"
  list_p_chr <- list()
  total_nb_double_global <- list()
  for (chr in chrms) {
    
    list_p_chr[[chr]] <- read.table(paste0(folderName, "/", prefix, ".", chr, ".", sufix, ".", popToAnalise, ".frq.count"), header = F, skip = 1)
    total_nb_double_global[[chr]] <- nrow(list_p_chr[[chr]])
  }
  tb_open <- do.call(rbind,list_p_chr)
  pPop_total_nb_double_global[[popToAnalise]] <- sum(unlist(total_nb_double_global)) #this value should not differ across pops
  #count doubletons
  nb_double_withinPop <- nrow(tb_open[which(tb_open[,6] == 2),])
  
  nb_shared_double <- nrow(tb_open[which(tb_open[,6] == 1),])
  double_shared <- paste0(tb_open[which(tb_open[,6] == 1),1], "_",tb_open[which(tb_open[,6] == 1),2])
  
  dd_shared_pop_and_other <- list()
  relative_sample_sizes <- list()
  
  for (p in allPops[which(allPops != popToAnalise)]) {
    
    list_op_chr <- list()
    for (chr in chrms) {
      list_op_chr[[chr]] <- read.table(paste0(folderName, "/", prefix, ".", chr, ".", sufix, ".", p, ".frq.count"), header = F, skip = 1)
    }
    #p <- "COTES-DARMOR"
    tb_other_pop <- do.call(rbind,list_op_chr)
    
    shared_dd_other <- nrow(tb_other_pop[which(tb_other_pop[,6] == 1),])
    dd_pos_shared_other <- paste0(tb_other_pop[which(tb_other_pop[,6] == 1),1], "_",tb_other_pop[which(tb_other_pop[,6] == 1),2])
    dd_shared_pop_and_other[[p]] <- length(intersect(double_shared, dd_pos_shared_other))
    
    relative_sample_sizes[[p]] <- 2*(sampleSizes[which(allPops == popToAnalise)]/totalSize)*(sampleSizes[which(allPops == p)]/totalSize)
    
  }
  
  v_final <- rep(0,length(allPops))
  rel_size <- rep(0,length(allPops))
  names(v_final) <- allPops
  v_final[match(names(unlist(dd_shared_pop_and_other)),allPops)] <- as.numeric(unlist(dd_shared_pop_and_other)/pPop_total_nb_double_global[[1]])
  v_final[which(allPops == popToAnalise)] <- nb_double_withinPop/pPop_total_nb_double_global[[1]]
  
  rel_size[match(names(unlist(dd_shared_pop_and_other)),allPops)] <- unlist(relative_sample_sizes)
  rel_size[which(allPops == popToAnalise)] <- (sampleSizes[which(allPops == popToAnalise)]/totalSize)^2
  
  doubleSharing_acrossPop[[popToAnalise]] <- v_final/rel_size
  barplot(v_final/rel_size, names.arg = "", col = colors_reg, axes = F)
  mtext(side=2, text=acronyms[count_p], las=2, line=0, cex = 1) 
  rect((which(allPops == popToAnalise)-1)+0.2*(which(allPops == popToAnalise)), 0, which(allPops == popToAnalise)+0.2*(which(allPops == popToAnalise)), as.numeric(v_final[which(allPops == popToAnalise)]/rel_size[which(allPops == popToAnalise)]), lwd=3)
  cat(paste0(paste0(c(nb_double_withinPop, as.numeric(unlist(dd_shared_pop_and_other))), collapse = "\t"), "\n"), file = paste0(folderName, "/f2_mac2Global_BRE_PDLL.txt"), sep = "\t", append = T)
  count_p <- count_p+1
}

m_allele_sharing <- matrix(unlist(doubleSharing_acrossPop), ncol = length(doubleSharing_acrossPop), byrow = T)
colnames(m_allele_sharing) <- acronyms
rownames(m_allele_sharing) <- acronyms

##########################
## generating PDF       ##
##########################
source("https://bioconductor.org/biocLite.R")
# biocLite()
# biocLite("made4")
# install.packages("corrplot")
library(made4)
library(gtools)
library(corrplot)

pdf(file = paste0(folderName, "/f2_globalMac2_ALLreg.pdf"), height=8, width = 8)
par(mfrow=c(length(allPops)+1,1), mar=c(1,4,1,1))
for (c in 1:nrow(m_allele_sharing)) {
  
  barplot(m_allele_sharing[c,], names.arg = "", col = colors_reg, axes = F, ylim=c(0, max(m_allele_sharing)))
  mtext(side=2, text=acronyms[c], las=2, line=0, cex = 1) 
  rect((which(allPops == allPops[c])-1)+0.2*(which(allPops == allPops[c])), 0, which(allPops == allPops[c])+0.2*(which(allPops == allPops[c])), 
       as.numeric(m_allele_sharing[c,which(allPops == allPops[c])]), lwd=3)
  
}
abline(h=0, col = "black")
v_x <- rep(0, length(allPops))
names(v_x) <- acronyms
par(mar=c(0,3,0,1))
plot(v_x, type = "n", xlab = "", ylab = "", xlim = c(0,19.7), ylim = c(0,10), axes = F)
#axis(1, at=seq(0.7,19.2, by = 1.2), labels = FALSE, las=2, line=2, outer=F, tick = F, col = NULL, col.ticks = NULL)
text(x=seq(1,18.5, length.out = length(acronyms)), y=10, labels = acronyms, srt=45, pos = 1, cex = 1.5, offset = 1)
#par(mar=c(6,4,0,1))
dev.off()

##########################
## generating PNG       ##
##########################

png(file =  paste0(folderName, "/f2_globalMac2_ALLreg.png"), height=600, width = 600)
par(mfrow=c(length(allPops)+1,1), mar=c(1,4,1,1))
for (c in 1:nrow(m_allele_sharing)) {
  
  barplot(m_allele_sharing[c,], names.arg = "", col = colors_reg, axes = F, ylim=c(0, max(m_allele_sharing)))
  mtext(side=2, text=acronyms[c], las=2, line=0, cex = 1) 
  rect((which(allPops == allPops[c])-1)+0.2*(which(allPops == allPops[c])), 0, which(allPops == allPops[c])+0.2*(which(allPops == allPops[c])), 
       as.numeric(m_allele_sharing[c,which(allPops == allPops[c])]), lwd=3)
  
}
abline(h=0, col = "black")
v_x <- rep(0, length(allPops))
names(v_x) <- acronyms
par(mar=c(0,3,0,1))
plot(v_x, type = "n", xlab = "", ylab = "", xlim = c(0,19.7), ylim = c(0,10), axes = F)
#axis(1, at=seq(0.7,19.2, by = 1.2), labels = FALSE, las=2, line=2, outer=F, tick = F, col = NULL, col.ticks = NULL)
text(x=seq(1,18.5, length.out = length(acronyms)), y=10, labels = acronyms, srt=45, pos = 1, cex = 1.5, offset = 1)
#par(mar=c(6,4,0,1))
dev.off()

#########################
## Defining colors
#########################
col.to.paint <- colorRampPalette(colors_reg)

png(file=paste0(folderName, "/f2_globalMac2_ALLreg_corrplot.png"), height=600, width = 600)
corrplot(cor(t(m_allele_sharing)), method = "color",
         col = col.to.paint(20), cl.length = 11, tl.col="black")

dev.off()


png(file=paste0(folderName,"/f2_globalMac2_ALLreg_heatplot.png"), height=700, width = 600)
heatplot(m_allele_sharing, scale = "none", dend="both", method = "average", dualScale = T, zlim = c(-1.13,2.57), 
         cols.default = T,lowcol = "blue", highcol = "red")
dev.off()

#########################
## Print table
#########################

write.table(m_allele_sharing, file = paste0(folderName,"/f2_globalMac2_ALLreg_m.txt"), row.names = F, col.names = T, sep = "\t", quote = F)


