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

chrID=$1
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

for i in `seq 1 22`;
do
    fileName=`ls ${outputFolder}/*chr${i}.*.pruned.bed`
    echo $fileName
    prefixFName=`echo $fileName | sed 's/\(.*\).bed/\1/'`
    echo $prefixFName

    echo $prefixFName.bed$' '$prefixFName.bim$' '$prefixFName.fam >> ${wkingDir}/plink/relatedness/fileList_tmp.txt
done
sed '1d' ${wkingDir}/plink/relatedness/fileList_tmp.txt >> ${wkingDir}/plink/relatedness/fileList.txt
rm ${wkingDir}/plink/relatedness/fileList_tmp.txt

##########################
### Merge all files    ###
##########################
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --merge-list ${wkingDir}/plink/relatedness/fileList.txt \
--make-bed --out ${outputFolder}/${prefixName}.all

rm ${outputFolder}/ld.chr*.*
rm ${outputFolder}/plink.chr*.*
rm ${outputFolder}/*hwe1e4.maxmiss.90.bed
rm ${outputFolder}/*hwe1e4.maxmiss.90.bim
rm ${outputFolder}/*hwe1e4.maxmiss.90.fam
rm ${outputFolder}/*hwe1e4.maxmiss.90.log

###########################
### IBS matrix creation ###
###########################
# IBS summarizes if samples are related
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --genome --out ${outputFolder}/matriceIBS
cat ${outputFolder}/matriceIBS.genome | awk '$10 > 0.1' > ${outputFolder}/relatedSamples.txt

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