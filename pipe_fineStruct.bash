#!/bin/sh

export PERL5LIB=/usr/share/perl5


cd /mnt/beegfs/ialves
folderSCRATCH=`pwd`

mkdir -p fs_WGS
workDir="/mnt/beegfs/ialves/fs_WGS"

# into /mnt/beegfs/ialves/fs_WGS
cd ${workDir}
####### Get genetic maps
cp -r /mnt/beegfs/genetic_map . 

#into /mnt/beegfs/ialves/fs_WGS/genetic_map
cd ${workDir}/genetic_map

projName="french_wgs"

#########################
# transforms the recombination map files from SHAPEit 
# webpage into the hapmap form 
# required for the proper computation of the recomb rates needed for 
# chromosome painting - automatic mode
########################
for file in *.txt;
	do
	chrID=`echo $file | cut -d$'_' -f3`
	sizeF=`sed 1d $file | wc -l`
	echo "chromosome" > ${chrID}_tmp.txt
	for ((i=1; i<=$sizeF; i++)); do echo $chrID >> ${chrID}_tmp.txt; done
	paste -d$' ' ${chrID}_tmp.txt $file > $file.bis
	echo "chromosome Position(BP) Rate(cm/Mb) Map(cM)" > $file
	sed 1d $file.bis >> $file
done
rm chr*_tmp.txt
rm *.bis

#into /mnt/beegfs/ialves/fs_WGS
cd ..
#######get the ids file
cp ${folderSCRATCH}/WGS_france_two.ids .
sed -e 's/ //2g' WGS_france_two.ids > WGS_france_coco.ids
rm WGS_france_two.ids

#generate the folder with input files
mkdir -p getdata
cmdfile="getdata_raw.sh"
rm -f $cmdfile
cp /commun/data/users/ialves/fs-2.1.3/scripts/impute2chromopainter.pl .
cp /commun/data/users/ialves/fs-2.1.3/scripts/convertrecfile.pl .
cp /commun/data/users/ialves/fs-2.1.3/fs . 
for chr in `seq 1 22`; do
cmdf="getdata/getdata_chr$chr.sh"
echo "#!/bin/sh" > $cmdf
echo ""  >> $cmdf
echo "#$ -S /bin/bash" >> $cmdf
echo "#$ -cwd" >> $cmdf
echo "#$ -N gd_\$JOB_ID" >> $cmdf
echo "#$ -o gd_o_\$JOB_ID" >> $cmdf
echo "#$ -e gd_e_\$JOB_ID" >> $cmdf
echo "#$ -m a" >> $cmdf
echo "#$ -M Isabel.Alves@univ-nantes.fr" >> $cmdf
echo "" >> $cmdf
echo "export PERL5LIB=/usr/share/perl5" >> $cmdf
echo "runDir=\"$workDir\"" >> $cmdf
echo "" >> $cmdf
echo "cd \$runDir" >> $cmdf
echo "" >> $cmdf
echo "chmod +x ${workDir}/impute2chromopainter.pl"
echo "chmod +x ${workDir}/convertrecfile.pl"
echo "cp ${folderSCRATCH}/phase/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.haps getdata/" >> $cmdf
echo "perl ${workDir}/impute2chromopainter.pl getdata/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.haps getdata/chr${chr}.phased.cp.haps" >> $cmdf
echo "perl ${workDir}/convertrecfile.pl -M hapmap getdata/chr${chr}.phased.cp.haps.phase genetic_map/genetic_map_chr${chr}_combined_b37.txt getdata/chrom${chr}.recombfile" >> $cmdf

chmod +x $cmdf
qsub $cmdf
done

declare -a PHASENAMES;
declare -a RECOMBNAMES;
CHROMS=( 4 10 15 22 )

for chrID in "${CHROMS[@]}";
	do 
	PHASENAMES[$chrID]="getdata/chr$chrID.phased.cp.haps.phase"
	RECOMBNAMES[$chrID]="getdata/chrom$chrID.recombfile"
done

# Generating command lines for stage one - estimating Ne and mu
genComStageOne="genCommStgOne.sh"
echo "#!/bin/sh" > $genComStageOne
echo "cd $workDir" >> $genComStageOne
echo "./fs $projName.cp -n -phasefiles ${PHASENAMES[*]} -recombfiles ${RECOMBNAMES[*]} \
-idfile WGS_france_coco.ids -hpc 1 -s1indfrac 0.1 -go" >> $genComStageOne

