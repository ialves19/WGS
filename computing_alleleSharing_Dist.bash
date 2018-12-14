#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N alS_$JOB_ID
#$ -o alS_o_$JOB_ID
#$ -e alS_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

##################### RE-WRITE
##
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do qsub computing_alleleSharing_Dist.bash chrID mac distInKms
## done
#####################


#setting the sart of the job
res1=$(date +%s.%N)

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/commun/data/users/abihouee/miniconda3/pkgs/libgcc-4.8.5-1/lib

r_scriptName="plotting_excessSharing_geoDist.R"
chmod +x ${HOME}/$r_scriptName

chrID=$1
macThreshold=$2
distKm=$3
wkingDir="/mnt/beegfs/ialves"

if [ ! -d "${wkingDir}/rare_by_dist" ]; 
    then
        mkdir ${wkingDir}/rare_by_dist
fi


/commun/data/packages/R/R-3.1.1/bin/Rscript ${HOME}/$r_scriptName $chrID $macThreshold $distKm

#timing the job
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

echo "Total runtime: $dd days $dh hrs $dm min $ds secs"