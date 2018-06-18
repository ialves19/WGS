#!/bin/bash

#$ -S /bin/bash
#$ -cwd
#$ -N conv
#$ -o conv_o_CHRID
#$ -e conv_e_CHRID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr

#setting the sart of the job
res1=$(date +%s.%N)

export PERL5LIB=/usr/share/perl5


#echo $HOME
inputFolder="/mnt/beegfs/ialves"
outputFolder="/mnt/beegfs/ialves"
geneticMapFolder="/mnt/beegfs/genetic_map"
scriptsFolder="/commun/data/users/ialves/fs-2.1.3/scripts"
referenceFolder="/commun/data/pubdb/mathgen.stats.ox.ac.uk/impute/ALL.integrated_phase1_SHAPEIT_16-06-14.nomono"

#do we use a reference panel
phasingWithRef=true

chrID=$1

#declaring file names
prefix="20180323.FRENCHWGS.REF0002"
sufix="onlysnps.MQ.30.mapRmved.hwe1e4.maxmiss.90"
refHapFn="integrated_phase1_v3.20101123.snps_indels_svs.genotypes.nomono.haplotypes.gz"
refLegFn="integrated_phase1_v3.20101123.snps_indels_svs.genotypes.nomono.legend.gz"
refSamFn="ALL.integrated_phase1_v3.20101123.snps_indels_svs.genotypes.sample"
group="$HOME/group.list"

echo "Working folder: $inputFolder"
echo ""
echo "Output folder: $outputFolder"
echo ""


#checking if output folder already exist
cd ${inputFolder}

if [ ! -d "vcf_cp/" ]; then
	mkdir vcf_cp/
fi
cd 

cd ${inputFolder}

if [ ! -d "phase/" ]; then
	mkdir phase/
fi
cd

#--- Remove fixed ALT and singletons
/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${inputFolder}/$prefix.$chrID.$sufix.recode.vcf --mac 2 --recode --out ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2

/commun/data/packages/vcftools/vcftools_0.1.12b/bin/vcftools --vcf ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2.recode.vcf \
--exclude-positions ${inputFolder}/$chrID.txt --recode --out ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2.over

/commun/data/users/ialves/shapeit.v2.904.2.6.32-696.18.7.el6.x86_64/bin/shapeit -V ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2.over.recode.vcf \
	-M ${geneticMapFolder}/genetic_map_${chrID}_combined_b37.txt --input-ref ${referenceFolder}/ALL.$chrID.${refHapFn} ${referenceFolder}/ALL.$chrID.${refLegFn} ${referenceFolder}/${refSamFn} \
	-O ${outputFolder}/phase/$prefix.mac2.$chrID.phased --window 0.5 --include-grp $group -T 12;


#--- RUNNING SHAPEIT
# if $phasingWithRef ; then

# 		#--- RUNNING SHAPEIT
# 	/commun/data/users/ialves/shapeit.v2.904.2.6.32-696.18.7.el6.x86_64/bin/shapeit -V ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2.recode.vcf \
# 	 -M ${geneticMapFolder}/genetic_map_${chrID}_combined_b37.txt --input-ref ${referenceFolder}/ALL.$chrID.${refHapFn} ${referenceFolder}/ALL.$chrID.${refLegFn} ${referenceFolder}/${refSamFn} \
# 	 -O ${outputFolder}/$prefix.mac2.$chrID.phased --window 0.5 --include-grp $group -T 12;
# else 
# 	#--- RUNNING SHAPEIT
# 	/commun/data/users/ialves/shapeit.v2.904.2.6.32-696.18.7.el6.x86_64/bin/shapeit -V ${outputFolder}/vcf_cp/$prefix.$chrID.$sufix.mac2.recode.vcf \
# 	 -M ${geneticMapFolder}/genetic_map_${chrID}_combined_b37.txt -O ${outputFolder}/$prefix.mac2.$chrID.phased --window 0.5 \
# 	 -T 12;
# fi 	


#--- CONVERTING FILES 
# perl ${scriptsFolder}/impute2chromopainter.pl ${outputFolder}/$prefix.$chrID.phased.haps ${outputFolder}/$prefix.$chrID
# perl ${scriptsFolder}/phasescreen.pl ${outputFolder}/$prefix.$chrID.phase ${outputFolder}/$prefix.$chrID.clean.phase
# perl ${scriptsFolder}/convertrecfile.pl -M hapmap ${outputFolder}/$prefix.$chrID.phase \
# ${geneticMapFolder}/genetic_map_${chrID}_combined_b37.txt \
# ${outputFolder}/map.${chrID}.recombfile 

# if [ ! -d ${outputFolder}/chromoFiles ]; then
#   mkdir ${outputFolder}/chromoFiles
# fi


# --- CONVERTING FILES - vs2
perl /commun/data/users/ialves/Chromopainter/impute2chromopainter2.pl ${outputFolder}/phase/$prefix.mac2.$chrID.phased.haps \
${geneticMapFolder}/genetic_map_${chrID}_combined_b37.txt ${outputFolder}/chromoFiles/$prefix.mac2.$chrID.phased.chromopainter -q

 
#--- running CHOMOPAINTERv2 to estimate switch rate and global mutation rate  
# /commun/data/users/ialves/Chromopainter/ChromoPainterv2 -g <GENOFILE> -r <RECOMBFILE> -t <IND_id_POP_id> -f <POPlist> -i <EM iterations> \
# -in -ip -iM -s <nbSamples> -n <doubleSwitchRate> -M <mutation prop> -k <chunksize> -a 0 0 -b <outputProbPerSite> -d <> -o <outputFileName>  

 
# /commun/data/users/ialves/Chromopainter/ChromoPainterv2 -g ${outputFolder}/chromoFiles/$prefix.$chrID.phased.chromopainter.haps \
# -r ${outputFolder}/chromoFiles/$prefix.$chrID.phased.chromopainter.recomrates -t ${outputFolder}/WGS_france.ids \
# -f ${outputFolder}/population.list 0 0 -i 10 -in -iM -a 0 0 -o ${outputFolder}/chromoOut/$prefix.$chrID



 
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
