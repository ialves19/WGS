#install.packages("Hmisc")

folderName <- "/home/isabelalves/Dropbox/instDuThorax"

dist_m <- read.table(paste0(folderName,"/f2/f2_globalMac2_ALLreg_m.txt"), header = T, sep = "\t")
geo_m <- read.table(paste0(folderName, "/f2/dist_m_ALLreg.txt"), header = T, sep = "\t")
colnames(dist_m)
colnames(geo_m) <- colnames(dist_m)

#removing Normandie
# dist_m_tmp <- cbind(dist_m[,1:3],dist_m[,5:7])
# geo_m_tmp <- cbind(geo_m[,1:3],geo_m[,5:7])
# 
# dist_m <- rbind(dist_m_tmp[1:3,],dist_m_tmp[5:7,])
# geo_m <- rbind(geo_m_tmp[1:3,],geo_m_tmp[5:7,])
# 
dist_v_tmp <- c()
geo_v_tmp <- c()

colors_reg <- c("#01665e", "#5ab4ac", "#c7eae5", "#f6e8c3", "#d8b365", "#8c510a")
acronyms <- c("BRE", "PL", "C", "LPCH", "NCP", "AL")
m_tmp <- list()
pointSyb <- c(7,15,16,17,18,19,20,21, 12)
png(file=paste0(folderName, "/f2/corr_distkm_f2_ALLreg.png"), width = 800, height = 400)
par(mfrow=c(1,2), mar=c(4,4,2,2))
for (rowNb in 1:nrow(dist_m)) {
  
  #rowNb <- 1
  m_tmp[[rowNb]] <- rbind(abs(dist_m[rowNb,]-dist_m[rowNb,rowNb])/dist_m[rowNb,rowNb], geo_m[rowNb,])
  if (rowNb == 1) {
    
    plot(x=as.numeric(geo_m[rowNb,]), y=as.numeric(dist_m[rowNb,]), col=colors_reg[1], pch=19, 
         xlab = "Distance km", ylab= "Difference in allele sharing f2", xlim = c(0,max(geo_m)), ylim=c(min(dist_m), max(dist_m)))
    dist_v_tmp <- as.numeric(dist_m[rowNb,])
    geo_v_tmp <- as.numeric(geo_m[rowNb,])
    
    
  } else if (rowNb < nrow(dist_m)) {
    points(x=as.numeric(geo_m[rowNb,c(1:nrow(dist_m))[which(c(1:nrow(dist_m)) >= rowNb)]]), y=as.numeric(dist_m[rowNb,][c(1:nrow(dist_m))[which(c(1:nrow(dist_m)) >= rowNb)]]),col=colors_reg[1], pch=19)
    dist_v_tmp <- c(dist_v_tmp,as.numeric(dist_m[rowNb,][c(1:nrow(dist_m))[which(c(1:nrow(dist_m)) >= rowNb)]]))
    geo_v_tmp <- c(geo_v_tmp, as.numeric(geo_m[rowNb,][c(1:nrow(dist_m))[which(c(1:nrow(dist_m)) >= rowNb)]]))
    
  }
  
}

cor(x=geo_v_tmp, y=dist_v_tmp)
sum_lm <- summary(lm(dist_v_tmp~geo_v_tmp))
abline(lm(dist_v_tmp~geo_v_tmp))
#legend("topright", legend = acronyms, fill = colors_reg, bty = "n", cex = 1)
legend(x=100, y=2.0, legend = paste0("R-squared= ", round(sum_lm$adj.r.squared, digits = 3), 
                                     "\n", "p-value= ",  format.pval(sum_lm$coefficients[2,4], digits=4, scientific = TRUE)), bty = "n")
mean_diff <- unlist(lapply(1:length(m_tmp), function(x) {  mean(as.numeric(m_tmp[[x]][1,-x]))}))
names(mean_diff) <- colnames(dist_m)
barplot(sort(mean_diff, decreasing = T), col = colors_reg[order(mean_diff, decreasing = T)], ylim = c(0,max(mean_diff)), xaxt="n",
        ylab = "Average differences in allele sharing, f2")
text(x=seq(0.5,length(acronyms)+length(acronyms)*0.13, length.out = length(acronyms)), y=0, labels = acronyms[order(mean_diff, decreasing = T)], srt=60, xpd=TRUE, pos = 1, cex = 1, offset = 1.2)
dev.off()
length(dist_v_tmp)
length(geo_v_tmp)
