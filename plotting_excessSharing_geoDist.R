#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

#######################
##
## FUNCTIONS
##
#######################
convert_REF_into_ANC <- function(x) {

  #x <- 1
  tmp_v <- l_transf_m[[flipPositions[x]]]
  new_tmp_v <- rep(0, length(tmp_v))
  new_tmp_v[which(tmp_v == 2)] <- 0
  new_tmp_v[which(tmp_v == 0)] <- 2
  return(new_tmp_v)
}
##-------------
#------


folderName <- "/mnt/beegfs/ialves/rare_by_dist"

# mac <- 2
# distKm <- "0_0"
# totalSampleSize <- 853
# chr <- "chr21"

chr <- args[1]
mac <- args[2]
distKm <- args[3]
totalSampleSize <- 853


#open genotypes matrix
dist_m <- read.table(paste0(folderName, "/20180323.FRENCHWGS.REF0002.", chr, ".mac", mac, ".", distKm, ".GT.FORMAT"), header = T, sep = "\t")
geo_dist_pw <- scan(paste0(folderName, "/dist_groups/dist_", distKm, "_pairwise.txt"), what = character())

#opening file with sites to remove, which are the ones for which the ANC is neither the REF nor the ALT
sites_to_remove <- read.table(paste0(folderName, "/20180323.FRENCHWGS.REF0002.", chr,".mac", mac, ".SNPsToRM"), header = F, sep = "\t")
#opening file with the sites for which the ANC is the ALT.
ref_alt_tbl <- read.table(paste0(folderName, "/20180323.FRENCHWGS.REF0002.", chr, ".mac", mac, ".ANCisALT"), header = F, sep = "\t")
# get the index of positions to flip
flipPositions <- match(ref_alt_tbl[,2], dist_m[,2])

#Remove sites in sites_to_remove
tmp_m <- dist_m

# summing minor alleles 1/1 -> 2
l_transf_m <- lapply(1:nrow(tmp_m), function(x) {
  m <- apply(matrix(as.numeric(unlist(strsplit(as.matrix(tmp_m[x, 3:ncol(tmp_m)]), split="/"))),ncol=2, byrow = T), 1,sum) })

# converting genotypes for which ANC is the ALT
transf_ref_anc <- lapply(1:length(flipPositions), convert_REF_into_ANC)
l_transf_m[flipPositions] <- transf_ref_anc

#merge genotype list in a matrix
m_transf_m <- do.call("rbind",l_transf_m)
new_GenoMatrix <- cbind(dist_m[,1:2], m_transf_m)
colnames(new_GenoMatrix) <- colnames(dist_m)
#get the nb of individuals within a given distance
nb_Ind_wi_dist <- ncol(new_GenoMatrix)-2


#computing allele frequencies
allele_freq <- apply(new_GenoMatrix[,3:ncol(new_GenoMatrix)], 1, sum, na.rm=T)
#keeping all the real derived mac = X
new_GenoMatrix <- new_GenoMatrix[which(allele_freq <= mac),]
nb_SNVs_mac <- nrow(new_GenoMatrix)
#computing allele frequencies
new_allele_freq <- apply(new_GenoMatrix[,3:ncol(new_GenoMatrix)], 1, sum, na.rm=T)

sharedSites_withDis <- lapply(1:nrow(new_GenoMatrix[which(new_allele_freq > 1),3:ncol(new_GenoMatrix)]), function(l) {
  
  print(l)
  #get the individuals' labels of indivs carrying the shared allele
  indLabels <- colnames(new_GenoMatrix)[which(new_GenoMatrix[which(new_allele_freq > 1),3:ncol(new_GenoMatrix)][l,] >= 1)+2] #changed to >= 1, Oct 16 to accomodate individuals that are homoz derived

  if (length(indLabels) > 1) { #>1 because we want to keep only those sites for which there are at least two inds
    indPairs <- unlist(lapply(1:ncol(combn(length(indLabels),2)), function(c) { paste(indLabels[combn(length(indLabels),2)[1,c]], indLabels[combn(length(indLabels),2)[2,c]], sep=":")  })  )
    indPair_wi_disBin <- intersect(geo_dist_pw, indPairs)
    if (length(indPair_wi_disBin) ==0) {
      
      indPair_wi_disBin <- NULL
    }
    
  } else {
      indPair_wi_disBin <- NULL
  }

  return(indPair_wi_disBin)
  
} )

# fileNames <- list.files(folderName, pattern = "*.txt", full.names = TRUE)
# listChr_alleleShar <- list()

# COUNT <- 1
# for (file in fileNames) {

#   listChr_alleleShar[[COUNT]] <- scan(file, what = numeric())  
#   COUNT <- COUNT+1
# }

# chr_allShar_tbl <- do.call(rbind, listChr_alleleShar)
v_sharedSites_withinDist <- unlist(lapply(sharedSites_withDis, FUN=length))

alleleSharExc <- lapply(1:length(v_sharedSites_withinDist[v_sharedSites_withinDist > 0]), function(k) {  t <- v_sharedSites_withinDist[v_sharedSites_withinDist > 0][k]/(ncol(combn(mac,2))*(length(geo_dist_pw)/ncol(combn(totalSampleSize,2))))  })
aveAlleleShar <- sum(unlist(alleleSharExc))/nrow(new_GenoMatrix)

cat(sum(unlist(alleleSharExc)), nrow(new_GenoMatrix), sep = "\t", file = paste0(folderName, "/alleleShar_", chr, "_mac", mac, "_", distKm, ".txt"))
  




















