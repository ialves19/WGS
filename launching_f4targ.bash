#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N f4_$JOB_ID
#$ -o f4_o_$JOB_ID
#$ -e f4_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr


#setting the sart of the job
res1=$(date +%s.%N)

###################
##
## This script should be launched within a for loop across all the input files in.*par
## which is passed as arg 1
## $2 and $3 are the input and output folders within the f4stats folder
##
###################

wkingDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel"
input=$1
tmpFolderIn=$2
tmpFolderOut=$3

popComb=`echo $input | sed 's/in.f4stats.\(.*\).par/\1/'`
echo "Running f4stats: $popComb";

/sandbox/users/alves-i/AdmixTools/bin/qpDstat -p ${wkingDir}/HumanOrigins/f4stats/${tmpFolderIn}/${input} > ${wkingDir}/HumanOrigins/f4stats/${tmpFolderOut}/out_f4test_${popComb}.log

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
