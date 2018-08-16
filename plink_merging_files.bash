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
## 
## 
## qsub plink_merging_files.bash chr1 relatedness/pca
## 
#####################


#setting the sart of the job
res1=$(date +%s.%N)

chrID=$1
methodType=$2

wkingDir="/mnt/beegfs/ialves"
inputFolder="/mnt/beegfs/ialves/vcf_ancestral"

if [ ! -d "${wkingDir}/plink" ]; 
    then
        mkdir ${wkingDir}/plink
fi

if [ "$methodType" == "relatedness" ]; 
    then

    if [ ! -d "${wkingDir}/relatedness" ]; 
        then
            mkdir ${wkingDir}/plink/relatedness
            outputFolder="${wkingDir}/plink/relatedness"
            echo "Mode: $methodType" 
    fi
elif [ "$methodType" == "pca" ];
    then 
    if [ ! -d "${wkingDir}/pca" ]; 
        then
            mkdir ${wkingDir}/plink/pca
            outputFolder="${wkingDir}/plink/pca"
            echo "Mode: $methodType" 
    fi
fi


prefixName="merged.WGS.1000G"
#sufixName="onlysnps.downsampled"
sufixName="PASS.FR.IBS.GBR.TSI"

for i in `seq 1 22`;
do
    fileName=`ls ${outputFolder}/*chr${i}.*.pruned.bis.bis.bed`
    echo $fileName
    prefixFName=`echo $fileName | sed 's/\(.*\).bed/\1/'`
    echo $prefixFName

    echo $prefixFName.bed$' '$prefixFName.bim$' '$prefixFName.fam >> ${outputFolder}/fileList_tmp.txt
done
sed '1d' ${outputFolder}/fileList_tmp.txt > ${outputFolder}/fileList.txt
rm ${outputFolder}/fileList_tmp.txt

##########################
### Merge all files    ###
##########################
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned --merge-list ${outputFolder}/fileList.txt \
--make-bed --keep-allele-order --out ${outputFolder}/${prefixName}.all

#rm ${outputFolder}/ld.chr*.*
#rm ${outputFolder}/plink.chr*.*
# rm ${outputFolder}/*hwe1e4.maxmiss.90.bed
# rm ${outputFolder}/*hwe1e4.maxmiss.90.bim
# rm ${outputFolder}/*hwe1e4.maxmiss.90.fam
# rm ${outputFolder}/*hwe1e4.maxmiss.90.log

if [ "${methodType}" == "relatedness" ];
    then
    ###########################
    ### IBS matrix creation ###
    ###########################
    # IBS summarizes if samples are related
    /commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.all --genome --out ${outputFolder}/matriceIBS
    cat ${outputFolder}/matriceIBS.genome | awk '$10 > 0.1' > ${outputFolder}/relatedSamples.txt

elif [ "${methodType}" == "pca" ]; 
    then

    cp ${outputFolder}/${prefixName}.all.fam ${outputFolder}/${prefixName}.all.pedind 
    #######################
    ### Create inputfile###
    #######################
    (
    echo "genotypename:  ${outputFolder}/${prefixName}.all.bed"
    echo "snpname:  ${outputFolder}/${prefixName}.all.bim"
    echo "indivname:  ${outputFolder}/${prefixName}.all.pedind" #(<--- which is the XXX.fam renamed)
    echo "evecoutname: ${outputFolder}/WGS.evec"
    echo "evaloutname: ${outputFolder}/WGS.eval"
    echo "deletesnpoutname: EIG_removed_SNPs"
    echo "numoutevec: 10"
    echo "fsthiprecision: YES"
    ) > ${outputFolder}/smarpca.WGS.txt

    #######################
    ### PCA ###
    #######################
    /commun/data/users/ialves/EIG-6.1.4/bin/smartpca -p ${outputFolder}/smarpca.WGS.txt > ${outputFolder}/logfile.txt

fi        

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