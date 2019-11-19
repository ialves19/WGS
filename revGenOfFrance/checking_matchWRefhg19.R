args <- commandArgs(trailingOnly = TRUE)
.libPaths( c("/sandbox/users/alves-i/R/x86_64-pc-linux-gnu-library/3.3", .libPaths() ) )
library(stringr)
#########################
##
## Checking if PoBI alleles are 
## in TOP configuration
##
########################

PoBI_dir <- args[1]
bimFile <- args[2]
refAlleles <- args[3]
chrID <- args[4]
checkREFexist <- args[5]

PoBI_dir <- "/home/ialves/Dropbox/jobRelated_Isabel/MyPapers/GenetHistofFRANCE/Revisions_1stRound/MS/EGAD00010000120/"
bimFile <- "MS_22_illumina_rec_allTOP_strand_hwe1e-5_noDup.bim"
refAlleles <- "referenceAllele_chr22_hg19.out"
chrID <- 22
checkREFindex <- T

openBim <- read.table(file=paste0(PoBI_dir, "/", bimFile), header = F)

    list_refAlleles <- scan(file=paste0(PoBI_dir, "/", refAlleles), what = list(pos="", refAllele=""), flush = T, skip = 0)
list_refAlleles$pos <- unlist(lapply(strsplit(unlist(lapply(strsplit(list_refAlleles$pos, split=":"), function(x) { x[2] })), split = "-"), function(y) { y[2] }))

listMatchSites <- unlist(lapply(1:length(list_refAlleles$pos), function(k) { 
  is.element(list_refAlleles$refAllele[k], as.character(unlist(openBim[match(list_refAlleles$pos[k], as.character(unlist(openBim[4]))),c(5,6)]))) }))
  
  rs_m <- matrix(openBim[match(list_refAlleles$pos, as.character(unlist(openBim[4])))[listMatchSites],2])
  write.table(rs_m, file=paste0(PoBI_dir, "/rsIds_toKeep_chr", chrID, ".keep"),  quote = F, row.names = F, col.names = F)

if (checkREFindex) {
  
  snpsWREF <- as.vector(rs_m)
  tmp_openBIM <- openBim[match(snpsWREF, openBim[,2]),]
  short_list_refAlleles_pos <- list_refAlleles$pos[match(tmp_openBIM[,4], list_refAlleles$pos)]
  short_list_refAlleles_refAllele <- list_refAlleles$refAllele[match(tmp_openBIM[,4], list_refAlleles$pos)]
  
  listSNPsToSwap <- snpsWREF[unlist(lapply(1:length(snpsWREF), function(snp) { which(short_list_refAlleles_refAllele[snp] == tmp_openBIM[snp,c(5,6)]) } )) == 1]
}

