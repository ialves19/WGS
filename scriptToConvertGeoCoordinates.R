#######################
## Transform geo coordinates in degrees, min and secs 
## in decimal degrees 
## the input file needs to have in column 1, column 2 and column 3: Region names, longuitude, latitude
## The input file needs to be tab separated and latitude is assumed to be always in the north hemisphere
#######################

##############
##
## Functions
##
##############
transform_long <- function(x) {

  #x <- m_coord[7,2]
  v_coord <- as.numeric(unlist(strsplit(as.character(x), split="\\,"))[1:3])
  east_west <- unlist(strsplit(as.character(x), split="\\,"))[4]
  
  decimals <- v_coord[1]+v_coord[2]/60+v_coord[3]/3600
  
  if (east_west == "O") {
    
    decimals <- -decimals
  }
  return(decimals)
}

transform_lat <- function(x) {
  
  #x <- m_coord[1,2]
  v_coord <- as.numeric(unlist(strsplit(as.character(x), split="\\,"))[1:3])
  decimals <- v_coord[1]+v_coord[2]/60+v_coord[3]/3600
  
  return(decimals)
}
###---------------
##--------
#-----

##################
##
## Main function
##
##################
library(geosphere)
m_coord <- read.table("/home/isabelalves/Dropbox/instDuThorax/samples/coordinates/regions_ALL_readyR.txt", header=F, sep = "\t")

v_long <- unlist(lapply(m_coord[,2], FUN = transform_long))
v_lat <- unlist(lapply(m_coord[,3], FUN = transform_lat))

new_Coord_df <- as.data.frame(cbind(as.character(m_coord[,1]), v_lat, v_long))

lat <- as.numeric(as.character(new_Coord_df[,2]))
log <- as.numeric(as.character(new_Coord_df[,3]))

#spDistsN1(matrix(cbind(log[1:2],lat[1:2]), ncol = 2, byrow = F), pt =c(-1.68222222222222,47.3613888888889) ,longlat = F)
distances_l <- list()

for (pop in new_Coord_df[,1]) {
  
  distances_l[[pop]] <- unlist(lapply(which(new_Coord_df[,1] != pop), function(x) { 
    
    coord_FocusPop <- as.numeric(as.character(unlist(new_Coord_df[which(new_Coord_df[,1] == pop),3:2])))
    dist_A_B <- distm(coord_FocusPop, as.numeric(as.character(unlist(new_Coord_df[x,3:2]))), fun = distHaversine)/1000
    
  }))
  
}
  
distances_total_l <-lapply(names(distances_l), function(x) { 
  
  tmp <- rep(0, length(distances_l[[x]])) 
  tmp[which(names(distances_l) != x)] <- distances_l[[x]]
  tmp[which(names(distances_l) == x)] <- 0
  return(tmp)
    })

distances_total_m <- do.call(rbind,distances_total_l)
colnames(distances_total_m) <- names(distances_l)

write.table(distances_total_m, file="/home/isabelalves/Dropbox/instDuThorax/samples/dist_m_ALLreg.txt", row.names = F, col.names = T, 
            quote = F, sep = "\t")





















