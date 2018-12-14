#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

folderName <- "/mnt/beegfs/ialves/rare_by_dist"
chrID <- args[1]
mac <- args[2]
ref_alt_tbl <- read.table(paste0(folderName, "/20180323.FRENCHWGS.REF0002", ".", chrID, ".mac", mac, ".INFO"), header = T, sep = "\t")

write.table((ref_alt_tbl[which(ref_alt_tbl[,5] != ref_alt_tbl[,3] & ref_alt_tbl[,5] != ref_alt_tbl[,4]),1:2]), 
            file = paste0(folderName, "/20180323.FRENCHWGS.REF0002.", chrID, ".mac", mac, ".SNPsToRM"), quote=F, col.names = F, row.names = F, sep = "\t")
write.table((ref_alt_tbl[which(ref_alt_tbl[,5] == ref_alt_tbl[,4]),]), 
            file = paste0(folderName, "/20180323.FRENCHWGS.REF0002.", chrID, ".mac", mac, ".ANCisALT"), quote=F, col.names = F, row.names = F, sep = "\t")
