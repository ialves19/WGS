#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N m_$JOB_ID
#$ -o m_o_$JOB_ID
#$ -e m_e_$JOB_ID
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
inputFolder="/mnt/beegfs/ialves/vcf_ancestral"

if [ ! -d "${wkingDir}/plink" ]; 
    then
        mkdir ${wkingDir}/plink
fi

if [ ! -d "${wkingDir}/relatedness" ]; 
    then
        mkdir ${wkingDir}/plink/relatedness
fi


outputFolder="${wkingDir}/plink/relatedness"

prefixName="20180323.FRENCHWGS.REF0002"
#sufixName="onlysnps.downsampled"
sufixName="onlysnps.MQ.30.mapRmved.AA.hwe1e4.maxmiss.90"

for file in ${wkingDir}/plink/relatedness/*.bed;
do
    fileName=`echo $file | sed s/.*.bed/\1/`

    echo $fileName.bed$' '$fileName.bim$' '$fileName.fam >> ${wkingDir}/plink/relatedness/fileList.txt
done

##########################
### Merge all files    ###
##########################
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --merge-list ${wkingDir}/plink/relatedness/fileList.txt \
--make-bed --out ${outputFolder}/${prefixName}.all

##################################
### Replace "." with CHROM:POS ###
##################################
cat ${outputFolder}/${outputFolder}/${prefixName}.all.bim | awk '{if($2 =="."){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/${prefixName}.all.bis.bim
mv ${outputFolder}/${prefixName}.all.bis.bim ${outputFolder}/${prefixName}.all.bim




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