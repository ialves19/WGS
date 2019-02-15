#!/bin/bash

chrID=$1
dirPath="/home/isabelalves/Dropbox/instDuThorax/SNP_reCalling"
outFile="vennDiagramValues_$chrID.txt"

listFiles=($dirPath/$chrID.*)
echo Dataset$'\t'All_sites$'\t'Uniq_Sites$'\t'sharedSites$'\t'uniqSites_Pop1$'\t'uniqSites_Pop2 > $dirPath/$outFile

COUNT=0
for file in ${listFiles[@]}; do 
    
    echo ${listFiles[$COUNT]};
    fileTagOne=`echo ${listFiles[$COUNT]} | cut -d$'/' -f7 | cut -d$'.' -f2`
    cat ${listFiles[$COUNT]} | sed '1d' | sort -k2 -n | uniq >> ${dirPath}/$chrID.ALLSITES.txt
    popAllSites=`cat ${listFiles[$COUNT]} | sed '1d' | sort -k2 -n | uniq | wc -l`
    echo $fileTagOne$'\t'$popAllSites$'\t'NA$'\t'NA$'\t'NA$'\t'NA >> $dirPath/$outFile 

    if [ $(( $COUNT + 1 )) -ge ${#listFiles[@]} ]; then break; fi

    for pair in `seq $COUNT $(( ${#listFiles[@]} - 1 ))`; 
    do 
    if [ $pair -gt $COUNT ]; then
    #echo $pair
    fileTagTwo=`echo ${listFiles[$pair]} | cut -d$'/' -f7 | cut -d$'.' -f2`
    echo $fileTagOne;
    echo $fileTagTwo;
    cat ${listFiles[$COUNT]} | sed '1d' | sort -k2 -n | uniq  >> ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt
    cat ${listFiles[(($pair))]} | sed '1d' | sort -k2 -n | uniq >> ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt

    cat ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt | sort -k2 -n | uniq >> ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.UNIQSITES.txt
    cat ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt | sort -k2 -n | uniq -cd | sed 's/^ \+//g' | sed 's/ /\t/g' | cut -d$'\t' -f2,3 > ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.COMMONSITES.txt
    # cat ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.UNIQSITES.txt > ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.UNIONTMP.txt
    # cat ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.COMMONSITES.txt >> ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.UNIONTMP.txt

    totalNbSites=`wc -l ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt | cut -d$' ' -f1`
    totalUniqSites=`cat  ${dirPath}/$chrID.${fileTagOne}_${fileTagTwo}.ALLSITES.txt | sort -k2 -n | uniq | wc -l`
    sharedSites=$(( $totalNbSites - $totalUniqSites ))
    sitesInOne=`cat ${listFiles[$COUNT]} | sed '1d' | sort -k2 -n | uniq | wc -l`
    sitesInTwo=`cat ${listFiles[$pair]} | sed '1d' | sort -k2 -n | uniq | wc -l`
    uniqToOne=$(( $sitesInOne - $sharedSites ))
    uniqToTwo=$(( $sitesInTwo - $sharedSites ))
    echo "$fileTagOne and $fileTagTwo share: $sharedSites sites";
    echo "$fileTagOne has this amount of unique sites: $uniqToOne sites";
    echo "$fileTagTwo has this amount of unique sites: $uniqToTwo sites";
    
    echo ${fileTagOne}_${fileTagTwo}$'\t'$totalNbSites$'\t'$totalUniqSites$'\t'$sharedSites$'\t'$uniqToOne$'\t'$uniqToTwo >> $dirPath/$outFile 
    fi
    done
    rm ${dirPath}/$chrID.*.ALLSITES.txt
    ((COUNT++));
done

cat ${dirPath}/$chrID.*.COMMONSITES.txt > ${dirPath}/$chrID.COMMONSITES.txt
allSitesAcrossPops=`cat ${dirPath}/$chrID.ALLSITES.txt | sort -k2 -n | uniq | wc -l`
commonSitesAllThree=`cat ${dirPath}/$chrID.COMMONSITES.txt | sort -k2 -n | uniq -cd | grep 3$' '$chrID | wc -l`
echo ALL$'\t'$allSitesAcrossPops$'\t'NA$'\t'$commonSitesAllThree$'\t'NA$'\t'NA >> $dirPath/$outFile 
cat ${dirPath}/$chrID.ALLSITES.txt | sort -k2 -n | uniq >> ${dirPath}/$chrID.allUNIQUE.sites
rm ${dirPath}/$chrID.*.txt