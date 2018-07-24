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
for chr in `seq 21 22`; do
cmdf="getdata/getdata_chr$chr.sh"
echo "#!/bin/sh" > $cmdf
echo ""  >> $cmdf
echo "#$ -S /bin/bash" >> $cmdf
echo "#$ -cwd" >> $cmdf
echo "#$ -N cp_\$JOB_ID" >> $cmdf
echo "#$ -o cp_o_\$JOB_ID" >> $cmdf
echo "#$ -e cp_e_\$JOB_ID" >> $cmdf
echo "#$ -m a" >> $cmdf
echo "#$ -M Isabel.Alves@univ-nantes.fr" >> $cmdf
echo "" >> $cmdf
echo "runDir=\"/commun/data/users/ialves/fs_example\"" >> $cmdf
echo "" >> $cmdf
echo "cd \$runDir" >> $cmdf
echo "" >> $cmdf
echo "cp ${folderSCRATCH}/phase/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.haps getdata/" >> $cmdf
echo "cp ${workDir}/genetic_map/genetic_map_chr${chr}_combined_b37.txt getdata/" >> $cmdf
echo "perl impute2chromopainter.pl getdata/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.haps getdata/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.cp.haps" >> $cmdf
echo "perl convertrecfile.pl -M hapmap getdata/20180323.FRENCHWGS.REF0002.mac2.chr${chr}.phased.cp.haps genetic_map/genetic_map_chr${chr}_combined_b37.txt getdata/chrom${chr}.recombfile" >> $cmdf
chmod +x $cmdf
echo "qsub $cmdf" >> $cmdfile
done

chmod +x $cmdfile
./$cmdfile
