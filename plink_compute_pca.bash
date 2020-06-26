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

module load bcftools plink

chrID=$1
samplesTOKeepFile=$2
sufOutput=$3
# comment below
chrID="chr6"
samplesTOKeepFile="indvs_to_keep.txt"
sufOutput="201119"
##---

minMAF=false
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

        echo "Filtering for maf between .01 and .10 "
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.01.maxmaf.10.$sufOutput

        bcftools view -Ou -S ${wkingDir}/plink/$samplesTOKeepFile ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz chr6:1-29691116 chr6:33054976-171115067 | \
        bcftools view -Ov -q 0.01[:minor] -Q 0.10[:minor] -o ${inputFolder}/${outputFile}.vcf
    else 
        echo "Filtering for maf between .01 and .10 "
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.01.maxmaf.10.$sufOutput

        bcftools view -Ou -S ${wkingDir}/plink/$samplesTOKeepFile ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz | \
        bcftools view -Ov -q 0.01[:minor] -Q 0.10[:minor] -o ${inputFolder}/${outputFile}.vcf
    fi
else
    if [ "$chrID" == "chr6" ]; #Zabaneh et al 2016 Scientific reports
    then
        echo "Filtering for maf > .10"
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.$sufOutput

        bcftools view -Ou -S ${wkingDir}/plink/$samplesTOKeepFile ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz chr6:1-29691116 chr6:33054976-171115067 | \
        bcftools view -Ov -q 0.10[:minor] -o ${inputFolder}/${outputFile}.vcf
    else 
        echo "Filtering for maf > .10"
        prefTmp=`echo $prefixName | cut -d$'.' -f2`
        outputFile=$prefTmp.$chrID.maf.10.$sufOutput

        bcftools view -Ou -S ${wkingDir}/plink/$samplesTOKeepFile ${inputFolder}/${prefixName}.$chrID.${sufixName}.recode.vcf.gz | \
        bcftools view -Ov -q 0.10[:minor] -o ${inputFolder}/${outputFile}.vcf

    fi
fi 
##########################
### Convert VCF to BED ###
##########################
plink --vcf ${inputFolder}/${outputFile}.vcf --vcf-filter --make-bed --out ${outputFolder}/${outputFile}

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
