#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N pca_$JOB_ID
#$ -o pca_o_$JOB_ID
#$ -e pca_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

##################### RE-WRITE
##
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do cp pipe_compute_afreq.bash pipe_compute_afreq.chr$i.bash;
## sed -i s/CHRID/$i/ pipe_compute_f2.chr$i.bash;
## qsub pipe_compute_f2.chr$i.bash; ARG1 ARG2
## done
#####################


#setting the sart of the job
res1=$(date +%s.%N)

chrID=$1
wkingDir="/mnt/beegfs/ialves"
inputFolder="/mnt/beegfs/ialves/vcf_ancestral"

if [ ! -d "${wkingDir}/plink" ]; 
    then
        mkdir ${wkingDir}/plink
fi

if [ ! -d "${wkingDir}/pca" ]; 
    then
        mkdir ${wkingDir}/plink/pca
fi


outputFolder="${wkingDir}/plink/pca"

prefixName="20180323.FRENCHWGS.REF0002"
#sufixName="onlysnps.downsampled"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90"

##############################
### Exclude sites MAF <0.1 ###
##############################
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf \
--keep ${wkingDir}/plink/indvs_to_keep.txt --recode --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf - --maf 0.05 \
--recode --out ${inputFolder}/${prefixName}.$chrID.${sufixName}.subset25.maf0.05


##########################
### Convert VCF to BED ###
##########################
/commun/data/packages/plink/plink-1.9.0/plink --vcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.subset25.maf0.05.recode.vcf --vcf-filter \
--make-bed --out ${outputFolder}/${prefixName}.$chrID.${sufixName}

##################################
### Replace "." with CHROM:POS ###
##################################
cat ${outputFolder}/${prefixName}.$chrID.${sufixName}.bim | awk '{if($2 =="."){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/${prefixName}.$chrID.${sufixName}.bis.bim
mv ${outputFolder}/${prefixName}.$chrID.${sufixName}.bis.bim ${outputFolder}/${prefixName}.$chrID.${sufixName}.bim

#######################
### Quality control ###
#######################
# Hardy-Weinberg equilibrum at 1e-04, --bfile to specify that the input data are in binary format
# Réduction aux SNP indépendants en deux étapes (LD pruning)
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --indep-pairwise 50 5 0.5 --out ${outputFolder}/plink.$chrID
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --extract ${outputFolder}/plink.$chrID.prune.in --make-bed --out ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --r2 --ld-window 500 --ld-window-kb 10000 --ld-window-r2 0.5 --out ${outputFolder}/ld.$chrID



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
