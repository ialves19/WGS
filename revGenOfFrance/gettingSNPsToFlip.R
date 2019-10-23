args <- commandArgs(trailingOnly = TRUE)

#########################
##
## Checking if PoBI alleles are 
## in TOP configuration and converts 
## in positive strand those that are in -
##
########################


PoBI_dir <- args[1]
mapFile <- args[2]
topFiles <- args[3]
chrID <- args[4]


# PoBI_dir <- "/home/ialves/Dropbox/jobRelated_Isabel/MyPapers/GenetHistofFRANCE/Revisions_1stRound/PoBI"
# mapFile <- "WTCCC2_POBI_illumina_calls_POBI_3_illumina_rec_allTOP.bim"
# topFiles <- "Human1-2M-DuoCustom_v1_A-b36.strand"
# chrID <- 3

openGen <- read.table(paste0(PoBI_dir, "/", mapFile), header = F)
openTop <- read.table(paste0(PoBI_dir, "/", topFiles), header = F) 

interSNPs <- intersect(openGen[,2], openTop[,1])
length(interSNPs)

#merging TOP alleles from col 5 and 6 in the .bim file
mTOP <- openGen[match(interSNPs,openGen[,2]),]
TOPallele_bim <- paste0(mTOP[,5],mTOP[,6])
snpIDs_bim <- as.vector(mTOP[,2])
length(TOPallele_bim)

mStrand <- openTop[match(interSNPs,openTop[,1]),]
TOPallele_strand <- as.vector(mStrand[,6])
snpIDs_strand <- as.vector(mStrand[,1])
strand <- mStrand[,5]
length(TOPallele_strand)

if (sum(snpIDs_bim == snpIDs_strand) == length(TOPallele_bim) && sum(TOPallele_bim == TOPallele_strand) == length(TOPallele_strand)) {
  
  m_SNPtoFlip <- snpIDs_strand[which(strand == "-")]
  write.table(m_SNPtoFlip, file = paste0(PoBI_dir, "/snps_to_flip_chr", chrID, ".txt"), quote = F, row.names = F, col.names = F)
  
} else {
  m_SNPtoRemNotStrandF <- matrix(snpIDs_bim[TOPallele_bim != TOPallele_strand])
  write.table(m_SNPtoRemNotStrandF, file = paste0(PoBI_dir, "/SNPtoRemNotStrandF_chr", chrID, ".txt"), quote = F, row.names = F, col.names = F)
  print("Warning: Alleles in the bim file are not the ones in the strand file!")  
}






