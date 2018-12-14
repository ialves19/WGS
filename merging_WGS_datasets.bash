#$ -S /bin/bash
#$ -cwd
#$ -N m1k_$JOB_ID
#$ -o m1k_o_$JOB_ID
#$ -e m1k_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr



#setting the sart of the job
res1=$(date +%s.%N)

################################
##
## this script takes the vcf (.GZ) file with the FR samples as an argument $1
## and detects from the file name, provided as arg, the chr it needs to look 
## for among the 1000G files.
## it also needs a file with all the FR and 1000G samples we want to keep in the vcf
##
## it merges the vcf with the FR samples and the 1000G only for the shared/all sites
## depending we setup the keepCommon= TRUE/FALSE respectively. 
##
## To launch it qsub merging_WGS_1000G.bash french_WGS.vcf
## NOTE: DO NOT ADD THE .gz to the input file.
##
## Oct 2018
###############################

inputFolder="/sandbox/shares/mages/GoNL1"

rawVcfFile=$1
keepCommon=true
sufixTag="allSites.v2"

module load bcftools
module load vcftools


if [ ! -d "${inputFolder}/clean" ]; 
	then
	mkdir ${inputFolder}/clean
fi

chrID=`echo $rawVcfFile | sed 's/.*\(chr[0-9]*\).*/\1/'`
chrNb=`echo $rawVcfFile | sed 's/.*chr\([0-9]*\).*/\1/'`
prefix=`echo $rawVcfFile | cut -d$'_' -f1`

echo "Merging chromosome: $chrID"

#keep biallelic sites in the 1000G vcf & keeping only GBR, IBS and TSU & replacing chr tag and zipping
bcftools view -m2 -M2 -v snps -f PASS ${inputFolder}/release5.4/SNVs/${rawVcfFile} -Ou | bcftools view -S ${inputFolder}/goNL_samples_children.txt -Ou \
| bcftools view -c1 -O v | sed s/^$chrNb/$chrID/g | bcftools view -Oz -o ${inputFolder}/clean/${prefix}.sampled.clean.${chrID}.vcf.gz
# indexing files
bcftools index -t ${inputFolder}/clean/${prefix}.sampled.clean.${chrID}.vcf.gz

bcftools view -R /sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel/accessGenome/accessGen_${chrID}.txt -Oz -o ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.${chrID}.vcf.gz ${inputFolder}/clean/${prefix}.sampled.clean.${chrID}.vcf.gz
# indexing files
bcftools index -t ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.${chrID}.vcf.gz

rm ${inputFolder}/clean/${prefix}.sampled.clean.${chrID}.vcf.gz*

vcftools --gzvcf ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.${chrID}.vcf.gz --max-missing 0.90 --hwe 0.0001 --recode --stdout \
| bcftools view -Oz -o ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz
# indexing files
bcftools index -t ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz

rm ${inputFolder}/clean/${prefix}.sampled.clean.acceGen.${chrID}.vcf.gz*



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
