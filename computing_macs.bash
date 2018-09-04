#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N dg_$JOB_ID
#$ -o dg_o_$JOB_ID
#$ -e dg_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

##################### 
##
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do qsub computing_macs.bash chrX Z
## done
## z : is the specific mac
## 
#####################

#setting the sart of the job
res1=$(date +%s.%N)

chrID=$1
macThreshold=$2
wkingDir="/mnt/beegfs/ialves"

if [ ! -d "${wkingDir}/rare_by_dist" ]; 
    then
        mkdir ${wkingDir}/rare_by_dist
fi


inputFolder="${wkingDir}/1000G"
outFolder="${wkingDir}/rare_by_dist"
prefixName="merged.WGS.1000G"
#sufixName="onlysnps.downsampled"
sufixName="PASS.FR.IBS.GBR.TSI"



commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf --mac ${macThreshold} --max-mac ${macThreshold} \
--get-INFO GT --out ${outFolder}/FR.1000G.$chrID.mac${macThreshold}


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