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

vcfFile=$1
keepCommon=true
sufixTag="allSites.v2"

#module load tabix

# /commun/data/packages/tabix-0.2.6/bgzip $inputFolder/vcf_ancestral/$vcfFile
# /commun/data/packages/tabix-0.2.6/tabix -p vcf $inputFolder/vcf_ancestral/$vcfFile.gz

if [ ! -d "${inputFolder}/1000G" ]; 
	then
		mkdir ${inputFolder}/1000G
fi

chrID=`echo $vcfFile | sed 's/.*\(chr[0-9]*\).*/\1/'`
chrNb=`echo $vcfFile | sed 's/.*chr\([0-9]*\).*/\1/'`

echo "Merging chromosome: $chrID"

#keep biallelic sites in the 1000G vcf & keeping only GBR, IBS and TSU & replacing chr tag and zipping
/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -m2 -M2 -v snps -f PASS \
/commun/data/pubdb/ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.${chrID}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz -Ou \
| /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -S ${inputFolder}/1000G/1000G_EURsamples.txt -Ou | /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -c1 -O v \
| sed s/^$chrNb/$chrID/g | /commun/data/packages/tabix-0.2.6/bgzip -c > $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz
# indexing files
/commun/data/packages/tabix-0.2.6/tabix -p vcf $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz

/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -R ${inputFolder}/accessGenome/accessGen_${chrID}.txt -O z -o $inputFolder/vcf_ancestral/1000G.clean.acceGen.${chrID}.vcf.gz $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz
# indexing files
/commun/data/packages/tabix-0.2.6/tabix -p vcf $inputFolder/vcf_ancestral/1000G.clean.acceGen.${chrID}.vcf.gz

rm $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz*

/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/vcf_ancestral/1000G.clean.acceGen.${chrID}.vcf.gz --max-missing 0.90 --hwe 0.0001 --recode --stdout \
| /commun/data/packages/tabix-0.2.6/bgzip -c > $inputFolder/vcf_ancestral/1000G.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz
# indexing files
/commun/data/packages/tabix-0.2.6/tabix -p vcf $inputFolder/vcf_ancestral/1000G.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz

rm $inputFolder/vcf_ancestral/1000G.clean.acceGen.${chrID}.vcf.gz*

#rm $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz

if [ "$keepCommon" == true ];
then

	# checking common sites 
	/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/vcf_ancestral/${vcfFile}.gz --gzdiff $inputFolder/vcf_ancestral/1000G.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz --out ${inputFolder}/1000G/out.${chrID}

	grep $'\t'B$'\t' ${inputFolder}/1000G/out.${chrID}.diff.sites_in_files | cut -d$'\t' -f1,2 > ${inputFolder}/1000G/common.sites.${chrID}.txt

	#merging 1000G and Fr WGS
	/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools merge -f PASS $inputFolder/vcf_ancestral/${vcfFile}.gz \
	$inputFolder/vcf_ancestral/1000G.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz -Ou | /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -m2 -M2 \
	-O v -o ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS.vcf
	#keeping only sites common to FR WGS and 1000G in the merged 
	/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS.vcf --positions ${inputFolder}/1000G/common.sites.${chrID}.txt \
	--recode --out ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS.FR.IBS.GBR.TSI
else 
	#merging 1000G and Fr WGS
	/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools merge -f PASS $inputFolder/vcf_ancestral/${vcfFile}.gz \
	$inputFolder/vcf_ancestral/1000G.clean.acceGen.maxmiss.90.hwe1e4.${chrID}.vcf.gz -Ou | /commun/data/packages/samtools/1.4/bcftools-1.4/bcftools view -m2 -M2 \
	-O v -o ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS.$sufixTag.FR.IBS.GBR.TSI.vcf
		
fi

echo "Merging finished"

# rm ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS.vcf
# rm $inputFolder/vcf_ancestral/1000G.clean.${chrID}.vcf.gz
# rm $inputFolder/vcf_ancestral/1000G.clean.${chrID}.tbi



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
