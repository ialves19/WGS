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
    echo "#This script takes FIVE arguments: (1)workDir (2)path to the executable (3) inputFile (4) file extensions 5) type of output"
    echo ""
    echo "#ALL the arguments MUST be parsed."
    echo "#the input file MUST NOT contain file extension."
    echo "#File extensions are provided in the in argument #4."
    echo "#File extension should be provided as following: "
    echo "# <genotype ext>,<ind ext>,<snp ext>"
    echo "#The type of output are those allowed by convertf and mergeit in the "
    echo "#Admixtools package: "
    echo "#ANCESTRYMAP, EIGENSTRAT, PED, PACKEDPED, PACKEDANCESTRYMAP"
    echo "for more details check the README file of ./convertf"
    echo "" 

}
##------------- end of Help

gettingArgs () { #verifies arguments; retrieves chr ID in case the input files are split by chromosome

    if [ "$wkingDir" != "-" ] | [ "$wkingDir" != "." ] | [ "$wkingDir" != "" ]; 
    then
        echo "Working directory: ${wkingDir}"
    else 
        echo "No working directory provided.";
        echo "You must provide working directory.";
        exit 1;
    fi

    if [ "$excPath" != "-" ] | [ "$excPath" != "." ] | [ "$excPath" != "" ]; 
    then
        echo "Software located here: ${excPath}"
    else 
        echo "ERROR: cannot find program to run.";
        exit 1;
    fi

    if [ "$inFileName" != "-" ] | [ "$inFileName" != "." ] | [ "$inFileName" != "" ]; 
    then
        echo "File name prefix: ${inFileName}"
    else 
        echo "No input file name provided.";
        echo "You must provide an input.";
        exit 1;
    fi

    if [ "$fileExt" != "-" ] | [ "$fileExt" != "." ] | [ "$fileExt" != "" ]; 
    then
        echo "Input files of the type: ${fileExt}."
        genoF=`echo $fileExt | cut -d$'/' -f1`
        indF=`echo $fileExt | cut -d$'/' -f2`
        snpF=`echo $fileExt | cut -d$'/' -f3`
    else 
        echo "ERROR: file extension MUST be provided.";
        exit 1;
    fi

    if [[ -f ${wkingDir}/${inFileName}.${genoF} ]]; 
    then
        echo "Input file ${inFileName}.${genoF} exists in the provided working dir.";
    else 
        echo "ERROR: Input file ${inFileName}.${genoF} does NOT exist in the provided working dir.";
        exit 1;
    fi


    if [ "$typeOutput" != "-" ] | [ "$typeOutput" != "." ] | [ "$typeOutput" != "" ]; 
    then
        echo "Output type: ${typeOutput}."
    else 
        echo "ERROR: no output type specified.";
        exit 1;
    fi

}
##------------- end of gettingArgs

gettingOutExtensions () {

    if [[ "$typeOutput" == "ANCESTRYMAP" ]]; 
    then
    outgeno=${wkingDir}/${inFileName}.ancestrymapgeno
    outInd=${wkingDir}/${inFileName}.ind
    outSnp=${wkingDir}/${inFileName}.snp

    elif [[ "$typeOutput" == "EIGENSTRAT" ]];
    then
    outgeno=${wkingDir}/${inFileName}.eigenstratgeno
    outInd=${wkingDir}/${inFileName}.ind
    outSnp=${wkingDir}/${inFileName}.snp

    elif [[ "$typeOutput" == "PED" ]];
    then
    outgeno=${wkingDir}/${inFileName}.ped
    outInd=${wkingDir}/${inFileName}.pedind
    outSnp=${wkingDir}/${inFileName}.pedsnp

    elif [[ "$typeOutput" == "PACKEDPED" ]];
    then
    outgeno=${wkingDir}/${inFileName}.bed
    outInd=${wkingDir}/${inFileName}.fam
    outSnp=${wkingDir}/${inFileName}.bim

    elif [[ "$typeOutput" == "PACKEDANCESTRYMAP" ]];
    then
    outgeno=${wkingDir}/${inFileName}.packedancestrymapgeno
    outInd=${wkingDir}/${inFileName}.ind
    outSnp=${wkingDir}/${inFileName}.snp
    fi
}
#-------------------
#######################
##
## END of Functions
##
#######################
module load plink #maybe remove

wkingDir=$1
excPath=$2
inFileName=$3
fileExt=$4
typeOutput=$5


if [ "$1" == "-h" ]; 
then
    display_help;
    echo ""
else
    gettingArgs;
    gettingOutExtensions;
    echo "All good with the parameters.";
    echo "";
    echo "Generating par file..."
    echo "genotypename:       ${wkingDir}/${inFileName}.${genoF}" > ${wkingDir}/input.to${typeOutput}.par
    echo "snpname:            ${wkingDir}/${inFileName}.${snpF}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "indivname:          ${wkingDir}/${inFileName}.${indF}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "outputformat:       ${typeOutput}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "genotypeoutname:    ${outgeno}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "snpoutname:         ${outSnp}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "indivoutname:       ${outInd}" >> ${wkingDir}/input.to${typeOutput}.par
    echo "familynames:        NO" >> ${wkingDir}/input.to${typeOutput}.par
    # hashcheck option will verify if one of the input files has been changed since
    #the creation of the geno file. it will stop running if that's the case
    echo "hashcheck:          NO" >> ${wkingDir}/input.to${typeOutput}.par
    $excPath/convertf -p ${wkingDir}/input.to${typeOutput}.par
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