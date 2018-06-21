#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N c_CHRID
#$ -o c_o_CHRID
#$ -e c_e_CHRID
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

chrID=$1

/commun/data/users/ialves/Chromopainter/ChromoPainterv2 -g ${outputFolder}/chromoFiles/$prefix.$chrID.phased.chromopainter.haps \
-r ${outputFolder}/chromoFiles/$prefix.$chrID.phased.chromopainter.recomrates -t ${outputFolder}/WGS_france.ids \
-f ${outputFolder}/population.list 0 0 -i 10 -in -iM -a 0 0 -o ${outputFolder}/chromoOut/$prefix.$chrID



 
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