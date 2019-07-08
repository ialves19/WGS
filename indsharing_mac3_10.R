#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

##############################
##
## Functions 
##
##############################
computing_doubletons_within_pop <- function(mOne, mTwo) { #mOne: table with the genotypes pos x ind; mTwo new table ind x ind
  # mOne <- openGT
  # mTwo <- m_ind_ind
  
  doubEqAlt <- as.numeric(apply(mOne[,3:ncol(mOne)], 1, function(x) { sum(x[which(x == 1 | x == 2)])  }))
  
  for (wihinPopD in as.numeric(which(doubEqAlt > 2))) {
    
    #wihinPopD <- 1
    ind_tmp <-  colnames(mOne[,3:ncol(mOne)])[which(mOne[wihinPopD,3:ncol(mOne)] == 1 | mOne[wihinPopD,3:ncol(mOne)] == 2)]
    ind_index_tmp <- sort(match(ind_tmp, colnames(mTwo)), decreasing = F)
    pairWComb <- combn(ind_index_tmp, 2)
    for(k in 1:ncol(pairWComb)) {
      #k <- 1
      mTwo[pairWComb[1,k], pairWComb[2,k]] <- mTwo[pairWComb[1,k], pairWComb[2,k]]+1
      mTwo[pairWComb[2,k], pairWComb[1,k]] <- mTwo[pairWComb[2,k], pairWComb[1,k]]+1
      
    }

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
nb.pop <- 5
nb.ind <- 100
tmpPops <- lapply(1:nb.pop, function(x) {paste0(x, "_", 1:nb.ind)})

for (p in 1:nb.pop) {
  write.table(matrix(tmpPops[[p]], ncol = 1), file=paste0(popDirName, "_pop", p, ".txt"), quote = F, row.names = F, col.names = F)  
}

##### - comment afterwards
###
# 

###
## opening the FORMAT file
openGT <- read.table(paste0(folderName, "/tmp.FORMAT"), header = F)
gettingSampleNames <- tmpPops
rm(tmpPops)
names(openGT) <- c("CHROM", "POS", unlist(gettingSampleNames))
pop_ss <- ncol(openGT)-2

totalNbSamples <- length(unlist(gettingSampleNames))
m_ind_ind <- matrix(rep(0, totalNbSamples*totalNbSamples), ncol=totalNbSamples)
colnames(m_ind_ind) <- unlist(gettingSampleNames)
rownames(m_ind_ind) <- unlist(gettingSampleNames)

##
### Handling sites for which the doubleton variant is not the ALT 
doubEqRef <- as.numeric(apply(openGT[,3:ncol(openGT)], 1, function(x) { sum(x[which(x == 2)])  }))
##----
openGT <- openGT[-c(which(doubEqRef > totalNbSamples)),]

#computing within pop individual sharing 
m_ind_ind <- computing_doubletons_within_pop(openGT, m_ind_ind) 

write.table(m_ind_ind, file = paste0(folderName, "/ind_doubleton_share", chrNb, ".txt"), quote = F, col.names = T, row.names = T, sep = "\t")  



