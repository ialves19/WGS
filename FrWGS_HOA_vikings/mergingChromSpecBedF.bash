#!/bin/bash


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
    echo "#The script checks whether the input file contains info on the chromosome."
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

        if [[ $inFileName =~ [._]chr[0-9]+[._] ]] || [[ $inFileName =~ [._][0-9]+[._] ]];
        then 
            echo "There's chrom info in the input file.";
            if [[ $inFileName =~ [._]chr[0-9]+[._] ]]; 
            then 
                chrID=`echo "$inFileName" | sed -r 's/.*[._](chr[0-9]+)[._].*/\1/'`
                chrTag=` echo "$inFileName" | sed -r 's/.*([._]chr[0-9]+[._]).*/\1/'`
                echo "Input file name contains chrom: ${chrID}."
                prefix=`echo "$inFileName" | sed -r 's/(.*)[._](chr[0-9]+)[._].*/\1/'`
                outputFName="${prefix}"
            elif [[ $inFileName =~ [._][0-9]+[._] ]]; 
            then
                chrID=`echo "$inFileName" | sed -r 's/.*[._]([0-9]+)[._].*/\1/'`
                chrTag=` echo "$inFileName" | sed -r 's/.*([._][0-9]+[._]).*/\1/'`
                echo "Input file name contains chrom: ${chrID}."
                prefix=`echo "$inFileName" | sed -r 's/(.*)[._]([0-9]+)[._].*/\1/'`
                outputFName="${prefix}"          
            fi
        else
            echo "NO chrom info in the input file.";
            echo "ERROR: BED files will not be merged.";
            break;
            # echo "We may be working with all the chromosomes.";
            # extensionF=`echo $inFileName | sed -r 's/^.*(bim)/\1/'`
            # outputFName=`echo $inFileName | sed -r 's/(.*).bim/\1/'`
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
        echo "NO output directory name provided.";
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

# wkingDir="/sandbox/users/alves-i/FR_WGS/MS_PS_datasets/EGAD00000000120/calls"
# inFileName="MS_1_illumina_rec_allTOP_strand_hwe1e-5_noDup.bed"
# outDir="-"
# outFileSuf="allCHROM"



if [ "$1" == "-h" ]; 
then
    display_help;
    echo ""
else
    gettingArgs;
    echo "";
    #creating input with all the names of the files to merge
    for i in `seq 1 22`;
    do
        #chrFileName=`ls ${wkingDir}/${prefix}.chr${i}.bim`
        newChrTag=`echo $chrTag | sed -e s/[0-9+]/$i/g`
        echo $newChrTag;
        chrFileName=`ls ${wkingDir}/${prefix}${newChrTag}*bim`;
        prefixOutFName=`echo $chrFileName | sed 's/\(.*\).bim/\1/'`;
        echo $prefixOutFName

        echo $prefixOutFName.bed$' '$prefixOutFName.bim$' '$prefixOutFName.fam >> ${wkingDir}/fileList_tmp.txt
    done
    sed '1d' ${wkingDir}/fileList_tmp.txt > ${wkingDir}/fileList.txt
    rm ${wkingDir}/fileList_tmp.txt

    #running plink to merge files based on the fileList.txt created above   
    plink --bfile ${wkingDir}/${inFileName} --merge-list ${wkingDir}/fileList.txt --make-bed --keep-allele-order --out ${outDir}/${outputFName}

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
