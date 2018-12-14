#$ -S /bin/bash
#$ -cwd
#$ -N sfs_$JOB_ID
#$ -o sfs_o_$JOB_ID
#$ -e sfs_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr



#setting the sart of the job
res1=$(date +%s.%N)

logFileName="report_checking_segSizes.log"

for i in `seq 1 22`; do
    COUNT_LINE=1
    chrID="chr$i"
    echo $chrID
    totalNbRegions=`grep ^$chrID$'\t' 20181116.bed | wc -l | cut -d$' ' -f1`
    echo "Nb of regions in chrm: $chrID is $totalNbRegions" >> $logFileName
    #COUNT_LINE=50

    while [ $COUNT_LINE -le "$totalNbRegions" ];
    do
        grep ^$chrID$'\t' 20181116.bed | sed -n ${COUNT_LINE}p | cut -d$'\t' -f5 | tr " " "\n" > neutral_region_${chrID}_${COUNT_LINE}_tmp.bed

        #replace : and - from the tmp bed file above
        sed 's/[:-]/\t/g' neutral_region_${chrID}_${COUNT_LINE}_tmp.bed | sort -k2 -n > neutral_region_${chrID}_${COUNT_LINE}.bed
        rm neutral_region_${chrID}_${COUNT_LINE}_tmp.bed

        COUNT=0;
        while IFS='' read -r line || [[ -n "$line" ]]; do
            #echo "Text read from file: $line"
            lastCol=`echo $line | cut -d$' ' -f3`
            #echo "$lastCol"
            firstCol=`echo $line | cut -d$' ' -f2`
            diff=$(( lastCol - firstCol ))
            #echo "$diff"
            COUNT=$(( COUNT + diff))
        done < "neutral_region_${chrID}_${COUNT_LINE}.bed"
        #echo "Region nb: $COUNT_LINE is of size: $COUNT"
        if [ $COUNT -ne 1000000 ]
        then
        echo "ERROR: Chromosome $chrID, segment nb $COUNT_LINE is of size: $COUNT" >> $logFileName
        break
        else
        cat neutral_region_${chrID}_${COUNT_LINE}.bed >> neutral_region_${chrID}.bed
        fi
        ((COUNT_LINE++))
    done
done
rm neutral_region_chr*_*.bed

for i in `seq 1 22`; do cat neutral_region_chr$i.bed >> neutral_regions_ALLChrms.bed; done

#check if there are overlapping regions
nrowF=`wc -l neutral_regions_ALLChrms.bed | cut -d$' ' -f1`
COUNT=1
while [ $COUNT -le $nrowF ]; do echo "$COUNT" >> line_tags_nb.tmp; ((COUNT++)); done

paste -d$'\t' neutral_regions_ALLChrms.bed line_tags_nb.tmp > neutral_regions_ALLChrms_tag.bed
/commun/data/packages/bedtools/bedtools2-2.25.0/bin/bedtools merge -c 4 -o collapse -i neutral_regions_ALLChrms_tag.bed >> in.sort.merged.neutralReg.bed

grep "," in.sort.merged.neutralReg.bed | cut -d$'\t' -f4 | cut -d, -f1 > tmp1.tmp
grep "," in.sort.merged.neutralReg.bed | cut -d$'\t' -f4 | cut -d, -f2 > tmp2.tmp
paste -d$'\t' tmp1.tmp tmp2.tmp > row_overlReg.txt
rm tmp*.tmp

while IFS='' read -r line || [[ -n "$line" ]]; do
    #echo "Text read from file: $line"
    lastCol=`echo $line | cut -d$' ' -f2`
    #echo "$lastCol"
    firstCol=`echo $line | cut -d$' ' -f1`
    diff=$(( lastCol - firstCol ))
    if [ $diff -gt 1 ]; 
    then
    echo "ERROR: Regions nb: $lastCol and $firstCol differ by more than one site: $diff"
    fi
done < "row_overlReg.txt"

/commun/data/packages/bedtools/bedtools2-2.25.0/bin/bedtools merge -c 4 -o collapse -i neutral_regions_ALLChrms_tag.bed >> in.sort.merged.neutralReg.bed
cut -d$'\t' -f1,2,3 in.sort.merged.neutralReg.bed > in.sort.merged.neutralReg_noTag.bed
 
for i in `seq 1 22`; do grep ^chr$i$'\t' in.sort.merged.neutralReg_noTag.bed > merged_neutralReg.chr$i.bed;done
for i in `seq 1 13`; do split -l 750 --numeric-suffixes merged_neutralReg.chr$i.bed merged_neutralReg.chr${i}_; done
for file in `ls merged_neutralReg.chr*_0*`; do mv $file $file.bed;done

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