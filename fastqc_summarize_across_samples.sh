#!/bin/bash

### Go through all fastsc folders within a folder, and summarize data

## do be ran from a folder containing FastQC folder as:
	# sh /nfs/users/bi/sbonnin/Scripts/fastqc_summarize_across_samples.sh

# Script directory

scrdir=~jlagarde/julien_utils/


#### Retrieve data and create tables ####


# 1. Overall summary of what modules have passed or failed FastQC threshold
# 2. Per base sequence quality for all samples
# 3. Table containing:
	# Total number of sequences
	# % GC
	# Number of sequences flagged as poor quality
	# Total deduplicated percentage


k=1

for i in `ls -d *fastqc`
do 
#echo $i
#echo $k
pref=`basename $i _fastqc`

if [ $k = 1 ]
then 
  # 1.
(echo "Sample"; grep ">>" ${i}/fastqc_data.txt | grep -v "END_MODULE" | cut -f1 | sed 's/>>//g') | paste -s > FastQC_allsamples_summary.txt
  # 2.
	# finally not used 
	#(echo "Sample"; awk '/^>>Per base sequence quality/{a=1;next}/>>END_MODULE/{a=0}a' ${i}/fastqc_data.txt | cut -f1) | sed 's/#//g' | paste -s | cut -f1,3- > Perbase_sequality_median.txt
  # 3.

echo -e Sample"\t"Total Number Sequences"\t"Percentage GC"\t"Number of sequenced flagged as poor quality"\t"Total deduplicated percentage > FastQC_table_summary.txt

fi

  # 1.
(echo ${pref}; grep ">>" ${i}/fastqc_data.txt | grep -v "END_MODULE" | cut -f2 | sed 's/>>//g') | paste -s >> FastQC_allsamples_summary.txt
  # 2. 	
	# retrieve median
	#(echo ${pref}; awk '/^>>Per base sequence quality/{a=1;next}/>>END_MODULE/{a=0}a' ${i}/fastqc_data.txt | cut -f3) | sed 's/#//g' | paste -s | cut -f1,3- >> Perbase_sequality_median.txt
  # 3.
ttot=`grep "Total Sequences" $i/fastqc_data.txt | cut -f2`
tgc=`grep "%GC" $i/fastqc_data.txt | cut -f2`
tpq=`grep "Sequences flagged as poor quality" $i/fastqc_data.txt | cut -f2`
tdep=`grep "Total Deduplicated Percentage" $i/fastqc_data.txt | cut -f2 | sed 's/#//g'`

echo -e ${pref}"\t"${ttot}"\t"${tgc}"\t"${tpq}"\t"${tdep} >> FastQC_table_summary.txt


((k = k + 1))
done


#### Create summarizing plots and save table_summary.txt into an Excel file ####

Rscript ${scrdir}/fastqc_summarize_all.R FastQC_allsamples_summary.txt FastQC_table_summary.txt


