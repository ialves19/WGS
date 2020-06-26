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
## qsub plink_merging_files.bash <input file no EXT> relatedness/pca wkdir inputDir
## 
#####################


#setting the sart of the job
res1=$(date +%s.%N)

module load plink

inFile=$1
methodType=$2
wkingDir=$3
inputFolder=$4

inFile="FRENCHWGS.chr6.maf.10.201119.pruned"
methodType="pca"
wkingDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel"
inputFolder="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel/plink/pca"

chrID=`echo $inFile | sed 's/.*\([chr]\{3\}[0-9]\{1,2\}\).*/\1/'`
prefixName=`echo $inFile | sed -e "s/^\(.*\)\.$chrID.*/\1/"`
#sufixName="onlysnps.downsampled"
sufixName=`echo $inFile | sed -e "s/.*.$chrID.\(.*\)/\1/"`


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
        else
            outputFolder="${wkingDir}/plink/relatedness"
            echo "Mode: $methodType" 
    fi
elif [ "$methodType" == "pca" ];
    then 
    if [ ! -d "${wkingDir}/plink/pca" ]; 
        then
            mkdir ${wkingDir}/plink/pca
            outputFolder="${wkingDir}/plink/pca"
            echo "Mode: $methodType" 
    else 
            outputFolder="${wkingDir}/plink/pca"
            echo "Mode: $methodType"    
    fi
fi


for i in `seq 1 22`;
do
    fileName=`ls ${outputFolder}/${prefixName}.chr${i}.${sufixName}.bed`
    #echo $fileName
    prefixFName=`echo $fileName | sed 's/\(.*\).bed/\1/'`
    echo $prefixFName

    echo $prefixFName.bed$' '$prefixFName.bim$' '$prefixFName.fam >> ${outputFolder}/fileList_tmp.txt
done
sed '1d' ${outputFolder}/fileList_tmp.txt > ${outputFolder}/fileList.txt
rm ${outputFolder}/fileList_tmp.txt

##########################
### Merge all files    ###
##########################
plink --bfile ${outputFolder}/${prefixName}.$chrID.${sufixName} --merge-list ${outputFolder}/fileList.txt \
--make-bed --keep-allele-order --out ${outputFolder}/${prefixName}.${sufixName}.all

rm ${outputFolder}/${prefixName}.$chrID.${sufixName}.pruned.*

if [ "${methodType}" == "relatedness" ];
    then
    ###########################
    ### IBS matrix creation ###
    ###########################
    # IBS summarizes if samples are related
    plink --bfile ${outputFolder}/${prefixName}.all --genome --out ${outputFolder}/matriceIBS
    cat ${outputFolder}/matriceIBS.genome | awk '$10 > 0.1' > ${outputFolder}/relatedSamples.txt

elif [ "${methodType}" == "pca" ]; 
    then

    cp ${outputFolder}/${prefixName}.${sufixName}.all.fam ${outputFolder}/${prefixName}.${sufixName}.all.pedind 
    d=$(date +%Y-%m-%d)
    echo "$d"
    COUNT=0; 
    while true; 
    do 
        if [ "$COUNT" -eq 0 ]; 
        then 
            if [ ! -d "${outputFolder}/$d" ]; 
            then 
                echo "folder: ${outputFolder}/$d doesnt exist"; 
                mkdir "${outputFolder}/$d"; 
                folderSmartPCAout="${outputFolder}/$d";
                break; 
            else 
                echo "folder: ${outputFolder}/$d already exists"; 
                ((COUNT++));
            fi 
        else 
            if [ ! -d "${outputFolder}/$d_$COUNT" ]; 
            then 
                echo "folder: ${outputFolder}/${d}_$COUNT doesnt exist"; 
                mkdir "${outputFolder}/${d}_$COUNT"; 
                folderSmartPCAout="${outputFolder}/${d}_$COUNT";
                break; 
            else 
                echo "folder: ${outputFolder}/${d}_$COUNT already exists";
                ((COUNT++)); 
            fi; 
        fi; 
    done

    #######################
    ### Create inputfile###
    #######################
    (
    echo "genotypename:  ${outputFolder}/${prefixName}.${sufixName}.all.bed"
    echo "snpname:  ${outputFolder}/${prefixName}.${sufixName}.all.bim"
    echo "indivname:  ${outputFolder}/${prefixName}.${sufixName}.all.pedind" #(<--- which is the XXX.fam renamed)
    echo "evecoutname: $folderSmartPCAout/WGS.evec"
    echo "evaloutname: $folderSmartPCAout/WGS.eval"
    echo "deletesnpoutname: EIG_removed_SNPs"
    echo "numoutevec: 10"
    ) > $folderSmartPCAout/smarpca.WGS.txt

    
    #######################
    ### PCA ###
    #######################
    /sandbox/users/alves-i/EIG-6.1.4/bin/smartpca -p $folderSmartPCAout/smarpca.WGS.txt > $folderSmartPCAout/logfile.txt

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