chmod +x $genComStageOne
qsub -hold_jid "gd_*" -N gcO -cwd $genComStageOne

#################
##
## stage 1
##
#################

#splitting command lines
splitComLStageOne="splitComLineStgO.sh"
echo "#!/bin/sh" > $splitComLStageOne
echo "cd ${workDir}/${projName}/commandfiles" >> $splitComLStageOne
echo "split -l 20 commandfile1.txt commandSub-" >> $splitComLStageOne

chmod +x $splitComLStageOne
qsub -hold_jid "gcO" -N stgOne -cwd $splitComLStageOne


echo "#$ -S /bin/sh"  > ${workDir}/tmp.sh
echo "#$ -cwd"  >> ${workDir}/tmp.sh
echo "#$ -N stO_\$JOB_ID" >> ${workDir}/tmp.sh
echo "#$ -o stO_o_\$JOB_ID" >> ${workDir}/tmp.sh
echo "#$ -e stO_e_\$JOB_ID" >> ${workDir}/tmp.sh
echo "#$ -m a" >> ${workDir}/tmp.sh
echo "#$ -M Isabel.Alves@univ-nantes.fr" >> ${workDir}/tmp.sh
echo "" >> ${workDir}/tmp.sh
echo "runDir=${workDir}" >> ${workDir}/tmp.sh
echo "" >> ${workDir}/tmp.sh
echo "cd \$runDir" >> ${workDir}/tmp.sh
echo "" >> ${workDir}/tmp.sh

launchStageOne="lauchingStgOne.sh"
echo '#!/bin/sh' > $launchStageOne
echo "" >> $launchStageOne
echo "cd ${workDir}/${projName}/commandfiles" >> $launchStageOne
echo "COUNT=0" >> $launchStageOne
echo "for fileCom in commandSub-*;" >> $launchStageOne
echo "do" >> $launchStageOne
echo -e "\tlet COUNT++;" >> $launchStageOne
echo -e "\tqsubName=\"qsub_\$COUNT.sh\"" >> $launchStageOne
echo -e "\tcp ${workDir}/tmp.sh ." >> $launchStageOne
echo -e "\tmv tmp.sh \$qsubName" >> $launchStageOne
echo "echo \"#running file \$fileCom >> \$qsubName\"" >> $launchStageOne
echo -e "\tsed 's/fs/\\.\/fs/g' \$fileCom >> \$qsubName" >> $launchStageOne
echo -e "\trm \$fileCom" >> $launchStageOne
echo "done" >> $launchStageOne
echo -e "\tmv *.sh ${workDir}/" >> $launchStageOne 


chmod +x $launchStageOne
qsub -hold_jid "gcO" -S /bin/sh -N lsO -cwd $launchStageOne
chmod +x qsub_*

jobNb="ls qsub_* | wc -l"
for jobs in `seq 1 $jobNb`; 
do
	qsub -hold_jid "lsO" -S /bin/sh -N stO -cwd qsub_$jobs.sh
done

################## End of stage one
##------------
#-------


#################
##
## stage 2
##
#################
declare -a PHASENAMES;
declare -a RECOMBNAMES;
CHROMS=( {1..22} )

for chrID in "${CHROMS[@]}";
	do 
	PHASENAMES[$chrID]="getdata/chr$chrID.phased.cp.haps.phase"
	RECOMBNAMES[$chrID]="getdata/chrom$chrID.recombfile"
done


fs french_wgs.cp -duplicate 1 french_wgs_new.cp -PHASEFILES ${PHASENAMES[*]}
fs french_wgs_new.cp -recombfiles ${RECOMBNAMES[*]}

ne=`grep Neinf french_wgs.cp | cut -d$' ' -f1`
mu=`grep muinf french_wgs.cp | cut -d$' ' -f1`

sed -i s/Neinf:-1/$ne/g french_wgs_new.cp
sed -i s/muinf:-1/$mu/g french_wgs_new.cp

# Generating command lines for stage two - chromosome paiting
genComStageTwo="genCommStgTwo.sh"
echo '#!/bin/sh' > $genComStageTwo
echo "cd $workDir" >> $genComStageTwo
echo "./fs ${projName}_new.cp -indsperproc 100 -go" >> $genComStageTwo

