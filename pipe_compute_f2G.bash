#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N f2_CHRID
#$ -o f2_o_CHRID
#$ -e f2_e_CHRID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

#####################
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

#echo $HOME
inputFolder="/mnt/beegfs/ialves"
outputFolder="/mnt/beegfs/ialves"
echo "Working folder: $inputFolder"
echo ""
echo "Output folder: $outputFolder"
echo ""

if [ ! -d "${inputFolder}/fTwo" ]; 
	then
		mkdir ${inputFolder}/fTwo
fi
#loading VCFtools
#module load vcftools/0.1.10

tag1=`echo $1 | sed 's/\(.*\).recode.vcf/\1/'`
echo "Working file: $tag1"
echo ""
tag2=`echo $2 | sed 's/\(.*\).txt/\1/'`
#echo $tag2


/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/$1 --mac 2 --max-mac 2 --recode --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf - --keep ${inputFolder}/$2 --recode --out ${outputFolder}/fTwo/$tag1.$tag2.mac2G  

/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${outputFolder}/fTwo/$tag1.$tag2.mac2G.recode.vcf --singletons --out ${outputFolder}/fTwo/$tag1.$tag2.mac2G

grep $'\t'D$'\t' ${outputFolder}/fTwo/$tag1.$tag2.mac2G.singletons | cut -d$'\t' -f1-2 > ${outputFolder}/fTwo/$tag1.$tag2.exclude


/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${outputFolder}/fTwo/$tag1.$tag2.mac2G.recode.vcf --exclude-positions ${outputFolder}/fTwo/$tag1.$tag2.exclude --recode --out ${outputFolder}/fTwo/$tag1.$tag2.mac2G.noDouble

rm ${outputFolder}/fTwo/$tag1.$tag2.mac2G.recode.vcf

for pop in `ls ${outputFolder}/pop_fTwo/*.txt`; 
	do 
	tmpTag=`echo $pop | cut -d$'/' -f6 | sed 's/\(.*\).txt/\1/'`;
	/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/fTwo/$tag1.$tag2.mac2G.noDouble.recode.vcf --keep $pop --recode --stdout | /commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf - --counts2 --out ${outputFolder}/fTwo/$tag1.$tag2.mac2G.noDouble.$tmpTag
	done

rm ${inputFolder}/fTwo/$tag1.$tag2.mac2G.noDouble.recode.vcf


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