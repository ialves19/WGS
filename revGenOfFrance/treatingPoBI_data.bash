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

wkingDir=$1
inFileName=$2
sampleFile=$3
sampleToKeep=$4
snpToKeep=$5
pathToRefFasta=$6
topFName=$7
strdFName=$8

# wkingDir="/sandbox/users/alves-i/FR_WGS/PoBI"
# inFileName="WTCCC2_POBI_illumina_calls_POBI_03_illumina.gen"
# sampleFile="WTCCC2_POBI_illumina_calls_POBI_illumina.sample"
# sampleToKeep="WTCCC2_POBI_illumina_qc_passed_POBI_illumina_sample_include.txt"
# snpToKeep="WTCCC2_POBI_illumina_qc_passed_POBI_illumina_SNP_include.txt"
# pathToRefFasta="/sandbox/resources/species/human/cng.fr/hs37d5/hs37d5_all_chr.fasta"


if [ "$1" == "-h" ]; 
then
    display_help;
    echo ""
else
    gettingArgs;
    echo "";
    cp ${wkingDir}/${sampleFile} ${wkingDir}/${sampleFNewName}

    #keeping snps and samples passing QC
    gtool -S --g ${wkingDir}/${inFileName} --s ${wkingDir}/${sampleFNewName} --sample_id ${wkingDir}/${sampleToKeep} --inclusion ${wkingDir}/${snpToKeep} --og ${wkingDir}/${outputFName}_tmp.gen
    #converting .gen to .ped, lhood probability > .90 and recoding alleles as ATGC (--snp), missing genoytpes are: 'N'
    gtool -G --g ${wkingDir}/${outputFName}_tmp.gen --s ${wkingDir}/${sampleFNewName}.subset --chr "$chrID" --alleles --threshold 0.90 --snp --ped ${wkingDir}/${outputFName}.ped --map ${wkingDir}/${outputFName}.map
    rm ${wkingDir}/${outputFName}_tmp.gen ${wkingDir}/*_chr$chrID.sample

    #converting to .bed, recoding 12 means that the allele 1 will be provided in a file generated as following:
    cat ${wkingDir}/${outputFName}.map | awk '{printf("%s\t%s\n", $2,$5);}' > ${wkingDir}/chr${chrID}_recode_allele.txt
    #plink --file ${wkingDir}/${outputFName} --missing-genotype 'N' --recode 12 --make-bed --out ${wkingDir}/${outputFName}_rec
    plink --file ${wkingDir}/${outputFName} --missing-genotype 'N' --a1-allele ${wkingDir}/chr${chrID}_recode_allele.txt --make-bed --out ${wkingDir}/${outputFName}_rec
    #plink --file ${wkingDir}/${outputFName}_rec --make-bed --out ${wkingDir}/${outputFName}_rec
    rm  ${wkingDir}/*${chrID}_illumina.ped ${wkingDir}/*${chrID}_illumina.map 

    #checkign if alleles are in TOP
    Rscript --vanilla checkingTOPalleles.R ${wkingDir} ${outputFName}_rec.bim ${topFName} ${chrID}
    if [ -f ${wkingDir}/notOnTOP_SNPs_chr$chrID.txt ];
    then
        echo ""
        echo "Removing sites not on TOP"
        echo ""
        #removing sites not in TOP 
        plink --bfile ${wkingDir}/${outputFName}_rec --exclude ${wkingDir}/notOnTOP_SNPs_chr${chrID}.txt --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP
        #re-cheking TOP conf
        Rscript --vanilla checkingTOPalleles.R ${wkingDir} ${outputFName}_rec_allTOP.bim ${topFName} ${chrID}
    else 
        echo ""
        echo "All sites are on TOP configuration."
        echo ""
        cp ${wkingDir}/${outputFName}_rec.bed ${wkingDir}/${outputFName}_rec_allTOP.bed
        cp ${wkingDir}/${outputFName}_rec.bim ${wkingDir}/${outputFName}_rec_allTOP.bim
        cp ${wkingDir}/${outputFName}_rec.fam ${wkingDir}/${outputFName}_rec_allTOP.fam
    fi

    #putting everything in the + strand
    #cp ${wkingDir}/Human1-2M-DuoCustom_v1_A-b36.strand ${wkingDir}/Human1-2M-DuoCustom_v1_A-b36_chr${chrID}.strand 
    #./update_build.sh ${wkingDir}/${outputFName}_rec_allTOP ${wkingDir}/Human1-2M-DuoCustom_v1_A-b36_chr${chrID}.strand ${wkingDir}/${outputFName}_rec_allTOP_strand
    Rscript --vanilla gettingSNPsToFlip.R ${wkingDir} ${outputFName}_rec_allTOP.bim $strdFName ${chrID}

    if [ -f ${wkingDir}/SNPtoRemNotStrandF_chr${chrID}.txt ];
    then 
        plink --bfile ${wkingDir}/${outputFName}_rec_allTOP --exclude ${wkingDir}/SNPtoRemNotStrandF_chr${chrID}.txt --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_tmp
        mv ${wkingDir}/${outputFName}_rec_allTOP_tmp.bim ${wkingDir}/${outputFName}_rec_allTOP.bim
        mv ${wkingDir}/${outputFName}_rec_allTOP_tmp.fam ${wkingDir}/${outputFName}_rec_allTOP.fam
        mv ${wkingDir}/${outputFName}_rec_allTOP_tmp.bed ${wkingDir}/${outputFName}_rec_allTOP.bed
        Rscript --vanilla gettingSNPsToFlip.R ${wkingDir} ${outputFName}_rec_allTOP.bim $strdFName ${chrID}

    fi

    plink --bfile ${wkingDir}/${outputFName}_rec_allTOP --flip ${wkingDir}/snps_to_flip_chr${chrID}.txt --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_strand
    
    #retrieve the physical positions to send lift to hg19
    cat ${wkingDir}/${outputFName}_rec_allTOP_strand.bim | awk '{OFS="\t"};{print $1, $4-1, $4}' | sed 's/^/chr/' > ${wkingDir}/map.chr${chrID}_1.bed
    liftOver ${wkingDir}/map.chr${chrID}_1.bed $HOME/hg18ToHg19.over.chain ${wkingDir}/map.chr${chrID}_1.new.bed ${wkingDir}/map.chr${chrID}_1.error

    liftError=`wc -l ${wkingDir}/map.chr${chrID}_1.error | cut -d$' ' -f1`
    if [ $liftError -ge 2 ]; 
    then  
        grep chr$chrID ${wkingDir}/map.chr${chrID}_1.error | awk '{print $3}' | while read Pos; do grep -n $Pos ${wkingDir}/${outputFName}_rec_allTOP_strand.bim | cut -d$'\t' -f2 >> ${wkingDir}/noLift_chr$chrID.txt; done;
        plink --bfile ${wkingDir}/${outputFName}_rec_allTOP_strand --exclude ${wkingDir}/noLift_chr$chrID.txt --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_strand_lift
        cat ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bim | awk '{OFS="\t"};{print $1, $4-1, $4}' | sed 's/^/chr/' > ${wkingDir}/map.chr${chrID}_2.bed
        liftOver ${wkingDir}/map.chr${chrID}_2.bed $HOME/hg18ToHg19.over.chain ${wkingDir}/map.chr${chrID}_2.new.bed ${wkingDir}/map.chr${chrID}_2.error
        #transform .bim file accordingly
        paste -d'\t' <(cut -d$'\t' -f1,2,3 ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bim) <(awk -F'\t' '{print $3}' ${wkingDir}/map.chr${chrID}_2.new.bed) <(cut -d$'\t' -f5,6 ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bim) > ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.bim
        cp ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bed ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.bed
        cp ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.fam ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.fam

    else

        #transform .bim file accordingly
        paste -d'\t' <(cut -d$'\t' -f1,2,3 ${wkingDir}/${outputFName}_rec_allTOP_strand.bim) <(awk -F'\t' '{print $3}' ${wkingDir}/map.chr${chrID}_1.new.bed) <(cut -d$'\t' -f5,6 ${wkingDir}/${outputFName}_rec_allTOP_strand.bim) > ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bim
        cp ${wkingDir}/${outputFName}_rec_allTOP_strand.bed ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.bed
        cp ${wkingDir}/${outputFName}_rec_allTOP_strand.fam ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.fam
        cp ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.bim ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.bim

    fi


    #filtering according to hwe
    plink -bfile ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp --hwe 1e-5 --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5
    rm ${wkingDir}/${outputFName}_rec_allTOP_strand_tmp.*

    #remove HLA regions #Zabaneh et al 2016 Scientific reports
    if [ "$chrID" == "6" ]
    then
        plink -bfile ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5 --exclude-snp --from-bp 29691116 --to-bp 33054976 --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5
    fi

    #remove duplicates
    plink -bfile ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5 --list-duplicate-vars --out ${wkingDir}/${outputFName}_to_exclude
    plink -bfile ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5 --exclude ${wkingDir}/${outputFName}_to_exclude.dupvar --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup_tmp
    
    #Deprecated. the following steps need to be removed as we are not using the script update_build.sh provided in https://www.well.ox.ac.uk/~wrayner/strand/index.html
    # grep -v "^$chrID" ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup_tmp.bim | cut -d$'\t' -f2 > ${wkingDir}/noChromMatch_chr$chrID.exclude
    # plink -bfile ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup_tmp --exclude ${wkingDir}/noChromMatch_chr$chrID.exclude --keep-allele-order --make-bed --out ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup
    
    #remove sites for which none of the alleles is the one in the reference. 
    #getting the ref allele 
    grep ^$chrID ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup.bim | awk '{printf("chr%s:%s-%s\n", $1,$4,$4);}' | while read P; do samtools faidx $pathToRefFasta ${P}; done > ${wkingDir}/referenceAllele_chr${chrID}_hg19.out
    #checking whether the ref is one of the alleles in the bim file
    Rscript --vanilla checking_matchWRefhg19.R ${wkingDir} ${outputFName}_rec_allTOP_strand_hwe1e-5_noDup.bim referenceAllele_chr${chrID}_hg19.out $chrID
   
    #cleaning up the folder
    rm ${wkingDir}/${outputFName}_rec.* ${wkingDir}/${outputFName}_rec_allTOP.* ${wkingDir}/${outputFName}_rec_allTOP_strand.* ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5.*
    rm ${wkingDir}/WTCCC2_POBI_illumina_calls_POBI_illumina_chr${chrID}.sample.subset
    rm ${wkingDir}/${outputFName}_rec_allTOP_strand_lift.* ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup.log
    #rm ${wkingDir}/map.chr$chrID*
    #rm ${wkingDir}/noLift_chr${chrID}.txt ${wkingDir}/notOnTOP_SNPs_chr${chrID}.txt
    #rm ${wkingDir}/snps_to_flip_chr${chrID}.txt ${wkingDir}/chr${chrID}_recode_allele.txt
    rm ${wkingDir}/${outputFName}_rec_strand_hwe1e-5_noDup.log 
    rm ${wkingDir}/${outputFName}_rec_strand_lift.bim
    rm ${wkingDir}/${outputFName}_to_exclude.dupvar
    rm ${wkingDir}/${outputFName}_to_exclude.log
    rm ${wkingDir}/${outputFName}_rec_allTOP_strand_hwe1e-5_noDup_tmp.*
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