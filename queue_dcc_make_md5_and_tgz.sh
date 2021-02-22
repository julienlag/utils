wd=$PWD
daf=$1
for dir in `cat dir_list.txt`; do
	file=`echo $dir|sed 's/\///g'`
	echo "#!/bin/bash
cd $wd
#set -e
. /etc/profile
PATH=\"~jlagarde/bin/:~jlagarde/julien_utils/:~jlagarde/bin/bin:$PATH\"
#$ -e $wd/$file.queue_dcc_make_md5_and_tgz.q.e
#$ -o $wd/$file.queue_dcc_make_md5_and_tgz.q.o
\rm $dir/md5sums.txt;
echo generating md5 checksums... >&2
bash ~/projects/encode/scaling/whole_genome/dcc_submission/scripts/make_md5s.sh $dir;
echo generating md5 checksums DONE... >&2
echo generating TGZs... >&2
#dir=`echo \$dir|sed 's/\///g'`; 
tar -zcf $file.tgz $daf $file.ddf $dir*
echo generating TGZs DONE... >&2
" > $file.queue_dcc_make_md5_and_tgz.q;
qsub -q main -l h_vmem=1G $file.queue_dcc_make_md5_and_tgz.q;

done;
