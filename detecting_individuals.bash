#!/bin/bash

folderMain="/home/isabelalves/Dropbox/instDuThorax/samples"
fileIndIDtoRm=$1
fileContainIndToRm=""

while IFS='' read -r line || [[ -n "$line" ]]; do
    
    fileContainIndToRm=`grep $line ${folderMain}/samples_PCA_wholeFrance_n25/*.txt | cut -d$':' -f1`
    if [ "$fileContainIndToRm" != "" ]; 
    then
        echo $line$'\t'$fileContainIndToRm >> ${folderMain}/relatedInd_PLINK/individuals_to_rm.txt
    fi


done < "${folderMain}/relatedInd_PLINK/${fileIndIDtoRm}"