#$ -S /bin/bash
#$ -cwd
#$ -N m1k_$JOB_ID
#$ -o m1k_o_$JOB_ID
#$ -e m1k_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr



#setting the sart of the job
res1=$(date +%s.%N)

################################
##
## this script takes the vcf (.GZ) file with the FR samples as an argument $1
## and detects from the file name, provided as arg, the chr it needs to look 
## for among the 1000G files.
## it also needs a file with all the FR and 1000G samples we want to keep in the vcf
##
## it merges the vcf with the FR samples and the 1000G only for the shared/all sites
## depending we setup the keepCommon= TRUE/FALSE respectively. 
##
## To launch it qsub merging_WGS_1000G.bash french_WGS.vcf
## NOTE: DO NOT ADD THE .gz to the input file.
##
## Oct 2018
###############################

inputFolder="/mnt/beegfs/ialves"

#full path to the files
fileOne=$1
fileTwo=$2

chrID=`echo $fileOne | sed 's/.*\(chr[0-9]*\).*/\1/'`
chrNb=`echo $fileOne | sed 's/.*chr\([0-9]*\).*/\1/'`
prefix="FR_1000G_goNL"

echo "Merging chromosome: $chrID"
keepCommon=false
sufixTag="allSites"
pops="FR.IBS.GBR.TSI.NL"


if [ "$keepCommon" == true ];
then
	# checking common sites 
	/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/${fileOne} --gzdiff $inputFolder/${fileTwo} --out $inputFolder/1000G/out.${prefix}.${chrID}

	grep $'\t'B$'\t' $inputFolder/1000G/out.${prefix}.${chrID}.diff.sites_in_files | cut -d$'\t' -f1,2 > ${inputFolder}/1000G/common.sites.${prefix}.${chrID}.txt

	#merging 1000G and Fr WGS
	/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools merge -f PASS $inputFolder/${fileTwo} $inputFolder/${fileOne} -Ou \
    | /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -m2 -M2 -O v -o ${inputFolder}/1000G/merged.WGS.${prefix}.${chrID}.PASS.vcf
	#keeping only sites common to FR WGS and 1000G in the merged 
	/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/1000G/merged.WGS.${prefix}.${chrID}.PASS.vcf --positions ${inputFolder}/1000G/common.sites.${prefix}.${chrID}.txt \
	--recode --out ${inputFolder}/1000G/merged.WGS.${prefix}.${chrID}.PASS.$sufixTag.$pops
else 
	#merging 1000G and Fr WGS
	/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools merge -f PASS $inputFolder/${fileOne} $inputFolder/${fileTwo} -Ou \
    | /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -m2 -M2 -Ov -o ${inputFolder}/1000G/merged.WGS.${prefix}.${chrID}.PASS.$sufixTag.$pops.vcf
		
fi

echo "Merging finished"

rm ${inputFolder}/1000G/merged.WGS.${prefix}.${chrID}.PASS.vcf


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



