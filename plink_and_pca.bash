#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N pca_CHRID
#$ -o pca_o_CHRID
#$ -e pca_e_CHRID
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

outputFolder="${wkingDir}/plink"
prefixName="20180323.FRENCHWGS.REF0002"
#sufixName="onlysnps.downsampled"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90"

#########################
### Downsample global vcf
#########################
#/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/$1 --keep ${inputFolder}/downsample.txt --recode-INFO-all \
#--stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf - --mac 2 --recode-INFO-all --out ${outputFolder}/${prefixName}.$chrID.${sufixName}


##########################
### Convert VCF to BED ###
##########################
/commun/data/packages/plink/plink-1.9.0/plink --vcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf --vcf-filter --make-bed --out ${outputFolder}/${prefixName}.$chrID.${sufixName}
# --vcf-filter to skip variants which failed one or more filters tracked by the FILTER field
# The BED files are encoded in binary format


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
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --indep 50 5 2 --out ${outputFolder}/plink
# plink.log plink.prune.out plink.nosex plink.prune.in created after this command 

/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --extract ${outputFolder}/plink.prune.in --make-bed --out ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --r2 --ld-window 50 --ld-window-kb 10000 --ld-window-r2 0.5 --out ${outputFolder}/ld
# no SNPs to remove in second stage ! if the file is not empty, then
cat ${outputFolder}/ld.ld | tr -s " " | cut -d " " -f4 > ${outputFolder}/snp2remove.txt
# and plink option --exclude snp2remove.txt
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --exclude ${outputFolder}/snp2remove.txt --make-bed --out ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned.clean
###########################
### IBS matrix creation ###
###########################
# IBS summarizes if samples are related
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned.clean --genome --out ${outputFolder}/matriceIBS
cat matriceIBS.genome | awk '$10 > 0.1' > echantAPP.txt
# from echantAPP.txt, you have to choose sample from each pair for removal (they are too closely related)
#cat echantAPP.txt | tr -s ' ' | sed -e 's/ /\t/g' | cut -d$'\t' -f2-14 
#################################################
### Remove related individuals or bad quality ###
#################################################
#/commun/data/packages/plink/plink-1.9.0/plink --bfile 20180226.miniACP_pruned_noBRS --remove ind2remove.txt --make-bed --out 20180226.miniACP_pruned_unrelated
# to remove samples, use option --remove with a text file with their IDs
# output of the above is almost ready for smartpca

# you may want to change .fam, for example in R, to replace 6th column with population labels, and save file with a suffix .pedind 
#cp 20180226.miniACP_pruned_unrelated.fam data.pedind


##########################
### PCA using smartpca ###
##########################
#module load eigensoft
#smartpca -p EIG_parfile_France.txt > logfile.txt
# Files created : WGS.eval, WGS.evec and logfile.txt