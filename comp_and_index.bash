#$ -S /bin/bash
#$ -cwd
#$ -N zip_$JOB_ID
#$ -o zip_o_$JOB_ID
#$ -e zip_e_$JOB_ID
#$ -m a
#$ -M Isabel.Alves@univ-nantes.fr


#setting the sart of the job
res1=$(date +%s.%N)

module load bcftools
wkdir="/sandbox/users/alves-i/FR_WGS/vcfs_no_filters"

chrNb=$1

bcftools view -O z -o ${wkdir}/20180323.FRENCHWGS.REF0002.chr$chrNb.onlysnps.hwe1e4.maxmiss.90.recode.vcf.gz ${wkdir}/20180323.FRENCHWGS.REF0002.chr$chrNb.onlysnps.hwe1e4.maxmiss.90.recode.vcf
bcftools index -t ${wkdir}/20180323.FRENCHWGS.REF0002.chr$chrNb.onlysnps.hwe1e4.maxmiss.90.recode.vcf.gz


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



