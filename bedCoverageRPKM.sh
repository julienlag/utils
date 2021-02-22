#!/bin/bash
shopt -s expand_aliases
source ~/.bashrc

#sorted BAM
inputBam=$1
#sorted GTF
annFile=$2
#genome file
genomeFile=$3
tempDir=$4


#-------------------------------------
# Exit immediately if a simple command exits with a non-zero status.
# (Simplistic error checking)
set -e

function check_exit {
## check the pipe status to ensure that piped command
## succeeded
local BAK=(${PIPESTATUS[@]})
for s in "${BAK[@]}"; do
if [ "$s" != "0" ]; then
echo "bash pipe failed: ${BAK[@]}" 1>&2;
echo $s;
break;
fi;
done
echo 0
}


#tempSortDir="${HOME}/temp/sort/$starBEDFile$time/"

#mkdir -p $tempSortDir
#echo "Created $tempSortDir for sort" >&2

echo "calc number of mapped reads. 'sort' temp dir is $tempDir ." >&2
#for proper counting of pair-end read mappings:
#mappedReads=$(samtools view -F 4 $inputBam |cut -f1|sort --parallel 10 -T $tempDir|uniq|wc -l)
#for simple, non pair-end counting:
mappedReads=$(samtools view -F 0x904 -c $inputBam)
if [ "$(check_exit)" != "0" ]; then echo "ERROR" 1>&2; fi

echo "number of mapped reads: $mappedReads" >&2
		echo "calc RPKMs" >&2
# -g $genomeFile
bedtools coverage -counts -sorted -split -g $genomeFile -a $annFile -b $inputBam  | perl -sne 'chomp; @line=split "\t"; $length=($line[4]-$line[3])+1; $reads=$line[-1]; $rpkm=$reads/($length/1000)/($frag/1000000); pop(@line); print join("\t",@line); print " RPKM \"$rpkm\"; reads \"$reads\";\n";' -- -frag=$mappedReads

		if [ "$(check_exit)" != "0" ]; then echo "ERROR" 1>&2; fi

#