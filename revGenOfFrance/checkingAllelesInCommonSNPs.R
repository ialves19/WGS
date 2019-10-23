args <- commandArgs(trailingOnly = TRUE)

#########################
##
## Checking if PoBI alleles are 
## in TOP configuration and converts 
## in positive strand those that are in -
##
########################

## reverse a string
revString <- function(text){
  paste(rev(unlist(strsplit(text,NULL))),collapse="")
}
###

PoBI_dir <- args[1]
MSfile <- args[2]
PSfile <- args[3]

PoBI_dir <- "/home/ialves/Dropbox/jobRelated_Isabel/MyPapers/GenetHistofFRANCE/Revisions_1stRound/MS"
MSfile <- "MS.allCHROM.EUR.bim"
PSfile <- "PS.allCHROM.IRE.bim"


openMS <- read.table(paste0(PoBI_dir, "/", MSfile), header = F)
openPS <- read.table(paste0(PoBI_dir, "/", PSfile), header = F) 
print(paste0("Number of SNPs in ", MSfile, ": ", nrow(openMS)))
print(paste0("Number of SNPs in ", PSfile, ": ", nrow(openPS)))

interSNPs <- intersect(as.vector(openMS[,2]), as.vector(openPS[,2]))
paste0("There are: ", length(interSNPs), " common SNPs.")

allelesDS1 <- paste0(openMS[match(interSNPs, as.vector(openMS[,2])),5],openMS[match(interSNPs, as.vector(openMS[,2])),6])
allelesDS2 <- paste0(openPS[match(interSNPs, as.vector(openPS[,2])),5],openPS[match(interSNPs, as.vector(openPS[,2])),6])

if (sum(allelesDS1 == allelesDS2) != length(interSNPs)) {
  
  print(paste0("Warning: Some SNPs do not contain the same alleles."))
  rsIDnotMatching <- matrix(interSNPs[allelesDS1 != allelesDS2], ncol = 1)
  write.table(rsIDnotMatching, file=paste0(PoBI_dir, "/SNPswithNotMatchAlleles.txt"), quote = F, row.names = F, col.names = F)
  revAllelesDS1 <- allelesDS1
  revAllelesDS1 <- as.vector(sapply(allelesDS1[allelesDS1 != allelesDS2], function(st) {revString(st)}))
  if (sum(revAllelesDS1 == allelesDS2) != length(interSNPs) ) {
    print("")
    print(paste0("Warning: Some SNPs do not contain the same alleles EVEN AFTER FLIPPING."))
  }
  
} else {
  
   print("All the SNPs have the same alleles.")
  
}

revString("AT")

tmp <- c("AT", "GC", "TA", "GT", "AG")

