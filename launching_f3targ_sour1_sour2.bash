#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N convPed_$JOB_ID
#$ -o convPed_o_$JOB_ID
#$ -e convPed_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr


#setting the sart of the job
res1=$(date +%s.%N)

wkingDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel"
pop=$1

/sandbox/users/alves-i/AdmixTools/bin/qp3Pop -p ${wkingDir}/HumanOrigins/f3stats/inFiles_Feb15/par.f3testTarg_${pop}_sour1_sour2.par > {wkingDir}/HumanOrigins/f3stats/outF_Feb15/out_f3test_${pop}.log

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
