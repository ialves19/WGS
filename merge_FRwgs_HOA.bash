#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N convPed_$JOB_ID
#$ -o convPed_o_$JOB_ID
#$ -e convPed_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

##################### RE-WRITE
##  This script requires 20181108.ISABELLRECAL.vcf to be 
##  processed, ie one needs to remove duplicated lines with treating_vcf_beforeTransfBed.bash
##
## This script needs to be launched with the following command:
## for i in `seq 1 22`; do cp pipe_compute_afreq.bash pipe_compute_afreq.chr$i.bash;
## sed -i s/CHRID/$i/ pipe_compute_f2.chr$i.bash;
## qsub pipe_compute_f2.chr$i.bash; ARG1 ARG2
## done
#####################


#setting the sart of the job
res1=$(date +%s.%N)

wkingDir="/sandbox/shares/mages/WGS_PREGO_Finistere_GAZEL/isabel"
methodType="pca"

if [ ! -d "${wkingDir}/HumanOrigins/plink" ]; 
    then
        mkdir ${wkingDir}/HumanOrigins/plink
fi


outputFolder="${wkingDir}/HumanOrigins/plink"

prefixName="20181108.ISABELLRECAL.snps.vcf"
pedFileName="FR_WGs_zoom_calledHOA"
outPrefix="FRwgs_HOA_zoom_maf0.01"

module load plink/1.90
module load vcftools/0.1.15

##########################
### Convert VCF to PED ###
### French WGS         ###
##########################
#converting vcf into BED file by considering half calls as missing data
plink --vcf 20181108.ISABELLRECAL.snps.vcf --vcf-filter --vcf-half-call missing --make-bed --out ${outputFolder}/$pedFileName
#same but with sample selection
vcftools --vcf 20181108.ISABELLRECAL.snps.vcf --keep indTags_westeurZoom.txt --recode --out ${wkingDir}/HumanOrigins/tmp_vcf
plink --vcf ${wkingDir}/HumanOrigins/tmp_vcf.recode.vcf -vcf-filter --vcf-half-call missing --make-bed --out ${outputFolder}/$pedFileName

#removing long LD regions listed in Price et al 2008
plink -bfile ${outputFolder}/$pedFileName --exclude range $wkingDir/HumanOrigins/regions_longLD_toExclude.txt \
--make-bed --out ${outputFolder}/${pedFileName}_clean
cat ${outputFolder}/FR_WGs_zoom_calledHOA_clean.bim | awk '{if($2 ~"."){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/FR_WGs_zoom_calledHOA_clean.bis.bim



##########################
### Treating HOA chip  ###
###                    ###
#convert PACKEDANCESTRY into BED
$HOME/EIG-6.1.4/bin/convertf -p ${wkingDir}/HumanOrigins/par.PACKEDANCESTRYMAP.PACKEDPED
#change coding of mt DNA from 90 to mt 
sed 's/^90/mt/g' HOA.bim > HOA_recoded.bim
#keeping only autosomes in the HOA
plink -bfile ${wkingDir}/HumanOrigins/plink/HOA --autosome --recode --make-bed --out ${wkingDir}/HumanOrigins/plink/HOA_auto
#keeping western eurasian/northern african samples
plink -bfile ${wkingDir}/HumanOrigins/plink/HOA_auto --keep-fam ${wkingDir}/HumanOrigins/westeuropeans_zoom_PCA_HOA.txt --make-bed --out ${wkingDir}/HumanOrigins/plink/HOA_westEur_zoom
#removing long LD regions listed in Price et al 2008
plink -bfile ${wkingDir}/HumanOrigins/plink/HOA_westEur_zoom --exclude range ${wkingDir}/HumanOrigins/regions_longLD_toExclude.txt \
--make-bed --out ${wkingDir}/HumanOrigins/plink/HOA_westEur_zoom_clean
#convert SNPs ids into chr:pos
cat ${outputFolder}/HOA_westEur_zoom_clean.bim | awk '{if($2 ~"Affx" || $2 ~"rs"){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/HOA_westEur_zoom_clean.bis.bim

########################################################
### Convert PED to PACKEDANCESTRY and MERGE DATASETS ###
########################################################
$HOME/EIG-6.1.4/bin/convertf -p ${wkingDir}/HumanOrigins/par.PACKEDPED.PACKEDANCESTRYMAP.FRwgs
$HOME/EIG-6.1.4/bin/convertf -p ${wkingDir}/HumanOrigins/par.PACKEDPED.PACKEDANCESTRYMAP.HOA
$HOME/EIG-6.1.4/bin/mergeit -p ${wkingDir}/HumanOrigins/parFile_mergeEIG.par

############################
### Convert .geno to BED ###
############################
$HOME/EIG-6.1.4/bin/convertf -p ${wkingDir}/HumanOrigins/par.mergedPACKEDANCESTRYMAP.PARCKEDPED #finish


#######################
### Quality control ###
#######################
# Hardy-Weinberg equilibrum at 1e-04, --bfile to specify that the input data are in binary format
# Réduction aux SNP indépendants en deux étapes (LD pruning)
plink --bfile ${outputFolder}/FRwgs_HOA_zoom --maf 0.01 --make-bed --out ${outputFolder}/FRwgs_HOA_zoom_maf0.01

plink --bfile ${outputFolder}/FRwgs_HOA_zoom_maf0.01 --indep-pairwise 50 5 0.1 --out ${outputFolder}/plink.$chrID
plink --bfile ${outputFolder}/FRwgs_HOA_zoom_maf0.01 --extract ${outputFolder}/plink.$chrID.prune.in --make-bed --out ${outputFolder}/FRwgs_HOA_zoom_maf0.01.pruned
plink --bfile ${outputFolder}/FRwgs_HOA_zoom_maf0.01.pruned --r2 --ld-window 10 --ld-window-kb 10000 --ld-window-r2 0.5 --out ${outputFolder}/ld.$chrID

if [ "${methodType}" == "relatedness" ];
    then
    ###########################
    ### IBS matrix creation ###
    ###########################
    # IBS summarizes if samples are related
    /commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/${prefixName}.all --genome --out ${outputFolder}/matriceIBS
    cat ${outputFolder}/matriceIBS.genome | awk '$10 > 0.1' > ${outputFolder}/relatedSamples.txt

elif [ "${methodType}" == "pca" ]; 
    then


    cp ${outputFolder}/${outPrefix}.pruned.fam ${outputFolder}/${outPrefix}.pruned.pedind 
    #######################
    ### Create inputfile###
    #######################
    (
    echo "genotypename:  ${outputFolder}/${outPrefix}.pruned.bed"
    echo "snpname:  ${outputFolder}/${outPrefix}.pruned.bim"
    echo "indivname:  ${outputFolder}/${outPrefix}.pruned.pedind" #(<--- which is the XXX.fam renamed)
    echo "evecoutname: ${outputFolder}/WGS.evec"
    echo "evaloutname: ${outputFolder}/WGS.eval"
    echo "deletesnpoutname: EIG_removed_SNPs"
    echo "numoutevec: 10"
    echo "fsthiprecision: YES"
    ) > ${outputFolder}/smarpca.WGS.txt

    #######################
    ### PCA ###
    #######################
    /sandbox/users/alves-i/EIG-6.1.4/bin/smartpca -p ${outputFolder}/smarpca.WGS.txt > ${outputFolder}/logfile.txt
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
