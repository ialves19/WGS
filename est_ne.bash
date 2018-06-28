#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N e_ne
#$ -o e_ne_o_CHRID
#$ -e e_ne_e_CHRID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

#setting the sart of the job
res1=$(date +%s.%N)

#echo $HOME
inputFolder="/mnt/beegfs/ialves"
outputFolder="/mnt/beegfs/ialves"
geneticMapFolder="/mnt/beegfs/genetic_map"
scriptsFolder="/commun/data/users/ialves/fs-2.1.3/scripts"

echo "Working folder: $inputFolder"
echo ""
echo "Output folder: $outputFolder"
echo ""

prefix="20180323.FRENCHWGS.REF0002.mac2"
sufix="onlysnps.MQ.30.mapRmved.hwe1e4.maxmiss.90.recode.vcf"

for chrID in 4 10 15 22; do 
	
	echo ${outputFolder}/chromoFiles/${prefix}.chr$chrID.phased.chromopainter.recomrates$'\t'${outputFolder}/chromoOut/${prefix}.chr$chrID.EMprobs.out >> ${outputFolder}/chromoOut/fileList_ne.txt
done

perl /commun/data/users/ialves/fs-2.1.3/scripts/neaverage.pl -o ${outputFolder}/chromoOut/neest.txt -l ${outputFolder}/chromoOut/fileList_ne.txt



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
