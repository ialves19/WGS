folderName <- "/Users/isabelalves/Dropbox/instDuThorax/"

dist_m <- read.table(paste0(folderName,"/samples/diff_propf2.txt"), header = T, sep = "\t")
geo_m <- read.table(paste0(folderName, "/samples/dist_m_West.txt"), header = T, sep = "\t")
colnames(dist_m)
colnames(geo_m) <- colnames(dist_m)
dist_v_tmp <- c()
geo_v_tmp <- c()

colors_reg <- c("#b2182b", "#d6604d", "#f4a582", "#fddbc7",  "#d1e5f0", "#92c5de", "#4393c3","#2166ac")
acronyms <- c("FIN", "CDA", "MOR", "IEV", "LA", "MAY", "MEL", "VEN")
png(file=paste0(folderName, "/f2/corr_distkm_f2.png"), width = 800, height = 400)
par(mfrow=c(1,2), mar=c(4,4,2,2))
for (rowNb in 1:nrow(dist_m)) {
  
  #rowNb <- 1
  m_tmp[[rowNb]] <- rbind(dist_m[rowNb,], geo_m[rowNb,])
  if (rowNb == 1) {
    
    plot(x=as.numeric(geo_m[rowNb,]), y=as.numeric(dist_m[rowNb,]), col=colors_reg[rowNb], pch=19, 
         xlab = "Distance km", ylab= "Difference in allele sharing f2", xlim = c(0,280), ylim=c(0,0.12))
    dist_v_tmp <- as.numeric(dist_m[rowNb,])
    geo_v_tmp <- as.numeric(geo_m[rowNb,])
    
    
  } else {
    points(x=as.numeric(geo_m[rowNb,]), y=as.numeric(dist_m[rowNb,]),col=colors_reg[rowNb], pch=19)
    dist_v_tmp <- c(dist_v_tmp,as.numeric(dist_m[rowNb,]))
    geo_v_tmp <- c(geo_v_tmp, as.numeric(geo_m[rowNb,]))
    
  }
  
}

cor(x=geo_v_tmp, y=dist_v_tmp)
sum_lm <- summary(lm(dist_v_tmp~geo_v_tmp))
abline(lm(dist_v_tmp~geo_v_tmp))
legend("topleft", legend = acronyms, fill = colors_reg, bty = "n", cex = 1)
legend("bottomright", legend = paste0("R-squared: ", round(sum_lm$adj.r.squared, digits = 3)), bty = "n")
mean_diff <- unlist(lapply(1:length(m_tmp), function(x) {  mean(as.numeric(m_tmp[[x]][1,-x]))}))
names(mean_diff) <- colnames(dist_m)
barplot(sort(mean_diff, decreasing = T), col = colors_reg[order(mean_diff, decreasing = T)], ylim = c(0,0.10), xaxt="n",
        ylab = "Average differences in allele sharing, f2")
text(x=seq(0.3,8.9, length.out = 8), y=0, labels = acronyms[order(mean_diff, decreasing = T)], srt=60, xpd=TRUE, pos = 1, cex = 1, offset = 1.2)
dev.off()
length(dist_v_tmp)
length(geo_v_tmp)
