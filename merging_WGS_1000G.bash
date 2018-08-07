#$ -S /bin/bash
#$ -cwd
#$ -N f2_$JOB_ID
#$ -o f2_o_$JOB_ID
#$ -e f2_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr



#setting the sart of the job
res1=$(date +%s.%N)

inputFolder="/mnt/beegfs/ialves"

vcfFile=$1

#module load tabix

/commun/data/packages/tabix-0.2.6/bgzip $inputFolder/vcf_ancestral/$vcfFile
/commun/data/packages/tabix-0.2.6/tabix -p vcf $inputFolder/vcf_ancestral/$vcfFile.gz

if [ ! -d "${inputFolder}/1000G" ]; 
	then
		mkdir ${inputFolder}/1000G
fi

chrID=`echo $vcfFile | sed 's/.*\(chr[0-9]*\).*/\1/'`
echo "Merging chromosome: $chrID"

/commun/data/packages/samtools/1.4/bcftools-1.4/bcftools merge -f PASS $inputFolder/vcf_ancestral/${vcfFile}.gz \
/commun/data/pubdb/ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.${chrID}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz -O v \
-o ${inputFolder}/1000G/merged.WGS.1000G.${chrID}.PASS

echo "Process finished"



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
