args <- commandArgs(trailingOnly = TRUE)

#########################
##
## Checking if PoBI alleles are 
## in TOP configuration
##
########################

PoBI_dir <- args[1]
mapFile <- args[2]
topFiles <- args[3]
chrID <- args[4]


    # PoBI_dir <- "/home/ialves/Dropbox/jobRelated_Isabel/MyPapers/GenetHistofFRANCE/Revisions_1stRound/PoBI"
    # mapFile <- "WTCCC2_POBI_illumina_calls_POBI_22_illumina_rec.bim"
    # topFiles <- "Human1-2M-DuoCustom_v1_A.update_alleles.txt"
    # chrID <- 22
    
openGen <- read.table(paste0(PoBI_dir, "/", mapFile), header = F)
openTop <- read.table(paste0(PoBI_dir, "/", topFiles), header = F) 

interSNPs <- intersect(openGen[,2], openTop[,1])
print(paste0("Number of snps overlapping: ", length(interSNPs)))
print(paste0("Number of snps in the map/bim file: ", nrow(openGen)))

NbOfSitesNotOnTOP <- sum(as.vector(openTop[match(interSNPs, openTop[,1]),4]) != as.vector(openGen[match(interSNPs, openGen[,2]),5]))
notTopSNPs <- as.vector(openGen[as.vector(openTop[match(interSNPs, openTop[,1]),4]) != as.vector(openGen[match(interSNPs, openGen[,2]),5]),2])

if(NbOfSitesNotOnTOP > 0) {
  
  print(paste0(NbOfSitesNotOnTOP, " SNPs in the map file are not on TOP configuration according to: ", topFiles))
  write.table(matrix(notTopSNPs), file = paste0(PoBI_dir, "/notOnTOP_SNPs_chr", chrID, ".txt"), quote = F, row.names = F, col.names = F) 
}