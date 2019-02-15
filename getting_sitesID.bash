#$ -S /bin/bash
#$ -cwd
#$ -N gs_$JOB_ID
#$ -o gs_o_$JOB_ID
#$ -e gs_e_$JOB_ID
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
outputFolder="/mnt/beegfs/ialves/sites_newSNPcalling"

if [ ! -d "$outputFolder" ];
then
    mkdir $outputFolder
fi 

WGS_fr_vcfFile=$1
WGS_1000G_vcfFile=$2
goNL_vcfFile=$3

chrID=`echo $WGS_fr_vcfFile | sed 's/.*\(chr[0-9]*\).*/\1/'`
chrNb=`echo $WGS_fr_vcfFile | sed 's/.*chr\([0-9]*\).*/\1/'`

echo "Merging chromosome: $chrID"

/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/vcf_ancestral/$WGS_fr_vcfFile --kept-sites --out $outputFolder/$chrID.FR_WGS.ALLSITES
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/vcf_ancestral/$WGS_1000G_vcfFile --kept-sites --out $outputFolder/$chrID.1000G.ALLSITES
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --gzvcf $inputFolder/goNL/$goNL_vcfFile --kept-sites --out $outputFolder/$chrID.goNL.ALLSITES


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
