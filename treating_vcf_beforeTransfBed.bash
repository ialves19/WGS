#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N convPed_$JOB_ID
#$ -o convPed_o_$JOB_ID
#$ -e convPed_e_$JOB_ID
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

wkingDir="/mnt/beegfs/ialves"

if [ ! -d "${wkingDir}/HumanOrigins/plink" ]; 
    then
        mkdir ${wkingDir}/HumanOrigins/plink
fi


outputFolder="${wkingDir}/HumanOrigins/plink"

prefixName="20181108.ISABELLRECAL.vcf"
pedFileName="FR_WGs_calledHOA"


declare -a LINENUMBER; COUNT=0; 
while IFS='' read -r line || [[ -n "$line" ]]; 
do 
chr=`echo $line | cut -d$' ' -f2`; 
pos=`echo $line | cut -d$' ' -f3`; 
LINENUMBER[$COUNT]=`grep -n $chr$'\t'$pos 20181108.ISABELLRECAL.vcf | cut -d$'\t' -f1 | cut -d$':' -f1 | sed -n 2p`; 
echo ${LINENUMBER[$COUNT]}; 
((COUNT++)); 
done < indels.txt


sed -e ${string}d  20181108.ISABELLRECAL.vcf > 20181108.ISABELLRECAL.snps.vcf 
wc -l 20181108.ISABELLRECAL.snps.vcf 

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
