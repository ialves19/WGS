#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N col_$JOB_ID
#$ -o col_o_$JOB_ID
#$ -e col_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

#setting the sart of the job
res1=$(date +%s.%N)

#echo $HOME
inputFolder="/mnt/beegfs/ialves/rare_by_dist"

for file in alleleShar_chr*_mac{7..10}*; 
	do 
	echo $file; 
	sed -i '' -e '$a\' $file;
done

ARRAY=( "0_0" "0_100" "100_200" "200_300" "300_400" "400_500" "500_600" "600_700" "700_800" "800_900" "900_1000" )

for i in "${ARRAY[@]}"; 
	do
	echo $i; 
	for chr in `seq 1 22`; 
	do 
	file="alleleShar_chr${chr}_mac7_$i.txt"; 
	cat $file >> alleleShar_allChrom_mac6_$i.txt; 
	done; 
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