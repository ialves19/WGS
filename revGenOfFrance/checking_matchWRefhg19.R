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

# PoBI_dir <- "/home/ialves/Dropbox/jobRelated_Isabel/MyPapers/GenetHistofFRANCE/Revisions_1stRound/PoBI"
# bimFile <- "WTCCC2_POBI_illumina_calls_POBI_21_illumina_rec_strand_hwe1e-5_noDup.bim"
# refAlleles <- "example.refAlleles.txt"
# chrID <- 21

openBim <- read.table(file=paste0(PoBI_dir, "/", bimFile), header = F)

list_refAlleles <- scan(file=paste0(PoBI_dir, "/", refAlleles), what = list(pos="", refAllele=""), flush = T, skip = 0)
list_refAlleles$pos <- unlist(lapply(strsplit(unlist(lapply(strsplit(list_refAlleles$pos, split=":"), function(x) { x[2] })), split = "-"), function(y) { y[2] }))

listMissMatchSites <- unlist(lapply(1:length(list_refAlleles$pos), function(k) { 
  is.element(list_refAlleles$refAllele[k], as.character(unlist(openBim[match(list_refAlleles$pos[k], as.character(unlist(openBim[4]))),c(5,6)]))) })
)

rs_m <- matrix(openBim[match(list_refAlleles$pos, as.character(unlist(openBim[4])))[listMissMatchSites],2])
write.table(rs_m, file=paste0(PoBI_dir, "/rsIds_toExclude_chr", chrID, ".keep"),  quote = F, row.names = F, col.names = F)


