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
    echo "#This script takes SEVEN arguments: (1)workDir (2)path to the executable (3)inputFile ONE (4)inputFile TWO (5)file extensions (6) output type (7)output file name"
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
    echo "Output file name should be provided without extension"
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

    if [ "$inFileNameONE" != "-" ] | [ "$inFileNameONE" != "." ] | [ "$inFileNameONE" != "" ]; 
    then
        echo "File name ONE prefix: ${inFileNameONE}"
    else 
        echo "No input file name provided.";
        echo "You must provide an input.";
        exit 1;
    fi

    if [ "$inFileNameTWO" != "-" ] | [ "$inFileNameTWO" != "." ] | [ "$inFileNameTWO" != "" ]; 
    then
        echo "File name TWO prefix: ${inFileNameTWO}"
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

    if [[ -f ${wkingDir}/${inFileNameONE}.${genoF} ]]; 
    then
        echo "Input file ${inFileNameONE}.${genoF} exists in the provided working dir.";
    else 
        echo "ERROR: Input file ${inFileNameONE}.${genoF} does NOT exist in the provided working dir.";
        exit 1;
    fi

    if [[ -f ${wkingDir}/${inFileNameTWO}.${genoF} ]]; 
    then
        echo "Input file ${inFileNameTWO}.${genoF} exists in the provided working dir.";
    else 
        echo "ERROR: Input file ${inFileNameTWO}.${genoF} does NOT exist in the provided working dir.";
        exit 1;
    fi

    if [ "$typeOutput" != "-" ] | [ "$typeOutput" != "." ] | [ "$typeOutput" != "" ]; 
    then
        echo "Output type: ${typeOutput}."
    else 
        echo "ERROR: no output type specified.";
        exit 1;
    fi

    if [ "$outFname" != "-" ] | [ "$outFname" != "." ] | [ "$outFname" != "" ]; 
    then
        echo "Output file name is: ${outFname}."

    else 
        echo "ERROR: no output type specified.";
        exit 1;
    fi
}
##------------- end of gettingArgs

gettingOutExtensions () {

    if [[ "$typeOutput" == "ANCESTRYMAP" ]]; 
    then
    outgeno=${wkingDir}/${outFname}.ancestrymapgeno
    outInd=${wkingDir}/${outFname}.ind
    outSnp=${wkingDir}/${outFname}.snp

    elif [[ "$typeOutput" == "EIGENSTRAT" ]];
    then
    outgeno=${wkingDir}/${outFname}.eigenstratgeno
    outInd=${wkingDir}/${outFname}.ind
    outSnp=${wkingDir}/${outFname}.snp

    elif [[ "$typeOutput" == "PED" ]];
    then
    outgeno=${wkingDir}/${outFname}.ped
    outInd=${wkingDir}/${outFname}.pedind
    outSnp=${wkingDir}/${outFname}.pedsnp

    elif [[ "$typeOutput" == "PACKEDPED" ]];
    then
    outgeno=${wkingDir}/${outFname}.bed
    outInd=${wkingDir}/${outFname}.fam
    outSnp=${wkingDir}/${outFname}.bim

    elif [[ "$typeOutput" == "PACKEDANCESTRYMAP" ]];
    then
    outgeno=${wkingDir}/${outFname}.packedancestrymapgeno
    outInd=${wkingDir}/${outFname}.ind
    outSnp=${wkingDir}/${outFname}.snp
    fi
}
#-------------------
#######################
##
## END of Functions
##
#######################


wkingDir=$1
excPath=$2
inFileNameONE=$3
inFileNameTWO=$4
fileExt=$5
typeOutput=$6
outFname=$7


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
    echo "geno1:           ${wkingDir}/${inFileNameONE}.${genoF}" > ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "snp1:            ${wkingDir}/${inFileNameONE}.${snpF}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "ind1:            ${wkingDir}/${inFileNameONE}.${indF}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "geno2:           ${wkingDir}/${inFileNameTWO}.${genoF}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par           
    echo "snp2:            ${wkingDir}/${inFileNameTWO}.${snpF}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "ind2:            ${wkingDir}/${inFileNameTWO}.${indF}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "genooutfilename: ${outgeno}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "snpoutfilename:  ${outSnp}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "indoutfilename:  ${outInd}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "outputformat:    ${typeOutput}" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "docheck:         YES" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    echo "hashcheck:       NO" >> ${wkingDir}/input.MERGEIT.to${typeOutput}.par
    $excPath/mergeit -p ${wkingDir}/input.MERGEIT.to${typeOutput}.par
fi
