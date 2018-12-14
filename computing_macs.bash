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
## for i in `seq 1 22`; do qsub computing_macs.bash chrX mac
## done
## z : is the specific mac
## 
#####################

#setting the sart of the job
res1=$(date +%s.%N)

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/commun/data/users/abihouee/miniconda3/pkgs/libgcc-4.8.5-1/lib

r_scriptName="computing_discordant_REF_ANC.R"
chmod +x ${HOME}/$r_scriptName

chrID=$1
macThreshold=$2
wkingDir="/mnt/beegfs/ialves"

if [ ! -d "${wkingDir}/rare_by_dist" ]; 
    then
        mkdir ${wkingDir}/rare_by_dist
fi


inputFolder="${wkingDir}/vcf_ancestral"
outFolder="${wkingDir}/rare_by_dist"
prefixName="20180323.FRENCHWGS.REF0002"
#sufixName="onlysnps.downsampled"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90"



/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz --max-missing 1 --mac ${macThreshold} --max-mac ${macThreshold} \
--recode --recode-INFO-all --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf - --get-INFO AA --out ${outFolder}/${prefixName}.$chrID.mac${macThreshold}

/commun/data/packages/R/R-3.1.1/bin/Rscript ${HOME}/$r_scriptName $chrID $macThreshold

for file in ${outFolder}/dist_groups/*.txt; 
do
        dist_tag=`echo $file | cut -d$'/' -f7 | sed 's/.*_\([0-9]*_[0-9]*\).txt/\1/'`
        echo $dist_tag
        /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz --max-missing 1 --mac ${macThreshold} --max-mac ${macThreshold} \
        --recode --recode-INFO-all --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf - --exclude-positions ${outFolder}/${prefixName}.$chrID.mac${macThreshold}.SNPsToRM \
        --recode --recode-INFO-all --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf - --keep $file --extract-FORMAT-info GT --out ${outFolder}/${prefixName}.$chrID.mac${macThreshold}.${dist_tag}
done



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