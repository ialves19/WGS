#!/bin/bash
###########################
##
## This script performes variant thinning, ie it uses ./bcfprune developed by Pierre Lindenbaum
## to select a single variant within a window of distance X, where X is specified as an argument for this script. 
##
## It uses the whole genome sequences in the folder below, select individuals from western France in the file : ~/fTwo.2/to_extract_f2G_West.tmp.tmp.txt
## and performes the thinning. 
##
## The script should be run as: qsub -S /bin/bash -cwd ./launchThinning_WGS_alleleShar.bash <chrID> <dir containing the vcf files> <window distance>
## Example: qsub -S /bin/bash -cwd -N thin22 ./launchThinning_WGS_alleleShar.bash chr22 /sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel/vcfs_no_filters 1000
##
## Written by Isabel - July 2020
##
############################


#wrkDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel/vcfs_no_filters"

prefix="20180323.FRENCHWGS.REF0002"
sufix="onlysnps.hwe1e4.maxmiss.90.recode.vcf.gz"

#loading modules
module load bcftools 

#printing file names and working dir
chrID=$1
echo ""
echo "The number of chromosomes in the vcf is : $chrID"
echo ""

vcf="$prefix.$chrID.$sufix"
echo ""
echo "The VCF file used is : $vcf"
echo ""

wrkDir=$2
echo ""
echo "The working directory is : $wrkDir"
echo ""

distance=$3
echo ""
echo "The window size for thinning is : $distance"
echo ""


if [ ! -d "${wrkDir}/fTwo.2" ]; 
        then
                mkdir ${wrkDir}/fTwo.2
fi

outPrefix="WESTfrance"
export LD_LIBRARY_PATH=/sandbox/apps/bioinfo/binaries/htslib/0.0.0/htslib
cd $HOME/bcfprune
bcftools view -S ${wrkDir}/fTwo.2/to_extract_f2G_West.tmp.tmp.txt -O u ${wrkDir}/$vcf \
| bcftools view --min-ac 2 --max-ac 2 -O u | ./bcfprune -O v -d $distance -o ${wrkDir}/fTwo.2/$outPrefix.$chrID.mac2.thinned.vcf

bcftools view -S  ${wrkDir}/fTwo.2/to_extract_f2G_West.tmp.tmp.txt -O u ${wrkDir}/$vcf \
| bcftools view --min-ac 3 --max-ac 10 -O u | ./bcfprune -O v -d $distance -o ${wrkDir}/fTwo.2/$outPrefix.$chrID.mac3to10.thinned.vcf





