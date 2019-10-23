#!/bin/bash

#####################
##
##  This script converts vcf or vcf.gz files into .bed with PLINK.
##  PLINK has to be available as a module in your cluster. otherwise this script
##  needs to be changed to replace the executable path to plink.
##
##  the script should be run as: 
##  ./my_scripts/convertingVCF_to_plink.bash <workingDir> <input file name without extension> <output folder if diff from input> <output sufix if wanted>
##
##  or in a cluster with chromosome-specific .bim files as follows:
##
##  COUNT=1;
##  for file in ~/FR_WGS/vcfs_no_filters/*.vcf; 
##  do
##    job_ID=`date +%s`; #assigning a unique id to the job
##    fileName=`echo $file | sed -r 's/^.*\/(.*.vcf$)/\1/'`; #removing the path from the file name
##    fileTag=`echo $fileName | sed -r 's/(.*).vcf.*/\1/'`; #removing the extension
##    #calling the bash script
##   qsub -cwd -N vcftolink_$job_ID -o vcftoplink_o_$job_ID -e vcftoplink_e_$job_ID my_scripts/convertingVCF_to_plink.bash ~/FR_WGS/vcfs_no_filters $fileTag ~/FR_WGS/plink/plinkFiles \-
##    sleep 1; #to be sure the job_id is unique
##  ((COUNT++));
##  done
#####################


#setting the sart of the job
res1=$(date +%s.%N)

#######################
##
## Functions
##
#######################
display_help () {

    echo ""
    echo "# HELP: -h"
    echo ""
    echo "#This script takes FOUR arguments: (1)workDir (2)inputFileName (3)outputDir (4)outputSufix"
    echo ""
    echo "#The first and second arguments MUST be provided."
    echo "#In case args 3 and 4 are not provided the user should write -"
    echo "#In case no ouput directory is specified the output files will be generated in working directory"
    echo "#The script checks whether the input files are chromosome specific or not."
    echo "#In case a sufix is not provided the output file name is either: "
    echo "	1. the name of the input file, in case this is not chromosome specific, "
    echo "	2. or the name of the input file name unill the chromosome tag plus the chromosome tag itself." 
    echo "" 

}
##-------------

gettingArgs () { #verifies arguments; retrieves chr ID in case the input files are split by chromosome

    if [ "$wkingDir" != "-" ]; 
    then
        echo "Working directory: ${wkingDir}"
    else 
        echo "No working directory provided.";
        echo "You must provide working directory.";
        break;
    fi

    if [ "$inFileName" != "-" ]; 
    then
        echo "Input file name: ${inFileName}"

        if [[ $inFileName =~ .chr[0-9]+. ]];
        then 
            echo "There's chrom info in the input file.";
            chrID=`echo "$inFileName" | sed -r 's/.*\.(chr[0-9]+)\..*/\1/'`
            echo "Input file name contains chrom: ${chrID}."
            prefix=`echo "$inFileName" | sed -r 's/(.*)\.chr[0-9]+\..*/\1/'`
            outputFName="${prefix}.${chrID}"

        else
            echo "NO chrom info in the input file.";
            echo "We may be working with all the chromosomes.";
            extensionF=`echo $inFileName | sed -r 's/^.*(vcf\.*)/\1/'`
            outputFName=`echo $inFileName | sed -r 's/(.*).vcf.*/\1/'`
        fi

    else 
        echo "No input file name provided.";
        echo "You must provide an input.";
        break;
    fi

    if [ "$outDir" != "-" ]; 
    then
        echo "Output directory name: ${outDir}."
        echo "Results will be printed in this folder: ${outDir}"
    else 
        echo "Output directory name provided.";
        echo "Results will be generated in the working directory.";
        outDir="${wkingDir}"
    fi

    if [ "$outFileSuf" != "-" ]; 
    then
        echo "Output sufix name provided: ${outFileSuf}."
        outputFName="${outputFName}.${outFileSuf}"
        echo "Output file file name : ${outputFName}"
    else 
        echo "Output sufix name NOT provided.";
        outputFName="${outputFName}";
        echo "Output file name: $outputFName";

    fi
}
##-------------
######################
##
## END of functions
##
#######################

#######################
##
## Main
##
#######################

module load plink

wkingDir=$1
inFileName=$2
outDir=$3
outFileSuf=$4

if [ "$1" == "-h" ]; 
then
    display_help;
    echo ""
else
    gettingArgs;
    echo "";
    plink --vcf ${wkingDir}/${inFileName}.vcf --vcf-filter --keep-allele-order --make-bed --out ${outDir}/${outputFName}

    cat ${outDir}/${outputFName}.bim | awk '{if($2 =="."){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outDir}/${outputFName}.bis.bim
    mv ${outDir}/${outputFName}.bis.bim ${outDir}/${outputFName}.bim
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
