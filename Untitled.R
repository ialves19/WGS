#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

##############################
##
## Functions 
##
##############################
computing_doubletons_within_pop <- function(mOne, mTwo) { #mOne: table with the genotypes pos x ind; mTwo new table ind x ind
  
  doubEqAlt <- as.numeric(apply(mOne[,3:ncol(mOne)], 1, function(x) { sum(x[which(x == 1)])  }))
  
  for (wihinPopD in as.numeric(which(doubEqAlt == 2))) {
    
    #wihinPopD <- which(doubEqAlt == 2)[1]
    ind_tmp <-  colnames(mOne)[which(mOne[wihinPopD,] == 1)]
    ind_index_tmp <- sort(match(ind_tmp, colnames(mTwo)), decreasing = F)
    
    mTwo[ind_index_tmp[1], ind_index_tmp[2]] <- mTwo[ind_index_tmp[1], ind_index_tmp[2]]+1
    mTwo[ind_index_tmp[2], ind_index_tmp[1]] <- mTwo[ind_index_tmp[2], ind_index_tmp[1]]+1  
  }
  return(mTwo)
}

##########################
##                      ##
##        MAIN          ##
##                      ##
##########################

chrNb <- args[1]
folderName <- args[2]


chrNb <- 1
folderName <- "/Users/isabelalves/Dropbox/instDuThorax/documents/elisabeth/May6_2019"
popDirName <- paste0(folderName, "/pops")

###tmp - creating pop files

tmpPops <- c(paste0("1_", 1:50), paste0("2_", 1:50))
write.table(matrix(tmpPops[1:50], ncol=1), file=paste0(popDirName, "_pop1.txt"), quote = F, row.names = F, col.names = F)
write.table(matrix(tmpPops[51:100], ncol=1), file=paste0(popDirName, "_pop2.txt"), quote = F, row.names = F, col.names = F)
##### - comment afterwards
###
# 

###
## opening the FORMAT file
formatF <- read.table(paste0(folderName, "/tmp.FORMAT"), header = F)
names(formatF) <- c("CHROM", "POS", tmpPops)

gettingSampleNames <- tmpPops
rm(tmpPops)

totalNbSamples <- length(gettingSampleNames)
m_ind_ind <- matrix(rep(0, totalNbSamples*totalNbSamples), ncol=totalNbSamples)
colnames(m_ind_ind) <- gettingSampleNames
rownames(m_ind_ind) <- gettingSampleNames
