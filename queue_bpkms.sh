wd=$PWD
# annfile=$1
cat $1 |while read file annfile; do
#for file in `cat bamFilesToFpkm.list`; do
	bn=`basename $file .bam`
	outFilePrefix=$bn.quant
#	if [ ! -f $outFilePrefix ];
#		then
#		echo "file $outFilePrefix needs to be generated. "
		echo "#!/bin/bash
cd $wd
set -e
. /etc/profile
PATH=\"~jlagarde/bin/:~jlagarde/julien_utils/:~jlagarde/bin/bin:$PATH\"
#$ -e $wd/$outFilePrefix.BPKM.q.e
#$ -o $wd/$outFilePrefix.BPKM.q.o
echo 'Running on' \$HOSTNAME >&2
date >&2
if [ ! -f $bn.bed ];
then
echo \"file $bn.bed needs to be generated. \" >&2
date >&2
bamToBed -bed12 -i $file > $bn.bed
date >&2
else
echo \"file $bn.bed already exists, not re-generating it.\" >&2
fi
date >&2
BPKM_on_starBED.sh -s $bn.bed -a $annfile -o $outFilePrefix 
date >&2
" > $outFilePrefix.BPKM.q;
qsub -q main -N j$bn -l h_vmem=22G $outFilePrefix.BPKM.q
#	else
#		echo "file $outFilePrefix already exists, skipping it."
#	fi
done;
