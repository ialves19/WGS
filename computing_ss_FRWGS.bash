#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N ss_$JOB_ID
#$ -o ss_o_$JOB_ID
#$ -e ss_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

##################### RE-WRITE
##
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do
## qsub computing_ss_FRWGS.bash ARG1 
## done
##
## eg ARG1 = chr21
#####################


#setting the sart of the job
res1=$(date +%s.%N)

wkingDir="/mnt/beegfs/ialves"

if [ ! -d "${wkingDir}/sumStats" ]; 
    then
        mkdir ${wkingDir}/sumStats
fi


outputFolder="${wkingDir}/sumStats"

prefixName="20180323.FRENCHWGS.REF0002"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90.recode.vcf.gz"
CHRID=$1

/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${wkingDir}/vcf_ancestral/${prefixName}.$CHRID.${sufixName} --het --out ${outputFolder}/${prefixName}.$CHRID
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${wkingDir}/vcf_ancestral/${prefixName}.$CHRID.${sufixName} --relatedness --out ${outputFolder}/${prefixName}.$CHRID
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${wkingDir}/vcf_ancestral/${prefixName}.$CHRID.${sufixName} --relatedness2 --out ${outputFolder}/${prefixName}.$CHRID
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf ${wkingDir}/vcf_ancestral/${prefixName}.$CHRID.${sufixName} --missing-indv --out ${outputFolder}/${prefixName}.$CHRID

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