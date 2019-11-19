#!/bin/bash

##################### RE-WRITE
##
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do qsub plink_compute_pca.bash <chrX> <name of the individual file> <sufix for the output>
## done
#####################


#setting the sart of the job
res1=$(date +%s.%N)

module load vcftools plink

chrID=$1
samplesTOKeepFile=$2
sufOutput=$3
minMAF=true
wkingDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel"
inputFolder="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel/vcf_ancestral"
outputFolder="${wkingDir}/plink/pca"
prefixName="20180323.FRENCHWGS.REF0002"
#sufixName="onlysnps.downsampled"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90"

if [ ! -d "${wkingDir}/plink" ]; 
    then
        mkdir ${wkingDir}/plink
fi

if [ ! -d "${wkingDir}/plink/pca" ]; 
    then
        mkdir ${wkingDir}/plink/pca
fi


##############################
### Exclude sites MAF <0.1 ###
##############################
if [ "$minMAF" == true ]; 
then
    if [ "$chrID" == "chr6" ]; #Zabaneh et al 2016 Scientific reports
    then

        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.maxmaf.01.$sufOutput

        vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz \
        --bed /sandbox/users/alves-i/chr6_excludeWindow.txt --recode --stdout | vcftools --gzvcf - \
        --max-maf 0.10 --maf 0.01 --recode --stdout | vcftools --gzvcf - --keep ${wkingDir}/plink/$samplesTOKeepFile --recode --out ${inputFolder}/${outputFile}
    else 
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.maxmaf.01.$sufOutput

        vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz \
        --max-maf 0.10 --maf 0.01 --recode --stdout | vcftools --gzvcf - --keep ${wkingDir}/plink/$samplesTOKeepFile \
        --recode --out ${inputFolder}/${outputFile}
    fi
else
    if [ "$chrID" == "chr6" ]; #Zabaneh et al 2016 Scientific reports
    then
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.$sufOutput

        vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz \
        --bed /sandbox/users/alves-i/chr6_excludeWindow.txt --recode --stdout | vcftools --gzvcf - \
        --maf 0.10 --recode --stdout | vcftools --gzvcf - \
        --keep ${wkingDir}/plink/$samplesTOKeepFile --recode --out ${inputFolder}/${outputFile}
    else 
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.$sufOutput

        vcftools --gzvcf ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz \
        --maf 0.10 --recode --stdout | vcftools --gzvcf - --keep ${wkingDir}/plink/$samplesTOKeepFile \
        --recode --out ${inputFolder}/${outputFile}
    fi
fi 
##########################
### Convert VCF to BED ###
##########################
plink --vcf ${inputFolder}/${outputFile}.recode.vcf --vcf-filter --make-bed --out ${outputFolder}/${outputFile}

##################################
### Replace "." with CHROM:POS ###
##################################
cat ${outputFolder}/${outputFile}.bim | awk '{if($2 =="."){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/${outputFile}.bis.bim
mv ${outputFolder}/${outputFile}.bis.bim ${outputFolder}/${outputFile}.bim

#######################
### Quality control ###
#######################
# Hardy-Weinberg equilibrum at 1e-04, --bfile to specify that the input data are in binary format
# Réduction aux SNP indépendants en deux étapes (LD pruning)
plink --bfile ${outputFolder}/${outputFile} --indep-pairwise 50 5 0.5 --out ${outputFolder}/plink.$chrID
plink --bfile ${outputFolder}/${outputFile} --extract ${outputFolder}/plink.$chrID.prune.in --make-bed --out ${outputFolder}/${outputFile}.pruned
#plink --bfile ${outputFolder}/${outputFile}.pruned --r2 --ld-window 10 --ld-window-kb 10000 --ld-window-r2 0.5 --out ${outputFolder}/ld.$chrID



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
