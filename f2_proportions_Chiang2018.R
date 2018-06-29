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

#8 regions
# allPops <- c("BRETAGNE", "PAYS-DE-LA-LOIRE", "CENTRE", "POITOU-CHARENTES", "LIMOUSIN", "NORD-PAS-DE-CALAIS", "LORRAINE", "ALSACE")
# acronyms <- c("BRET", "PDDL", "CEN", "PC", "LIM", "NPDC", "LOR", "ALS")

#16 populations
# allPops <- c("COTES-DARMOR", "FINISTERE", "ILLE-ET-VILAINE", "MORBIHAN", "LOIRE-ATLANTIQUE", "MAINE-ET-LOIRE", "MAYENNE", "SARTHE", "VENDEE", 
#              "NORD", "PAS-DE-CALAIS",  "MEURTHE-ET-MOSELLE.MOSELLE.VOSGES", "BAS-RHIN.HAUT-RHIN", "CORREZE.CREUSE.HAUTE-VIENNE",  
#              "VIENNE.DEUX-SEVRES.CHARENTE", "LOIR-ET-CHER.INDRE-ET-LOIRE.LOIRET")
# acronyms <- c("CD_B", "F_B", "IEV_B", "M_B", "LA_PL", "ML_PL", "MNE_PL", "S_PL", "V_PL","N_NPC", "PC_NPC", "MMV_L", "BRHR_A",
#               "CCHV_L", "VDSC_PC", "LIL_C")

chrms <- paste0("chr", 1:22)
par(mfrow=c(length(allPops)+1,1), mar=c(1,4,1,1))
#colors_reg <- randomColor(length(allPops), luminosity = "dark")
#colors_reg <- c("#01665e", "#35978f", "#80cdc1", "#c7eae5",  "#f6e8c3", "#dfc27d", "#bf812d","#8c510a")
#colors_reg <- c("#b2182b", "#d6604d", "#f4a582", "#fddbc7",  "#d1e5f0", "#92c5de", "#4393c3","#2166ac")
colors_reg <- c("#01665e", "#5ab4ac", "#c7eae5", "#f5f5f5", "#f6e8c3", "#d8b365", "#8c510a")
#chrID <- "chr22"
count_p <- 1
cat(paste0(paste0(allPops, collapse = "\t"), "\n"), file = paste0(folderName, "/f2_mac2Global.txt"), sep = "\t")

pPop_total_nb_double_global <- list()

for (popToAnalise in allPops) {
  
  #popToAnalise <- "BRETAGNE"
  list_p_chr <- list()
  total_nb_double_global <- list()
  for (chr in chrms) {
    
    list_p_chr[[chr]] <- read.table(paste0(folderName, "/", prefix, ".", chr, ".", sufix, ".", popToAnalise, ".frq.count"), header = F, skip = 1)
    total_nb_double_global [[chr]] <- nrow(list_p_chr[[chr]])
  }
  tb_open <- do.call(rbind,list_p_chr)
  pPop_total_nb_double_global[[popToAnalise]] <- sum(unlist(total_nb_double_global))
  #count doubletons
  nb_double_withinPop <- nrow(tb_open[which(tb_open[,6] == 2),])*2
  
  nb_shared_double <- nrow(tb_open[which(tb_open[,6] == 1),])
  double_shared <- paste0(tb_open[which(tb_open[,6] == 1),1], "_",tb_open[which(tb_open[,6] == 1),2])
  
  dd_shared_pop_and_other <- list()

  
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
    
  }
  
  v_final <- rep(0,length(allPops))
  rel_size <- rep(0,length(allPops))
  names(v_final) <- allPops
  v_final[match(names(unlist(dd_shared_pop_and_other)),allPops)] <- as.numeric(unlist(dd_shared_pop_and_other)/(totalSize*2))
  v_final[which(allPops == popToAnalise)] <- nb_double_withinPop/(totalSize*2)
  rel_size[match(names(unlist(dd_shared_pop_and_other)),allPops)] <- sampleSizes[match(names(unlist(dd_shared_pop_and_other)),allPops)]/totalSize
  rel_size[which(allPops == popToAnalise)] <- sampleSizes[which(allPops == popToAnalise)]/totalSize
  
  barplot(v_final/rel_size, names.arg = "", col = colors_reg, axes = F)
  mtext(side=2, text=acronyms[count_p], las=2, line=0, cex = 1) 
  rect((which(allPops == popToAnalise)-1)+0.2*(which(allPops == popToAnalise)), 0, which(allPops == popToAnalise)+0.2*(which(allPops == popToAnalise)), as.numeric(v_final[which(allPops == popToAnalise)]/rel_size[which(allPops == popToAnalise)]), lwd=3)
  cat(paste0(paste0(c(nb_double_withinPop, as.numeric(unlist(dd_shared_pop_and_other))), collapse = "\t"), "\n"), file = paste0(folderName, "/f2_mac2Global.txt"), sep = "\t", append = T)
  count_p <- count_p+1
}

v_x <- rep(0, length(allPops))
names(v_x) <- acronyms
par(mar=c(0,3,0,1))
plot(v_x, type = "n", xlab = "", ylab = "", xlim = c(0,19.7), ylim = c(0,10), axes = F)
#axis(1, at=seq(0.7,19.2, by = 1.2), labels = FALSE, las=2, line=2, outer=F, tick = F, col = NULL, col.ticks = NULL)
text(x=seq(1.5,18.5, length.out = 7), y=10, labels = acronyms, srt=45, pos = 1, cex = 1.2, offset = 1)
#par(mar=c(6,4,0,1))