chmod +x $genComStageTwo
qsub -hold_jid "stO" -N stgTwo -cwd $genComStageTwo

#splitting command lines
splitComLStageTwo="splitComLineStgT.sh"
echo "#!/bin/sh" > $splitComLStageTwo
echo "cd ${workDir}/${projName}_new/commandfiles" >> $splitComLStageTwo
echo "split -l 2 commandfile2.txt commandSample-" >> $splitComLStageTwo

chmod +x $splitComLStageTwo

sed -i s/stO/stT/g tmp.sh

launchStageTwo="lauchingStgTwo.sh"
echo '#!/bin/sh' > $launchStageTwo
echo "" >> $launchStageTwo
echo "cd ${workDir}/${projName}_new/commandfiles" >> $launchStageTwo
echo "COUNT=0" >> $launchStageTwo
echo "for fileCom in commandSample-*;" >> $launchStageTwo
echo "do" >> $launchStageTwo
echo -e "\tlet COUNT++;" >> $launchStageTwo
echo -e "\tqsubName=\"qsub_\$COUNT.sh\"" >> $launchStageTwo
echo -e "\tcp ${workDir}/tmp.sh ." >> $launchStageTwo
echo -e "\tmv tmp.sh \$qsubName" >> $launchStageTwo
echo "echo \"#running file \$fileCom >> \$qsubName\"" >> $launchStageTwo
echo -e "\tsed 's/fs/\\.\/fs/g' \$fileCom >> \$qsubName" >> $launchStageTwo
echo -e "\trm \$fileCom" >> $launchStageTwo
echo "done" >> $launchStageTwo
echo -e "\tmv *.sh ${workDir}/" >> $launchStageTwo 


# Generating command lines for stage two - chromosome paiting
genComStageThree="genCommStgThree.sh"
echo '#!/bin/sh' > $genComStageThree
echo "cd $workDir" >> $genComStageThree
echo "./fs ${projName}_new.cp -s3iters 2000000 -go" >> $genComStageThree

# Generating command lines for stage two - chromosome paiting
genAfterStageThree="genAfterStgThree.sh"
echo '#!/bin/sh' > $genAfterStageThree
echo "cd $workDir" >> $genAfterStageThree
echo "./fs ${projName}_new.cp -go" >> $genAfterStageThree



##STEP FOUR
#splitting command lines for tree construction step 4
splitComFStageFour="splitComFStageFour.sh"
echo "#!/bin/sh" > $splitComFStageFour
echo "cd ${workDir}/${projName}_new/commandfiles" >> $splitComFStageFour
echo "split -l 1 commandfile4.txt commandSample-" >> $splitComFStageFour

chmod +x $splitComFStageFour

sed -i s/stT/stF/g tmp.sh

launchStageFour="launchStageFour.sh"
echo '#!/bin/sh' > $launchStageFour
echo "" >> $launchStageFour
echo "cd ${workDir}/${projName}_new/commandfiles" >> $launchStageFour
echo "COUNT=0" >> $launchStageFour
echo "for fileCom in commandSample-*;" >> $launchStageFour
echo "do" >> $launchStageFour
echo -e "\tlet COUNT++;" >> $launchStageFour
echo -e "\tqsubName=\"job_fs_stage4_\$COUNT.sh\"" >> $launchStageFour
echo -e "\tcp ${workDir}/tmp.sh ." >> $launchStageFour
echo -e "\tmv tmp.sh \$qsubName" >> $launchStageFour
echo "echo \"#running file \$fileCom >> \$qsubName\"" >> $launchStageFour
echo -e "\tsed 's/^fs/\\.\/fs/g' \$fileCom >> \$qsubName" >> $launchStageFour
echo -e "\trm \$fileCom" >> $launchStageFour
echo "done" >> $launchStageFour
echo -e "\tmv *.sh ${workDir}/" >> $launchStageFour 

chmod +x $launchStageFour

qsub -N step4 -cwd -S /bin/sh $launchStageFour 

# Generating command lines for stage two - chromosome paiting
genAfterStageFour="genAfterStageFour.sh"
echo '#!/bin/sh' > $genAfterStageFour
echo "cd $workDir" >> $genAfterStageFour
echo "./commun/data/users/ialves/fs-2.1.3/fs ${projName}.cp -go" >> $genAfterStageFour


