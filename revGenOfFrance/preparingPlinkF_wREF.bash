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
    echo "This script takes .gen files from SNP arrays and transform them in binary plink files (bed)"
    echo "after: 1) keeping the sites that passed the QC as indicated in the dataset, "
    echo "2) checking if alleles are in TOP configuration (Human1-2M-DuoCustom_v1_A.update_alleles.txt) and removing the ones that are not;"
    echo "3) checking which alleles need to be flipped by using the strand file; 4) lifting genomic coordinates from hg18 to hg19;"
    echo "5) removing those sites that could not get hg19 coordinates; 6) removing sites not in HWE and 7) duplicated sites."
    echo ""
    echo "NOTE: to keep track of the TOP alleles required to perform the strand flip one needs to convert gen files in ped/maf"
    echo "by exporting with --snp (12 will be replace by the corresponding allele ATGC) and then convert to binary plink files"
    echo ".bed by specifying the missing data character (N) and specifying allele A1 in a text file."
    echo ""
    echo "#This script takes SIX arguments: (1) workDir (2) inputFileName (3) file with all samples in the gen file (4) file w/ samples to keep (5) file w/ snps to include "
    echo "(6) path to the reference genome, (7) file with TOP alleles (8) strand file"
    echo ""
    echo "#Arguments 1,2,3 MUST be provided."
    echo "#if args 4 and 5 aren't provided no subsetting will take place."
    echo "#The script checks whether the input file contains info on the chromosome."
    echo "#Chromosome info will be used to rename sample file, to write output files and generate map file with chromosome info"
    echo "" 

}
##-------------

gettingArgs () { #verifies arguments; retrieves chr ID in case the input files are split by chromosome

    if [ "$wkingDir" != "-" ] | [ "$wkingDir" != "." ] | [ "$wkingDir" != "" ];
    then
        echo "Working directory: ${wkingDir}"
    else 
        echo "No working directory provided.";
        echo "You must provide working directory.";
        exit 1;
    fi

    if [ "$inFileName" != "-" ] | [ "$inFileName" != "." ] | [ "$inFileName" != "" ]; 
    then
        echo "Input file name: ${inFileName}"

        if [[ $inFileName =~ _[0-9]+_ ]];
        then 
            echo "There's chrom info in the input file.";
            chrID=`echo "$inFileName" | sed -r 's/.*\_([0-9]+)\_.*/\1/'`
            if [[ "$chrID" =~ ^0 ]];
                then
                chrID=`echo $chrID | sed 's/^0//g'`
            fi
            echo "Input file name contains chrom: ${chrID}."
            prefix=`echo "$inFileName" | sed -r 's/(.*)\_[0-9]+\_.*/\1/'`
            outputFName="${prefix}_${chrID}_illumina"

        else
            echo "NO chrom info in the input file.";
            exit 1;
            # echo "We may be working with all the chromosomes.";
            # extensionF=`echo $inFileName | sed -r 's/^.*(bim)/\1/'`
            # outputFName=`echo $inFileName | sed -r 's/(.*).bim/\1/'`
        fi

        if [ ! -f ${wkingDir}/${inFileName} ]; 
        then
            echo "There is no input file in the folder: ${wkingDir}";
            exit 1;
        fi

    else 
        echo "No input file name provided.";
        echo "You must provide an input.";
        exit 1;
    fi

    if [ "$sampleFile" != "-" ] | [ "$sampleFile" != "." ] | [ "$sampleFile" != "" ]; 
    then
        echo "Sample file name: ${sampleFile}"

        if [ ! -f ${wkingDir}/${sampleFile} ]; 
        then
            echo "ERROR: Couldn't find sample file in the folder: ${wkingDir}";
            exit 1;
        else
            samplePref=`echo "$sampleFile" | sed -r 's/(.*)\.sample/\1/'`
            sampleFNewName="${samplePref}_chr$chrID.sample"
            
        fi

    else 
        echo "No sample file name provided.";
        echo "You MUST provide it.";
        exit 1;
    fi

    if [ "$sampleToKeep" != "-" ] | [ "$sampleToKeep" != "." ] | [ "$sampleToKeep" != "" ];  
    then
        echo "The file with samples to keep: ${sampleToKeep}"

        if [ ! -f ${wkingDir}/${sampleToKeep} ]; 
        then
            echo "ERROR: Couldn't find the file with samples to keep.";
            exit 1;
        fi

    else 
        echo "No sample subsetting. All samples will be kept.";
    fi

    if [ "$snpToKeep" != "-" ] | [ "$snpToKeep" != "." ] | [ "$snpToKeep" != "" ]; 
    then
        echo "The file with samples to keep: ${snpToKeep}"

        if [ ! -f ${wkingDir}/${snpToKeep} ]; 
        then
            echo "ERROR: Couldn't find the file with snps to keep.";
            exit 1;
        fi

    else 
        echo "No snp subsetting. All snps will be kept.";
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

module load gtool plink R ucsc samtools

wkingDir="/sandbox/users/alves-i/FR_WGS/MS_PS_datasets/EGAD00000000120/calls"
inFileName="MS_21_illumina_rec_allTOP_strand_hwe1e-5_noDup"
pathToRefFasta="/sandbox/resources/species/human/cng.fr/hs37d5/hs37d5_all_chr.fasta"


if [ "$1" == "-h" ]; 
then
    display_help;
    echo ""
else
    gettingArgs;
    echo "";


    if [ -f ${wkingDir}/rsIds_toKeep_chr$chrID.keep ]; 
        then 
        echo "Chr${chrID}: Removing SNPs for which there is no REF allele among a1/a2 alleles."
        echo ""
        plink -bfile ${wkingDir}/${inFileName} --extract ${wkingDir}/rsIds_toKeep_chr$chrID.keep --keep-allele-order --make-bed ${wkingDir}/

    else 
        echo "Chr${chrID}: all SNPs contain the REF allele."
        echo ""
    fi
fi


bcftools merge -m none -0 -O z -o Mbuti.SimonsProj.vcf.gz LP6005592-DNA_C03.annotated.nh2.variants.vcf.gz LP6005441-DNA_B08.annotated.nh2.variants.vcf.gz LP6005441-DNA_A08.annotated.nh2.variants.vcf.gz