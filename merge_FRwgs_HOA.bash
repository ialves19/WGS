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

wkingDir="/mnt/beegfs/ialves"
methodType="pca"

if [ ! -d "${wkingDir}/HumanOrigins/plink" ]; 
    then
        mkdir ${wkingDir}/HumanOrigins/plink
fi


outputFolder="${wkingDir}/HumanOrigins/plink"

prefixName="20181108.ISABELLRECAL.snps.vcf"
pedFileName="FR_WGs_calledHOA"
outPrefix="FRwgs_HOAlazaridis"


##########################
### Convert VCF to PED ###
##########################
#converting vcf into BED file by considering half calls as missing data
/commun/data/packages/plink/plink-1.9.0/plink --vcf 20181108.ISABELLRECAL.snps.vcf --vcf-filter --vcf-half-call missing --make-bed --out ${outputFolder}/$pedFileName
#removing long LD regions listed in Price et al 2008
/commun/data/packages/plink/plink-1.9.0/plink -bfile ${outputFolder}/$pedFileName --exclude range /mnt/beegfs/ialves/HumanOrigins/regions_longLD_toExclude.txt \
--make-bed --out ${outputFolder}/${pedFileName}_clean





#convert PACKEDANCESTRY into BED
$HOME/EIG-6.1.4/bin/convertf -p /mnt/beegfs/ialves/HumanOrigins/par.PACKEDANCESTRYMAP.PACKEDPED
#change coding of mt DNA from 90 to mt 
sed 's/^90/mt/g' HOA.bim > HOA_recoded.bim
#keeping only autosomes in the HOA
/commun/data/packages/plink/plink-1.9.0/plink -bfile /mnt/beegfs/ialves/HumanOrigins/plink/HOA --autosome --recode --make-bed --out /mnt/beegfs/ialves/HumanOrigins/plink/HOA_auto
#keeping western eurasian/northern african samples
/commun/data/packages/plink/plink-1.9.0/plink -bfile /mnt/beegfs/ialves/HumanOrigins/plink/HOA_auto --keep-fam ${wkingDir}/HumanOrigins/westeurasians_PCA_HOA.txt --make-bed --out /mnt/beegfs/ialves/HumanOrigins/plink/HOA_westEur
#removing long LD regions listed in Price et al 2008
/commun/data/packages/plink/plink-1.9.0/plink -bfile /mnt/beegfs/ialves/HumanOrigins/plink/HOA_westEur --exclude range /mnt/beegfs/ialves/HumanOrigins/regions_longLD_toExclude.txt \
--make-bed --out /mnt/beegfs/ialves/HumanOrigins/plink/HOA_westEur_clean
#convert SNPs ids into chr:pos
cat ${outputFolder}/HOA_westEur_clean.bim | awk '{if($2 ~"Affx"){OFS="\t";print $1,$1":"$4,$3,$4,$5,$6}else{print $0}}' > ${outputFolder}/HOA_westEur_clean.bis.bim

########################################################
### Convert PED to PACKEDANCESTRY and MERGE DATASETS ###
########################################################
$HOME/EIG-6.1.4/bin/convertf -p /mnt/beegfs/ialves/HumanOrigins/par.PACKEDPED.PACKEDANCESTRYMAP.FRwgs
$HOME/EIG-6.1.4/bin/convertf -p /mnt/beegfs/ialves/HumanOrigins/par.PACKEDPED.PACKEDANCESTRYMAP.HOA
$HOME/EIG-6.1.4/bin/mergeit -p /mnt/beegfs/ialves/HumanOrigins/parFile_mergeEIG.par

############################
### Convert .geno to BED ###
############################
$HOME/EIG-6.1.4/bin/convertf -p /mnt/beegfs/ialves/HumanOrigins/par.mergedPACKEDANCESTRYMAP.PARCKEDPED #finish


#######################
### Quality control ###
#######################
# Hardy-Weinberg equilibrum at 1e-04, --bfile to specify that the input data are in binary format
# Réduction aux SNP indépendants en deux étapes (LD pruning)
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/FRwgs_HOAlazaridis --indep-pairwise 50 5 0.5 --out ${outputFolder}/plink.$chrID
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/FRwgs_HOAlazaridis --extract ${outputFolder}/plink.$chrID.prune.in --make-bed --out ${outputFolder}/FRwgs_HOAlazaridis.pruned
/commun/data/packages/plink/plink-1.9.0/plink --bfile ${outputFolder}/FRwgs_HOAlazaridis.pruned --r2 --ld-window 10 --ld-window-kb 10000 --ld-window-r2 0.5 --out ${outputFolder}/ld.$chrID

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
    /commun/data/users/ialves/EIG-6.1.4/bin/smartpca -p ${outputFolder}/smarpca.WGS.txt > ${outputFolder}/logfile.txt
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
